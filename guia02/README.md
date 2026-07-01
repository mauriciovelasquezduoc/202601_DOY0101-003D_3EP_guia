# Evaluación Parcial 3 — Observabilidad y Entornos Reales en DevOps

## Descripción

Guía completa para configurar un entorno DevOps con observabilidad, métricas y cumplimiento normativo en Amazon EKS.

## Indicadores de Evaluación

| Indicador     | Descripción                              | Peso | Directorio                             |
| ------------- | ----------------------------------------- | ---- | -------------------------------------- |
| **IE1** | Herramientas de monitoreo (CloudWatch)    | 20%  | `08-cloudwatch/`                     |
| **IE2** | Despliegue en Kubernetes en la nube       | 20%  | `01-create-eks/`, `06-aplicacion/` |
| **IE3** | Dashboard con métricas clave             | 10%  | `09-dashboard/`                      |
| **IE4** | Documentación de integración CI/CD      | 10%  | `11-documentacion/`                  |
| **IE5** | Políticas de cumplimiento automatizadas  | 20%  | `12-auditoria/`                      |
| **IE6** | Pipeline se detiene ante fallas críticas | 20%  | `06-aplicacion/`                     |

---

## Requisitos Previos

Se debe iniciar todo con abrir la aplicación DockerDesktop y luego:

### 1. Docker

```bash
docker build -t devops-eks-lab .
```

### 2. Ejecutar contenedor

```bash
docker run -it -v ".":/root/work -v ~/.aws:/root/.aws -v /var/run/docker.sock:/var/run/docker.sock devops-eks-lab
```

### 3. Configurar AWS

Se debe ingresar a aws acadmy, luego seleccionar el curso para posteriormente inicial el laboratorio, cuando ya este el icono con el color verde, se debe hacer click para ver el detalle y a partir de ahi sacar las credenciales:

```bash
aws configure
```

---

## Paso a Paso

### Paso 1 — Crear Cluster EKS

**Directorio:** `01-create-eks/`

```bash
cd 01-create-eks
bash ejecutar.sh
```

**Resultado:** Cluster EKS `laboratorio-eks` creado (~15 min).

---

### Paso 2 — Crear Node Groups

**Directorio:** `02-create-groups/`

```bash
cd ../02-create-groups
bash ejecutar.sh
```

**Resultado:** Workers nodes Ready en el cluster.

---

### Paso 3 — Crear Repositorios ECR

**Directorio:** `03-ecr/`

```bash
cd ../03-ecr
bash ejecutar.sh
```

**Resultado:** Repositorios ECR listos para imágenes Docker.

---

### Paso 4 — Manifests de Kubernetes

**Directorio:** `04-k8s/`

Archivos disponibles:

- `namespace.yaml` - Namespace de la aplicación
- `backend-deployment.yaml` - Deployment del backend
- `backend-service.yaml` - Service del backend
- `k8s-Backend.sh` - Script de despliegue

```bash
cd ../04-k8s
bash k8s-Backend.sh
```

**Resultado:** Backend desplegado en Kubernetes.

---

### Paso 5 — Configuración de GitHub

**Directorio:** `05-github/`

```bash
cd ../05-github
cat Readme.md
```

**Resultado:** Repositorio y secrets de GitHub configurados.

---

### Paso 6 — Aplicación Backend

**Directorio:** `06-aplicacion/`

```bash
cd ../06-aplicacion
git init 
git add .
git commit -m "feature: init"
```

Antes de hacer push debes crear un access token

1. click en el icono de tu cuenta en github
2. ir a Settings
3. Developers Settings
4. Personal access tokens > tokens (classic)
5. Generate new token > Generate new token (classic)
6. Verificar el codigo por correo
7. Poner el nomre al access token y poner todos los permisos y copiar el token

Luego debes crear un repositorio vacio y rescatar el nombre del repositroio (reemplazar nombre_uusario y repositiro) en la consola luego lanzar

```
git remote add origin https://github.com/NOMBRE_USUARIO/REPOSITORIO.git
```


y finalmente hacer push a github

```
git push -u origin main
```

Ahi te pedira el usaurio y la contrasena, ahi pones el token y comenzara a subir el codigo


Contenido:

- `src/` - Código fuente Java
- `k8s/` - Manifests de Kubernetes
- `.github/workflows/ci-cd-pipeline.yml` - Pipeline CI/CD unificado
- `Dockerfile` - Docker para la aplicación
- `pom.xml` - Configuración Maven

**Pipeline CI/CD:**
El pipeline ejecuta automáticamente:

1. Security Scan (Snyk)
2. Quality Check (SonarQube + PMD)
3. Test Coverage (JaCoCo)
4. Compliance Check
5. Build & Push a ECR
6. Deploy a EKS

---

### Paso 7 — CloudWatch: Logs, Métricas y Alarmas ⭐ IE1

**Directorio:** `08-cloudwatch/`

```bash
cd ../08-cloudwatch
bash ejecutar.sh
```

**Verificación:**

```bash
bash verificar.sh
```

**Resultado:**

- Fluent Bit enviando logs a CloudWatch
- Container Insights con métricas de CPU/memoria/red
- Alarmas para errores y disponibilidad

**Cubre:** IE1 (20%)

---

### Paso 8 — Dashboard de Observabilidad ⭐ IE3

**Directorio:** `09-dashboard/`

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

**Cubre:** IE3 (10%)

---

### Paso 9 — Quality Gates (Pipeline CI/CD) ⭐ IE6

**Ubicación:** `06-aplicacion/.github/workflows/ci-cd-pipeline.yml`

Los quality gates ya están integrados en el pipeline. Se ejecutan automáticamente en cada push a main o pull request.

**Componentes:**

- **Security Scan** (Snyk): Vulnerabilidades críticas
- **Quality Check** (SonarQube + PMD): Calidad de código
- **Test Coverage** (JaCoCo): Mínimo 80% cobertura
- **Compliance Check**: Documentación y archivos sensibles
- **Deploy Gate**: Solo despliega si todo pasa

**Configuración en GitHub Secrets:**

- `SNYK_TOKEN`: Token de Snyk
- `SONAR_TOKEN`: Token de SonarQube
- `AWS_ACCESS_KEY_ID`: Credenciales AWS
- `AWS_SECRET_ACCESS_KEY`: Credenciales AWS
- `AWS_SESSION_TOKEN`: Token de sesión AWS

**Cubre:** IE6 (20%)

---

### Paso 10 — Documentación ⭐ IE4

**Directorio:** `11-documentacion/`

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

**Cubre:** IE4 (10%)

---

### Paso 11 — Auditoría ⭐ IE5

**Directorio:** `12-auditoria/`

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
- Herramientas de cumplimiento verificadas
- reporte-auditoria.txt generado

**Cubre:** IE5 (20%)

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
│   │   └── ci-cd-pipeline.yml
│   ├── src/
│   ├── k8s/
│   ├── Dockerfile
│   └── pom.xml
├── 07-revision/            # Scripts de revisión
├── 08-cloudwatch/          # Configuración de CloudWatch
├── 09-dashboard/           # Dashboard de CloudWatch
├── 11-documentacion/       # Documentación del proyecto
├── 12-auditoria/           # Scripts de auditoría
├── Dockerfile              # Docker para el laboratorio
└── README.md               # Este archivo
```

---

## Herramientas

| Categoría                | Herramienta          | Propósito             |
| ------------------------- | -------------------- | ---------------------- |
| **Monitoreo**       | CloudWatch Logs      | Logs de la aplicación |
|                           | Container Insights   | Métricas de recursos  |
|                           | CloudWatch Alarms    | Alertas automáticas   |
|                           | CloudWatch Dashboard | Visualización         |
| **CI/CD**           | GitHub Actions       | Automatización        |
|                           | Snyk                 | Seguridad              |
|                           | SonarQube            | Calidad                |
|                           | PMD                  | Análisis estático    |
|                           | JaCoCo               | Cobertura              |
| **Infraestructura** | Amazon EKS           | Orquestación          |
|                           | Amazon ECR           | Registro de imágenes  |

---

## Solución de Problemas

### Cluster EKS no responde

```bash
aws eks update-kubeconfig --region us-east-1 --name laboratorio-eks
kubectl get nodes
```

### Pods no arrancan

```bash
kubectl get pods -n alumnos
kubectl describe pod <pod-name> -n alumnos
```

### CloudWatch no recibe logs

```bash
kubectl get pods -n amazon-cloudwatch
kubectl logs -l app=fluent-bit -n amazon-cloudwatch
```

### Pipeline falla en quality gates

Verificar logs en GitHub Actions → Seleccionar workflow fallido → Revisar cada job.

---

## Referencias

- [Amazon EKS](https://docs.aws.amazon.com/eks/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Snyk](https://docs.snyk.io/)
- [SonarCloud](https://docs.sonarcloud.io/)

