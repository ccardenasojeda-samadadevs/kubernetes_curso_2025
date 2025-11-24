# 💾 Clase 5: Almacenamiento Persistente en Kubernetes

## 📑 **Índice**

1. [🎯 Objetivos de Aprendizaje](#objetivos-de-aprendizaje)
2. [📋 Recursos Incluidos](#recursos-incluidos)
3. [💡 Conceptos Fundamentales](#conceptos-fundamentales)
   - [PersistentVolume (PV)](#persistentvolume-pv)
   - [PersistentVolumeClaim (PVC)](#persistentvolumeclaim-pvc)
   - [StorageClass](#storageclass)
4. [🔧 Configuración de NFS](#configuración-de-nfs)
   - [Preparar Servidor NFS](#preparar-servidor-nfs)
   - [Práctica PV y PVC con NFS](#práctica-pv-y-pvc-con-nfs)
5. [⚡ StorageClass Dinámico](#storageclass-dinámico)
   - [NFS Provisioner](#nfs-provisioner)
6. [🏗️ Longhorn - Storage Distribuido](#longhorn---storage-distribuido)
   - [Prerrequisitos](#prerrequisitos)
   - [Instalación](#instalación)
   - [Configuración](#configuración)
7. [📊 Benchmarks de Rendimiento](#benchmarks-de-rendimiento)
   - [PostgreSQL + pgbench](#postgresql--pgbench)
   - [Pruebas de I/O](#pruebas-de-io)
8. [🌍 Ejemplo Completo: WordPress](#ejemplo-completo-wordpress)

---

## 🎯 **Objetivos de Aprendizaje**

Al finalizar esta clase, serás capaz de:

- ✅ **Comprender los conceptos** de almacenamiento persistente en Kubernetes
- ✅ **Configurar servidores NFS** para almacenamiento compartido
- ✅ **Crear PersistentVolumes y PersistentVolumeClaims** manualmente
- ✅ **Implementar StorageClasses** para aprovisionamiento dinámico
- ✅ **Instalar y configurar Longhorn** para storage distribuido
- ✅ **Realizar benchmarks** de rendimiento de almacenamiento
- ✅ **Desplegar aplicaciones completas** con persistencia (WordPress)
- ✅ **Troubleshoot problemas** comunes de almacenamiento

---

## 📋 **Recursos Incluidos**

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `01-pv.yaml` | PersistentVolume | Volumen NFS estático |
| `02-pvc.yaml` | PersistentVolumeClaim | Claim para el PV NFS |
| `03-pod.yaml` | Pod | Nginx con volumen persistente |
| `04-pvc-storageclass.yaml` | PVC | Aprovisionamiento dinámico |
| `05-pvc-pod-longhorn.yaml` | Pod + PVC | Prueba con Longhorn |
| `06-pgbech-longhorn.yaml` | StatefulSet | PostgreSQL con Longhorn |
| `07-pgbech-nfs.yaml` | StatefulSet | PostgreSQL con NFS |
| `wp/` | Directorio | WordPress completo con MySQL |

---

## 💡 **Conceptos Fundamentales**

### 🗄️ **PersistentVolume (PV)**

Un **PersistentVolume** es un recurso de almacenamiento en el cluster que:
- ✅ Existe independientemente de los Pods
- ✅ Tiene un ciclo de vida independiente
- ✅ Puede ser aprovisionado estática o dinámicamente
- ✅ Soporta diferentes backends (NFS, iSCSI, Cloud providers)

### 📋 **PersistentVolumeClaim (PVC)**

Un **PersistentVolumeClaim** es una solicitud de almacenamiento que:
- ✅ Especifica tamaño y modos de acceso
- ✅ Se vincula automáticamente a un PV compatible
- ✅ Puede usar StorageClasses para aprovisionamiento dinámico
- ✅ Actúa como "interfaz" entre Pods y almacenamiento

### ⚙️ **StorageClass**

Una **StorageClass** define:
- ✅ Tipo de almacenamiento disponible
- ✅ Aprovisionador (provisioner) a usar
- ✅ Parámetros específicos del backend
- ✅ Políticas de reclaim y binding

---

## 🔧 **Configuración de NFS**

### 📦 **Preparar Servidor NFS** (Diapo 10)

#### 1️⃣ **Crear directorio compartido**
```bash
# En el servidor NFS
sudo mkdir -p /app/k8s
sudo chown nobody:nogroup /app/k8s
sudo chmod 755 /app/k8s
```

#### 2️⃣ **Instalar servicios NFS**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nfs-kernel-server rpcbind -y
```

#### 3️⃣ **Configurar y habilitar servicios**
```bash
# Iniciar servicios
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server

# Verificar estado
sudo systemctl status nfs-server
```

#### 4️⃣ **Configurar exports**
```bash
# Configurar /etc/exports (ajustar IPs según tu red)
echo "/app/k8s 170.210.5.8(rw,no_root_squash,sync,no_subtree_check) 170.210.5.9(rw,no_root_squash,sync,no_subtree_check) 170.210.5.10(rw,no_root_squash,sync,no_subtree_check) 170.210.5.11(rw,no_root_squash,sync,no_subtree_check) " | sudo tee -a /etc/exports
# echo "/app/k8s 170.210.5.0/24(rw,no_root_squash,sync,no_subtree_check)" | sudo tee -a /etc/exports

# Aplicar configuración
sudo exportfs -ra
sudo exportfs -v  # Verificar exports activos
```

### 🧪 **Práctica PV y PVC con NFS** (Diapo 11)

#### 1️⃣ **Preparar namespace**
```bash
# Limpiar namespace si existe
k delete namespace prueba --ignore-not-found=true
k create namespace prueba

# Configurar contexto
k ns prueba
```

#### 2️⃣ **Crear PersistentVolume**
```bash
# Aplicar configuración (ajustar IP del servidor NFS)
k apply -f 01-pv.yaml

# Verificar estado
k get pv
k describe pv nginx-volum
```

#### 3️⃣ **Crear PersistentVolumeClaim**
```bash
# Crear claim
k apply -f 02-pvc.yaml

# Verificar binding
k get pv,pvc
k describe pvc nginx-volum
```

#### 4️⃣ **Desplegar Pod con volumen**
```bash
# Crear pod
k apply -f 03-pod.yaml

# Verificar montaje
k get pods
k describe pod nginx
```

#### 5️⃣ **Probar persistencia**
```bash
# Port forward para acceder
k port-forward pod/nginx 8080:80

# Crear contenido
k exec -it nginx -- bash -c "echo 'Hello Persistent Storage!' > /usr/share/nginx/html/index.html"

# Verificar
curl http://localhost:8080

# Eliminar pod y recrear
k delete pod nginx
k apply -f 03-pod.yaml

# Verificar que el contenido persiste
k port-forward pod/nginx 8080:80
curl http://localhost:8080
```

#### 6️⃣ **Modificar desde servidor NFS**
```bash
# En el servidor NFS
echo "<h1>Modified from NFS Server</h1>" | sudo tee /app/k8s/nginx/index.html

# Verificar cambios en el Pod
curl http://localhost:8080
```

---

## ⚡ **StorageClass Dinámico**

### 🚀 **NFS Provisioner**

#### 1️⃣ **Instalar NFS Subdir External Provisioner**
```bash
# Agregar repositorio Helm
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# Instalar provisioner (ajustar server y path)
helm install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=170.210.5.12 \
  --set nfs.path=/app/k8s \
  --set storageClass.onDelete=true \
  --set storageClass.defaultClass=false \
  --set storageClass.name=nfs-client \
  --create-namespace \
  --namespace nfs-provisioner-system

# Verificar instalación
k get pods -n nfs-provisioner-system
k get storageclass
```

#### 2️⃣ **Probar aprovisionamiento dinámico**
```bash
# Limpiar recursos anteriores
k delete namespace prueba
k create namespace prueba
k delete pv nginx-volum

# Crear PVC con StorageClass
k apply -f 04-pvc-storageclass.yaml

# Verificar aprovisionamiento automático
k get pvc,pv
k describe pvc nginx-volum-sc
```

#### 3️⃣ **Verificar en servidor NFS**
```bash
# En el servidor NFS, ver directorio creado automáticamente
ls -la /app/k8s/
# Debería mostrar: prueba-nginx-volum-sc-pvc-<uuid>
```

#### 4️⃣ **Probar eliminación**
```bash
# Eliminar PVC
k delete pvc nginx-volum-sc

# Verificar en servidor NFS (directorio archivado)
ls -la /app/k8s/
# Debería mostrar: archived-prueba-nginx-volum-sc-pvc-<uuid>

# Comprobar configuración en la instalación del provisioner con helm
helm show values nfs-subdir-external-provisioner/nfs-subdir-external-provisioner | grep -5 archived
```

---

## 🏗️ **Longhorn - Storage Distribuido**

### ✅ **Prerrequisitos**
Fuente: https://longhorn.io/docs/archives/1.7.3/deploy/install/#installation-requirements

#### 1️⃣ **Verificar prerrequisitos automáticamente**

```bash
# For AMD64 platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.7.3/longhornctl-linux-amd64
# For ARM platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.7.3/longhornctl-linux-arm64

chmod +x longhornctl
./longhornctl check preflight
```

OTRA FORMA:
```bash
# Instalar jq si no está instalado
sudo apt install jq -y

# Ejecutar script de verificación
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.7.3/scripts/environment_check.sh | bash
```

#### 2️⃣ **Instalar prerequisitos en todos los nodos**

```bash
# Instalar prerequisitos
./longhornctl install preflight
```

OTRA FORMA: 
```bash
# En todos los nodos del cluster
sudo apt update

# Instalar herramientas básicas requeridas
echo "🔧 Instalando herramientas básicas..."
sudo apt install -y bash curl grep gawk util-linux
sudo apt install -y cryptsetup
sudo apt-get install dmsetup

# Instalar open-iscsi
sudo apt install open-iscsi -y
sudo systemctl enable iscsid
sudo systemctl start iscsid

# Instalar cliente NFSv4 para soporte RWX
sudo apt install -y nfs-common
```

#### 3️⃣ **Verificar nodos son schedulables (opcional)**
```bash
# Si los masters tienen taint NoSchedule, removerlo
k taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- || true
k taint nodes --all node-role.kubernetes.io/master:NoSchedule- || true

# Verificar nodos
k get nodes -o wide
```

### 🚀 **Instalación**

#### 1️⃣ **Instalar Longhorn**
```bash
# Método 1: Usando k
k apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.3/deploy/longhorn.yaml

# Método 2: Usando Helm (recomendado)
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.defaultDataPath="/var/lib/longhorn/" \
  --version 1.7.3

# Verificar instalación
k get pods -n longhorn-system -w
```

#### 2️⃣ **Configurar acceso al UI**
```bash
# Crear usuario para autenticación
USER=admin
PASSWORD="LonghornAdmin123!"
echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" > auth
k -n longhorn-system create secret generic basic-auth --from-file=auth
rm auth

# Crear Ingress para acceso web
k apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # prevent the controller from redirecting (308) to HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
    # custom max body size for file uploading like backing image uploading
    nginx.ingress.kubernetes.io/proxy-body-size: 10000m
spec:
  ingressClassName: nginx
  rules:
  - host: longhorn.k8s.riu.edu.ar
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
EOF
```

#### 3️⃣ **Acceso alternativo con LoadBalancer**
```bash
# Cambiar servicio a LoadBalancer
k patch svc longhorn-frontend -n longhorn-system -p '{"spec":{"type":"LoadBalancer"}}'

# Obtener IP externa
k get svc longhorn-frontend -n longhorn-system
```

### 🧪 **Configuración y Pruebas** (Diapo 29)

#### 1️⃣ **Verificar StorageClass**
```bash
# Ver StorageClass creado
k get storageclass
k describe storageclass longhorn

# Hacer Longhorn el StorageClass por defecto (opcional)
k patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### 2️⃣ **Probar con Pod de ejemplo**
```bash
# Crear Pod con PVC Longhorn
k apply -f 05-pvc-pod-longhorn.yaml

# Verificar estado
k get pods,pvc,pv
k describe pvc nginx-volum-sc-lh
```

#### 3️⃣ **Verificar en nodos**
```bash
# En cualquier nodo del cluster
sudo ls -la /var/lib/longhorn/replicas/
# Debería mostrar directorios de las réplicas
```

---

## 📊 **Benchmarks de Rendimiento**

### 🐘 **PostgreSQL + pgbench**

#### 1️⃣ **Benchmark con Longhorn**
```bash
# Eliminar recursos anteriores
k delete pod nginx-lh --ignore-not-found=true
k delete pvc nginx-volum-sc-lh --ignore-not-found=true

# Desplegar PostgreSQL con Longhorn
k apply -f 06-pgbech-longhorn.yaml

# Esperar a que esté listo
k wait --for=condition=ready pod -l app=postgres --timeout=300s

# Ejecutar benchmark
POD_NAME=$(k get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
k exec -it $POD_NAME -- bash -c "
  su - postgres -c '
    createdb prueba
    pgbench -i -s 50 prueba
    echo \"Starting pgbench test with Longhorn...\"
    time pgbench -c 4 -j 4 -t 1000 prueba
  '
"

# Prueba I/O
k exec -it $POD_NAME -- bash -c "
  echo 'Testing sequential write with Longhorn...'
  time dd if=/dev/zero of=/var/lib/postgresql/data/test-longhorn bs=64k count=16k conv=fdatasync
  ls -lh /var/lib/postgresql/data/test-longhorn
"
```

#### 2️⃣ **Benchmark con NFS**
```bash
# Limpiar recursos Longhorn
k delete -f 06-pgbech-longhorn.yaml

# Desplegar PostgreSQL con NFS
k apply -f 07-pgbech-nfs.yaml

# Esperar a que esté listo
k wait --for=condition=ready pod -l app=postgres-nfs --timeout=300s

# Ejecutar benchmark
POD_NAME=$(k get pods -l app=postgres-nfs -o jsonpath='{.items[0].metadata.name}')
k exec -it $POD_NAME -- bash -c "
  su - postgres -c '
    createdb prueba
    pgbench -i -s 50 prueba
    echo \"Starting pgbench test with NFS...\"
    time pgbench -c 4 -j 4 -t 1000 prueba
  '
"

# Prueba de I/O  
k exec -it $POD_NAME -- bash -c "
  echo 'Testing sequential write with NFS...'
  time dd if=/dev/zero of=/var/lib/postgresql/data/test-nfs bs=64k count=16k conv=fdatasync
  ls -lh /var/lib/postgresql/data/test-nfs
"
```

---

## 🌍 **Ejemplo Completo: WordPress**

### 📁 **Estructura del directorio wp/**

```
wp/
├── 01-mysql-secret.yaml      # Credenciales de MySQL
├── 02-mysql-storage.yaml     # PVC para MySQL
├── 03-mysql-service.yaml     # Service para MySQL
├── 04-mysql-deployment.yaml  # Deployment de MySQL
├── 05-wp-service.yaml        # Service para WordPress
├── 06-wp-storage.yaml        # PVC para WordPress
├── 07-wp-deploy.yaml         # Deployment de WordPress
└── 08-ingress.yaml           # Ingress para acceso web
```

### 🚀 **Desplegar WordPress completo**
```bash
# Aplicar todos los manifiestos
k apply -f wp/

# Verificar despliegue
k get all -n prueba
k get pvc,pv -n prueba

# Obtener URL de acceso
k get ingress -n prueba
```
