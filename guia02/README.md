# Evaluación Parcial 3 — Observabilidad y Entornos Reales en DevOps

## Descripción

Esta guía contiene los pasos para configurar un entorno completo de DevOps con observabilidad, métricas y cumplimiento normativo en Amazon EKS.

## Indicadores de Evaluación

| Indicador | Descripción | Peso | Paso |
|-----------|-------------|------|------|
| **IE1** | Herramientas de monitoreo (CloudWatch) | 20% | Paso 7 |
| **IE2** | Despliegue en Kubernetes en la nube | 20% | Paso 4, 5, 13 |
| **IE3** | Dashboard con métricas clave | 10% | Paso 8 |
| **IE4** | Documentación de integración CI/CD | 10% | Paso 11 |
| **IE5** | Políticas de cumplimiento automatizadas | 20% | Paso 12 |
| **IE6** | Pipeline se detiene ante fallas críticas | 20% | Paso 10 |

---

## Requisitos Previos

### 1. Construir imagen Docker del laboratorio

```bash
docker build -t devops-eks-lab .
```

### 2. Ejecutar contenedor Docker

```bash
docker run -it \
  -v "$(pwd)":/root/work \
  -v ~/.aws:/root/.aws \
  -v /var/run/docker.sock:/var/run/docker.sock \
  devops-eks-lab
```

### 3. Configurar credenciales AWS

```bash
aws configure
```

---

## Pasos del Laboratorio

### Paso 1 — Validar entorno Docker + AWS

**Objetivo:** Verificar que Docker, AWS CLI, kubectl y credenciales estén configurados.

```bash
cd bloque06/etapa01-ValidaEntorno
bash ejecutar.sh
```

**Resultado:** Entorno validado y listo para crear el clúster EKS.

---

### Paso 2 — Crear VPC Multi-AZ con CloudFormation

**Objetivo:** Desplegar VPC completa con subnets públicas/privadas y endpoints.

```bash
cd ../etapa02-CreaVPC
bash ejecutar.sh
```

**Resultado:** VPC multi-AZ lista con subnets, endpoints y stack de CloudFormation.

---

### Paso 3 — Validar tags EKS en subnets

**Objetivo:** Verificar tags de EKS en subnets para descubrimiento y Load Balancers.

```bash
cd ../etapa03-ValidaSubnets
bash ejecutar.sh
```

**Resultado:** Subnets etiquetadas correctamente para EKS.

---

### Paso 4 — Crear Cluster EKS + Conectar kubectl

**Objetivo:** Desplegar cluster EKS con addons y NodeGroup SPOT.

```bash
cd ../etapa04-CreaClusterEKS
bash ejecutar.sh
```

**Resultado:** Cluster EKS operativo con kubectl conectado (~15 min).

---

### Paso 5 — Validar / Crear NodeGroup SPOT

**Objetivo:** Verificar/crear NodeGroup con instancias t3.large SPOT.

```bash
cd ../etapa05-CreaNodeGroup
bash ejecutar.sh
```

**Resultado:** Workers nodes Ready en el cluster.

---

### Paso 6 — Validar Metrics Server + CloudWatch

**Objetivo:** Verificar monitoreo del cluster (metrics-server + CloudWatch).

```bash
cd ../etapa06-ValidaObservabilidad
bash ejecutar.sh
```

**Resultado:** `kubectl top` funcionando y CloudWatch recibiendo logs.

---

### Paso 7 — Configurar CloudWatch: Logs, Métricas y Alarmas ⭐ IE1

**Objetivo:** Configurar CloudWatch como herramienta completa de observabilidad.

```bash
cd ../08-cloudwatch
bash ejecutar.sh
```

**Verificación:**

```bash
bash verificar.sh
```

**Resultado:**
- Logs de todos los pods en CloudWatch
- Métricas de CPU/memoria/red (Container Insights)
- Alarmas para errores y disponibilidad

**Cubre:** IE1 (20%) — Herramientas de monitoreo con CloudWatch.

---

### Paso 8 — Dashboard de Observabilidad en CloudWatch ⭐ IE3

**Objetivo:** Crear dashboard con métricas clave del sistema.

```bash
cd ../09-dashboard
bash ejecutar.sh
```

**Verificación:**

```bash
bash verificar.sh
```

**URL del Dashboard:**
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=laboratorio-eks-observability
```

**Resultado:**
- Tiempo de despliegue
- Cobertura de pruebas
- Uso de CPU/memoria
- Errores registrados
- Estado de pods

**Cubre:** IE3 (10%) — Dashboard con métricas clave.

---

### Paso 9 — Crear repositorios en Amazon ECR

**Objetivo:** Crear repositorios ECR para imágenes Docker.

```bash
cd ../etapa07-PublicaECR
bash ejecutar.sh
```

**Resultado:** Tres repositorios ECR listos (~2 min).

---

### Paso 10 — Quality Gates integrados en el Pipeline CI/CD ⭐ IE6

**Objetivo:** Quality gates automáticos que bloquean deploys con problemas.

**Ubicación:** `06-aplicacion/.github/workflows/ci-cd-pipeline.yml`

**Componentes:**
- **Security Scan** (Snyk): Detecta vulnerabilidades críticas
- **Quality Check** (SonarQube + PMD): Analiza calidad de código
- **Test Coverage** (JaCoCo): Garantiza mínimo 80% de cobertura
- **Compliance Check**: Valida documentación y archivos sensibles
- **Deploy Gate**: Solo despliega si TODOS los checks pasan

**Configuración requerida en GitHub Secrets:**
- `SNYK_TOKEN`: Token de Snyk (snyk.io/edu)
- `SONAR_TOKEN`: Token de SonarQube (sonarcloud.io)

**Branch Protection:**
- Settings → Branches → Add rule
- Branch name pattern: `main`
- Require status checks: security-scan, quality-check, test-coverage

**Cubre:** IE6 (20%) — Pipeline se detiene ante fallas críticas.

---

### Paso 11 — Documentación: Integración de Herramientas en CI/CD ⭐ IE4

**Objetivo:** Generar documentación completa de integración.

```bash
cd ../11-documentacion
bash ejecutar.sh
```

**Verificación:**

```bash
bash verificar.sh
```

**Resultado:**
- DOCUMENTACION_CICD.md
- docs/ARQUITECTURA.md
- docs/ADR.md

**Cubre:** IE4 (10%) — Documentación de integración CI/CD.

---

### Paso 12 — Auditoría: Políticas de Cumplimiento Automatizadas ⭐ IE5

**Objetivo:** Verificar todas las políticas de cumplimiento configuradas.

```bash
cd ../12-auditoria
bash ejecutar.sh
```

**Verificación:**

```bash
bash verificar.sh
```

**Resultado:**
- Branch Protection verificado
- SonarQube configurado
- Snyk configurado
- PMD configurado
- JaCoCo configurado
- reporte-auditoria.txt generado

**Cubre:** IE5 (20%) — Políticas de cumplimiento automatizadas.

---

### Paso 13 — Publicar en GitHub + Desplegar en Kubernetes

**Objetivo:** Desplegar aplicación completa en EKS.

```bash
cd ../etapa08-DespliegaK8s
bash ejecutar.sh
```

**Resultado:** DB, Backend y Frontend corriendo en EKS (~15-20 min).

---

### Paso 14 — Validación final + Operación Avanzada

**Objetivo:** Verificar aplicación y demostrar capacidades avanzadas.

```bash
cd ../etapa09-ValidaApp
bash ejecutar.sh
```

**Resultado:**
- Auto-healing verificado
- HPA funcionando
- Métricas de CPU/memoria visibles

---

### Paso 15 — Conectividad + URL de la aplicación

**Objetivo:** Obtener URL pública de la aplicación.

```bash
cd ../etapa10-ConectividadURL
bash ejecutar.sh
```

**Resultado:** URL de la aplicación lista para acceder desde navegador.

---

### Paso 16 — Auditoría / Reporte completo del laboratorio

**Objetivo:** Generar reporte completo de evidencia.

```bash
cd ../etapa11-Auditoria
bash ejecutar.sh
```

**Resultado:** `reporte.txt` con checklist de evaluación.

---

### Paso 17 — Limpieza total del laboratorio

**Objetivo:** Eliminar todos los recursos creados.

```bash
cd ../etapa12-LimpiezaTotal
bash ejecutar.sh
```

**Resultado:** Entorno completamente limpio.

---

## Estructura del Proyecto

```
guia02/
├── 01-create-eks/          # Crear cluster EKS
├── 02-create-groups/       # Crear node groups
├── 03-ecr/                 # Crear repositorios ECR
├── 04-k8s/                 # Manifests de Kubernetes
├── 05-github/              # Configuración de GitHub
├── 06-aplicacion/          # Código fuente de la aplicación
│   ├── .github/workflows/
│   │   └── ci-cd-pipeline.yml   # Pipeline unificado
│   ├── src/                # Código Java
│   ├── k8s/                # Manifests K8s
│   ├── Dockerfile
│   ├── pom.xml
│   └── README.md
├── 07-revision/            # Scripts de revisión
├── 08-cloudwatch/          # Configuración de CloudWatch
├── 09-dashboard/           # Dashboard de CloudWatch
├── 11-documentacion/       # Documentación del proyecto
├── 12-auditoria/           # Scripts de auditoría
├── Dockerfile              # Docker para el laboratorio
├── backend-alumnos.zip     # Código fuente original
└── pasos.md                # Pasos detallados
```

---

## Herramientas Utilizadas

| Categoría | Herramienta | Propósito |
|-----------|-------------|-----------|
| **Monitoreo** | CloudWatch Logs | Almacenamiento de logs |
| | Container Insights | Métricas de CPU/memoria/red |
| | CloudWatch Alarms | Alertas automáticas |
| | CloudWatch Dashboard | Visualización de métricas |
| **CI/CD** | GitHub Actions | Automatización de pipeline |
| | Snyk | Escaneo de seguridad |
| | SonarQube | Análisis de calidad |
| | PMD | Análisis estático |
| | JaCoCo | Cobertura de pruebas |
| **Infraestructura** | Amazon EKS | Orquestación de contenedores |
| | Amazon ECR | Registro de imágenes Docker |
| | CloudFormation | Infraestructura como código |

---

## Costos Estimados

| Componente | Costo Mensual |
|------------|---------------|
| EKS Cluster | ~$73 USD |
| EC2 (3x t3.large SPOT) | ~$30 USD |
| CloudWatch | ~$5-10 USD |
| ECR | ~$1 USD |
| **Total** | **~$110-120 USD** |

**Nota:** Para uso académico, AWS Academy proporciona créditos gratuitos.

---

## Solución de Problemas

### El cluster EKS no responde

```bash
aws eks update-kubeconfig --region us-east-1 --name laboratorio-eks
kubectl get nodes
```

### Los pods no arrancan

```bash
kubectl get pods -n alumnos
kubectl describe pod <pod-name> -n alumnos
kubectl logs <pod-name> -n alumnos
```

### CloudWatch no recibe logs

```bash
kubectl get pods -n amazon-cloudwatch
kubectl logs -l app=fluent-bit -n amazon-cloudwatch
```

### El pipeline falla en quality gates

Revisar los logs en GitHub Actions → Seleccionar el workflow fallido → Revisar cada job.

---

## Referencias

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Snyk Documentation](https://docs.snyk.io/)
- [SonarCloud Documentation](https://docs.sonarcloud.io/)
