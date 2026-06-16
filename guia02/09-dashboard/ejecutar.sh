#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# PASO 9 — Dashboard de CloudWatch + Métricas CI/CD
# ============================================================

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-laboratorio-eks}"
DASHBOARD_NAME="${CLUSTER_NAME}-observability"
NAMESPACE="alumnos"

echo ""
echo "=========================================="
echo " DASHBOARD DE OBSERVABILIDAD"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1) Verificar conexión al cluster
# ----------------------------------------------------------
echo "--- 1. Verificando conexión al cluster EKS ---"
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [ -z "$CURRENT_CONTEXT" ]; then
  echo "  ERROR: No hay contexto kubectl configurado"
  exit 1
fi
echo "  Contexto: $CURRENT_CONTEXT"
echo ""

# ----------------------------------------------------------
# 2) Crear métricas custom iniciales (para que el dashboard tenga datos)
# ----------------------------------------------------------
echo "--- 2. Publicando métricas custom iniciales ---"

# Métrica: Tiempo de despliegue (simulado - en real viene del pipeline)
aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployDuration" \
  --dimensions "Service=backend" \
  --value 180 \
  --unit "Seconds" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica - verifique permisos)"

aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployDuration" \
  --dimensions "Service=frontend" \
  --value 120 \
  --unit "Seconds" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica)"

# Métrica: Cobertura de pruebas (simulado - en real viene del pipeline)
aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "TestCoverage" \
  --dimensions "Project=backend" \
  --value 75 \
  --unit "Percent" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica)"

aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "TestCoverage" \
  --dimensions "Project=frontend" \
  --value 82 \
  --unit "Percent" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica)"

# Métrica: Número de despliegues
aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployCount" \
  --dimensions "Service=backend" \
  --value 1 \
  --unit "Count" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica)"

aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployCount" \
  --dimensions "Service=frontend" \
  --value 1 \
  --unit "Count" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo publicar métrica)"

echo "  ✔ Métricas custom publicadas"
echo ""

# ----------------------------------------------------------
# 3) Crear Dashboard en CloudWatch
# ----------------------------------------------------------
echo "--- 3. Creando Dashboard en CloudWatch ---"

# Generar dashboard JSON con variables reales
DASHBOARD_BODY=$(cat <<EOF
{
  "widgets": [
    {
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "# Dashboard de Observabilidad — EKS Cluster: ${CLUSTER_NAME}"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Uso de CPU por Pod (%)",
        "metrics": [
          ["ContainerInsights", "pod_cpu_utilization", "ClusterName", "${CLUSTER_NAME}", "Namespace", "${NAMESPACE}", "Pod", "alumnos-backend", {"stat": "Average", "period": 60}],
          ["...", "alumnos-frontend", {"stat": "Average", "period": 60}],
          ["...", "alumnos-db", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Uso de Memoria por Pod (%)",
        "metrics": [
          ["ContainerInsights", "pod_memory_working_set", "ClusterName", "${CLUSTER_NAME}", "Namespace", "${NAMESPACE}", "Pod", "alumnos-backend", {"stat": "Average", "period": 60}],
          ["...", "alumnos-frontend", {"stat": "Average", "period": 60}],
          ["...", "alumnos-db", {"stat": "Average", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Tráfico de Red (bytes)",
        "metrics": [
          ["ContainerInsights", "pod_network_rx_bytes", "ClusterName", "${CLUSTER_NAME}", "Namespace", "${NAMESPACE}", {"stat": "Sum", "period": 60}],
          ["...", "pod_network_tx_bytes", {"stat": "Sum", "period": 60}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 7,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Tiempo de Despliegue (segundos)",
        "metrics": [
          ["Custom", "DeployDuration", "Service", "backend", {"stat": "Average", "period": 300}],
          ["...", "frontend", {"stat": "Average", "period": 300}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 300,
        "annotations": {
          "horizontal": [{"label": "Objetivo (<5 min)", "value": 300, "color": "#2ca02c"}]
        }
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 7,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Cobertura de Pruebas (%)",
        "metrics": [
          ["Custom", "TestCoverage", "Project", "backend", {"stat": "Average", "period": 86400}],
          ["...", "frontend", {"stat": "Average", "period": 86400}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 86400,
        "annotations": {
          "horizontal": [{"label": "Objetivo (>80%)", "value": 80, "color": "#2ca02c"}]
        }
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 7,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Errores en Logs",
        "metrics": [
          ["AWS/Logs", "IncomingBytes", "LogGroup", "/aws/eks/${CLUSTER_NAME}/application", {"stat": "Sum", "period": 300}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 13,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Estado de Pods",
        "metrics": [
          ["ContainerInsights", "pod_number_of_container_status_running", "ClusterName", "${CLUSTER_NAME}", "Namespace", "${NAMESPACE}", {"stat": "Average", "period": 60, "label": "Running"}],
          ["...", "pod_number_of_container_status_pending", {"stat": "Average", "period": 60, "label": "Pending"}],
          ["...", "pod_number_of_container_status_failed", {"stat": "Average", "period": 60, "label": "Failed", "color": "#d62728"}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 13,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Alarmas Activas",
        "metrics": [
          ["AWS/CloudWatch", "AlarmState", "AlarmName", "${CLUSTER_NAME}-backend-errors", {"stat": "Maximum", "period": 300}],
          ["...", "${CLUSTER_NAME}-pods-availability", {"stat": "Maximum", "period": 300}],
          ["...", "${CLUSTER_NAME}-high-cpu", {"stat": "Maximum", "period": 300}],
          ["...", "${CLUSTER_NAME}-high-memory", {"stat": "Maximum", "period": 300}]
        ],
        "view": "timeSeries",
        "region": "${REGION}",
        "period": 300
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 19,
      "width": 24,
      "height": 6,
      "properties": {
        "title": "Últimos Errores en Logs",
        "query": "SOURCE '/aws/eks/${CLUSTER_NAME}/application' | fields @timestamp, @message | filter @message like /ERROR|Exception/ | sort @timestamp desc | limit 20",
        "region": "${REGION}",
        "view": "table"
      }
    }
  ]
}
EOF
)

# Crear el dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "$DASHBOARD_NAME" \
  --dashboard-body "$DASHBOARD_BODY" \
  --region "$REGION" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "  ✅ Dashboard creado: $DASHBOARD_NAME"
  echo "  URL: https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${DASHBOARD_NAME}"
else
  echo "  ❌ Error al crear dashboard"
fi
echo ""

# ----------------------------------------------------------
# 4) Verificar dashboard
# ----------------------------------------------------------
echo "--- 4. Verificando Dashboard ---"
DASHBOARD_INFO=$(aws cloudwatch get-dashboard \
  --dashboard-name "$DASHBOARD_NAME" \
  --region "$REGION" \
  --query 'DashboardName' \
  --output text 2>/dev/null || echo "")

if [ "$DASHBOARD_INFO" = "$DASHBOARD_NAME" ]; then
  echo "  ✅ Dashboard verificado: $DASHBOARD_INFO"
  echo "  Widgets: $(aws cloudwatch get-dashboard --dashboard-name "$DASHBOARD_NAME" --region "$REGION" --query 'DashboardBody' --output text 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('widgets',[])))" 2>/dev/null || echo "N/A")"
else
  echo "  ❌ Dashboard no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 5) Resumen
# ----------------------------------------------------------
echo "=========================================="
echo " DASHBOARD CONFIGURADO"
echo "=========================================="
echo ""
echo "  📊 MÉTRICAS EN EL DASHBOARD:"
echo ""
echo "  ✅ CPU por Pod (Backend, Frontend, DB)"
echo "  ✅ Memoria por Pod (Backend, Frontend, DB)"
echo "  ✅ Tráfico de Red (RX/TX)"
echo "  ✅ Tiempo de Despliegue (custom metric)"
echo "  ✅ Cobertura de Pruebas (custom metric)"
echo "  ✅ Errores en Logs"
echo "  ✅ Estado de Pods (Running/Pending/Failed)"
echo "  ✅ Alarmas Activas"
echo "  ✅ Logs de Errores (tabla)"
echo ""
echo "  🔗 ACCESO:"
echo "  https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${DASHBOARD_NAME}"
echo ""
echo "=========================================="
