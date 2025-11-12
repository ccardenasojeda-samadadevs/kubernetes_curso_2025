---

## 🔑 Conceptos Clave

### Tipos de Secrets
- **Opaque**: Datos arbitrarios definidos por usuario
- **kubernetes.io/dockerconfigjson**: Credenciales de registry
- **kubernetes.io/tls**: Certificados TLS

### ConfigMap vs Secret
| ConfigMap | Secret |
|-----------|--------|
| Datos no sensibles | Datos sensibles |
| Plain text | Base64 encoded |
| Visible en describe | Oculto en describe |
| No encriptado | Puede encriptarse at-rest |

### QoS Classes
- **Guaranteed**: requests = limits para todos los recursos
- **Burstable**: Al menos un recurso tiene request != limit
- **BestEffort**: Sin requests ni limits

### Resource Units
- **CPU**: 1 = 1 vCPU, 1000m = 1 vCPU, 100m = 0.1 vCPU
- **Memory**: 1Gi = 1024Mi, 1Mi = 1024Ki

---

## 🛠️ Comandos Útiles

### Secrets
```bash
# Crear secret TLS
kubectl create secret tls my-tls --cert=cert.pem --key=key.pem

# Ver contenido de secret (decodificado)
kubectl get secret my-secret -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

### ConfigMaps
```bash
# Crear desde directorio
kubectl create configmap app-config --from-file=config/

# Recargar ConfigMap en pods
kubectl rollout restart deployment/my-app
```

### Jobs y CronJobs
```bash
# Ver historial de CronJob
kubectl get jobs --sort-by=.metadata.creationTimestamp

# Crear Job desde CronJob
kubectl create job --from=cronjob/my-cronjob manual-run

# Limpiar Jobs completados
kubectl delete jobs --field-selector status.successful=1
```

### Resources
```bash
# Ver uso de recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Ver límites del namespace
kubectl describe namespace my-namespace
```

### RBAC
```bash
# Verificar permisos
kubectl auth can-i create pods --as=user1 --namespace=ns-user1

# Listar recursos RBAC
kubectl get roles,rolebindings,clusterroles,clusterrolebindings
```