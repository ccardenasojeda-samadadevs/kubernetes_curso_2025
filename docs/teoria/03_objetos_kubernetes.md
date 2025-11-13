# 📘 Clase 3 – Objetos de Kubernetes
## 📑 Índice

1. [Introducción](#1-introducción)
2. [Desired State & Reconciliation](#2-desired-state--convergencia)
3. [Estructura general de un archivo YAML](#3-estructura-general-de-un-archivo-yaml)
4. [Namespaces](#4-namespaces)
5. [Pods](#5-pods)
6. [ReplicaSet](#6-replicaset)
7. [Deployment](#7-deployment)
8. [DaemonSet](#8-daemonset)
9. [StatefulSet](#9-statefulset)
10. [ConfigMaps](#10-configmaps)
11. [Secrets](#11-secrets)
12. [Volúmenes y Persistencia](#12-volúmenes-y-persistencia)
13. [Services](#13-services)
14. [Endpoints](#14-endpoints--endpointslice)
15. [Ingress](#15-ingress)
16. [MetalLB](#16-metallb)
17. [Ejercicios aplicados en clase](#17-ejercicios-realizados-en-clase)
18. [Referencias](#18-referencias-oficiales)
> Documentación integradora basada en la clase SIU ARIU + documentación oficial Kubernetes.

---

# 1. Introducción

Kubernetes es un orquestador de contenedores basado en un modelo declarativo.
El usuario define el estado deseado mediante archivos YAML, y Kubernetes ajusta continuamente
el estado actual hasta que ambos coinciden.

### Los objetos de Kubernetes representan recursos que el sistema administra.
```txt
Kubernetes Objects:
  ├── Workloads
  │     ├── Deployment
  │     ├── StatefulSet
  │     └── DaemonSet
  ├── Networking
  │     ├── Service
  │     ├── Ingress
  │     └── NetworkPolicy
  └── Storage
        ├── PV
        ├── PVC
        └── StorageClass

```
### ✔️ Componentes principales de un objeto:

| Componente     | Descripción                                                 |
| -------------- | ----------------------------------------------------------- |
| **apiVersion** | Define qué versión de la API se usa para crear el objeto.   |
| **kind**       | Indica el tipo de recurso (Pod, Deployment, Service, etc.). |
| **metadata**   | Contiene nombre, etiquetas y anotaciones del recurso.       |
| **spec**       | Define el estado deseado (lo que el usuario quiere).        |
| **status**     | Estado actual, generado por Kubernetes                      |

El cluster calcula y actualiza automáticamente el status, que representa:

- el estado actual del recurso,

- su disponibilidad,

- eventos asociados,

- información operacional real.

> [!NOTE]
> ¿Por qué es importante esta clase?📌
>Esta unidad es clave porque:
>- Introduce los objetos básicos y avanzados de Kubernetes.
>- Explica cómo escribir y entender archivos YAML, que es el idioma nativo de K8s.
>- Prepara el terreno para despliegues reales, control de versiones y prácticas de producción.
>- Permite comprender cómo Kubernetes crea, replica, escala y repara aplicaciones automáticamente.
  
> [!NOTE]
> ### 🧠 Concepto central: Declarativo, no imperativo
> En Kubernetes:
> - 👉 No decís "crear 3 contenedores", sino "quiero 3 réplicas".
> - 👉 No decís "abrir este puerto", sino "quiero que se exponga por el puerto X".
> - 👉 No decís "mover este contenedor a otro nodo",sino "quiero que siempre exista este Deployment".

Kubernetes analiza continuamente esta intención y la hace realidad.
  
---

# 2. Desired State & Convergencia 

Kubernetes opera mediante un ciclo continuo que compara:
- Lo que el usuario quiere (Desired State)
- Lo que realmente sucede (Actual State)

Si existe diferencia, los controladores aplican acciones correctivas.

###  ✔️ Diagrama conceptual del ciclo de Convergencia del estado:

```txt

  +---------------------------------------+
  |     USUARIO APLICA YAML (Desired)     |
  +---------------------------------------+
                      |
                      v
  +---------------------------------------+
  |         API SERVER (Validación)       |
  +---------------------------------------+
                      |
                      v
  +---------------------------------------+
  |        etcd (Almacena Desired)        |
  +---------------------------------------+
                      |
                      v
  +------------------------------------------------+
  | CONTROLLERS (Comparan Desired vs Actual State) |
  +------------------------------------------------+
                      |
                      v
  +----------------------------------------------+
  |   Si difiere -> Acciones correctivas         |
  +----------------------------------------------+
                      |
                      v
  +---------------------------------------+
  |         ESTADO REAL (Actual)          |
  +---------------------------------------+
```
Este ciclo se ejecuta ininterrumpidamente mientras el cluster esté funcionando.

---

# 3. Estructura general de un archivo YAML

Todos los objetos siguen una estructura común:

```yaml
apiVersion: version
kind: tipo-de-objeto
metadata:
  name: nombre  # ← Hasta este campo son obligatorios para crear el objeto básico.
  namespace: namespace
spec:
  definicion-del-objeto
```
Los campos obligatorios en todos los recursos son:
- apiVersion
- kind
- metadata.name

El contenido de "spec" depende del tipo de objeto.

---

# 4. Namespaces

Los namespaces permiten organizar y separar recursos dentro del cluster.

### Usos principales:
- Separar ambientes (dev, test, prod)
- Evitar colisiones de nombres
- Delimitar permisos (RBAC)
- Aislar proyectos y equipos
- Una forma de agrupar Pods y servicios en una misma aplicación
- Un mecanismo para limitar el acceso a los recursos del clúster

### Namespaces incluidos por defecto:
- default
- kube-system
- kube-public
- kube-node-lease

### Diagrama conceptual de namespaces:
```txt
  +-----------------------------------------+
  |           Kubernetes Cluster            |
  +-----------------------------------------+
  |  Namespace: default                     |
  |    - pods                               |
  |    - services                           |
  +-----------------------------------------+
  |  Namespace: kube-system                 |
  |    - dns                                |
  |    - calico                             |
  |    - control plane components           |
  +-----------------------------------------+
  |  Namespace: prueba                      |
  |    - recursos aislados                  |
  +-----------------------------------------+
```
Ejemplos útiles:
```bash
kubectl get ns
kubectl create ns prueba
kubectl delete ns prueba
```
---

# 5. Pods

El Pod es la unidad mínima de ejecución en Kubernetes. Puede contener uno o varios
contenedores que comparten red, almacenamiento y namespaces de proceso.

Ejemplo básico de pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-ejemplo
spec:
  containers:
  - name: cont
    image: nginx
```
Diagrama detallado del Pod:
```txt
  +------------------------------------------------+
  |                     POD                        |
  |                                                |
  |   +--------------------+   +-----------------+ |
  |   |    CONTAINER 1     |   |   CONTAINER 2   | |
  |   | - nginx            |   | - sidecar       | |
  |   | - puertos          |   | - logs          | |
  |   +--------------------+   +-----------------+ |
  |                                                |
  |  Recursos compartidos:                         |
  |   - red (IP única del Pod)                     |
  |   - volúmenes                                  |
  |   - namespaces                                 |
  +------------------------------------------------+
```
Los Pods son efímeros: Kubernetes puede destruirlos y recrearlos automáticamente.

# 6. ReplicaSet

ReplicaSet garantiza que siempre exista un número específico de Pods idénticos ejecutándose.
Si un Pod muere, ReplicaSet crea otro automáticamente.

Ejemplo básico de ReplicaSet:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-ejemplo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: miapp
  template:
    metadata:
      labels:
        app: miapp
    spec:
      containers:
      - name: cont
        image: nginx
```
Diagrama conceptual:
```txt
  +---------------------------+
  |        ReplicaSet         |
  +---------------------------+
          /        |        \
         v         v         v
  +---------+ +---------+ +---------+
  | Pod #1  | | Pod #2  | | Pod #3  |
  +---------+ +---------+ +---------+
```

El ReplicaSet no se usa directamente la mayoría de las veces:  
los Deployments generan y controlan ReplicaSets internamente.

---

# 7. Deployment

Deployment es el recurso más utilizado en Kubernetes.  
Gestiona:

- Actualizaciones (rolling updates)
- Retrocesos (rollbacks)
- Escalado automático o manual
- Historial de revisiones
- Estrategias de despliegue

Ejemplo básico:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```
Diagrama conceptual de Deployment → ReplicaSet → Pods:
```txt

  +---------------------------+
  |        Deployment         |
  +---------------------------+
               |
               v
  +---------------------------+
  |        ReplicaSet         |
  +---------------------------+
          /        \
         v          v
  +---------+   +---------+
  | Pod #1  |   | Pod #2  |
  +---------+   +---------+

Actualizaciones rolling update:

  +--------------------------+
  |   Deployment v1 (RS1)    |
  +--------------------------+
            |
    Rolling Update
            v
  +--------------------------+
  |   Deployment v2 (RS2)    |
  +--------------------------+
```
Comandos importantes:
```bash
kubectl rollout status deployment nginx-deploy  
kubectl rollout history deployment nginx-deploy  
kubectl rollout undo deployment nginx-deploy  
```
---

# 8. DaemonSet

DaemonSet asegura que un Pod se ejecute en TODOS los nodos del cluster, o en un subconjunto si se usan tolerations o node selectors.

Casos típicos de uso:

- Agentes de logs (Fluentd, Filebeat)
- Agentes de monitoreo (Node Exporter, Prometheus)
- Componentes de red (Calico, Cilium)
- Almacenamiento (CSI daemons)

Diagrama conceptual:
```txt
  +---------------------------+
  |         DaemonSet         |
  +---------------------------+
        |       |       |     
        v       v       v
  +---------+ +---------+ +---------+
  | Node 1  | | Node 2  | | Node 3  |
  | Pod DS  | | Pod DS  | | Pod DS  |
  +---------+ +---------+ +---------+
```
DaemonSet = un Pod por nodo.

---

# 9. StatefulSet

StatefulSet gestiona aplicaciones con estado (stateful) que requieren:

- Identidad persistente  
- Nombres estables  
- Almacenamiento persistente por réplica  
- Orden de creación y apagado  

Ejemplos:  
bases de datos, clusters distribuidos, almacenamiento, mensajes.

Ejemplo básico:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mi-stateful
spec:
  serviceName: miapp
  replicas: 1
  selector:
    matchLabels:
      app: miapp
  template:
    metadata:
      labels:
        app: miapp
    spec:
      containers:
      - name: cont
        image: busybox
        args: ["sleep", "3600"]
        volumeMounts:
        - mountPath: /data
          name: datos
  volumeClaimTemplates:
  - metadata:
      name: datos
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: local-storage
      resources:
        requests:
          storage: 5Gi
```
Diagrama conceptual del StatefulSet:
```txt
  +----------------------------+
  |        StatefulSet         |
  +----------------------------+
              |
      +------------------+
      | Pod miapp-0     |
      | PVC miapp-0     |
      +------------------+
              |
      +------------------+
      | Pod miapp-1     |
      | PVC miapp-1     |
      +------------------+
```
Cada Pod tiene su propio volumen persistente.

---

# 10. ConfigMaps

ConfigMaps almacenan configuración no sensible.

Ejemplo:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cfg
data:
  modo: produccion
  url: https://example.com

Montaje como variables:

env:
- name: MODO
  valueFrom:
    configMapKeyRef:
      name: cfg
      key: modo

Montaje como archivo:

volumes:
- name: cfg
  configMap:
    name: cfg
```
---

# 11. Secrets

Secrets almacenan información sensible:

- Contraseñas
- Tokens
- Certificados
- Claves SSH

Ejemplo simple:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sec
type: Opaque
data:
  pass: cGFzc3dvcmQ=
```
Comandos útiles:
```bash
kubectl create secret generic nombre --from-literal=pass=123  
kubectl describe secret nombre  
kubectl get secret nombre -o yaml  
```
Secrets pueden montarse:

- Como variables de entorno
- Como archivos dentro de un volumen

# 12. Volúmenes y Persistencia

Los Pods son efímeros: si mueren, se recrean sin conservar datos.  
Para datos persistentes, Kubernetes ofrece:

- PersistentVolume (PV): volumen físico disponible en el cluster.  
- PersistentVolumeClaim (PVC): pedido de un volumen por parte de un Pod.  
- StorageClass: define cómo se generan (o no) los volúmenes.

Diagrama conceptual:
```txt
  +------------------------+
  |   PersistentVolume     |
  +------------------------+
              ^
              |
  +------------------------+
  | PersistentVolumeClaim  |
  +------------------------+
              ^
              |
  +------------------------+
  |         Pod            |
  +------------------------+
```
Ejemplo de PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: datos
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 5Gi
```
StatefulSets crean PVCs automáticamente usando volumeClaimTemplates.

---

# 13. Services

Los Services permiten exponer Pods para comunicación interna o externa.

Tipos:

1. ClusterIP (default):  
   Acceso interno dentro del cluster.

2. NodePort:  
   Expone un puerto en todos los nodos para acceder desde fuera.

3. LoadBalancer:  
   Requiere soporte cloud o MetalLB en entornos on-premise.

4. ExternalName:  
   Alias DNS.

Ejemplo de ClusterIP:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```
Diagrama conceptual de Service:
```txt
  +-----------+      +---------+
  | Service   | ---> | Pod A   |
  +-----------+      +---------+
         \            +---------+
          \---------> | Pod B   |
                       +---------+
```
El Service crea automáticamente Endpoints.

---

# 14. Endpoints & EndpointSlice

Cuando un Service usa selector, Kubernetes genera:

- **Endpoints**: lista de IPs de los pods asociados.
- **EndpointSlice**: versión más nueva, escalable.
```txt
Ejemplo conceptual:

  Service “web”
         |
         v
  +-----------------------+
  |  EndpointSlice(s)     |
  |  - 10.0.1.10:80       |
  |  - 10.0.1.11:80       |
  +-----------------------+
```
Podés verlos con:
```bash
kubectl get endpoints  
kubectl get endpointslices  
```
---

# 15. Ingress

Ingress es una capa de enrutamiento HTTP/HTTPS.  
Permite usar múltiples sitios bajo un mismo LoadBalancer.

Requiere un controlador: en este curso usamos **Ingress-NGINX**.

Ejemplo básico:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  rules:
  - host: sitio.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```
```txt
Diagrama conceptual:

                +---------------------+
Internet --->   |   Ingress-NGINX     |
                +---------------------+
                  /              \
                 v                v
          +-------------+   +-------------+
          | Service A   |   | Service B   |
          +-------------+   +-------------+
```
---

# 16. MetalLB

MetalLB permite usar LoadBalancer en entornos locales (on-premise).  
Trabaja en modo:

- L2 (ARP/NDP) → el más usado y simple  
- BGP → avanzado  

Ejemplo de pool:
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ippool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.10.251-192.168.10.254
```
Diagrama:
```txt
  +-------------------+
  |   MetalLB Speaker |
  +-------------------+
         |
         v
  Anuncia IPs del LB en la red física
```
Luego los Services tipo LoadBalancer reciben una IP del pool.

---

# 17. Ejercicios realizados en clase

Relación directa con la práctica real del curso:

1. **Despliegue de NGINX con Deployment**
   ```bash kubectl apply -f deployment-nginx.yaml```

2. **Service NodePort**
   kubectl apply -f svc-nodeport.yaml  
   Acceso por: http://IP_DEL_NODO:puerto

3. **Configuración de MetalLB**
   - creación del IPAddressPool  
   - creación del L2Advertisement  
   - prueba con un Service LoadBalancer

4. **Instalación de Ingress-NGINX**
   helm repo add ingress-nginx  
   helm install ...

5. **Cert-Manager + Let's Encrypt**
   helm repo add jetstack  
   kubectl apply -f ClusterIssuer/

6. **StatefulSet con almacenamiento local**
   - creación de StorageClass local-storage  
   - creación de PVC  
   - prueba con busybox + volumeClaimTemplates  

7. Exploración de:
   kubectl get pods  
   kubectl get svc  
   kubectl get endpoints  
   kubectl logs  
   kubectl describe  

---

# 18. Referencias oficiales

Kubernetes Docs:  
https://kubernetes.io/docs/

MetalLB:  
https://metallb.universe.tf/

Ingress-NGINX:  
https://kubernetes.github.io/ingress-nginx/

Cert-Manager:  
https://cert-manager.io/docs/



