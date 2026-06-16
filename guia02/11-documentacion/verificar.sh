#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Verificación de Documentación IE4
# ============================================================

echo ""
echo "=========================================="
echo " VERIFICACIÓN DE DOCUMENTACIÓN"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1) Verificar archivos principales
# ----------------------------------------------------------
echo "--- 1. Archivos de documentación ---"

DOC_FILES=(
  "DOCUMENTACION_CICD.md"
  "docs/ARQUITECTURA.md"
  "docs/ADR.md"
)

for FILE in "${DOC_FILES[@]}"; do
  if [ -f "$FILE" ]; then
    LINES=$(wc -l < "$FILE" 2>/dev/null || echo "0")
    echo "  ✅ $FILE ($LINES líneas)"
  else
    echo "  ❌ $FILE: NO encontrado"
  fi
done
echo ""

# ----------------------------------------------------------
# 2) Verificar contenido de DOCUMENTACION_CICD.md
# ----------------------------------------------------------
echo "--- 2. Contenido de DOCUMENTACION_CICD.md ---"

if [ -f "DOCUMENTACION_CICD.md" ]; then
  # Verificar secciones clave
  SECTIONS=(
    "Visión General"
    "Herramientas Integradas"
    "Monitoreo"
    "Métricas"
    "Seguridad"
    "Cumplimiento"
    "Flujo de Datos"
    "Toma de Decisiones"
    "Mejora Continua"
  )
  
  for SECTION in "${SECTIONS[@]}"; do
    if grep -q "$SECTION" DOCUMENTACION_CICD.md 2>/dev/null; then
      echo "  ✅ Sección: $SECTION"
    else
      echo "  ⚠️  Sección no encontrada: $SECTION"
    fi
  done
else
  echo "  ❌ DOCUMENTACION_CICD.md no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 3) Verificar contenido de ARQUITECTURA.md
# ----------------------------------------------------------
echo "--- 3. Contenido de ARQUITECTURA.md ---"

if [ -f "docs/ARQUITECTURA.md" ]; then
  ARCH_SECTIONS=(
    "Visión General"
    "Componentes"
    "Microservicios"
    "Infraestructura"
    "Seguridad"
    "Monitoreo"
    "Pipeline CI/CD"
  )
  
  for SECTION in "${ARCH_SECTIONS[@]}"; do
    if grep -q "$SECTION" docs/ARQUITECTURA.md 2>/dev/null; then
      echo "  ✅ Sección: $SECTION"
    else
      echo "  ⚠️  Sección no encontrada: $SECTION"
    fi
  done
else
  echo "  ❌ docs/ARQUITECTURA.md no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 4) Verificar contenido de ADR.md
# ----------------------------------------------------------
echo "--- 4. Contenido de ADR.md ---"

if [ -f "docs/ADR.md" ]; then
  ADR_COUNT=$(grep -c "^## ADR-" docs/ADR.md 2>/dev/null || echo "0")
  echo "  ADRs documentados: $ADR_COUNT"
  
  # Verificar que tienen formato correcto
  if grep -q "Estado:" docs/ADR.md 2>/dev/null; then
    echo "  ✅ Formato correcto (con Estado)"
  else
    echo "  ⚠️  Formato incompleto"
  fi
else
  echo "  ❌ docs/ADR.md no encontrado"
fi
echo ""

# ----------------------------------------------------------
# 5) Resumen
# ----------------------------------------------------------
echo "=========================================="
echo " RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo ""
echo "  📄 DOCUMENTACIÓN IE4:"
echo "     - Documentación de integración CI/CD"
echo "     - Diagramas de arquitectura"
echo "     - Decisiones arquitectónicas"
echo "     - Guías de mejora continua"
echo ""
echo "=========================================="
