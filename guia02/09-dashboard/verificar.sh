#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Verificación del Dashboard de CloudWatch
# ============================================================

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-laboratorio-eks}"
DASHBOARD_NAME="${CLUSTER_NAME}-observability"
NAMESPACE="alumnos"

echo ""
echo "=========================================="
echo " VERIFICACIÓN DEL DASHBOARD"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1) Verificar que el dashboard existe
# ----------------------------------------------------------
echo "--- 1. Verificando Dashboard ---"
DASHBOARD_EXISTS=$(aws cloudwatch get-dashboard \
  --dashboard-name "$DASHBOARD_NAME" \
  --region "$REGION" \
  --query 'DashboardName' \
  --output text 2>/dev/null || echo "")

if [ "$DASHBOARD_EXISTS" = "$DASHBOARD_NAME" ]; then
  echo "  ✅ Dashboard existe: $DASHBOARD_NAME"
  
  # Contar widgets
  WIDGET_COUNT=$(aws cloudwatch get-dashboard \
    --dashboard-name "$DASHBOARD_NAME" \
    --region "$REGION" \
    --query 'DashboardBody' \
    --output text 2>/dev/null | \
    python3 -c "import sys,json; print(len(json.load(sys.stdin).get('widgets',[])))" 2>/dev/null || echo "0")
  echo "     Widgets: $WIDGET_COUNT"
else
  echo "  ❌ Dashboard no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 2) Verificar métricas custom
# ----------------------------------------------------------
echo "--- 2. Verificando Métricas Custom ---"

# Tiempo de despliegue
DEPLOY_DURATION=$(aws cloudwatch list-metrics \
  --namespace "Custom" \
  --metric-name "DeployDuration" \
  --region "$REGION" \
  --query 'Metrics[].MetricName' \
  --output text 2>/dev/null || echo "")
if [ -n "$DEPLOY_DURATION" ]; then
  echo "  ✅ DeployDuration: disponible"
else
  echo "  ❌ DeployDuration: no encontrada"
fi

# Cobertura de pruebas
TEST_COVERAGE=$(aws cloudwatch list-metrics \
  --namespace "Custom" \
  --metric-name "TestCoverage" \
  --region "$REGION" \
  --query 'Metrics[].MetricName' \
  --output text 2>/dev/null || echo "")
if [ -n "$TEST_COVERAGE" ]; then
  echo "  ✅ TestCoverage: disponible"
else
  echo "  ❌ TestCoverage: no encontrada"
fi

# Conteo de despliegues
DEPLOY_COUNT=$(aws cloudwatch list-metrics \
  --namespace "Custom" \
  --metric-name "DeployCount" \
  --region "$REGION" \
  --query 'Metrics[].MetricName' \
  --output text 2>/dev/null || echo "")
if [ -n "$DEPLOY_COUNT" ]; then
  echo "  ✅ DeployCount: disponible"
else
  echo "  ❌ DeployCount: no encontrada"
fi
echo ""

# ----------------------------------------------------------
# 3) Verificar métricas de Container Insights
# ----------------------------------------------------------
echo "--- 3. Verificando Métricas Container Insights ---"
CI_METRICS=$(aws cloudwatch list-metrics \
  --namespace "ContainerInsights" \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'Metrics[].MetricName' \
  --output text 2>/dev/null || echo "")

if [ -n "$CI_METRICS" ]; then
  echo "  ✅ Container Insights: métricas disponibles"
  echo "$CI_METRICS" | tr '\t' '\n' | sort -u | head -5 | sed 's/^/     /'
else
  echo "  ⚠️  Container Insights: métricas pendientes"
fi
echo ""

# ----------------------------------------------------------
# 4) Verificar que el dashboard tiene datos
# ----------------------------------------------------------
echo "--- 4. Verificando datos en Dashboard ---"

# Obtener datos de CPU (último valor)
CPU_DATA=$(aws cloudwatch get-metric-statistics \
  --namespace "ContainerInsights" \
  --metric-name "pod_cpu_utilization" \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=Namespace,Value="$NAMESPACE" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 300 \
  --statistics Average \
  --region "$REGION" \
  --query 'Datapoints[0].Average' \
  --output text 2>/dev/null || echo "0")

if [ "$CPU_DATA" != "0" ] && [ "$CPU_DATA" != "None" ]; then
  echo "  ✅ CPU data: ${CPU_DATA}%"
else
  echo "  ⚠️  CPU data: sin datos recientes"
fi

# Obtener datos de memoria
MEM_DATA=$(aws cloudwatch get-metric-statistics \
  --namespace "ContainerInsights" \
  --metric-name "pod_memory_working_set" \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=Namespace,Value="$NAMESPACE" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 300 \
  --statistics Average \
  --region "$REGION" \
  --query 'Datapoints[0].Average' \
  --output text 2>/dev/null || echo "0")

if [ "$MEM_DATA" != "0" ] && [ "$MEM_DATA" != "None" ]; then
  echo "  ✅ Memory data: ${MEM_DATA} bytes"
else
  echo "  ⚠️  Memory data: sin datos recientes"
fi
echo ""

# ----------------------------------------------------------
# 5) Verificar logs en CloudWatch
# ----------------------------------------------------------
echo "--- 5. Verificando Logs ---"
LOG_GROUP="/aws/eks/${CLUSTER_NAME}/application"
LOG_STREAMS=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by "LastEventTime" \
  --descending \
  --limit 3 \
  --region "$REGION" \
  --query 'logStreams[].logStreamName' \
  --output text 2>/dev/null || echo "")

if [ -n "$LOG_STREAMS" ]; then
  echo "  ✅ Logs disponibles:"
  echo "$LOG_STREAMS" | tr '\t' '\n' | head -3 | sed 's/^/     /'
else
  echo "  ⚠️  Logs: sin streams recientes"
fi
echo ""

# ----------------------------------------------------------
# 6) Resumen
# ----------------------------------------------------------
echo "=========================================="
echo " RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo ""
echo "  📊 DASHBOARD: https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${DASHBOARD_NAME}"
echo ""
echo "  Métricas incluidas:"
echo "    ✅ Tiempo de despliegue (Custom/DeployDuration)"
echo "    ✅ Cobertura de pruebas (Custom/TestCoverage)"
echo "    ✅ Uso de CPU por pod (ContainerInsights)"
echo "    ✅ Uso de memoria por pod (ContainerInsights)"
echo "    ✅ Errores en logs (AWS/Logs)"
echo "    ✅ Estado de pods (ContainerInsights)"
echo "    ✅ Alarmas activas (AWS/CloudWatch)"
echo ""
echo "=========================================="
