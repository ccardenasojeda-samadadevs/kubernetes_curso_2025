# CLASE 2

## Configurar `kube-vip` (Diapo 20)

> Modificar nombre de placa de red e IP en `kube-vip.yaml`

```bash
cp kube-vip.yaml /etc/kubernetes/manifests/
chmod 600 /etc/kubernetes/manifests/kube-vip.yaml
```

## Iniciar cluster kubernetes (Diapo 21)

> RECORDAD CAMBIAR --service-dns-domain

```bash
kubeadm init --pod-network-cidr=172.21.0.0/16 --service-cidr=10.96.0.0/16 --service-dns-domain=cluster.local --control-plane-endpoint=k8s.riu.edu.ar
```

### Verificar contenedores e IP flotante
```bash
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a
ip add
```

## Conectar cliente `kubectl` con el cluster (Diapo 22)
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

## Conectar cliente `kubectl` con el cluster en PC local (Diapo 23)

### Instalar cliente
```bash
apt update -y
apt upgrade -y
apt install kubectl=1.26.0-00 -y
```

### Copiar credenciales
```bash
mkdir -p $HOME/.kube
scp root@<k8s-server>:/etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Instalar HELM (Diapo 26)

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

## Instalar KREW (Diapo 27)

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
nano ~/.bashrc
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
source ~/.bashrc
```

### Instalar plugins
```bash
kubectl krew install ns 
kubectl krew install get-all
```

## Crear Alias de `kubectl` como `k` (Diapo 28)
```bash
nano ~/.bashrc
alias k='kubectl'
```

### Cargar `.bashrc`
```bash
source ~/.bashrc
```

## Instalar `CALICO` (Diapo 32)
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Verificar
```bash
k get nodes
```

### Permitir pod en control-plane
```bash
k taint nodes k8s1 node-role.kubernetes.io/control-plane:NoSchedule-
```

## Instalar `METALLB` (Diapo 33)
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```

## Setear pool de IP address al LoadBalancer (Diapo 34)
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

## Instalar `INGRESS` (Diapo 35)
```bash
helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx --create-namespace   --set controller.replicaCount=1,controller.service.loadBalancerIP=170.210.5.160
```

### Comprobar IP externa del servicio
```bash
k get svc -n ingress-nginx
```

## Instalar Lets-Encrypt (Diapo 36)

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
  --version v1.11.0 \
  --set installCRDs=true
```

### Moverse al ns de cert-manager y aplicar los ClusterIssuer
```bash
kubectl apply -n cert-manager -f ClusterIssuer/.
```

## Ejecutar script de instalación en segundo nodo
```bash
ssh k8s2.riu.edu.ar
```

### Instalar
```bash
chmod +x instalar-k8s-debian11-ubuntu2204.sh
sh instalar-k8s-debian11-ubuntu2204.sh
```
```bash
reboot
```

## Regenerar los certificados del Control Plane en el primer nodo creado con: 
```bash
kubeadm init phase upload-certs --upload-certs
```

## Obtener nuevo token de Join en el primer nodo creado
```bash
kubeadm token create --print-join-command
```

## En nodo a unir ejecutar:
```bash
kubeadm join <ip-address>:<port> --token <token> --discovery-token-ca-cert-hash sha256:<hash> --control-plane --certificate-key <certificate-key>
```