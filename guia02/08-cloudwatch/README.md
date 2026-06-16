# CloudWatch — Observabilidad en el Pipeline CI/CD

## Descripción

Este módulo configura **Amazon CloudWatch** como herramienta única de observabilidad para el clúster EKS, cubriendo los cuatro aspectos requeridos por la Evaluación Parcial 3:

| Aspecto | Cómo se cubre |
|---------|---------------|
| **Logs** | Fluent Bit envía logs de todos los pods a CloudWatch Logs |
| **Métricas de uso** | Container Insights recolecta CPU, memoria, red y disco |
| **Errores** | Alarmas de CloudWatch detectan patrones de error en logs |
| **Disponibilidad** | Health checks + métricas de pods running/failed/pending |

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      EKS Cluster                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │   DB     │  │ Backend  │  │ Frontend │  ← Pods          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                  │
│       │              │              │                        │
│       └──────────────┼──────────────┘                       │
│                      │                                      │
│              ┌───────▼───────┐                              │
│              │  Fluent Bit   │  ← DaemonSet                │
│              │  (Collector)  │                              │
│              └───────┬───────┘                              │
└──────────────────────┼──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │       Amazon CloudWatch      │
        │  ┌────────────────────────┐  │
        │  │    CloudWatch Logs     │  │  ← Logs de todos los pods
        │  └────────────────────────┘  │
        │  ┌────────────────────────┐  │
        │  │  Container Insights    │  │  ← Métricas de CPU/Mem/Red
        │  └────────────────────────┘  │
        │  ┌────────────────────────┐  │
        │  │    CloudWatch Alarms   │  │  ← Alertas de error/disponibilidad
        │  └────────────────────────┘  │
        └──────────────────────────────┘
```

## Componentes

### 1. Fluent Bit (Recolección de Logs)

- **DaemonSet** que corre en cada nodo del clúster
- Recoge logs de `/var/log/containers/*.log`
- Envía logs a CloudWatch Logs con prefijo `fluentbit-`
- Incluye metadata de Kubernetes (pod, namespace, nodo)

### 2. Container Insights (Métricas)

- **Namespace**: `amazon-cloudwatch`
- **Métricas recolectadas**:
  - CPU: `pod_cpu_utilization`, `node_cpu_total_usage`
  - Memoria: `pod_memory_utilization`, `node_memory_working_set`
  - Red: `pod_network_rx_bytes`, `pod_network_tx_bytes`
  - Disco: `node_filesystem_usage`

### 3. CloudWatch Alarms (Alertas)

| Alarma | Condición | Acción |
|--------|-----------|--------|
| `*-backend-errors` | Errores en logs > 10 en 5 min | Notificación |
| `*-pods-availability` | Pods running < 1 | Notificación |
| `*-high-cpu` | CPU > 80% por 5 min | Notificación |
| `*-high-memory` | Memoria > 80% por 5 min | Notificación |

### 4. Health Checks (Disponibilidad)

Configurados en cada deployment:

```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 45
  periodSeconds: 10

livenessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 15
```

## Uso en la Toma de Decisiones

### Decisiones Técnicas Soportadas

1. **Escalamiento**: Las métricas de CPU/memoria alimentan el HPA (Horizontal Pod Autoscaler)
2. **Debugging**: Los logs permiten identificar errores en producción rápidamente
3. **Capacidad**: Las métricas de recursos ayudan a dimensionar nodos
4. **Confiabilidad**: Las alarmas permiten detectar problemas antes de que impacten usuarios

### Dashboard de Operaciones

Acceder a CloudWatch Console:
1. Ir a **CloudWatch** → **Logs** → **Log Groups**
2. Seleccionar `/aws/eks/laboratorio-eks/application`
3. Ver logs de todos los microservicios

Para métricas:
1. Ir a **CloudWatch** → **Container Insights**
2. Seleccionar el clúster `laboratorio-eks`
3. Ver métricas de CPU, memoria, red por pod/nodo

## Integración con Pipeline CI/CD

La observabilidad se integra en el pipeline de la siguiente manera:

```
Push a main
    │
    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Build     │────▶│   Deploy    │────▶│  Verify     │
│   (Docker)  │     │   (K8s)     │     │ (CloudWatch)│
└─────────────┘     └─────────────┘     └─────────────┘
                           │                    │
                           ▼                    ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Pods      │     │   Logs +    │
                    │   Running   │     │   Métricas  │
                    └─────────────┘     └─────────────┘
```

### Después del Deploy

1. **Fluent Bit** comienza a enviar logs automáticamente
2. **Container Insights** empieza a recolectar métricas
3. **Alarmas** monitorean errores y disponibilidad
4. **Health checks** validan que los pods estén sanos

## Comandos Útiles

```bash
# Ver logs recientes
aws logs tail /aws/eks/laboratorio-eks/application --follow

# Ver métricas de pods
kubectl top pods -n alumnos

# Ver alarmas
aws cloudwatch describe-alarms --alarm-name-prefix laboratorio-eks

# Verificar estado de Fluent Bit
kubectl get pods -n amazon-cloudwatch

# Exportar logs para análisis
aws logs filter-log-events \
  --log-group-name /aws/eks/laboratorio-eks/application \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "ERROR"
```

## Costos Estimados

- **CloudWatch Logs**: $0.50/GB ingestion + $0.03/GB almacenamiento
- **Container Insights**: $0.30/pod/mes
- **CloudWatch Alarms**: $0.10/alarm/mes

**Estimación mensual para 3 microservicios**: ~$5-10 USD
