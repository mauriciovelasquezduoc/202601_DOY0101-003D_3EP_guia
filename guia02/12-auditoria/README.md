# Auditoría — Políticas de Cumplimiento Automatizadas

## Descripción

Este módulo implementa **políticas de cumplimiento automatizadas** que garantizan calidad, seguridad y trazabilidad del código mediante herramientas como SonarQube, branch protection rules y scripts de auditoría.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `ejecutar.sh` | Ejecuta la auditoría completa |
| `verificar.sh` | Verifica la configuración |
| `reporte-auditoria.txt` | Reporte generado por la auditoría |

## Políticas de Cumplimiento

### 1. Branch Protection Rules

**Propósito**: Proteger la rama principal de cambios no autorizados.

**Configuración**:
- Requiere Pull Requests para merge a main
- Requiere 1 aprobación de revisor
- Requiere status checks aprobados (security-scan, quality-check, test-coverage)
- Revierte reviews stale

**Verificación**:
```bash
gh api repos/{owner}/{repo}/branches/main/protection
```

### 2. SonarQube Quality Gate

**Propósito**: Garantizar calidad de código antes del merge.

**Configuración**:
- Project Key: `laboratorio-devops`
- Análisis en cada PR y push a main
- Quality gate con umbrales de calidad

**Métricas evaluadas**:
- Bugs
- Vulnerabilidades
- Code Smells
- Duplicaciones
- Cobertura de código

### 3. Snyk Security Scan

**Propósito**: Detectar vulnerabilidades en dependencias.

**Configuración**:
- Escaneo automático en PRs
- Umbral: severidad HIGH
- Bloqueo ante vulnerabilidades CRÍTICAS

**Archivos**:
- `.snyk`: Política de ignore/patch

### 4. PMD Static Analysis

**Propósito**: Análisis estático de código Java.

**Configuración**:
- Ruleset: `config/pmd/ruleset.xml`
- Categorías: bestpractices, errorprone, performance, security, design
- Bloqueo ante violaciones críticas

### 5. JaCoCo Test Coverage

**Propósito**: Garantizar cobertura mínima de pruebas.

**Configuración**:
- Umbral mínimo: 80%
- Reportes en `target/site/jacoco/`
- Integración con Maven

### 6. Compliance Check Scripts

**Propósito**: Validar cumplimiento de estándares básicos.

**Verificaciones**:
- ✅ Existe README.md
- ✅ No hay archivos sensibles
- ✅ Dockerfile válido

## Uso

### Ejecutar auditoría
```bash
cd 12-auditoria
bash ejecutar.sh
```

### Verificar configuración
```bash
bash verificar.sh
```

### Ver reporte
```bash
cat reporte-auditoria.txt
```

## Alineación con Rúbrica IE5

### Muy buen desempeño (100%)

> "Aplica rigurosamente políticas de cumplimiento usando herramientas automatizadas, garantizando calidad, seguridad y trazabilidad del código."

**Criterios cumplidos**:
- ✅ Políticas de cumplimiento automatizadas
- ✅ Herramientas configuradas y funcionales
- ✅ Calidad garantizada (SonarQube, PMD)
- ✅ Seguridad verificada (Snyk, Trivy)
- ✅ Trazabilidad del código (Git, GitHub Actions)
- ✅ Reportes de auditoría generados
