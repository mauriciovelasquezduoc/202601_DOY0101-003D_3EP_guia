#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Verificación de Auditoría IE5
# ============================================================

echo ""
echo "=========================================="
echo " VERIFICACIÓN DE AUDITORÍA"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1) Verificar scripts de auditoría
# ----------------------------------------------------------
echo "--- 1. Scripts de auditoría ---"

AUDIT_SCRIPTS=(
  "ejecutar.sh"
  "verificar.sh"
)

for SCRIPT in "${AUDIT_SCRIPTS[@]}"; do
  if [ -f "$SCRIPT" ] && [ -x "$SCRIPT" ]; then
    echo "  ✅ $SCRIPT (ejecutable)"
  elif [ -f "$SCRIPT" ]; then
    echo "  ⚠️  $SCRIPT (no ejecutable)"
  else
    echo "  ❌ $SCRIPT: NO encontrado"
  fi
done
echo ""

# ----------------------------------------------------------
# 2) Verificar configuración de cumplimiento
# ----------------------------------------------------------
echo "--- 2. Configuración de cumplimiento ---"

COMPLIANCE_ITEMS=(
  "sonar-project.properties:SonarQube"
  ".snyk:Snyk"
  "config/pmd/ruleset.xml:PMD"
  "pom.xml:JaCoCo"
)

for ITEM in "${COMPLIANCE_ITEMS[@]}"; do
  FILE=$(echo "$ITEM" | cut -d':' -f1)
  NAME=$(echo "$ITEM" | cut -d':' -f2)
  
  if [ -f "$FILE" ]; then
    echo "  ✅ $NAME: configurado"
  else
    echo "  ❌ $NAME: NO configurado"
  fi
done
echo ""

# ----------------------------------------------------------
# 3) Verificar GitHub Actions
# ----------------------------------------------------------
echo "--- 3. GitHub Actions ---"

if [ -d ".github/workflows" ]; then
  WORKFLOWS=$(ls -1 .github/workflows/*.yml 2>/dev/null | wc -l || echo "0")
  echo "  Workflows encontrados: $WORKFLOWS"
  
  # Verificar que quality-gates.yml existe
  if [ -f ".github/workflows/quality-gates.yml" ]; then
    echo "  ✅ quality-gates.yml: existe"
  else
    echo "  ❌ quality-gates.yml: NO encontrado"
  fi
else
  echo "  ❌ .github/workflows: directorio no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 4) Verificar reporte de auditoría
# ----------------------------------------------------------
echo "--- 4. Reporte de auditoría ---"

if [ -f "reporte-auditoria.txt" ]; then
  echo "  ✅ reporte-auditoria.txt: existe"
  
  # Verificar que tiene contenido
  LINES=$(wc -l < "reporte-auditoria.txt" 2>/dev/null || echo "0")
  echo "     Líneas: $LINES"
else
  echo "  ⚠️  reporte-auditoria.txt: no generado aún"
fi
echo ""

# ----------------------------------------------------------
# 5) Resumen
# ----------------------------------------------------------
echo "=========================================="
echo " RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo ""
echo "  📋 POLÍTICAS IE5:"
echo "     - Branch Protection Rules"
echo "     - SonarQube Quality Gate"
echo "     - Snyk Security Scan"
echo "     - PMD Static Analysis"
echo "     - JaCoCo Test Coverage"
echo "     - Compliance Check Scripts"
echo ""
echo "=========================================="
