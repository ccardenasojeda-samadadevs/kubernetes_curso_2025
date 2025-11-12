---

## 🔧 **Comandos Útiles**

### 📋 **Gestión de Volúmenes**
```bash
# Ver todos los recursos de almacenamiento
kubectl get pv,pvc,sc

# Describir volúmenes
kubectl describe pv <nombre>
kubectl describe pvc <nombre> -n <namespace>

# Ver uso de almacenamiento por nodo
kubectl top nodes
kubectl describe node <nombre>

# Ver eventos relacionados con almacenamiento
kubectl get events --field-selector reason=FailedMount -n <namespace>
```

### 🔍 **Debugging de Almacenamiento**
```bash
# Ver logs del provisioner NFS
kubectl logs -n nfs-provisioner-system deployment/nfs-subdir-external-provisioner

# Ver logs de Longhorn
kubectl logs -n longhorn-system daemonset/longhorn-manager

# Verificar montajes en pods
kubectl exec -it <pod> -- df -h
kubectl exec -it <pod> -- mount | grep <volume>

# Ver detalles de StorageClass
kubectl describe storageclass <nombre>
```

### 📊 **Monitoreo y Métricas**
```bash
# Ver métricas de volúmenes (si metrics-server está instalado)
kubectl top pods --containers -n <namespace>

# Verificar capacidad de nodos
kubectl describe nodes | grep -A 5 "Allocated resources"

# Ver PVCs pendientes
kubectl get pvc --all-namespaces | grep Pending
```

---

## 🚨 **Troubleshooting**

### ❌ **Problemas Comunes**

#### 🔴 **PVC en estado Pending**
```bash
# Verificar eventos
kubectl describe pvc <nombre> -n <namespace>

# Posibles causas:
# 1. No hay PV disponible que coincida
# 2. StorageClass no existe o está mal configurado
# 3. Provisioner no está funcionando

# Solución:
kubectl get storageclass
kubectl get pv
kubectl logs -n <provisioner-namespace> <provisioner-pod>
```

#### 🔴 **Pod no puede montar volumen**
```bash
# Ver eventos del pod
kubectl describe pod <nombre> -n <namespace>

# Verificar en nodos
# Para NFS:
sudo showmount -e <nfs-server>
sudo mount -t nfs <nfs-server>:<path> /tmp/test

# Para Longhorn:
kubectl get pods -n longhorn-system
kubectl logs -n longhorn-system <longhorn-manager-pod>
```

#### 🔴 **Rendimiento lento**
```bash
# Verificar métricas de nodos
kubectl top nodes
kubectl describe node <nombre>

# Para NFS: verificar red y configuración
ping <nfs-server>
showmount -e <nfs-server>

# Para Longhorn: verificar réplicas y distribución
# Acceder al UI de Longhorn y revisar volúmenes
```
---

## 📚 **Referencias y Documentación**

### 📖 **Documentación Oficial**
- [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

### 🛠️ **Herramientas y Proyectos**
- [Longhorn](https://longhorn.io/) - Cloud native distributed storage
- [NFS Subdir Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
- [Rook](https://rook.io/) - Storage orchestration for Kubernetes
- [OpenEBS](https://openebs.io/) - Container attached storage

### 🔗 **Enlaces Útiles**
- [Cloud Provider Storage](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner)
- [Volume Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [Reclaim Policies](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaim-policy)

---