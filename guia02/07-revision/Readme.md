# 07 - Revision: Cómo acceder al Backend en EKS

## 1. Obtener IP pública de los nodos workers

### Opción A: Con kubectl

```bash
kubectl get nodes -o wide
```

Busca la columna `EXTERNAL-IP`. Cualquiera de esas IPs funciona.

### Opción B: Con AWS CLI

```bash
aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/ep3-devops,Values=owned" \
  --query 'Reservations[].Instances[].{IP:PublicIpAddress,Name:Tags[?Key==`Name`].Value|[0]}' \
  --region us-east-1
```

## 2. Probar en Terminal

Reemplaza `<IP_PUBLICA>` con la IP de algún nodo worker:

```bash
# Health check
curl http://<IP_PUBLICA>:30080/api/health

# Listar alumnos
curl http://<IP_PUBLICA>:30080/api/alumnos

# Swagger UI (documentación interactiva)
curl http://<IP_PUBLICA>:30080/swagger-ui.html

# OpenAPI spec
curl http://<IP_PUBLICA>:30080/v3/api-docs
```

## 3. Abrir en el Browser

```
http://<IP_PUBLICA>:30080/api/alumnos
http://<IP_PUBLICA>:30080/swagger-ui.html
http://<IP_PUBLICA>:30080/h2-console
```

> **Nota:** Las IPs públicas pueden cambiar si los nodos workers se reemplazan (auto-scaling, actualización, etc.).
