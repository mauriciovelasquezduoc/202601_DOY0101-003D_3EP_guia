# Alumnos API — version00 (Gradle)

REST API para gestión de alumnos construida con Spring Boot 3, siguiendo **arquitectura limpia (Clean Architecture)** y una pirámide de tests completa.

---

## Tabla de contenidos

- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura limpia](#arquitectura-limpia)
- [Diseño del sistema](#diseño-del-sistema)
- [Requisitos previos](#requisitos-previos)
- [Configuración local](#configuración-local)
- [Calidad de código](#calidad-de-código)
- [Operación con Docker](#operación-con-docker)
- [API Reference](#api-reference)
- [Pirámide de tests](#pirámide-de-tests)
- [Cobertura y análisis estático](#cobertura-y-análisis-estático)
- [CI/CD](#cicd)
- [Orquestación con Kubernetes](#orquestación-con-kubernetes)

---

## Stack tecnológico

| Categoría | Tecnología | Versión |
|---|---|---|
| Lenguaje | Java | 21 |
| Framework | Spring Boot | 3.4.5 |
| Build tool | Gradle | 9.x |
| Persistencia | Spring Data JPA + Hibernate | 6.x |
| Base de datos | H2 (in-memory) | 2.x |
| Seguridad | Spring Security | 6.x |
| Documentación API | SpringDoc OpenAPI (Swagger) | 2.5.0 |
| Mapeo de objetos | Lombok | 1.18.x |
| Tests unitarios | JUnit 5 + Mockito | 5.x / 5.x |
| Tests de integración | Spring Boot Test / MockMvc | 3.4.5 |
| Tests de repositorio | @DataJpaTest | 3.4.5 |
| Tests de aceptación | Cucumber | 7.20.1 |
| Tests de contrato | Spring Cloud Contract | 4.2.1 |
| Cobertura | JaCoCo | 0.8.13 |
| Mutation testing | PIT (Pitest) | 1.19.x |
| Refactoring automático | OpenRewrite | 6.30.0 |
| Formato de código | Spotless + Google Java Format | 7.0.4 / 1.25.2 |
| Análisis estático | PMD | 7.13.0 |
| Análisis SAST | SonarCloud | — |
| Contenedores | Docker + Docker Compose | — |

---

## Arquitectura limpia

El proyecto implementa **Clean Architecture** (también conocida como arquitectura hexagonal o ports & adapters). El principio central es la **Regla de Dependencia**: las capas internas no conocen nada de las capas externas.

### Capas y responsabilidades

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INFRASTRUCTURE                               │
│   (Frameworks, DB, HTTP, Spring, JPA, Swagger)                      │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                      APPLICATION                            │   │
│   │   (Casos de uso, orquestación, reglas de aplicación)        │   │
│   │                                                             │   │
│   │   ┌─────────────────────────────────────────────────────┐   │   │
│   │   │                    DOMAIN                           │   │   │
│   │   │   (Entidades, reglas de negocio puras)              │   │   │
│   │   │   Sin dependencias externas                         │   │   │
│   │   └─────────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Mapeo al código fuente

```
src/main/java/cl/duocuc/alumnos/
│
├── domain/                         ← CAPA DE DOMINIO (núcleo)
│   └── Alumno.java                   Entidad pura: solo datos y reglas de negocio.
│                                     Sin anotaciones de Spring, JPA ni Lombok.
│
├── application/                    ← CAPA DE APLICACIÓN (casos de uso)
│   └── AlumnoService.java            Orquesta el dominio. Depende solo de interfaces
│                                     (puertos). No conoce HTTP ni JPA.
│
├── config/                         ← CONFIGURACIÓN TRANSVERSAL
│   ├── GlobalExceptionHandler.java   Manejo centralizado de errores HTTP.
│   └── SecurityConfig.java           Configuración de Spring Security.
│
└── infrastructure/                 ← CAPA DE INFRAESTRUCTURA (adaptadores)
    │
    ├── controller/                   ADAPTADOR DE ENTRADA (driving)
    │   └── AlumnoController.java     Recibe HTTP → llama al servicio → retorna JSON.
    │
    ├── entity/                       ADAPTADOR DE SALIDA (driven)
    │   └── AlumnoEntity.java         Representación JPA de Alumno para la BD.
    │
    ├── mapper/                       TRADUCTOR entre capas
    │   └── AlumnoMapper.java         Convierte Alumno (dominio) ↔ AlumnoEntity (JPA).
    │
    ├── repository/                   PUERTO DE SALIDA
    │   └── AlumnoRepository.java     Interfaz Spring Data — la implementación la provee JPA.
    │
    └── config/                       CONFIGURACIÓN DE INFRAESTRUCTURA
        ├── OpenApiConfig.java        Metadatos de la documentación OpenAPI.
        └── WebConfig.java            Configuración de recursos estáticos (ReDoc).
```

### Flujo de una petición

```
HTTP Request
    │
    ▼
AlumnoController          ← Infrastructure (adaptador entrada)
    │  llama a
    ▼
AlumnoService             ← Application (caso de uso)
    │  usa puerto
    ▼
AlumnoRepository          ← Puerto de salida (interfaz)
    │  implementado por
    ▼
Spring Data JPA           ← Infrastructure (adaptador salida)
    │  persiste en
    ▼
H2 / Base de datos
```

### Regla de dependencia

| Capa | Puede depender de | No puede depender de |
|---|---|---|
| `domain` | Nada externo | `application`, `infrastructure`, Spring |
| `application` | `domain` | `infrastructure`, Spring MVC, JPA |
| `infrastructure` | `application`, `domain` | — (puede usar todo) |

---

## Diseño del sistema

### Diagrama de componentes

```
┌──────────────────────────────────────────────────────────────────┐
│                         Cliente HTTP                             │
│              (curl / Swagger UI / Cucumber / Tests)              │
└──────────────────────────┬───────────────────────────────────────┘
                           │ HTTP/REST
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Spring Boot Application                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  SecurityConfig          GlobalExceptionHandler             │ │
│  │  (Spring Security)       (HTTP 4xx/5xx unificados)          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────────────┐   │
│  │  AlumnoController    │───▶│  AlumnoService               │   │
│  │  @RestController     │    │  @Service                    │   │
│  │  GET  /alumnos       │    │  listar()                    │   │
│  │  POST /alumnos       │    │  crear()                     │   │
│  │  PUT  /alumnos/{id}  │    │  actualizar()                │   │
│  │  DELETE /alumnos/{id}│    │  eliminar()                  │   │
│  │  GET  /alumnos/export│    │  exportar()                  │   │
│  │  POST /alumnos/import│    │  importar()                  │   │
│  └──────────────────────┘    └──────────────┬───────────────┘   │
│                                             │                   │
│  ┌──────────────────────┐    ┌──────────────▼───────────────┐   │
│  │  AlumnoMapper        │◀──▶│  AlumnoRepository            │   │
│  │  domain ↔ entity     │    │  JpaRepository<AlumnoEntity> │   │
│  └──────────────────────┘    └──────────────┬───────────────┘   │
│                                             │                   │
│                              ┌──────────────▼───────────────┐   │
│                              │  H2 In-Memory Database       │   │
│                              │  (dev/test: jdbc:h2:mem:)    │   │
│                              └──────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Modelo de datos

```
┌─────────────────────────────┐
│         alumno_entity       │
├─────────────────────────────┤
│ id        BIGINT  PK AUTO   │
│ nombre    VARCHAR(255)      │
│ apellido  VARCHAR(255)      │
└─────────────────────────────┘
```

### Perfiles de configuración

| Perfil | Base de datos | Log level | Uso |
|---|---|---|---|
| `default` | H2 in-memory | INFO | Desarrollo rápido |
| `dev` | H2 in-memory + H2 Console | DEBUG | Desarrollo con consola BD |
| `prod` | H2 in-memory | WARN | Simulación producción |

---

## Requisitos previos

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| JDK | 21 | `java -version` |
| Gradle | 9.x (o usar `./gradlew`) | `gradle -version` |
| Docker | 24.x | `docker -v` |
| Docker Compose | 2.x | `docker compose version` |
| Git | 2.x | `git --version` |

---

## Configuración local

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd jobs/java/version00
```

### 2. Compilar el proyecto

```bash
# Con el wrapper incluido (recomendado)
./gradlew build -x test

# O con Gradle instalado globalmente
gradle build -x test
```

### 3. Ejecutar la aplicación

```bash
./gradlew bootRun
```

La aplicación levanta en `http://localhost:8080`.

### 4. Verificar que funciona

```bash
curl http://localhost:8080/alumnos
# Respuesta esperada: []
```

### 5. Acceder a la documentación interactiva

| Interfaz | URL |
|---|---|
| Swagger UI | http://localhost:8080/swagger-ui.html |
| OpenAPI JSON | http://localhost:8080/v3/api-docs |
| ReDoc | http://localhost:8080/redoc.html |
| H2 Console | http://localhost:8080/h2-console |

> **H2 Console:** JDBC URL `jdbc:h2:mem:testdb`, usuario `sa`, sin contraseña.

### 6. Perfiles disponibles

```bash
# Perfil de desarrollo (activa H2 Console y logs DEBUG)
./gradlew bootRun --args='--spring.profiles.active=dev'

# Perfil de producción
./gradlew bootRun --args='--spring.profiles.active=prod'
```

---

## Calidad de código

El proyecto incluye tres herramientas que se ejecutan **antes de compilar**, en el job `code-quality` del pipeline CI. Esto garantiza que el código llega limpio a SonarCloud.

```
code-quality → build-and-test → security (SonarCloud + Snyk) → docker → deploy
```

### OpenRewrite — Refactoring automático

Aplica recetas de modernización y limpieza de código de forma automática.

**Recetas activas:**

| Receta | Qué hace |
|---|---|
| `UpgradeToJava21` | Moderniza sintaxis a Java 21 (records, pattern matching, etc.) |
| `UpgradeSpringBoot_3_4` | Migra APIs deprecadas de Spring Boot |
| `CommonStaticAnalysis` | Elimina código muerto y patrones problemáticos |
| `UnnecessaryThrows` | Limpia declaraciones `throws` innecesarias |
| `SimplifyBooleanExpression` | Simplifica condiciones booleanas redundantes |
| `RemoveUnusedImports` | Elimina imports sin usar |

```bash
# Ver qué cambiaría (modo CI — no modifica archivos)
./gradlew rewriteDryRun

# Aplicar cambios automáticamente (modo local)
./gradlew rewriteRun
```

### Spotless — Formato de código

Garantiza formato consistente usando **Google Java Format** con estilo AOSP (4 espacios).

```bash
# Verificar formato (modo CI — falla si hay diferencias)
./gradlew spotlessCheck

# Aplicar formato automáticamente (modo local)
./gradlew spotlessApply
```

### PMD — Análisis estático de reglas

Valida reglas de calidad, seguridad y buenas prácticas. El ruleset está en `config/pmd/ruleset.xml`.

**Categorías activas:** `bestpractices`, `errorprone`, `performance`, `security`, `design`, `codestyle`

```bash
# Analizar código principal (modo CI — falla si hay violaciones)
./gradlew pmdMain pmdTest

# Ver reporte HTML
open build/reports/pmd/main.html
```

### Task combinado

```bash
# Ejecuta los 3 checks en orden (equivalente al job CI)
./gradlew codeQuality
```

> **Flujo recomendado antes de hacer push:**
> ```bash
> ./gradlew rewriteRun spotlessApply   # aplica correcciones automáticas
> ./gradlew codeQuality                # verifica que todo pasa
> ./gradlew clean check                # tests + cobertura
> ```

---

## Operación con Docker

### Dockerfile (build multi-etapa)

El `Dockerfile` usa un build en dos etapas:

1. **Etapa build:** imagen `gradle:8.13.0-jdk21` — compila y empaqueta el jar
2. **Etapa runtime:** imagen `eclipse-temurin:21-jre-jammy` — solo el JRE, imagen final liviana (~200MB)

Características de seguridad:
- Corre con usuario no-root (`appuser`)
- Healthcheck integrado
- Sin herramientas de build en la imagen final

```bash
# Construir la imagen
docker build -t alumnos-app:latest .

# Ejecutar el contenedor
docker run -d \
  --name alumnos-app \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  alumnos-app:latest

# Ver estado del healthcheck
docker inspect --format='{{.State.Health.Status}}' alumnos-app
```

### Docker Compose

```bash
docker compose up -d        # levantar en background
docker compose logs -f      # ver logs en tiempo real
docker compose ps           # ver estado de servicios
docker compose down -v      # detener y limpiar volúmenes
```

> La aplicación estará disponible en `http://localhost:8080` una vez que el healthcheck reporte `healthy` (~30 segundos).

---

## API Reference

### Base URL

```
http://localhost:8080/alumnos
```

### Endpoints

| Método | Ruta | Descripción | Body |
|---|---|---|---|
| `GET` | `/alumnos` | Listar todos los alumnos | — |
| `POST` | `/alumnos` | Crear un alumno | `{"nombre":"Juan","apellido":"Pérez"}` |
| `PUT` | `/alumnos/{id}` | Actualizar un alumno | `{"nombre":"Juan","apellido":"Soto"}` |
| `DELETE` | `/alumnos/{id}` | Eliminar un alumno | — |
| `GET` | `/alumnos/export` | Exportar alumnos a CSV | — |
| `POST` | `/alumnos/import` | Importar alumnos desde CSV | `Juan,Pérez\nAna,López` |

### Ejemplos con curl

```bash
# Crear alumno
curl -X POST http://localhost:8080/alumnos \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan","apellido":"Pérez"}'

# Listar alumnos
curl http://localhost:8080/alumnos

# Actualizar alumno (id=1)
curl -X PUT http://localhost:8080/alumnos/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan","apellido":"Soto"}'

# Eliminar alumno (id=1)
curl -X DELETE http://localhost:8080/alumnos/1

# Exportar CSV
curl http://localhost:8080/alumnos/export

# Importar CSV
curl -X POST http://localhost:8080/alumnos/import \
  -H "Content-Type: text/plain" \
  -d 'Juan,Pérez
Ana,López'
```

---

## Pirámide de tests

El proyecto implementa una pirámide de tests completa con 5 capas:

```
                    ╔══════════════════════╗
                    ║   CONTRACT TESTS     ║  3 contratos
                    ║  Spring Cloud        ║  (producer side)
                    ╚══════════════════════╝
                  ╔════════════════════════════╗
                  ║     ACCEPTANCE TESTS       ║  7 escenarios
                  ║       Cucumber BDD         ║  E2E con HTTP real
                  ╚════════════════════════════╝
              ╔══════════════════════════════════════╗
              ║        INTEGRATION TESTS             ║
              ║  @WebMvcTest (8) + @SpringBootTest(2)║
              ╚══════════════════════════════════════╝
          ╔══════════════════════════════════════════════╗
          ║           REPOSITORY TESTS                   ║
          ║           @DataJpaTest (6)                   ║
          ╚══════════════════════════════════════════════╝
      ╔══════════════════════════════════════════════════════╗
      ║                  UNIT TESTS                          ║
      ║   AlumnoServiceTest(5) + AlumnoMapperTest(4)         ║
      ║   GlobalExceptionHandlerTest(2)  = 11 tests          ║
      ╚══════════════════════════════════════════════════════╝
```

### Capa 1 — Unit Tests (11 tests)

Tests rápidos, sin Spring context, con mocks de Mockito.

| Clase de test | Tests | Qué verifica |
|---|---|---|
| `AlumnoServiceTest` | 5 | Lógica de negocio: listar, crear, actualizar, eliminar |
| `AlumnoMapperTest` | 4 | Conversión `Alumno` ↔ `AlumnoEntity`, incluyendo nulos |
| `GlobalExceptionHandlerTest` | 2 | Handler de excepciones retorna HTTP 500 con mensaje |

```bash
./gradlew test --tests "cl.duocuc.alumnos.AlumnoServiceTest"
```

### Capa 2 — Repository Tests (6 tests)

Tests con `@DataJpaTest` — levanta solo el contexto JPA con H2 en memoria.

| Clase de test | Tests | Qué verifica |
|---|---|---|
| `AlumnoRepositoryTest` | 6 | save, findAll, findById, deleteById, update contra H2 real |

### Capa 3 — Integration Tests (10 tests)

| Clase de test | Anotación | Tests | Qué verifica |
|---|---|---|---|
| `AlumnoControllerTest` | `@WebMvcTest` | 8 | Todos los endpoints REST con MockMvc |
| `DemoApplicationTest` | `@SpringBootTest` | 2 | Contexto completo levanta sin errores |

### Capa 4 — Acceptance Tests / BDD (7 escenarios)

Tests escritos en Gherkin con Cucumber. Levantan el servidor completo y hacen llamadas HTTP reales.

| Escenario | Qué verifica |
|---|---|
| Listar alumnos cuando no hay ninguno | GET /alumnos retorna lista vacía |
| Crear un alumno exitosamente | POST /alumnos persiste y retorna el alumno |
| Listar alumnos después de crear uno | Flujo crear → listar |
| Actualizar un alumno existente | PUT /alumnos/{id} modifica el recurso |
| Eliminar un alumno existente | DELETE /alumnos/{id} elimina el recurso |
| Exportar alumnos a CSV | GET /alumnos/export retorna formato CSV |
| Importar alumnos desde CSV | POST /alumnos/import procesa el CSV |

### Capa 5 — Contract Tests (3 contratos)

Tests de contrato con Spring Cloud Contract (producer side).

| Contrato | Qué verifica |
|---|---|
| `listar_alumnos.groovy` | GET /alumnos retorna JSON array |
| `crear_alumno.groovy` | POST /alumnos retorna alumno con id numérico |
| `exportar_csv.groovy` | GET /alumnos/export retorna texto plano |

```bash
# Todos los tests + cobertura
./gradlew clean test jacocoTestReport

# Build completo incluyendo contratos
./gradlew clean generateContractTests contractTest test jacocoTestReport check
```

---

## Cobertura y análisis estático

### JaCoCo — Cobertura de código

El build falla si la cobertura baja del **80%** en instrucciones y ramas.

```bash
./gradlew jacocoTestReport
open build/reports/jacoco/test/html/index.html
```

### PIT — Mutation Testing

Verifica la calidad real de los tests mutando el código. El build falla si el mutation score baja del **80%**.

```bash
./gradlew pitest
open build/reports/pitest/index.html
```

### SonarCloud — SAST

Análisis de seguridad, bugs y code smells. El pipeline bloquea si el Quality Gate falla.

```bash
./gradlew sonar \
  -Dsonar.token=<tu-token> \
  -Dsonar.organization=<tu-org>
```

---

## CI/CD

El pipeline tiene **5 jobs secuenciales**. Cada job solo corre si el anterior pasa.

```
┌─────────────────────────────────────────────────────────────────┐
│  JOB 0: Code Quality                                            │
│  ├── OpenRewrite dry-run  (falla si hay recetas pendientes)     │
│  ├── Spotless check       (falla si el formato no es correcto)  │
│  ├── PMD main + test      (falla si hay violaciones de reglas)  │
│  └── Artefacto: pmd-report                                      │
└────────────────────┬────────────────────────────────────────────┘
                     │ (solo si calidad pasa)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB 1: Build & Test                                            │
│  ├── ./gradlew clean check jacocoTestReport                     │
│  ├── Cobertura JaCoCo ≥ 80%                                     │
│  └── Artefactos: jacoco-report, test-results, cucumber-report   │
└────────────────────┬────────────────────────────────────────────┘
                     │ (solo si tests pasan)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB 2: Security Analysis                                       │
│  ├── SonarCloud (SAST) — Quality Gate bloquea si falla         │
│  └── Snyk (SCA) — Bloquea si hay vulnerabilidades HIGH/CRITICAL │
└────────────────────┬────────────────────────────────────────────┘
                     │ (solo si seguridad pasa)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB 3: Docker Build & Push                                     │
│  ├── Build imagen multi-stage (gradle → jre)                   │
│  ├── Push a GitHub Container Registry (GHCR)                   │
│  └── Tags: latest (main), sha-XXXXX, branch-name               │
└────────────────────┬────────────────────────────────────────────┘
                     │ (solo en push a main)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB 4: Deploy — environment: production                        │
│  ├── docker compose up -d --build                               │
│  ├── Health check: espera estado "healthy"                      │
│  └── Smoke test: curl /alumnos                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Secrets requeridos en GitHub

| Secret | Descripción |
|---|---|
| `SONAR_TOKEN` | Token de autenticación de SonarCloud |
| `SONAR_ORGANIZATION` | Organización en SonarCloud |
| `SNYK_TOKEN` | Token de autenticación de Snyk |

> `GITHUB_TOKEN` es generado automáticamente por GitHub Actions.

---

## Orquestación con Kubernetes

```
k8s/
├── deployment.yaml   # 2 réplicas, RollingUpdate, health checks, límites de recursos
├── service.yaml      # ClusterIP en puerto 80 → 8080
├── hpa.yaml          # HorizontalPodAutoscaler: 2-5 réplicas según CPU/memoria
└── secret.yaml       # Plantilla de secrets (NO commitear valores reales)
```

- **Alta disponibilidad:** 2 réplicas mínimas con `RollingUpdate` (sin downtime)
- **Escalabilidad automática:** HPA escala de 2 a 5 pods según carga (CPU > 70%, memoria > 80%)
- **Seguridad:** usuario no-root, `allowPrivilegeEscalation: false`, capabilities dropeadas

```bash
kubectl apply -f k8s/
kubectl get pods -l app=alumnos-app
kubectl get hpa alumnos-app-hpa
```

---

## Estructura del proyecto

```
version00/
├── .github/
│   ├── workflows/ci.yml            ← Pipeline CI/CD (5 jobs)
│   └── dependabot.yml
├── config/
│   └── pmd/
│       └── ruleset.xml             ← Reglas PMD personalizadas
├── k8s/                            ← Manifiestos Kubernetes
├── src/
│   ├── main/java/cl/duocuc/alumnos/
│   │   ├── domain/                 ← Capa de dominio (núcleo)
│   │   ├── application/            ← Casos de uso
│   │   ├── config/                 ← Configuración transversal
│   │   └── infrastructure/         ← Adaptadores (REST, JPA, config)
│   └── test/java/cl/duocuc/alumnos/
│       ├── AlumnoServiceTest.java
│       ├── config/
│       ├── contract/
│       ├── cucumber/
│       └── infrastructure/
├── build.gradle                    ← Gradle + plugins de calidad
├── Dockerfile                      ← Multi-stage build
├── docker-compose.yml
└── README.md
```

---

## Uso de Inteligencia Artificial

| Herramienta | Uso |
|---|---|
| Kiro (Amazon) | Generación de código base, configuración de plugins Gradle, estructura de tests |
| — | Todas las decisiones de arquitectura, justificaciones técnicas y reflexiones son propias del equipo |

> Todo contenido generado con IA fue revisado, validado y adaptado por el equipo.
> Referencia: https://bibliotecas.duoc.cl/ia

---

## Reflexiones individuales

### Integrante 1

> *[Escribir aquí la reflexión personal sobre el aprendizaje obtenido en este proyecto: qué fue lo más desafiante, qué conceptos de DevOps quedaron más claros, y cuál fue tu contribución específica al equipo. Mínimo 150 palabras. Sin uso de IA.]*

### Integrante 2

> *[Escribir aquí la reflexión personal sobre el aprendizaje obtenido en este proyecto: qué fue lo más desafiante, qué conceptos de DevOps quedaron más claros, y cuál fue tu contribución específica al equipo. Mínimo 150 palabras. Sin uso de IA.]*

---

## Licencia

MIT
