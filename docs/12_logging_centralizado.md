# 🧾 Logging centralizado en Kubernetes

Este documento describe cómo implementar un servicio de **logging centralizado** dentro del clúster Kubernetes y cómo integrar servidores externos (por ejemplo, Debian) para enviar sus logs en tiempo real.

---

## 🎯 Objetivo

Implementar una solución ligera y de baja latencia para recopilar logs de todos los nodos y servidores externos en un punto central, permitiendo visualización y análisis casi en tiempo real.

---

## ⚡ Opción 1: Loki + Promtail + Grafana (rápida y ligera)

- **Promtail** se ejecuta como *DaemonSet* en cada nodo o servidor externo.
- **Loki** almacena los logs indexando solo etiquetas (no el contenido completo).
- **Grafana** consulta Loki para mostrar los logs con un retardo menor a 1 segundo.

Ideal para laboratorios o entornos de desarrollo donde se prioriza **velocidad y simplicidad**.

### 📦 Despliegue rápido con Helm

```bash
kubectl create namespace logging

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack   --namespace logging   --set grafana.enabled=true   --set promtail.enabled=true   --set loki.persistence.enabled=false
```

Esto instala:
- Loki (almacenamiento)
- Promtail (recolector local)
- Grafana (interfaz web)

Podés acceder a Grafana exponiendo el servicio con NodePort o MetalLB (por ejemplo `192.168.10.253`).

---

## 🌍 Recepción de logs desde servidores externos (Debian fuera del cluster)

También podés instalar **Promtail** en servidores Debian externos para enviar sus logs hacia Loki dentro del clúster.

### 🔧 Configuración de Promtail en servidor externo

Archivo `/etc/promtail/config.yaml`:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.10.251:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          host: debian-ext-01
          __path__: /var/log/*.log
```

> ⚠️ Cambiar `192.168.10.251` por la IP o DNS del servicio Loki expuesto en tu clúster.

Iniciar servicio:
```bash
sudo systemctl enable promtail
sudo systemctl start promtail
```

Esto envía los logs de `/var/log/*.log` del servidor externo directamente al Loki central.

---

## 🧩 Opción 2: Fluent Bit + Elasticsearch + Kibana

- **Fluent Bit** recolecta y envía logs hacia **Elasticsearch**.
- **Kibana** permite búsqueda avanzada, dashboards y análisis.
- Requiere más recursos (RAM/CPU) que Loki, pero ofrece más capacidad analítica.

### Ejemplo de configuración de Fluent Bit en servidor Debian

Archivo `/etc/fluent-bit/fluent-bit.conf`:

```ini
[INPUT]
    Name              tail
    Path              /var/log/*.log
    Tag               debian.*
    Refresh_Interval  5
    Read_from_Head    True

[OUTPUT]
    Name  es
    Host  192.168.10.251
    Port  9200
    Index logs
    Type  _doc
```

> Loki/Elasticsearch deben estar expuestos en una IP accesible (`192.168.10.251` en este ejemplo).

---

## ⚙️ Consideraciones de red y seguridad

- Asegurarse de que el puerto del backend (Loki o Elasticsearch) esté accesible desde los servidores externos.
- Puede exponerse como `LoadBalancer` o `NodePort`.
- Recomendado habilitar TLS y autenticación básica si se usan redes compartidas.

---

## ⚡ Rendimiento esperado

- Latencia promedio: **300–800 ms** desde la generación del log hasta su visualización.
- Uso de CPU por agente (Promtail/Fluent Bit): **<1 % por nodo**.
- Propagación inmediata de logs críticos del sistema o contenedores.

---

## 🧰 Comandos útiles

| Comando | Descripción |
|----------|-------------|
| `kubectl get pods -n logging` | Verifica el estado de Loki, Promtail y Grafana |
| `kubectl port-forward svc/loki-grafana 3000:80 -n logging` | Acceso local a Grafana |
| `sudo systemctl status promtail` | Verifica el estado del agente en Debian externo |
| `curl http://192.168.10.251:3100/metrics` | Chequea la disponibilidad de Loki |

---

## 📊 Resultado esperado

Una vez desplegado:
- Los logs de todos los nodos Kubernetes se recolectan automáticamente.
- Los servidores externos Debian envían sus logs hacia Loki.
- Grafana muestra los logs con mínimo retardo.

---

> **Autor:** Cristian Samuel Cárdenas Ojeda  
> **Institución:** Universidad Nacional de la Patagonia Austral – UNPA  
> **Fecha:** Noviembre 2025
