# CLASE 3 - Recursos Básicos

## 📑 Índice

1. [Introducción](#introducción)
2. [Namespaces](#namespaces)
3. [Pods](#pods)
4. [Servicios](#servicios)
5. [Ingress](#ingress)
6. [ReplicaSet](#replicaset)
7. [Deployment](#deployment)
8. [StatefulSet](#statefulset)
9. [DaemonSet](#daemonset)
10. [Conceptos Clave](#conceptos-clave)
11. [Comandos Útiles](#comandos-útiles)

---

## 📖 Introducción

Esta clase cubre los objetos fundamentales de Kubernetes necesarios para desplegar aplicaciones:
- **Namespaces**: Aislamiento lógico de recursos
- **Pods**: Unidad mínima de despliegue
- **Services**: Exposición de aplicaciones
- **Ingress**: Acceso HTTP/HTTPS desde el exterior
- **Controllers**: ReplicaSet, Deployment, StatefulSet, DaemonSet

---

## 🏷️ Namespaces (Diapo 13)

Los namespaces proporcionan aislamiento lógico de recursos en el cluster.

### Mostrar namespaces existentes
```bash
k get namespace
# o usando el alias
k get ns
```

### Crear namespace imperativo
```bash
k create namespace prueba
```

### Borrar namespace
```bash
# Borra el namespace y TODOS sus recursos
k delete ns prueba
```

### Crear namespace con manifiesto
```bash
k apply -f 01-namespace.yml
```

### Verificar namespace creado
```bash
k get ns prueba
k describe ns prueba
```

### Borrar namespace con manifiesto
```bash
# Borra el namespace y TODOS sus recursos
k delete -f 01-namespace.yml
```

### Recrear namespace para la práctica
```bash
k apply -f 01-namespace.yml
```

---

## 🐋 Pods (Diapo 16)

Los Pods son la unidad más pequeña de despliegue en Kubernetes.

### Crear Pod con manifiesto
```bash
k apply -f 02-pod.yml -n prueba
```

### Ver Pods creados
```bash
k get pod -n prueba
k get pod -n prueba -o wide  # más información
```

### Describir Pod (información detallada)
```bash
k describe pod nginx -n prueba
```

### Ver logs del Pod
```bash
k logs nginx -n prueba
k logs nginx -n prueba --tail 100 -f  # seguir logs
```

### Ejecutar comandos en el Pod
```bash
k exec -it nginx -n prueba -- /bin/sh
```

### Configurar namespace por defecto 
```bash
# Usar plugin krew ns (si está instalado)
k ns prueba
```

### Borrar pod
```bash
k delete pod nginx
# O usando manifiesto k delete -f 02-pod.yml
```

### Volver a crear Pod con manifiesto
```bash
k apply -f 02-pod.yml
```

### Probar conectividad directa al Pod
```bash
# Obtener IP del Pod
k get pod -o wide

# Probar desde otro pod o nodo del cluster
curl http://<ip-pod-nginx>
```

---

## 🔗 Servicios (Diapo 27)

Los Services exponen Pods y proporcionan descubrimiento de servicios.

### Aplicar servicios
```bash
k apply -f 03-services.yml
```

### Ver servicios creados
```bash
k get svc -n prueba
k get svc -n prueba -o wide
```

### Ver endpoints (conexiones Pod-Service)
```bash
k get endpoints -n prueba
k describe endpoints nginx-html-ci -n prueba
```

### Probar los diferentes tipos de servicios

#### ClusterIP (acceso interno)
```bash
k get svc nginx-html-ci -n prueba
# Probar desde dentro del cluster
curl http://<cluster-ip>
```

#### NodePort (acceso por puerto del nodo)
```bash
k get svc nginx-html-np -n prueba
# Probar desde cualquier nodo
curl http://localhost:30285
curl http://<ip-nodo>:30285
```

#### LoadBalancer (acceso externo)
```bash
k get svc nginx-html-lb -n prueba
# Probar con la IP externa asignada
curl http://<external-ip>
```
> Luego abrir http://<external-ip> en el navegador

### Port-forward para testing local
```bash
# Ejecutar en terminal local (fuera del cluster)
k port-forward service/nginx-html-ci 8080:80 -n prueba
```
> Luego abrir http://localhost:8080 en el navegador

### Verificar alta disponibilidad
```bash
# Borrar el Pod
k delete pod nginx -n prueba

# Ver que el Service sigue existiendo
k get svc -n prueba

# Ver que los endpoints están vacíos
k get endpoints -n prueba

# Recrear el Pod
k apply -f 02-pod.yml -n prueba

# Verificar que los endpoints se reconectan automáticamente
k get endpoints -n prueba
```

---

## 🌐 Ingress (Diapo 33)

Ingress proporciona acceso HTTP/HTTPS desde internet con certificados SSL.

### Preparar el manifiesto
> ⚠️ **Importante**: Modifica `04-ingress.yml` con tu dominio antes de aplicar

### Aplicar Ingress
```bash
k apply -f 04-ingress.yml
```

### Verificar estado
```bash
k get ingress -n prueba
k describe ingress nginx-ingress -n prueba
```

### Verificar certificado SSL
```bash
k get certificate -n prueba
k describe certificate prueba.k8s.riu.edu.ar -n prueba
```

### Acceder desde navegador

https://prueba.k8s.riu.edu.ar


### Borrar pod
```bash
k delete pod nginx
```

### Acceder nuevamente desde navegador

https://prueba.k8s.riu.edu.ar

### Troubleshooting
Si hay errores con cert-manager:
```bash
# Ver logs de cert-manager
k logs -n cert-manager deployment/cert-manager

# Reiniciar cert-manager si es necesario
k rollout restart deployment/cert-manager -n cert-manager
```

---

## 📋 ReplicaSet (Diapo 38)

ReplicaSet asegura que un número específico de Pods esté ejecutándose.

### Aplicar ReplicaSet
```bash
k apply -f 05-replicaset.yml
```

### Verificar Pods creados
```bash
k get pod -n prueba
k get rs -n prueba
```

### Demostrar auto-recuperación
```bash
# Eliminar un Pod
k delete pod nginx-<hash> -n prueba

# Ver cómo se recrea automáticamente
k get pod -n prueba -w
```

### Escalar ReplicaSet
```bash
# Editar manualmente
k edit rs nginx -n prueba
# Cambiar replicas: 3

# O usar comando scale
k scale rs nginx --replicas=3 -n prueba

# Verificar escalado
k get pod -n prueba
```

---

## 🚀 Deployment (Diapo 41)

Deployment es la forma recomendada de desplegar aplicaciones (maneja ReplicaSets automáticamente).

### Limpiar ReplicaSet anterior
```bash
k delete rs nginx -n prueba
k get pod -n prueba  # Verificar que se eliminaron
```

### Aplicar Deployment
```bash
k apply -f 06-deploy.yml
```

### Verificar recursos creados
```bash
k get deployment -n prueba
k get rs -n prueba
k get pod -n prueba
```

### Actualizar aplicación (Rolling Update)
```bash
# Cambiar imagen a versión más nueva
k edit deploy nginx -n prueba
# Cambiar image: nginx:1.26-alpine

# Ver el progreso del rollout
k rollout status deployment/nginx -n prueba

# Ver historial de despliegues
k rollout history deployment/nginx -n prueba
```

### Verificar la actualización
```bash
k describe pod nginx-<nuevo-hash> -n prueba
# Verificar que la imagen cambió
```

### Rollback si es necesario
```bash
k rollout undo deployment/nginx -n prueba
# k rollout history deployment/nginx --revision=2
# k rollout undo deployment/nginx -n prueba --to-revision=2
```

### Verificar rollback
```bash
k describe pod nginx-<nuevo-hash> -n prueba
# Verificar que la imagen volvió
```

> Probar lo mismo configurando la imagen no exitente nginx:1.99 

---

## 🗄️ StatefulSet (Diapo 43)

StatefulSet maneja aplicaciones con estado que necesitan identidad de red estable y almacenamiento persistente.

### Aplicar StatefulSet
```bash
k apply -f 07-statefulset.yml
```

### Verificar recursos
```bash
k get statefulset -n prueba
k get pod -n prueba
k get svc -n prueba
```

### Observar características especiales
```bash
# Pods tienen nombres ordenados: postgresql-db-0, postgresql-db-1
k get pod -n prueba -l app=postgresql-db

# Ver orden de creación/eliminación
k get pod -n prueba -w
```

### Probar eliminación y recreación ordenada
```bash
k delete pod postgresql-db-0 postgresql-db-1 -n prueba
k get pod -n prueba -w
# Observar que se recrean en orden: 0, luego 1
```

### Escalar StatefulSet
```bash
k scale statefulset postgresql-db --replicas=3 -n prueba
k get pod -n prueba -w
```

---

## 👹 DaemonSet (Diapo 45)

DaemonSet asegura que un Pod ejecute en todos (o algunos) nodos del cluster.

### Ver labels de los nodos
```bash
k get nodes --show-labels
```

### Aplicar DaemonSet
```bash
k apply -f 08-daemonset.yml
```

### Verificar estado inicial
```bash
k get daemonset -n prueba
k get pod -n prueba -o wide
# No debería haber pods porque ningún nodo tiene el label requerido
```

### Agregar label a nodos
```bash
# Reemplaza con nombres reales de tus nodos
k label nodes <nodo1> monitoreo=habilitado
k label nodes <nodo2> monitoreo=habilitado
```

### Verificar que se crean los Pods
```bash
k get daemonset -n prueba
k get pod -n prueba -o wide
# Debería haber un pod de node-exporter en cada nodo etiquetado
```

### Eliminar label de un nodo
```bash
k label nodes <nodo1> monitoreo-
```

### Verificar que se elimina el Pod
```bash
k get daemonset -n prueba
k get pod -n prueba -o wide
```
