# 🧩 Clase 1 — Instalación y Preparación del Entorno

> 📚 Basado en el material del curso SIU ARIU – Clase 1  
> **Tema:** Introducción a Kubernetes y preparación del entorno Debian 12  
> **Objetivo:** Comprender la arquitectura básica de Kubernetes y preparar el sistema para la instalación.

---

## 🎯 Objetivos de la clase

- Comprender la diferencia entre **máquinas virtuales y contenedores**.  
- Conocer los conceptos de **imagen**, **contenedor** y **Dockerfile**.  
- Identificar los **componentes principales de Kubernetes**.  
- Preparar un entorno Debian 12 o Ubuntu 24.04 para instalar Kubernetes usando `kubeadm`.  
- Ejecutar el script automatizado de instalación y validar la configuración.

---

## 🧠 Conceptos teóricos

### Contenedores vs Máquinas Virtuales
- Los **contenedores** aíslan aplicaciones compartiendo el mismo kernel del sistema operativo.  
- Son más livianos y rápidos de iniciar que las máquinas virtuales.  
- Cada contenedor incluye su propia aplicación, librerías y dependencias.

### Imágenes y Dockerfile
- Una **imagen** es un paquete inmutable con todo lo necesario para ejecutar una aplicación.  
- Se define a través de un **Dockerfile**, que especifica las instrucciones de construcción.  
- Las imágenes pueden almacenarse y versionarse en repositorios como Docker Hub o Harbor.

### Introducción a Kubernetes
- **Kubernetes (K8s)** es una plataforma de orquestación de contenedores que automatiza el despliegue, escalado y operación de aplicaciones.  
- Se basa en una arquitectura **Maestro–Nodo (Control Plane–Worker)**.

### Componentes principales

| Componente | Función |
|-------------|----------|
| `kube-apiserver` | Expone la API de Kubernetes y gestiona las peticiones. |
| `etcd` | Base de datos distribuida que guarda el estado del cluster. |
| `kube-scheduler` | Asigna Pods a nodos disponibles. |
| `kube-controller-manager` | Supervisa el estado de los recursos y aplica cambios. |
| `kubelet` | Agente que corre en cada nodo y gestiona los Pods. |
| `kube-proxy` | Gestiona la red interna de los Pods y los servicios. |

---

## ⚙️ Preparación del sistema

Antes de la instalación:
- Desactivar **swap**.  
- Configurar los módulos `br_netfilter` y `overlay`.  
- Ajustar `sysctl` para permitir reenvío de paquetes (`net.ipv4.ip_forward=1`).  
- Instalar dependencias: `git`, `curl`, `gpg`, `nfs-common`, `ca-certificates`.

### Ejecución del script de instalación

```bash
chmod +x instalar-k8s-debian12-ubuntu2404.sh
sudo sh instalar-k8s-debian12-ubuntu2404.sh
sudo reboot
```

Este script instala:
- `containerd` como runtime de contenedores.  
- `runc` y `CNI plugins`.  
- `kubeadm`, `kubelet` y `kubectl`.  
- Configura parámetros de red y kernel necesarios para Kubernetes.

---

## 🧩 Relación con la práctica

La práctica consistió en:
1. Ejecutar el script automatizado.  
2. Reiniciar la máquina virtual.  
3. Validar que los binarios (`kubeadm`, `kubectl`) estén instalados correctamente.  
4. Preparar la red y confirmar la conectividad entre nodos.  

```bash
kubectl version --client
kubeadm version
```

---

## 📚 Referencias

- Curso SIU ARIU – Clase 1: *Introducción a Kubernetes*  
- Script: `instalar-k8s-debian12-ubuntu2404.sh`  
- Documentación oficial: [kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
