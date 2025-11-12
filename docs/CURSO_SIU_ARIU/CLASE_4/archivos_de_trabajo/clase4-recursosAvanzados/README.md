# CLASE 4 - ConfigMaps, Secrets, Jobs y Control de Recursos

## 📑 Índice

1. [Introducción](#introducción)
2. [Preparación del Entorno](#preparación-del-entorno)
3. [Secrets](#secrets)
4. [ConfigMaps](#configmaps)
5. [Jobs y CronJobs](#jobs-y-cronjobs)
6. [Resource Requests y Limits](#resource-requests-y-limits)
7. [LimitRange](#limitrange)
8. [ResourceQuota](#resourcequota)
9. [Control de Acceso y Usuarios](#control-de-acceso-y-usuarios)
10. [Conceptos Clave](#conceptos-clave)
11. [Comandos Útiles](#comandos-útiles)

---

## 📖 Introducción

Esta clase cubre los recursos avanzados de Kubernetes para la gestión de configuración, secretos, trabajos automatizados y control de recursos:

- **Secrets**: Almacenamiento seguro de información sensible
- **ConfigMaps**: Gestión de configuración de aplicaciones
- **Jobs/CronJobs**: Ejecución de tareas de una vez o programadas
- **Resource Management**: Control de CPU y memoria
- **RBAC**: Control de acceso basado en roles

---

## 🧹 Preparación del Entorno

### Limpiar recursos de clases anteriores

```bash
# Cambiar al namespace de trabajo
k ns prueba
# kubectl config set-context --current --namespace=prueba

# Eliminar recursos previos
kubectl delete deployment nginx --ignore-not-found=true
kubectl delete statefulset postgresql-db --ignore-not-found=true
kubectl delete daemonset node-exporter --ignore-not-found=true
kubectl delete service --all

# Verificar limpieza
kubectl get all
```

---

## 🔐 Secrets

Los Secrets almacenan información sensible como contraseñas, tokens OAuth, claves SSH, etc.

### Crear Secret desde archivo y literal

Primero, verificar el contenido del archivo:
```bash
cat postgres.env
```

Crear el secret combinando archivo y literal:
```bash
kubectl create secret generic postgres.env \
  --from-file=postgres.env \
  --from-literal=POSTGRES_PASSWORD=postgres \
  -n prueba
```

### Inspeccionar el Secret creado

```bash
kubectl describe secret postgres.env -n prueba
kubectl get secret postgres.env -o yaml -n prueba
```

### Crear Secret desde manifiesto

#### Codificar valores en base64
```bash
echo -n 'admin' | base64
echo -n 'password' | base64
```

#### Aplicar el manifiesto
```bash
kubectl apply -f 01-secret-postgres.yml
```

#### Verificar y decodificar valores
```bash
kubectl get secret postgres2.env -o yaml -n prueba

# Decodificar password
kubectl get secret postgres2.env -o jsonpath="{.data.password}" -n prueba | base64 -d
echo ""  # nueva línea

# Decodificar username
kubectl get secret postgres2.env -o jsonpath="{.data.username}" -n prueba | base64 -d
echo ""  # nueva línea
```

### Usar Secrets en un Deployment

```bash
kubectl apply -f 02-postgresql-deploy.yml
```

### Verificar que las variables de entorno se cargaron

```bash
# Esperar a que el pod esté ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s -n prueba

# Obtener nombre del pod
kubectl get pods -l app=postgres -n prueba

# Verificar variables de entorno
k exec -it postgres-<ID> -- env | grep PGTZ
k exec -it postgres-<ID> -- env | grep admin
# Otra forma directa en el deploy: kubectl exec -it deployment/postgres -n prueba -- env | grep -E "(POSTGRES|PGTZ|admin)"
```

### Buenas prácticas con Secrets

- ✅ Usar `stringData` en lugar de `data` para valores no codificados
- ✅ Montar secrets como volúmenes en lugar de variables de entorno cuando sea posible
- ✅ Rotar secrets regularmente
- ⚠️ Los secrets no están encriptados por defecto en etcd

---

## 📋 ConfigMaps

Los ConfigMaps separan la configuración de las imágenes de contenedores.

### Crear ConfigMap desde archivo

```bash
# Ver contenido de nginx.conf
cat nginx.conf

# Crear ConfigMap
kubectl create configmap nginx-conf --from-file=nginx.conf -n prueba
```

### Crear ConfigMap desde manifiesto

```bash
kubectl apply -f 03-nginx-configmap.yml
```

```bash
kubectl describe cm nginx-html -n prueba
kubectl get cm nginx-html -o yaml -n prueba
```

### Usar ConfigMap en Deployment

```bash
kubectl apply -f 04-nginx-deploy.yml
```

### Verificar montaje de archivos

```bash
# Esperar a que el pod esté listo
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s -n prueba

# Verificar archivos montados
kubectl exec -it deployment/nginx -n prueba -- ls -la /var/www/
kubectl exec -it deployment/nginx -n prueba -- ls -la /etc/nginx/conf.d/

# Ver contenido de los archivos
kubectl exec -it deployment/nginx -n prueba -- cat /var/www/index.html
kubectl exec -it deployment/nginx -n prueba -- cat /var/www/index2.html
kubectl exec -it deployment/nginx -n prueba -- cat /etc/nginx/conf.d/nginx.conf
```

### Probar la aplicación

```bash
# Obtener IP del pod
kubectl get pod -l app=nginx -o wide -n prueba

# Crear servicio para probar
kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-svc -n prueba

# Port forward para probar localmente
kubectl port-forward service/nginx-svc 8080:80 -n prueba &

# Probar en otra terminal
curl http://localhost:8080/index.html
curl http://localhost:8080/index2.html

# Detener port-forward
pkill -f "kubectl port-forward"
```

### Actualizar ConfigMap

```bash
# Editar el ConfigMap
kubectl edit cm nginx-html -n prueba
# Cambiar el contenido de index2

# O aplicar cambios desde archivo
kubectl apply -f 03-nginx-configmap.yml

# Reiniciar deployment para tomar cambios
kubectl rollout restart deployment/nginx -n prueba

# Verificar cambios
kubectl port-forward service/nginx-svc 8080:80 -n prueba &
curl http://localhost:8080/index2.html
pkill -f "kubectl port-forward"
```

---

## ⚙️ Jobs y CronJobs

### Jobs - Ejecución de tareas de una vez

```bash
kubectl apply -f 05-job-date.yml
```

#### Monitorear la ejecución

```bash
# Ver el Job
kubectl get jobs -n prueba

# Ver los Pods del Job
kubectl get pods -l job-name=date-job -n prueba

# Ver logs del Job
kubectl logs job/date-job -n prueba

# Ver estado del Job
kubectl describe job date-job -n prueba
```

#### Limpiar el Job

```bash
kubectl delete job date-job -n prueba
```

### CronJobs - Ejecución programada

```bash
kubectl apply -f 06-cronjob.yml
```

#### Monitorear CronJob

```bash
# Ver CronJob
kubectl get cronjob -n prueba

# Ver historial de Jobs
kubectl get jobs -n prueba

# Ver Pods creados
kubectl get pods -l job-name -n prueba

# Ver logs de un Job específico
kubectl logs job/<job-name> -n prueba

# Ver los próximos schedules
kubectl describe cronjob maintenance-cronjob -n prueba
```

#### Ejecutar CronJob manualmente

```bash
kubectl create job --from=cronjob/maintenance-cronjob manual-job -n prueba
```

#### Suspender/reanudar CronJob

```bash
# Suspender
kubectl patch cronjob maintenance-cronjob -p '{"spec":{"suspend":true}}' -n prueba
k get cronjob

# Reanudar
kubectl patch cronjob maintenance-cronjob -p '{"spec":{"suspend":false}}' -n prueba
k get cronjob
```

---

## 💪 Resource Requests y Limits

### Limpiar recursos anteriores

```bash
kubectl delete deployment postgres nginx --ignore-not-found=true -n prueba
kubectl delete cronjob maintenance-cronjob --ignore-not-found=true -n prueba
kubectl delete service nginx-svc --ignore-not-found=true -n prueba
```

### Aplicar Deployment con Resources

```bash
kubectl apply -f 07-requests.yml
```

### Verificar recursos asignados

```bash
kubectl get pods -n prueba
kubectl describe pod -l app=nginx -n prueba | grep -A 10 "Limits\|Requests"
```

### Demostrar QoS Classes

```bash
# Ver QoS Class del pod
kubectl get pod -l app=nginx -o yaml -n prueba | grep qosClass
```

### Probar límites de CPU

#### Configurar recursos altos (fallará)

```bash
# Editar para usar CPU alta
kubectl patch deployment nginx -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"5"},"limits":{"cpu":"5"}}}]}}}}' -n prueba

# Ver el estado
kubectl get pods -n prueba
kubectl describe pod -l app=nginx -n prueba | grep -A 10 "Events"
```

#### Configurar recursos normales

```bash
# Revertir a valores normales
kubectl patch deployment nginx -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"250m","memory":"64Mi"},"limits":{"cpu":"500m","memory":"128Mi"}}}]}}}}' -n prueba

kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s -n prueba
```

### Stress test de CPU

```bash
# Obtener nombre del pod
POD_NAME=$(kubectl get pod -l app=nginx -o jsonpath="{.items[0].metadata.name}" -n prueba)

# Ejecutar stress test en background
kubectl exec -it $POD_NAME -n prueba -- /bin/sh -c "yes > /dev/null"

```

Entrar a nodo donde está ejecuntandose el pod y ejecutar top 
```bash
top
```

> Repetir pero configurando 1000m en limits. 

---

## 📏 LimitRange

LimitRange establece límites por defecto y máximos/mínimos para recursos en un namespace.

### Limpiar y aplicar LimitRange

```bash
kubectl delete deployment nginx --ignore-not-found=true -n prueba
kubectl apply -f 08-limitrange.yml
```

### Verificar LimitRange

```bash
kubectl get limitrange -n prueba
kubectl describe limitrange cpu-resource-constraint -n prueba
kubectl describe limitrange memory-resource-constraint -n prueba
```

### Probar Deployment sin resources

```bash
kubectl apply -f 09-nginx-lr.yml
```

```bash
# Ver que se aplicaron los defaults del LimitRange
kubectl describe pod -l app=nginx-limitrange-test -n prueba | grep -A 10 "Limits\|Requests"
```

### Probar con recursos fuera del límite

```bash
# Editar para exceder límites
kubectl patch deployment nginx -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"cpu":"2"}}}]}}}}' -n prueba

# Ver el error
kubectl describe replicaset -l app=nginx-limitrange-test -n prueba | grep -A 5 "Events"
```

---

## 🎯 ResourceQuota

ResourceQuota limita el consumo total de recursos en un namespace.

### Limpiar y aplicar ResourceQuotas

```bash
kubectl delete deployment nginx --ignore-not-found=true -n prueba
kubectl apply -f 10-resourcequota.yml
kubectl apply -f 11-resourcequota-objets.yml
```

### Verificar ResourceQuotas

```bash
kubectl get resourcequota -n prueba
kubectl describe resourcequota -n prueba
```

### Probar Deployment sin memoria (fallará)

```bash
kubectl apply -f 12-nginx-rq.yml
```

```bash
# Ver el error
kubectl get pods -n prueba
kubectl describe replicaset -l app=nginx-resourcequota-test -n prueba
```

### Agregar recursos de memoria

```bash
# Patch para agregar memoria
kubectl patch deployment nginx -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"250m"}}}]}}}}' -n prueba

kubectl get pods -n prueba
```

### Verificar uso de quota

```bash
kubectl describe resourcequota -n prueba
```

### Probar límite de pods

```bash
kubectl scale deployment nginx --replicas=1 -n prueba

# Bajar el limite de pods a 2
kubectl patch resourcequota object-counts-quota -n prueba \
  --type merge -p '{"spec":{"hard":{"pods":"2"}}}'

kubectl scale deployment nginx --replicas=3 -n prueba

# Ver estado
kubectl describe resourcequota -n prueba
kubectl get pods -n prueba
kubectl describe replicaset -l app=nginx-resourcequota-test -n prueba
```

### Eliminar restricción de objetos

```bash
kubectl delete resourcequota object-counts-quota -n prueba

# Verificar que se crean más pods (esperar ttl)
kubectl get pods -n prueba
```

---

## 👤 Control de Acceso y Usuarios

### Revisar script de configuración

```bash
cd certificados-usuarios
ls -la
cat user-config.sh
```

### Crear certificados para usuario

```bash
# Crear usuario con acceso a namespace específico
./user-config.sh user1 ns-user1 cluster-curso
```

### Verificar certificados creados

```bash
ls -la user1*
ls -la cluster-curso*
```

### Configurar acceso para el nuevo usuario

```bash
# Configurar cluster
kubectl config set-cluster cluster-curso \
  --server=https://ed-k8s.siu.edu.ar:6443 \
  --certificate-authority=cluster-curso.crt \
  --embed-certs=true

# Configurar usuario
kubectl config set-credentials user1 \
  --client-key=user1.key \
  --client-certificate=user1.crt \
  --embed-certs=true

# Configurar contexto
kubectl config set-context user1@cluster-curso \
  --cluster=cluster-curso \
  --user=user1 \
  --namespace=ns-user1

# Cambiar a contexto del usuario
kubectl config use-context user1@cluster-curso
```

### Probar acceso del usuario

```bash
# Ver contexto actual
kubectl config get-contexts

# Probar comando (debería fallar por falta de permisos)
kubectl get pods

# Probar acceso a namespace específico (también fallará sin RBAC)
kubectl get pods -n ns-user1
```

### Crear RBAC para el usuario

```bash
# Volver al contexto admin
kubectl config use-context <admin-context>

# Crear namespace para el usuario
kubectl create namespace ns-user1

# Crear Role
kubectl create role user1-role \
  --verb=get,list,create,delete,patch,update \
  --resource=pods,deployments,services,configmaps,secrets \
  -n ns-user1

# Crear RoleBinding
kubectl create rolebinding user1-binding \
  --role=user1-role \
  --user=user1 \
  -n ns-user1
```

### Probar permisos del usuario

```bash
# Cambiar a usuario
kubectl config use-context user1@cluster-curso

# Ahora debería funcionar
kubectl get pods -n ns-user1
kubectl run test-pod --image=nginx -n ns-user1

# Verificar que no puede acceder a otros namespaces
kubectl get pods -n default  # Debería fallar
```

### Limpiar configuración de usuario

```bash
# Volver a contexto admin
kubectl config use-context <admin-context>

# Eliminar configuración de usuario
kubectl config delete-cluster cluster-curso
kubectl config delete-user user1
kubectl config delete-context user1@cluster-curso

# Limpiar archivos
rm -f user1* cluster-curso*
cd ..
```

