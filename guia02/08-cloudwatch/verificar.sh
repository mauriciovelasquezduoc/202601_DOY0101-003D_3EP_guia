#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Verificación de CloudWatch — Logs, Métricas, Alarmas
# ============================================================

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-laboratorio-eks}"
NAMESPACE="alumnos"
LOG_GROUP_NAME="/aws/eks/${CLUSTER_NAME}/application"

echo ""
echo "=========================================="
echo " VERIFICACIÓN DE CLOUDWATCH"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1) Verificar Log Group
# ----------------------------------------------------------
echo "--- 1. Log Group en CloudWatch ---"
LOG_GROUP=$(aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP_NAME" \
  --region "$REGION" \
  --query 'logGroups[?logGroupName==`'"$LOG_GROUP_NAME"'`]' \
  --output json 2>/dev/null || echo "[]")

if echo "$LOG_GROUP" | grep -q "$LOG_GROUP_NAME"; then
  RETENTION=$(echo "$LOG_GROUP" | python3 -c "import sys,json; print(json.load(sys.stdin)[0].get('retentionInDays','Sin retención'))" 2>/dev/null || echo "N/A")
  echo "  ✅ Log Group: $LOG_GROUP_NAME"
  echo "     Retención: $RETENTION días"
else
  echo "  ❌ Log Group no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 2) Verificar Fluent Bit
# ----------------------------------------------------------
echo "--- 2. Fluent Bit DaemonSet ---"
FLUENTBIT_PODS=$(kubectl get pods -n amazon-cloudwatch -l app=fluent-bit --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$FLUENTBIT_PODS" -gt 0 ]; then
  echo "  ✅ Fluent Bit corriendo: $FLUENTBIT_PODS pods"
  kubectl get pods -n amazon-cloudwatch -l app=fluent-bit --no-headers 2>/dev/null | head -3
else
  echo "  ❌ Fluent Bit no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 3) Verificar logs recientes
# ----------------------------------------------------------
echo "--- 3. Logs recientes en CloudWatch ---"
RECENT_LOGS=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by "LastEventTime" \
  --descending \
  --limit 5 \
  --region "$REGION" \
  --query 'logStreams[].logStreamName' \
  --output text 2>/dev/null || echo "")

if [ -n "$RECENT_LOGS" ]; then
  echo "  ✅ Streams de logs disponibles:"
  echo "$RECENT_LOGS" | tr '\t' '\n' | head -5 | sed 's/^/     /'
else
  echo "  ⚠️  No hay streams de logs aún (puede tardar en aparecer)"
fi
echo ""

# ----------------------------------------------------------
# 4) Verificar métricas Container Insights
# ----------------------------------------------------------
echo "--- 4. Métricas Container Insights ---"
METRICS=$(aws cloudwatch list-metrics \
  --namespace "ContainerInsights" \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'Metrics[].MetricName' \
  --output text 2>/dev/null || echo "")

if [ -n "$METRICS" ]; then
  echo "  ✅ Métricas disponibles:"
  echo "$METRICS" | tr '\t' '\n' | sort -u | head -10 | sed 's/^/     /'
else
  echo "  ⚠️  Métricas no disponibles aún (Container Insights puede tardar)"
fi
echo ""

# ----------------------------------------------------------
# 5) Verificar alarmas
# ----------------------------------------------------------
echo "--- 5. Alarmas de CloudWatch ---"
ALARMS=$(aws cloudwatch describe-alarms \
  --alarm-name-prefix "${CLUSTER_NAME}" \
  --region "$REGION" \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}' \
  --output json 2>/dev/null || echo "[]")

if echo "$ALARMS" | grep -q "AlarmName"; then
  echo "  ✅ Alarmas configuradas:"
  echo "$ALARMS" | python3 -c "
import sys, json
alarms = json.load(sys.stdin)
for a in alarms:
    print(f\"     - {a['Name']}: {a['State']}\")
" 2>/dev/null || echo "$ALARMS" | head -10
else
  echo "  ❌ No se encontraron alarmas"
fi
echo ""

# ----------------------------------------------------------
# 6) Verificar pods y disponibilidad
# ----------------------------------------------------------
echo "--- 6. Disponibilidad de Pods ---"
PODS_RUNNING=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l || echo "0")
PODS_TOTAL=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")

if [ "$PODS_RUNNING" -gt 0 ]; then
  echo "  ✅ Pods corriendo: $PODS_RUNNING / $PODS_TOTAL"
  kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | sed 's/^/     /'
else
  echo "  ❌ No hay pods corriendo en $NAMESPACE"
fi
echo ""

# ----------------------------------------------------------
# 7) Verificar métricas de recursos
# ----------------------------------------------------------
echo "--- 7. Métricas de Recursos (kubectl top) ---"
kubectl top pods -n "$NAMESPACE" 2>/dev/null | sed 's/^/     /' || \
  echo "  ⚠️  metrics-server no disponible"
echo ""

# ----------------------------------------------------------
# Resumen
# ----------------------------------------------------------
echo "=========================================="
echo " RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo ""

CHECKS=0
PASSED=0

# Log Group
CHECKS=$((CHECKS + 1))
if echo "$LOG_GROUP" | grep -q "$LOG_GROUP_NAME"; then
  echo "  [✅] Log Group en CloudWatch"
  PASSED=$((PASSED + 1))
else
  echo "  [❌] Log Group en CloudWatch"
fi

# Fluent Bit
CHECKS=$((CHECKS + 1))
if [ "$FLUENTBIT_PODS" -gt 0 ]; then
  echo "  [✅] Fluent Bit enviando logs"
  PASSED=$((PASSED + 1))
else
  echo "  [❌] Fluent Bit no configurado"
fi

# Logs
CHECKS=$((CHECKS + 1))
if [ -n "$RECENT_LOGS" ]; then
  echo "  [✅] Logs visibles en CloudWatch"
  PASSED=$((PASSED + 1))
else
  echo "  [⚠️] Logs pendientes de aparecer"
fi

# Métricas
CHECKS=$((CHECKS + 1))
if [ -n "$METRICS" ]; then
  echo "  [✅] Métricas Container Insights"
  PASSED=$((PASSED + 1))
else
  echo "  [⚠️] Métricas pendientes"
fi

# Alarmas
CHECKS=$((CHECKS + 1))
if echo "$ALARMS" | grep -q "AlarmName"; then
  echo "  [✅] Alarmas configuradas"
  PASSED=$((PASSED + 1))
else
  echo "  [❌] Alarmas no configuradas"
fi

# Disponibilidad
CHECKS=$((CHECKS + 1))
if [ "$PODS_RUNNING" -gt 0 ]; then
  echo "  [✅] Pods disponibles ($PODS_RUNNING/$PODS_TOTAL)"
  PASSED=$((PASSED + 1))
else
  echo "  [❌] Pods no disponibles"
fi

echo ""
echo "  Resultado: $PASSED / $CHECKS verificaciones pasaron"
echo ""
echo "=========================================="
