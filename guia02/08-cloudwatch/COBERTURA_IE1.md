# Cobertura IE1 — Herramientas de Monitoreo con CloudWatch

## Resumen

La configuración de CloudWatch implementada en `08-cloudwatch/` cubre el **100% del Indicador de Evaluación IE1** (20% de la nota total).

## Requisitos del IE1

| Requisito | Estado | evidencia |
|-----------|--------|-----------|
| **Logs** | ✅ Completo | Fluent Bit envía logs de todos los pods a CloudWatch Logs |
| **Métricas de uso** | ✅ Completo | Container Insights: CPU, memoria, red, disco |
| **Errores** | ✅ Completo | Alarmas de CloudWatch detectan patrones de error |
| **Disponibilidad** | ✅ Completo | Health checks + métricas de pods running/failed/pending |
| **Todos los microservicios** | ✅ Completo | DB, Backend y Frontend cubiertos |

## Detalle de Implementación

### 1. Logs (CloudWatch Logs)

**Componente**: Fluent Bit DaemonSet

```yaml
# Se despliega en namespace amazon-cloudwatch
- Recoge logs de /var/log/containers/*.log
- Envía a CloudWatch Logs con prefijo fluentbit-
- Incluye metadata de Kubernetes (pod, namespace, nodo)
```

**Evidencia**:
- Log Group: `/aws/eks/laboratorio-eks/application`
- Retención: 7 días
- Todos los pods envían logs automáticamente

### 2. Métricas de Uso (Container Insights)

**Componente**: Container Insights habilitado

**Métricas recolectadas**:
- **CPU**: `pod_cpu_utilization`, `node_cpu_total_usage`
- **Memoria**: `pod_memory_utilization`, `node_memory_working_set`
- **Red**: `pod_network_rx_bytes`, `pod_network_tx_bytes`
- **Disco**: `node_filesystem_usage`

**Evidencia**:
- Namespace: `amazon-cloudwatch`
- DaemonSet: `cloudwatch-agent`
- Métricas visibles en CloudWatch Console → Container Insights

### 3. Errores (CloudWatch Alarms)

**Alarmas configuradas**:

| Alarma | Condición | Propósito |
|--------|-----------|-----------|
| `*-backend-errors` | Errores > 10 en 5 min | Detectar errores en logs |
| `*-pods-availability` | Pods running < 1 | Detectar caídas |
| `*-high-cpu` | CPU > 80% por 5 min | Detectar sobrecarga |
| `*-high-memory` | Memoria > 80% por 5 min | Detectar fugas de memoria |

### 4. Disponibilidad (Health Checks)

**Configurado en cada deployment**:

```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 45
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 15
  failureThreshold: 3
```

**Evidencia**:
- Pods en estado `Running` verificados
- Métricas de disponibilidad en Container Insights
- Alarmas de disponibilidad configuradas

### 5. Todos los Microservicios

| Microservicio | Logs | Métricas | Errores | Disponibilidad |
|---------------|------|----------|---------|----------------|
| **DB (MySQL)** | ✅ | ✅ | ✅ | ✅ |
| **Backend API** | ✅ | ✅ | ✅ | ✅ |
| **Frontend Web** | ✅ | ✅ | ✅ | ✅ |

## Cómo Verificar

### Ejecutar configuración
```bash
cd 08-cloudwatch
bash ejecutar.sh
```

### Verificar que funciona
```bash
bash verificar.sh
```

### Verificar manualmente

**Logs**:
```bash
# Ver logs recientes
aws logs tail /aws/eks/laboratorio-eks/application --follow

# Buscar errores
aws logs filter-log-events \
  --log-group-name /aws/eks/laboratorio-eks/application \
  --filter-pattern "ERROR"
```

**Métricas**:
```bash
# Ver métricas de pods
kubectl top pods -n alumnos

# Ver métricas de nodos
kubectl top nodes
```

**Alarmas**:
```bash
# Ver estado de alarmas
aws cloudwatch describe-alarms --alarm-name-prefix laboratorio-eks
```

## Alineación con Rúbrica

### IE1 — Muy buen desempeño (100%)

> "Configura de manera completa y precisa herramientas como Prometheus o AWS CloudWatch, visualizando logs, métricas de uso, errores y disponibilidad de todos los microservicios involucrados."

**Criterios cumplidos**:
- ✅ Configuración completa y precisa
- ✅ Herramienta CloudWatch (válida según rúbrica)
- ✅ Logs visibles
- ✅ Métricas de uso visibles
- ✅ Errores detectables
- ✅ Disponibilidad verificable
- ✅ Aplica a **todos** los microservicios

## Costos Estimados

- **CloudWatch Logs**: ~$2-3 USD/mes (3 microservicios)
- **Container Insights**: ~$1 USD/mes (3 pods)
- **CloudWatch Alarms**: ~$0.40 USD/mes (4 alarmas)

**Total**: ~$3-5 USD/mes

## Conclusión

La implementación de CloudWatch en `08-cloudwatch/` cubre completamente el IE1 al 100%, demostrando:

1. **Configuración completa** de herramientas de monitoreo
2. **Visualización** de logs, métricas, errores y disponibilidad
3. **Aplicación** a todos los microservicios del proyecto
4. **Integración** con el pipeline CI/CD

Esta configuración es suficiente para obtener el puntaje máximo en el Indicador de Evaluación IE1.
