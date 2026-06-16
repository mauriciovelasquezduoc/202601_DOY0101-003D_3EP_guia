#!/usr/bin/env bash
# ============================================================
# Script para publicar métricas del pipeline CI/CD a CloudWatch
# Ejecutar después de cada deploy exitoso
# ============================================================

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
SERVICE="${1:-backend}"
DEPLOY_START="${2:-$(date -d '3 minutes ago' +%s)}"
DEPLOY_END="${3:-$(date +%s)}"
TEST_COVERAGE="${4:-0}"
DEPLOY_STATUS="${5:-success}"

echo "Publicando métricas para: $SERVICE"

# Calcular duración del despliegue
DEPLOY_DURATION=$(( DEPLOY_END - DEPLOY_START ))

# Métrica 1: Tiempo de despliegue
aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployDuration" \
  --dimensions "Service=${SERVICE}" \
  --value "$DEPLOY_DURATION" \
  --unit "Seconds" \
  --region "$REGION"

echo "  ✓ Tiempo de despliegue: ${DEPLOY_DURATION}s"

# Métrica 2: Cobertura de pruebas
if [ "$TEST_COVERAGE" -gt 0 ]; then
  aws cloudwatch put-metric-data \
    --namespace "Custom" \
    --metric-name "TestCoverage" \
    --dimensions "Project=${SERVICE}" \
    --value "$TEST_COVERAGE" \
    --unit "Percent" \
    --region "$REGION"
  echo "  ✓ Cobertura de pruebas: ${TEST_COVERAGE}%"
fi

# Métrica 3: Conteo de despliegues
aws cloudwatch put-metric-data \
  --namespace "Custom" \
  --metric-name "DeployCount" \
  --dimensions "Service=${SERVICE}" \
  --value 1 \
  --unit "Count" \
  --region "$REGION"
echo "  ✓ Despliegue registrado"

# Métrica 4: Estado del despliegue
if [ "$DEPLOY_STATUS" = "success" ]; then
  aws cloudwatch put-metric-data \
    --namespace "Custom" \
    --metric-name "DeploySuccess" \
    --dimensions "Service=${SERVICE}" \
    --value 1 \
    --unit "Count" \
    --region "$REGION"
  echo "  ✓ Estado: exitoso"
else
  aws cloudwatch put-metric-data \
    --namespace "Custom" \
    --metric-name "DeployFailure" \
    --dimensions "Service=${SERVICE}" \
    --value 1 \
    --unit "Count" \
    --region "$REGION"
  echo "  ✗ Estado: fallido"
fi

echo ""
echo "Métricas publicadas correctamente"
