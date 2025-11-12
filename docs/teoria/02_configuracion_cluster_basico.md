# ⚙️ Clase 2 — Configuración de un Cluster Básico

> 📚 Basado en el material del curso SIU ARIU – Clase 2  
> **Tema:** Configuración inicial del cluster Kubernetes  
> **Objetivo:** Comprender la creación, configuración y extensión de un cluster K8s de alta disponibilidad.

---

## 🎯 Objetivos de la clase

- Crear un **cluster Kubernetes** con `kubeadm init`.  
- Configurar **kube-vip** para alta disponibilidad.  
- Instalar herramientas de gestión: **Helm**, **Krew** y **kubectl**.  
- Implementar **Calico** como red de Pods.  
- Configurar **MetalLB**, **Ingress-NGINX** y **Cert-Manager**.  
- Conectar nodos adicionales al cluster.

---

## 🧠 Conceptos teóricos

### Arquitectura del cluster
Un cluster de Kubernetes se compone de:
- **Nodos de control (Control Plane):** gestionan el estado global del cluster.  
- **Nodos trabajadores (Workers):** ejecutan los Pods (aplicaciones).

### Alta disponibilidad con kube-vip
`kube-vip` provee una **IP virtual flotante** que permite que múltiples nodos compartan un punto de acceso al API Server.  
Esta IP se asocia automáticamente al nodo activo mediante ARP o BGP.

### Inicialización del cluster
Comando base:
```bash
sudo kubeadm init --pod-network-cidr=172.21.0.0/16   --service-cidr=10.96.0.0/16   --service-dns-domain=cluster.local   --control-plane-endpoint=k8stest.unpa.edu.ar
```
Esto configura las redes internas del cluster y el dominio de servicio.

### Plugins y extensiones

| Herramienta | Función |
|--------------|----------|
| **Helm** | Gestor de paquetes para instalar aplicaciones dentro del cluster. |
| **Krew** | Gestor de plugins para `kubectl`. |
| **Calico** | Plugin CNI para redes de Pods. |
| **MetalLB** | Provee soporte *LoadBalancer* en entornos sin nube pública. |
| **Ingress-NGINX** | Controlador de entrada HTTP/HTTPS hacia servicios internos. |
| **Cert-Manager** | Automatiza la emisión y renovación de certificados TLS. |

---

## ⚙️ Instalaciones paso a paso

### 1. Configurar kube-vip
Copiar el manifiesto:
```bash
sudo cp kube-vip.yaml /etc/kubernetes/manifests/
```

### 2. Inicializar cluster
```bash
sudo kubeadm init --pod-network-cidr=172.21.0.0/16 ...
```

### 3. Configurar cliente kubectl
```bash
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### 4. Instalar herramientas
Instalar **Helm** y **Krew** para extender las capacidades de `kubectl`.

### 5. Instalar Calico
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/calico.yaml
```

### 6. Configurar MetalLB
Definir el rango de IPs para servicios tipo LoadBalancer:
```bash
kubectl apply -f ipaddresspool.yaml
```

### 7. Instalar Ingress NGINX
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
```

### 8. Instalar Cert-Manager
Permite gestionar certificados SSL/TLS automáticamente.

---

## 🧩 Relación con la práctica

En la práctica se implementaron los siguientes pasos:
1. Ejecución de `kubeadm init` y validación del API Server.  
2. Instalación de `Calico` para red de Pods.  
3. Configuración de `MetalLB` con IPs locales (`192.168.10.251–254`).  
4. Instalación de `Ingress` y `Cert-Manager`.  
5. Conexión de nodos adicionales mediante `kubeadm join`.  

```bash
kubeadm token create --print-join-command
```

---

## 📚 Referencias

- Curso SIU ARIU – Clase 2: *Configuración de cluster Kubernetes*.  
- Documentación oficial de Calico, MetalLB e Ingress NGINX.  
- `README.md` de práctica correspondiente a Clase 2.  
