#!/bin/bash
# ============================================================
# Script de instalación de Kubernetes Node en Debian 12 Bookworm
# Adaptado de versión para Ubuntu 24.04
# ============================================================
set -e

# ======== VARIABLES DE VERSIÓN ========
CONTAINERD_VERSION=2.1.3
RUNC_VERSION=1.3.0
CNI_PLUGINS_VERSION=1.7.1
K8S_VERSION=1.33

# ======== VALIDACIÓN DE ENTORNO ========
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root."
    exit 1
fi

echo "✅ Usuario root verificado"
echo "✅ Sistema detectado: $(lsb_release -ds || cat /etc/debian_version)"

# ======== PAQUETES BÁSICOS ========
echo "####### Instalando dependencias base"
apt update -y
apt install -y curl wget ca-certificates gnupg lsb-release apt-transport-https software-properties-common net-tools iproute2 vim jq

# ======== DESACTIVAR SWAP ========
echo "####### Desactivar SWAP"
cp /etc/fstab /etc/fstab.bkp
swapoff -a
sed -i.bak '/^\s*[^#]*swap/d' /etc/fstab

# ======== CONFIGURAR MÓDULOS Y SYSCTL ========
echo "####### Configurar módulos y sysctl para Kubernetes"
echo "br_netfilter" > /etc/modules-load.d/k8s.conf
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ======== INSTALAR GIT Y GPG ========
apt install -y git gpg

# ======== INSTALAR CONTAINERD ========
echo "####### Instalar containerd"
wget -P /tmp https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
tar -C /usr/local -xzvf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

cat <<EOF | tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now containerd

# ======== INSTALAR RUNC ========
echo "####### Instalar runc"
wget -P /tmp https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc

# ======== INSTALAR CNI PLUGINS ========
echo "####### Instalar CNI plugins"
wget -P /tmp https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzvf /tmp/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz

# ======== CONFIGURACIÓN CONTAINERD ========
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
systemctl restart containerd

# ======== AJUSTE DE INOTIFY ========
echo "####### Ajustar fs.inotify.max_user_instances"
sysctl -w fs.inotify.max_user_instances=256
echo 'fs.inotify.max_user_instances=256' > /etc/sysctl.d/99-inotify.conf
sysctl --system

# ======== INSTALAR KUBERNETES ========
echo "####### Instalar Kubernetes v${K8S_VERSION}"
apt install -y nfs-common

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key -o /etc/apt/keyrings/kubernetes-release.key
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg /etc/apt/keyrings/kubernetes-release.key
rm /etc/apt/keyrings/kubernetes-release.key

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update -y

HIGHEST_VERSION=$(apt-cache madison kubeadm | grep ${K8S_VERSION} | head -n1 | awk '{print $3}')
if [ -z "$HIGHEST_VERSION" ]; then
	echo "❌ No se encontró versión de kubeadm para v${K8S_VERSION}. Abortando."
	exit 1
fi

echo "Instalando Kubernetes versión: $HIGHEST_VERSION"
apt install -y kubeadm=${HIGHEST_VERSION} kubelet=${HIGHEST_VERSION} kubectl=${HIGHEST_VERSION} --allow-change-held-packages
apt-mark hold kubelet kubeadm kubectl

# ======== VERIFICAR INSTALACIÓN ========
echo "####### Verificando kubeadm"
kubeadm version
KUBEADM_VERSION=$(kubeadm version -o short 2>/dev/null || kubeadm version 2>/dev/null | grep GitVersion | cut -d'"' -f4)
echo "✅ kubeadm instalado correctamente. Versión: $KUBEADM_VERSION"

echo "####### Instalación completada correctamente."
echo "💡 Debe reiniciar el sistema para aplicar todos los cambios (recomendado)"

