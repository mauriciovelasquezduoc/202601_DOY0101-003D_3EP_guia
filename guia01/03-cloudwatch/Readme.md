# Cloudwatch

Vamos a activar un agente en la maquina creada para que entregue información

## EC2 en funcionamiento

![1780427134748](image/Readme/1780427134748.png)

## Obtener token IMDSv2

```
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

![1780427228300](image/Readme/1780427228300.png)

## Verificar el rol IAM asociado

```
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

![1780427261696](image/Readme/1780427261696.png)

## Instalar CloudWatch Agent

```
sudo dnf install amazon-cloudwatch-agent -y
```

![1780427421115](image/Readme/1780427421115.png)

## Crear configuración del agente

```
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
```

![1780427473699](image/Readme/1780427473699.png)


## Hacerse root (administrador)

```
sudo su -
```

## Crear el archivo de configuración

```
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "totalcpu": true
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "*"
        ]
      }
    }
  }
}
EOF
```


![1780427996849](image/Readme/1780427996849.png)


## Iniciar el servicio de agente

```
systemctl start amazon-cloudwatch-agent
```

![1780428079027](image/Readme/1780428079027.png)


## Verificar el funcionamiento

```
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
```

![1780428159969](image/Readme/1780428159969.png)


## Ahora vamos a buscar en cloudWatch

![1780428236287](image/Readme/1780428236287.png)


## Todas las metricas



![1780428284260](image/Readme/1780428284260.png)



## Acceso a los registros

![1780428321265](image/Readme/1780428321265.png)
