#!/bin/bash

# Script de instalación Kubernetes node para Ubuntu 24.04
set -e

# Versiones
CONTAINERD_VERSION=2.1.3
RUNC_VERSION=1.3.0
CNI_PLUGINS_VERSION=1.7.1
K8S_VERSION=1.33

# Actualizar Repositorios y sistema
apt update -y
apt upgrade -y


# Desactivar SWAP
echo "####### Desactivar SWAP"
cp /etc/fstab /etc/fstab.bkp
swapoff -a
# Eliminar entradas swap de /etc/fstab
sed -i.bak '/^\s*[^#]*swap/d' /etc/fstab

# Configuración de módulos y sysctl para Kubernetes
echo "####### Configurar módulos y sysctl para Kubernetes"
# Cargar módulo br_netfilter (overlay se carga automáticamente por containerd.service)
echo "br_netfilter" > /etc/modules-load.d/k8s.conf
modprobe br_netfilter

# Configurar sysctl para Kubernetes
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
EOF

# Habilitar net.ipv4.ip_forward en /etc/sysctl.conf
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
systemctl restart systemd-sysctl || true
sysctl --system

# Instala Git y gpg
apt install git gpg -y

# Instalar containerd
echo "####### Instalar containerd"

wget -P /tmp https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
tar -C /usr/local -xzvf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Usar el archivo de servicio del role si está disponible
if [ -f "$(dirname "$0")/k8s_node/files/containerd.service" ]; then
	cp "$(dirname "$0")/k8s_node/files/containerd.service" /etc/systemd/system/containerd.service
else
	cat <<EOF | tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target dbus.service

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable --now containerd

# Instalar runc
echo "####### Instalar runc"
wget -P /tmp https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc



# Instalar CNI plugins
echo "####### Instalar CNI plugins"
wget -P /tmp https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzvf /tmp/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz



# Configuración por defecto containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
systemctl restart containerd

# Ajuste extra: aumentar fs.inotify.max_user_instances
echo "####### Configurar fs.inotify.max_user_instances"
sysctl -w fs.inotify.max_user_instances=256
echo 'fs.inotify.max_user_instances=256' > /etc/sysctl.d/99-inotify.conf
sysctl --system

# Copiar multipath.conf si existe en el role
if [ -f "$(dirname "$0")/k8s_node/files/multipath.conf" ]; then
	cp "$(dirname "$0")/k8s_node/files/multipath.conf" /etc/multipath.conf
fi


echo "####### Instalar Kubernetes"
# Instalar dependencias instalación kubernetes
apt install -y software-properties-common nfs-common apt-transport-https ca-certificates curl gpg

# Agregar repositorio de kubernetes
mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key -o /etc/apt/keyrings/Release.key
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg /etc/apt/keyrings/Release.key
rm /etc/apt/keyrings/Release.key

apt update -y
apt upgrade -y



# Instalar la última versión disponible de kubeadm/kubelet/kubectl para v${K8S_VERSION}
HIGHEST_VERSION=$(apt-cache madison kubeadm | grep ${K8S_VERSION} | head -n1 | awk '{print $3}')
if [ -z "$HIGHEST_VERSION" ]; then
	echo "No se encontró versión de kubeadm para v${K8S_VERSION}. Abortando."
	exit 1
fi
echo "Instalando Kubernetes versión: $HIGHEST_VERSION"
apt install -y kubeadm=${HIGHEST_VERSION} kubelet=${HIGHEST_VERSION} kubectl=${HIGHEST_VERSION} --allow-change-held-packages
apt-mark hold kubelet kubeadm kubectl


# Exponer métricas si existen los manifiestos
for manifest in /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml; do
	if [ -f "$manifest" ]; then
		sed -i 's/--listen-metrics-urls=http:\/\/127.0.0.1:2381/--listen-metrics-urls=http:\/\/0.0.0.0:2381/g' "$manifest"
		sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' "$manifest"
	fi
done

# Verificar la versión de kubeadm instalada
echo "####### Verificar instalación"
kubeadm version
KUBEADM_VERSION=$(kubeadm version -o short 2>/dev/null || kubeadm version 2>/dev/null | grep GitVersion | cut -d'"' -f4)
echo "La versión de kubeadm instalada es: $KUBEADM_VERSION"

echo "####### DEBE REINICIAR LA VIRTUAL para aplicar los cambios"
