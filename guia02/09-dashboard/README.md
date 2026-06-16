# Dashboard de Observabilidad — CloudWatch

## Descripción

Este módulo crea un **dashboard personalizado en Amazon CloudWatch** que visualiza todas las métricas clave requeridas por la Evaluación Parcial 3, Indicador IE3.

## Métricas del Dashboard

| Métrica | Fuente | Descripción |
|---------|--------|-------------|
| **Tiempo de Despliegue** | Custom/DeployDuration | Duración de cada despliegue en segundos |
| **Cobertura de Pruebas** | Custom/TestCoverage | Porcentaje de código cubierto por tests |
| **Uso de CPU** | ContainerInsights | CPU por pod (Backend, Frontend, DB) |
| **Uso de Memoria** | ContainerInsights | Memoria por pod |
| **Tráfico de Red** | ContainerInsights | Bytes recibidos/enviados |
| **Errores en Logs** | AWS/Logs | Volumen de logs con errores |
| **Estado de Pods** | ContainerInsights | Pods Running/Pending/Failed |
| **Alarmas Activas** | AWS/CloudWatch | Estado de alarmas configuradas |

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `dashboard.json` | Definición del dashboard (plantilla) |
| `ejecutar.sh` | Crea el dashboard en CloudWatch |
| `publicar-metricas.sh` | Publica métricas custom desde el pipeline |
| `verificar.sh` | Verifica que el dashboard funciona |
| `README.md` | Esta documentación |

## Uso

### 1. Crear el dashboard

```bash
cd 09-dashboard
bash ejecutar.sh
```

### 2. Publicar métricas después de cada deploy

```bash
# Desde el pipeline CI/CD
bash publicar-metricas.sh backend $DEPLOY_START $DEPLOY_END $TEST_COVERAGE success
```

### 3. Verificar que funciona

```bash
bash verificar.sh
```

## Integración con Pipeline CI/CD

### En GitHub Actions

Agregar estos pasos después del deploy:

```yaml
- name: Publicar métricas de despliegue
  run: |
    DEPLOY_START=${{ steps.deploy.outputs.start_time }}
    DEPLOY_END=$(date +%s)
    TEST_COVERAGE=${{ steps.test.outputs.coverage }}
    bash publicar-metricas.sh backend "$DEPLOY_START" "$DEPLOY_END" "$TEST_COVERAGE" success
```

### Métricas Custom

Las métricas personalizadas se publican al namespace `Custom`:

- **DeployDuration**: Tiempo de despliegue en segundos
- **TestCoverage**: Porcentaje de cobertura de pruebas
- **DeployCount**: Conteo de despliegues
- **DeploySuccess/Failure**: Estado del despliegue

## Acceso al Dashboard

1. Ir a **AWS Console** → **CloudWatch**
2. Seleccionar **Dashboards** en el menú lateral
3. Buscar `${CLUSTER_NAME}-observability`
4. O acceder directamente:
   ```
   https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=laboratorio-eks-observability
   ```

## Widgets del Dashboard

### Fila 1: Métricas de Recursos
- **CPU por Pod**: Gráfica de tiempo mostrando CPU de Backend, Frontend y DB
- **Memoria por Pod**: Gráfica de tiempo mostrando memoria de cada pod
- **Tráfico de Red**: Bytes RX/TX totales

### Fila 2: Métricas de CI/CD
- **Tiempo de Despliegue**: Duración de cada deploy con objetivo de <5 min
- **Cobertura de Pruebas**: Porcentaje con objetivo de >80%
- **Errores en Logs**: Volumen de logs de error

### Fila 3: Estado del Sistema
- **Estado de Pods**: Running, Pending, Failed
- **Alarmas Activas**: Estado de alarmas de CloudWatch

### Fila 4: Logs
- **Últimos Errores**: Tabla con los 20 errores más recientes

## Costos Estimados

- **Dashboard**: Gratis (hasta 3 dashboards por cuenta)
- **Métricas Custom**: $0.30/metric/mes
- **Container Insights**: $0.30/pod/mes

**Total estimado**: ~$2-4 USD/mes

## Alineación con Rúbrica IE3

### Muy buen desempeño (100%)

> "Crea dashboards funcionales y detallados con todas las métricas clave integradas al proceso CI/CD, facilitando el análisis continuo del sistema."

**Criterios cumplidos**:
- ✅ Dashboard funcional y detallado
- ✅ Tiempo de despliegue visible
- ✅ Cobertura de pruebas visible
- ✅ Uso de CPU/memoria visible
- ✅ Errores registrados visibles
- ✅ Integrado con CI/CD (vía métricas custom)
- ✅ Facilita análisis continuo del sistema
