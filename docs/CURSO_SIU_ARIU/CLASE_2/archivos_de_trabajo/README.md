# CLASE 2

1. [Introducción](#introducción)
2. [Configurar kube-vip](#configurar-kube-vip)
3. [Iniciar cluster Kubernetes](#iniciar-cluster-kubernetes)
4. [Conectar cliente kubectl](#conectar-cliente-kubectl)
5. [Instalar herramientas (HELM, KREW)](#instalar-herramientas-helm-krew)
6. [Instalar Calico](#instalar-calico)
7. [Instalar MetalLB y configurar LoadBalancer](#instalar-metallb-y-configurar-loadbalancer)
8. [Instalar Ingress](#instalar-ingress)
9. [Instalar Let's Encrypt (Cert-Manager)](#instalar-lets-encrypt-cert-manager)
10. [Agregar nodos al cluster](#agregar-nodos-al-cluster)

---

## Introducción

En esta clase aprenderás a:
- Configurar un cluster Kubernetes de alta disponibilidad con kube-vip.
- Instalar y configurar herramientas esenciales como Helm, Krew, Calico, MetalLB, Ingress y Cert-Manager.
- Conectar clientes locales y remotos al cluster.
- Agregar nodos adicionales y gestionar certificados.

---

## Configurar kube-vip (Diapo 23)
> Modifica el nombre de la placa de red e IP en `kube-vip.yaml` según tu entorno.

```bash
sudo cp kube-vip.yaml /etc/kubernetes/manifests/
sudo chmod 600 /etc/kubernetes/manifests/kube-vip.yaml
```

## Iniciar cluster kubernetes (Diapo 24)

> Recuerda cambiar `--service-dns-domain` si lo necesitas.

```bash
echo "192.168.10.245 k8stest.unpa.edu.ar" | sudo tee -a /etc/hosts
sudo kubeadm init --pod-network-cidr=172.21.0.0/16 --service-cidr=10.96.0.0/16 --service-dns-domain=cluster.local --control-plane-endpoint=k8stest.unpa.edu.ar
```

### Verificar contenedores e IP flotante
```bash
sudo crictl ps -a
ip add
```

### Conectar cliente `kubectl` con el cluster (Diapo 25)
```bash
chmod +x conectar-cliente.sh
sh conectar-cliente.sh
```

Contenido del script:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Verificar 
```bash
kubectl get nodes
```

### Conectar cliente `kubectl` con el cluster en PC local (Diapo 26)

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install kubectl=1.33.4-00 -y
```

### Copiar credenciales
```bash
mkdir -p $HOME/.kube
scp root@<k8s-server>:/etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Instalar herramientas (HELM, KREW) 

### Instalar HELM (Diapo 29)

```bash
chmod +x instalar-helm.sh
sh instalar-helm.sh
```

Contenido del script:
```bash
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```
#### OTRA OPCION HELM 
 curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
 chmod 700 get_helm.sh
 ./get_helm.sh
### Instalar KREW (Diapo 30)

```bash
chmod +x instalar-krew.sh
sh instalar-krew.sh
```

Contenido del script:
```bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
```

### Agregar export a `.bashrc` 
```bash
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Instalar plugins
```bash
kubectl krew install ns 
kubectl krew install get-all
kubectl krew install stern
kubectl krew install tree
```

## Crear Alias de `kubectl` como `k` (Diapo 31)
```bash
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc
```

## Instalar `CALICO` (Diapo 35)
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/calico.yaml
```

### Verificar
```bash
k get nodes
```

### Permitir pod en control-plane
```bash
k taint nodes k8s1 node-role.kubernetes.io/control-plane:NoSchedule-
```

## Instalar `METALLB` (Diapo 36)
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

### Setear pool de IP address al LoadBalancer (Diapo 37)
```bash
cat << EOF | sudo tee ipaddresspool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ippool 
  namespace: metallb-system
spec:
  addresses:
  - 170.210.5.160 - 170.210.5.163
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb-system
EOF
```
```
cat <<EOF | kubectl apply -f -
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
EOF
```

### Aplicar el pool anteriormente creado
```bash
kubectl apply -f ipaddresspool.yaml -n metallb-system
```

### Probar con un ejemplo de servicio
```bash
cat <<EOF | sudo tee example-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
EOF
```

### Aplicar ejemplo, comprobar y eliminar servicio
```bash
k apply -f example-loadbalancer.yaml -n metallb-system
k get svc -n metallb-system
k delete svc nginx -n metallb-system
```

## Instalar `INGRESS` (Diapo 38)

> Instalaremos ingress-nginx usando Helm y asignando una IP fija del pool de MetalLB (por ejemplo, 170.210.5.160) directamente en el comando, sin usar archivo values.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.11.8 \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.loadBalancerIP=170.210.5.160
```

> Cambia la IP por una disponible en tu pool de MetalLB si es necesario.

### Comprobar IP externa del servicio
```bash
k get svc -n ingress-nginx
```

## Instalar Lets-Encrypt (Diapo 39)

### Instalar Cert-Manager
#### Agregar repo y actualizar paquetes:
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

#### Instalar cert-manager con CRDs:
```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.2 \
  --set installCRDs=true
```

### Moverse al ns de cert-manager y aplicar los ClusterIssuer
```bash
kubectl apply -n cert-manager -f ClusterIssuer/.############################## Preguntar
```

## Agregar nodos al cluster (Diapo 42)

> Repite el proceso de instalación y usa el comando de join generado en el nodo principal.

### Ejecutar script de instalación en segundo nodo
```bash
ssh k8s2.riu.edu.ar
chmod +x instalar-k8s-debian12-ubuntu2404.sh
./instalar-k8s-debian12-ubuntu2404.sh
sudo reboot
```

### Regenerar los certificados del Control Plane en el primer nodo creado con: 
```bash
kubeadm init phase upload-certs --upload-certs
```

### Obtener nuevo token de Join en el primer nodo creado
```bash
kubeadm token create --print-join-command
```

### En nodo a unir ejecutar:
```bash
kubeadm join <ip-address>:<port> --token <token> --discovery-token-ca-cert-hash sha256:<hash> --control-plane --certificate-key <certificate-key>
sudo kubeadm join k8stest.unpa.edu.ar:6443 --token pouipi.wwukxj0fnqj5nr65 --discovery-token-ca-cert-hash sha256:3c4140f0d6c4e54f9ee57c8af4b627e24ae8d80321f321b3c3684f0cf0c1e950
```
