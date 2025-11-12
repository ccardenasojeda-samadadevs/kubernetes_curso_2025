# 🧾 Kubernetes Cluster – Laboratorio Debian 12 (UNPA)

Implementación y configuración completa de un clúster Kubernetes v1.33 sobre Debian 12, con Calico, MetalLB, Ingress NGINX, Cert-Manager y almacenamiento persistente local.  
Entorno pensado para uso académico, laboratorio o pruebas de despliegue.

---

## 🧱 1. Topología y entorno

**Red física:** `192.168.10.0/24`  
**Red Pods:** `172.21.0.0/16`  
**Red Services:** `10.96.0.0/16`  
**IP flotante (control-plane):** `192.168.10.250`  
**Endpoint DNS:** `k8stest.unpa.edu.ar`

| Nodo | Rol | IP | SO | Estado |
|------|-----|----|----|--------|
| k8s-nodo0 | Control Plane | 192.168.10.245 | Debian 12 | ✅ Ready |
| nodo1 | Worker | 192.168.10.248 | Debian 12 | ✅ Ready |
| nodo2 | Worker | 192.168.10.249 | Debian 12 | ✅ Ready |
| nodo3 | Worker | 192.168.10.246 | Debian 12 | ✅ Ready |
| nodo4 | Worker | 192.168.10.247 | Debian 12 | ✅ Ready |

---

## ⚙️ 2. Instalación base

Script adaptado: `install_k8s_node_debian12.sh`

Incluye:
- Instalación de containerd v2.1.3, runc v1.3.0, CNI v1.7.1  
- Configuración de módulos `br_netfilter` y sysctl  
- Desactivación de swap  
- Repositorio oficial: `https://pkgs.k8s.io/core:/stable:/v1.33/deb/`

---

## 🚀 3. Inicialización del cluster

```bash
sudo kubeadm init   --pod-network-cidr=172.21.0.0/16   --service-cidr=10.96.0.0/16   --service-dns-domain=cluster.local   --control-plane-endpoint=k8stest.unpa.edu.ar
```

Configuración del acceso kubectl:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Unión de nodos workers:

```bash
kubeadm join 192.168.10.245:6443 --token <token>   --discovery-token-ca-cert-hash sha256:<hash>
```

---

## 🌐 4. Red Calico

Instalación del CNI:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

---

## ⚡ 5. MetalLB (LoadBalancer L2)

Instalación:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
```

Configuración IP Pool:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ippool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.10.251-192.168.10.254
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb-system
```

Verificación:

```bash
kubectl get ipaddresspools -n metallb-system
kubectl get pods -n metallb-system
```

---

## 🌍 6. Ingress NGINX

Instalación con Helm:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx   --version 4.11.8   --namespace ingress-nginx   --create-namespace   --set controller.service.type=LoadBalancer   --set controller.service.loadBalancerIP=192.168.10.251
```

Validación:

```bash
kubectl get svc -n ingress-nginx
```

---

## 🔐 7. Cert-Manager y ClusterIssuer

Instalación:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.18.2   --set installCRDs=true
```

ClusterIssuer (Let's Encrypt):

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@k8stest.unpa.edu.ar
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

Aplicar y verificar:

```bash
kubectl apply -n cert-manager -f ClusterIssuer/
kubectl get clusterissuers
```

---

## 🧹 8. Limpieza de entorno de pruebas

Eliminar recursos de prueba y mantener solo infraestructura base:

```bash
kubectl delete ns prueba
kubectl delete all --all -n default
kubectl get pods -A -o wide
kubectl get svc -A
```

---

## 🧰 9. Comandos útiles

| Comando | Descripción |
|----------|--------------|
| `kubectl get ns` | Lista namespaces |
| `kubectl get pods -A -o wide` | Muestra pods con nodo e IP |
| `kubectl get svc -A` | Lista servicios |
| `kubectl get deploy -A` | Lista deployments |
| `kubectl get nodes -o wide` | Verifica nodos del cluster |
| `kubectl logs <pod>` | Logs de un pod |
| `kubectl describe <recurso>` | Detalle de configuración |
| `kubectl apply -f <archivo>.yaml` | Aplica manifiesto |
| `kubectl delete all --all -n <ns>` | Limpieza de namespace |
| `helm list -A` | Listar charts instalados |
| `helm uninstall <nombre> -n <ns>` | Desinstalar un chart |

---

## 🧩 10. Estado final verificado

Componentes activos:
- `kube-system` → CoreDNS, Calico, kube-proxy  
- `metallb-system` → controller y speakers  
- `ingress-nginx` → LoadBalancer activo en 192.168.10.251  
- `cert-manager` → emisión automática de certificados  
- `default` → vacío y limpio

---

## 💾 11. Persistencia de datos (Local Storage)

Para las pruebas de almacenamiento persistente se utilizó un **StatefulSet** con volúmenes locales administrados por Kubernetes.

### 📘 Manifiesto del StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-csi-app-set
spec:
  selector:
    matchLabels:
      app: mypod
  serviceName: "my-frontend"
  replicas: 1
  template:
    metadata:
      labels:
        app: mypod
    spec:
      containers:
      - name: my-frontend
        image: busybox
        args: ["sleep", "infinity"]
        volumeMounts:
        - name: csi-pvc
          mountPath: "/data"
  volumeClaimTemplates:
  - metadata:
      name: csi-pvc
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: local-storage
      resources:
        requests:
          storage: 5Gi
```

### 🧱 11.1 Definir StorageClass local

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

Aplicar:

```bash
kubectl apply -f local-storage.yaml
kubectl get storageclass
```

### 🧩 11.2 Crear PersistentVolume (uno por nodo)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-node1
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - nodo1
```

Verificar:

```bash
kubectl get pv
kubectl get pvc
```

### 🧰 11.3 Comandos útiles

| Comando | Descripción |
|----------|-------------|
| `kubectl get storageclass` | Lista las clases de almacenamiento |
| `kubectl get pv` | Ver los volúmenes persistentes |
| `kubectl get pvc` | Ver las reclamaciones activas |
| `kubectl describe pvc <nombre>` | Ver detalles del vínculo PVC/PV |
| `kubectl exec -it <pod> -- sh` | Accede al contenedor para validar /data |
| `kubectl delete pvc --all` | Elimina volúmenes de prueba |

### 🧹 11.4 Limpieza de pruebas de persistencia

```bash
kubectl delete statefulset my-csi-app-set
kubectl delete pvc --all
kubectl delete pv --all
```

---

> **Autor:** Cristian Samuel Cárdenas Ojeda  
> **Institución:** Universidad Nacional de la Patagonia Austral – UNPA  
> **Fecha:** Noviembre 2025
