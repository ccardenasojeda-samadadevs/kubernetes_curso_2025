# Comandos Útiles - Clase 3

## 🔍 Comandos de Información

### Ver todos los recursos en el namespace
```bash
kubectl get all -n prueba
kubectl get all -n prueba -o wide
```

### Ver recursos específicos con detalles
```bash
kubectl get pods -n prueba -o yaml
kubectl get svc -n prueba -o json
kubectl get deployment -n prueba -o wide
```

### Describir recursos para troubleshooting
```bash
kubectl describe pod <pod-name> -n prueba---

## 🔑 Conceptos Clave

### Labels y Selectors
```bash
# Ver labels de los recursos
kubectl get pod --show-labels -n prueba

# Filtrar por labels
kubectl get pod -l app=nginx -n prueba

# Agregar labels
kubectl label pod nginx version=v1 -n prueba
```

### Annotations
```bash
# Ver annotations
kubectl get pod nginx -o yaml -n prueba | grep -A5 annotations
```

### Resource Requests y Limits
Los manifiestos deberían incluir:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

---

## 🛠️ Comandos Útiles

### Información general
```bash
# Ver todos los recursos en el namespace
kubectl get all -n prueba

# Describir cualquier recurso
kubectl describe <tipo>/<nombre> -n prueba

# Ver logs
kubectl logs <pod> -n prueba -f

# Ejecutar comandos
kubectl exec -it <pod> -n prueba -- /bin/bash
```

### Limpieza
```bash
# Eliminar recursos específicos
kubectl delete -f <archivo>.yml

# Eliminar todo el namespace (cuidado!)
kubectl delete ns prueba

# Eliminar por selector
kubectl delete pod -l app=nginx -n prueba
```

### Debugging
```bash
# Ver eventos del namespace
kubectl get events -n prueba --sort-by=.metadata.creationTimestamp

# Ver configuración de un recurso
kubectl get <recurso> <nombre> -o yaml -n prueba

# Probar conectividad desde un pod temporal
kubectl run test --image=busybox -it --rm -n prueba -- /bin/sh
```


kubectl describe service <service-name> -n prueba
kubectl describe ingress <ingress-name> -n prueba
```

### Ver logs
```bash
# Logs básicos
kubectl logs <pod-name> -n prueba

# Logs en tiempo real
kubectl logs <pod-name> -n prueba -f

# Logs de los últimos 100 líneas
kubectl logs <pod-name> -n prueba --tail=100

# Logs de un container específico (si hay múltiples)
kubectl logs <pod-name> -c <container-name> -n prueba
```

### Ver eventos del namespace---

## 🔑 Conceptos Clave

### Labels y Selectors
```bash
# Ver labels de los recursos
kubectl get pod --show-labels -n prueba

# Filtrar por labels
kubectl get pod -l app=nginx -n prueba

# Agregar labels
kubectl label pod nginx version=v1 -n prueba
```

### Annotations
```bash
# Ver annotations
kubectl get pod nginx -o yaml -n prueba | grep -A5 annotations
```

### Resource Requests y Limits
Los manifiestos deberían incluir:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

---

## 🛠️ Comandos Útiles

### Información general
```bash
# Ver todos los recursos en el namespace
kubectl get all -n prueba

# Describir cualquier recurso
kubectl describe <tipo>/<nombre> -n prueba

# Ver logs
kubectl logs <pod> -n prueba -f

# Ejecutar comandos
kubectl exec -it <pod> -n prueba -- /bin/bash
```

### Limpieza
```bash
# Eliminar recursos específicos
kubectl delete -f <archivo>.yml

# Eliminar todo el namespace (cuidado!)
kubectl delete ns prueba

# Eliminar por selector
kubectl delete pod -l app=nginx -n prueba
```

### Debugging
```bash
# Ver eventos del namespace
kubectl get events -n prueba --sort-by=.metadata.creationTimestamp

# Ver configuración de un recurso
kubectl get <recurso> <nombre> -o yaml -n prueba

# Probar conectividad desde un pod temporal
kubectl run test --image=busybox -it --rm -n prueba -- /bin/sh
```


```bash
kubectl get events -n prueba
kubectl get events -n prueba --sort-by=.metadata.creationTimestamp
```

## 🏷️ Trabajar con Labels y Selectors

### Ver labels de recursos
```bash
kubectl get pods --show-labels -n prueba
kubectl get nodes --show-labels
```

### Filtrar por labels
```bash
kubectl get pods -l app=nginx -n prueba
kubectl get pods -l tier=frontend -n prueba
kubectl get all -l app=nginx -n prueba
```

### Agregar/modificar labels
```bash
kubectl label pod <pod-name> version=v2 -n prueba
kubectl label node <node-name> environment=production
```

### Eliminar labels
```bash
kubectl label pod <pod-name> version- -n prueba
kubectl label node <node-name> environment-
```

## 🔧 Comandos de Edición y Actualización

### Editar recursos en vivo
```bash
kubectl edit deployment nginx -n prueba
kubectl edit service nginx-html-ci -n prueba
kubectl edit ingress nginx-ingress -n prueba
```

### Escalar deployments
```bash
kubectl scale deployment nginx --replicas=3 -n prueba
kubectl scale statefulset postgresql-db --replicas=3 -n prueba
```

### Actualizar imagen
```bash
kubectl set image deployment/nginx nginx=nginx:1.25 -n prueba
```

### Ver historial de rollouts
```bash
kubectl rollout history deployment/nginx -n prueba
kubectl rollout status deployment/nginx -n prueba
```

### Hacer rollback
```bash
kubectl rollout undo deployment/nginx -n prueba
kubectl rollout undo deployment/nginx --to-revision=2 -n prueba
```

## 🐛 Debugging y Troubleshooting

### Ejecutar comandos dentro de un pod
```bash
# Acceso interactivo
kubectl exec -it <pod-name> -n prueba -- /bin/bash
kubectl exec -it <pod-name> -n prueba -- /bin/sh

# Ejecutar comando específico
kubectl exec <pod-name> -n prueba -- ls -la /var/www/html
kubectl exec <pod-name> -n prueba -- cat /etc/nginx/nginx.conf
```

### Port forwarding para pruebas
```bash
# Forward puerto de pod
kubectl port-forward pod/<pod-name> 8080:80 -n prueba

# Forward puerto de servicio
kubectl port-forward service/<service-name> 8080:80 -n prueba

# Forward puerto de deployment
kubectl port-forward deployment/<deployment-name> 8080:80 -n prueba
```

### Pod temporal para debugging
```bash
# Pod temporal con herramientas de red
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -n prueba -- /bin/bash

# Pod temporal básico
kubectl run test --image=busybox -it --rm -n prueba -- /bin/sh

# Pod temporal con curl
kubectl run curl-test --image=curlimages/curl -it --rm -n prueba -- /bin/sh
```

### Copiar archivos desde/hacia pods
```bash
# Copiar desde pod local
kubectl cp <pod-name>:/path/to/file ./local-file -n prueba

# Copiar hacia pod
kubectl cp ./local-file <pod-name>:/path/to/file -n prueba
```

## 📊 Monitoreo y Métricas

### Ver uso de recursos
```bash
kubectl top nodes
kubectl top pods -n prueba
kubectl top pods -n prueba --containers
```

### Ver información de recursos asignados
```bash
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

## 🗑️ Limpieza y Eliminación

### Eliminar por archivo
```bash
kubectl delete -f <archivo>.yml
kubectl delete -f <directorio>/
```

### Eliminar por selector
```bash
kubectl delete pods -l app=nginx -n prueba
kubectl delete all -l tier=frontend -n prueba
```

### Eliminar recursos específicos
```bash
kubectl delete pod <pod-name> -n prueba
kubectl delete deployment <deployment-name> -n prueba
kubectl delete service <service-name> -n prueba
```

### Eliminar namespace completo (¡CUIDADO!)
```bash
kubectl delete namespace prueba
```

### Forzar eliminación (usar con precaución)
```bash
kubectl delete pod <pod-name> -n prueba --force --grace-period=0
```

## 🔄 Comandos de Apply y Patch

### Apply con diferentes opciones
```bash
# Apply normal
kubectl apply -f archivo.yml

# Apply con dry-run para validar
kubectl apply -f archivo.yml --dry-run=client

# Apply y registrar el comando
kubectl apply -f archivo.yml --record

# Apply de todo un directorio
kubectl apply -f ./manifiestos/
```

### Patch recursos
```bash
# Patch estratégico (merge)
kubectl patch deployment nginx -p '{"spec":{"replicas":3}}' -n prueba

# Patch JSON
kubectl patch service nginx-html-ci --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]' -n prueba
```

## 🔐 Contextos y Namespaces

### Trabajar con contextos
```bash
# Ver contexto actual
kubectl config current-context

# Cambiar namespace por defecto del contexto
kubectl config set-context --current --namespace=prueba

# Ver configuración completa
kubectl config view
```

### Usar alias para kubectl
```bash
# Agregar a ~/.bashrc o ~/.zshrc
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
```

## 📈 Comandos Avanzados

### Watch (seguir cambios)
```bash
kubectl get pods -n prueba -w
kubectl get events -n prueba -w
```

### Output personalizado
```bash
# Mostrar solo nombres
kubectl get pods -n prueba -o name

# Mostrar columnas específicas
kubectl get pods -n prueba -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# JSONPath
kubectl get pods -n prueba -o jsonpath='{.items[*].metadata.name}'
```

### Filtrar por campo
```bash
kubectl get pods --field-selector status.phase=Running -n prueba
kubectl get events --field-selector involvedObject.name=nginx -n prueba
```
