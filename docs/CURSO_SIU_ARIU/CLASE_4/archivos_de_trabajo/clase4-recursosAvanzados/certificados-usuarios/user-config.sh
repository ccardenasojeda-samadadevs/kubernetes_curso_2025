#!/bin/bash

export USER=$1
export NAMESPACE=$2
export CLUSTER=$3

echo "USER=$1"
echo "NAMESPACE=$2"

# Guardar el certificado del cluster
ca_data=$(kubectl config view --minify --raw --output 'jsonpath={.clusters[0].cluster.certificate-authority-data}')
ca_file=$(kubectl config view --minify --raw --output 'jsonpath={.clusters[0].cluster.certificate-authority}')

if [ -n "$ca_data" ]; then
    # Si tiene certificate-authority-data (base64)
    echo "$ca_data" | base64 -d > ${CLUSTER}.crt
    echo "Certificado extraído de certificate-authority-data"
elif [ -n "$ca_file" ]; then
    # Si tiene certificate-authority (archivo)
    cp "$HOME/.kube/$ca_file" ${CLUSTER}.crt
    echo "Certificado copiado desde: $HOME/.kube/$ca_file"
else
    echo "⚠️  ADVERTENCIA: No se encontró certificado CA del cluster"
    echo "   Usando --insecure-skip-tls-verify en los comandos de configuración"
fi

server=$(kubectl config view --minify --raw --output 'jsonpath={.clusters[0].cluster.server}')

# Crear el namespace y los roles
kubectl create namespace ${NAMESPACE}
cat admin-role.yaml | envsubst | kubectl apply -f -
cat admin-rolebinding.yaml | envsubst | kubectl apply -f -

# Crear el certificado de conexión al cluster para el USER
echo "🔧 Generando clave privada para ${USER}..."
openssl genrsa -out ${USER}.key 2048

echo "📝 Creando Certificate Signing Request (CSR)..."
openssl req -new -key ${USER}.key -out ${USER}.csr -subj "/CN=${USER}/O=${NAMESPACE}"

# Eliminar CSR anterior si existe
echo "🧹 Limpiando CSR anterior si existe..."
kubectl delete csr ${USER}-csr 2>/dev/null || true

echo "📤 Enviando CSR a Kubernetes..."
export BASE64_CSR
BASE64_CSR=$(cat ./${USER}.csr | base64 | tr -d '\n')
cat user-csr.yaml | envsubst | kubectl apply -f -

echo "✅ Aprobando CSR..."
kubectl certificate approve ${USER}-csr

echo "📥 Obteniendo certificado firmado..."
# Esperar un momento para que el certificado esté disponible
sleep 2
kubectl get csr ${USER}-csr -o jsonpath='{.status.certificate}'| base64 -d > ${USER}.crt

# Verificar que el certificado coincida con la clave privada
echo "🔍 Verificando concordancia clave privada/certificado..."
PRIVATE_KEY_HASH=$(openssl rsa -in ${USER}.key -pubout -outform PEM 2>/dev/null | sha256sum | cut -d' ' -f1)
CERT_KEY_HASH=$(openssl x509 -in ${USER}.crt -pubkey -noout 2>/dev/null | sha256sum | cut -d' ' -f1)

if [ "$PRIVATE_KEY_HASH" = "$CERT_KEY_HASH" ]; then
    echo "✅ Certificado y clave privada coinciden correctamente"
else
    echo "❌ ERROR: Certificado y clave privada NO coinciden"
    echo "   Hash clave privada: $PRIVATE_KEY_HASH"
    echo "   Hash certificado:   $CERT_KEY_HASH"
    exit 1
fi

echo "Comandos para configurar la conexión en el cliente del usuario"
if [ -f "${CLUSTER}.crt" ]; then
    echo kubectl config set-cluster ${CLUSTER} --server=$server --certificate-authority=${CLUSTER}.crt --embed-certs=true
else
    echo kubectl config set-cluster ${CLUSTER} --server=$server --insecure-skip-tls-verify=true
fi
echo kubectl config set-credentials ${USER} --client-key=${USER}.key --client-certificate=${USER}.crt --embed-certs=true
echo kubectl config set-context ${USER}@${CLUSTER} --cluster=${CLUSTER} --user=${USER}
echo kubectl config use-context ${USER}@${CLUSTER}