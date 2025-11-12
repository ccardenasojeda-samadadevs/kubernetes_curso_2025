# Pasos para conectarse al cluster

## Instalación de cliente `kubectl` (solo si no lo tienen instalado)

> NOTA: Los pasos son para instalación en Linux en distribuciones basadas en DEBIAN. Para instalación en Windows referirse a: https://kubernetes.io/es/docs/tasks/tools/included/install-kubectl-windows/#instalar-kubectl-en-windows (SOLO INSTALAR)

1. Paquetes necesarios
```bash
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

2. Descargar clave pública firmada de repositorios de k8s
```bash
curl -fsSLk https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
```

3. Agregar repositorio de k8s

```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

4. Update y Upgrade
```bash
sudo apt update -y
sudo apt upgrade -y
```

5. Instalación de cliente
```bash
sudo apt install kubectl=1.26.0-00 -y --allow-change-held-packages
```

## Comandos para configurar la conexión en el cliente `kubectl`

> NOTA: Los archivos de certificados de usuario y cluster deben estar en el directorio actual.

Configurar un nuevo cluster en el cliente
```bash
kubectl config set-cluster cluster-curso-siu --server=https://k8s.devops.siu.edu.ar:6443 --certificate-authority=cluster-curso-siu.crt --embed-certs=true
```

Configurar credenciales del usuario
```bash
kubectl config set-credentials user-curso-siu --client-key=user-curso-siu.key --client-certificate=user-curso-siu.crt --embed-certs=true
```

Configurar conexión del usuario al cluster
```bash
kubectl config set-context user-curso-siu@cluster-curso-siu --cluster=cluster-curso-siu --user=user-curso-siu
```

Seleccionar conexión
```bash
kubectl config use-context user-curso-siu@cluster-curso-siu
```

Configurar namespace **COMPLETAR CON NOMBRE DE USUARIO en <>**
```bash
kubectl config set-context --current --namespace=<NOMBRE-DE-USUARIO>
```

Comprobar
```bash
kubectl get pods
```

Salida esperada:
>  No resources found in \<NOMBRE-DE-USUARIO\> namespace.