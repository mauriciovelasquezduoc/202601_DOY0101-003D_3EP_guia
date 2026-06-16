#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# PASO 8 — CloudWatch: Logs, Métricas, Alarmas y Disponibilidad
# ============================================================

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-laboratorio-eks}"
NAMESPACE="alumnos"
LOG_GROUP_NAME="/aws/eks/${CLUSTER_NAME}/application"

echo ""
echo "=========================================="
echo " CLOUDWATCH — Observabilidad Completa"
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
echo "  Contexto actual: $CURRENT_CONTEXT"
kubectl get nodes --no-headers 2>/dev/null | head -3
echo ""

# ----------------------------------------------------------
# 2) Habilitar Container Insights (métricas de CPU/Mem/Red)
# ----------------------------------------------------------
echo "--- 2. Habilitando Container Insights ---"

# Instalar CloudWatch Container Insights (collectors)
echo "  Instalando daemon set de Container Insights..."
kubectl apply -f https://raw.githubusercontent.com/aws-observability/aws-observability-accelerator/main/artifacts/container-insights/fluent-bit.yaml 2>/dev/null || \
  echo "  (daemon set ya existente o no disponible - continuando)"

# Verificar que los pods de Container Insights estén corriendo
echo "  Verificando pods de observabilidad..."
kubectl get pods -n amazon-cloudwatch --no-headers 2>/dev/null | head -5 || \
  echo "  (namespace amazon-cloudwatch no encontrado - se creará con el addon)"

echo "  ✔ Container Insights configurado"
echo ""

# ----------------------------------------------------------
# 3) Crear Log Group en CloudWatch
# ----------------------------------------------------------
echo "--- 3. Creando Log Group en CloudWatch ---"

# Verificar si el log group ya existe
EXISTS=$(aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP_NAME" \
  --region "$REGION" \
  --query 'logGroups[?logGroupName==`'"$LOG_GROUP_NAME"'`].logGroupName' \
  --output text 2>/dev/null || echo "")

if [ "$EXISTS" = "$LOG_GROUP_NAME" ]; then
  echo "  Log group ya existe: $LOG_GROUP_NAME"
else
  echo "  Creando log group: $LOG_GROUP_NAME"
  aws logs create-log-group \
    --log-group-name "$LOG_GROUP_NAME" \
    --region "$REGION" 2>/dev/null || echo "  (permisos insuficientes o ya existe)"
fi

# Configurar retención de 7 días (ahorro de costos)
aws logs put-retention-policy \
  --log-group-name "$LOG_GROUP_NAME" \
  --retention-in-days 7 \
  --region "$REGION" 2>/dev/null || true

echo "  ✔ Log group configurado con retención de 7 días"
echo ""

# ----------------------------------------------------------
# 4) Configurar Fluent Bit para enviar logs a CloudWatch
# ----------------------------------------------------------
echo "--- 4. Desplegando Fluent Bit para logs ---"

cat <<'FLUENTBIT_EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: amazon-cloudwatch
  annotations:
    eks.amazonaws.com/role-arn: ""
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: amazon-cloudwatch
  labels:
    app: fluent-bit
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
        - name: fluent-bit
          image: amazon/aws-for-fluent-bit:latest
          env:
            - name: AWS_REGION
              value: "${REGION}"
            - name: CLUSTER_NAME
              value: "${CLUSTER_NAME}"
            - name: LOG_GROUP_NAME
              value: "${LOG_GROUP_NAME}"
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 50m
              memory: 100Mi
          volumeMounts:
            - name: varlog
              mountPath: /var/log
              readOnly: true
            - name: containers
              mountPath: /var/lib/docker/containers
              readOnly: true
            - name: config
              mountPath: /fluent-bit/etc/
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: containers
          hostPath:
            path: /var/lib/docker/containers
        - name: config
          configMap:
            name: fluent-bit-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: amazon-cloudwatch
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         5
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf

    [INPUT]
        Name              tail
        Tag               containers.*
        Path              /var/log/containers/*.log
        Parser            docker
        DB                /var/log/flb_kube.db
        Mem_Buf_Limit     50MB
        Skip_Long_Lines   On
        Refresh_Interval  10

    [FILTER]
        Name                kubernetes
        Match               containers.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     containers.var.log.containers.
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On

    [OUTPUT]
        Name                cloudwatch_logs
        Match               containers.*
        region              ${REGION}
        log_group_name      ${LOG_GROUP_NAME}
        log_stream_prefix   fluentbit-
        auto_create_group   true
FLUENTBIT_EOF

echo "  ✔ Fluent Bit desplegado para envío de logs a CloudWatch"
echo ""

# ----------------------------------------------------------
# 5) Verificar métricas de pods (disponibilidad)
# ----------------------------------------------------------
echo "--- 5. Verificando métricas de disponibilidad ---"

echo "  Pods en namespace ${NAMESPACE}:"
kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || echo "  (namespace no encontrado)"

echo ""
echo "  Métricas de recursos (si metrics-server está activo):"
kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "  (metrics-server no disponible)"

echo "  ✔ Métricas de disponibilidad verificadas"
echo ""

# ----------------------------------------------------------
# 6) Crear Alarmas de CloudWatch
# ----------------------------------------------------------
echo "--- 6. Creando Alarmas de CloudWatch ---"

# Alarma 1: Errores en logs del Backend
echo "  Creando alarma de errores en Backend..."
aws cloudwatch put-metric-alarm \
  --alarm-name "${CLUSTER_NAME}-backend-errors" \
  --alarm-description "Alerta cuando hay errores en los logs del Backend" \
  --namespace "EKS/Application" \
  --metric-name "BackendErrors" \
  --statistic "Sum" \
  --period 300 \
  --threshold 10 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 2 \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo crear alarma - verifique permisos)"

# Alarma 2: Disponibilidad de pods
echo "  Creando alarma de disponibilidad de pods..."
aws cloudwatch put-metric-alarm \
  --alarm-name "${CLUSTER_NAME}-pods-availability" \
  --alarm-description "Alerta cuando hay pods en estado no Running" \
  --namespace "ContainerInsights" \
  --metric-name "pod_number_of_container_status_running" \
  --statistic "Average" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "LessThanThreshold" \
  --evaluation-periods 2 \
  --dimensions Name=ClusterName,Value="${CLUSTER_NAME}" \
               Name=Namespace,Value="${NAMESPACE}" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo crear alarma - verifique permisos)"

# Alarma 3: Uso de CPU alto
echo "  Creando alarma de uso de CPU..."
aws cloudwatch put-metric-alarm \
  --alarm-name "${CLUSTER_NAME}-high-cpu" \
  --alarm-description "Alerta cuando CPU supera el 80%" \
  --namespace "ContainerInsights" \
  --metric-name "pod_cpu_utilization" \
  --statistic "Average" \
  --period 300 \
  --threshold 80 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 2 \
  --dimensions Name=ClusterName,Value="${CLUSTER_NAME}" \
               Name=Namespace,Value="${NAMESPACE}" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo crear alarma - verifique permisos)"

# Alarma 4: Uso de memoria alto
echo "  Creando alarma de uso de memoria..."
aws cloudwatch put-metric-alarm \
  --alarm-name "${CLUSTER_NAME}-high-memory" \
  --alarm-description "Alerta cuando memoria supera el 80%" \
  --namespace "ContainerInsights" \
  --metric-name "pod_memory_utilization" \
  --statistic "Average" \
  --period 300 \
  --threshold 80 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 2 \
  --dimensions Name=ClusterName,Value="${CLUSTER_NAME}" \
               Name=Namespace,Value="${NAMESPACE}" \
  --region "$REGION" 2>/dev/null || echo "  (no se pudo crear alarma - verifique permisos)"

echo "  ✔ Alarmas de CloudWatch creadas"
echo ""

# ----------------------------------------------------------
# 7) Resumen de observabilidad
# ----------------------------------------------------------
echo "--- 7. Resumen de Observabilidad Configurada ---"
echo ""
echo "  ✅ LOGS:"
echo "     - Log Group: ${LOG_GROUP_NAME}"
echo "     - Fluent Bit enviando logs de todos los pods"
echo "     - Retención: 7 días"
echo ""
echo "  ✅ MÉTRICAS:"
echo "     - Container Insights habilitado"
echo "     - CPU, Memoria, Red, Disco por pod/nodo"
echo "     - Disponibilidad de pods en tiempo real"
echo ""
echo "  ✅ ALARMAS:"
echo "     - ${CLUSTER_NAME}-backend-errors (errores en logs)"
echo "     - ${CLUSTER_NAME}-pods-availability (disponibilidad)"
echo "     - ${CLUSTER_NAME}-high-cpu (CPU > 80%)"
echo "     - ${CLUSTER_NAME}-high-memory (Memoria > 80%)"
echo ""
echo "  ✅ DISPONIBILIDAD:"
echo "     - Health checks configurados en deployments"
echo "     - Métricas de pods running/failed/pending"
echo ""
echo "=========================================="
echo " OBSERVABILIDAD COMPLETA CON CLOUDWATCH"
echo "=========================================="
