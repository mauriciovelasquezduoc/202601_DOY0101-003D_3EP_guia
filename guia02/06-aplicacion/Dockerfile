# ============================================================
# BUILD STAGE
# ============================================================

FROM maven:3.9.9-eclipse-temurin-21-alpine AS build

WORKDIR /app

# Copiar archivos de build y wrapper (para cache de dependencias)
COPY pom.xml ./
COPY .mvn ./.mvn
COPY mvnw ./

# Descargar dependencias (aprovecha cache de Docker)
RUN mvn dependency:go-offline -B || true

# Copiar código fuente
COPY src ./src

# Compilar y empaquetar (sin tests en esta etapa)
RUN mvn clean package -DskipTests -B

# ============================================================
# RUNTIME STAGE
# ============================================================

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build /app/target/alumnos-app-1.0.0.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget --spider -q http://localhost:8080/alumnos || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
