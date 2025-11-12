#!/bin/bash

export USER=user-curso-siu
export CLUSTER=cluster-curso-siu

# Guardar el certificado del cluster
kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -d | openssl x509 -out - > ${CLUSTER}.crt
server=$(kubectl config view --minify --raw --output 'jsonpath={..cluster.server}')

echo $server

request="openssl req -new -key ${USER}.key -out ${USER}.csr -subj \"/CN=${USER}"
# Crear namespaces y los roles
while read line || [ -n "$line" ];
do
    export NAMESPACE=$line
    echo $line
    kubectl create namespace ${NAMESPACE}
    cat admin-role.yaml | envsubst | kubectl apply -f -
    cat admin-rolebinding.yaml | envsubst | kubectl apply -f -
    request="$request/O=${NAMESPACE}"
done < namespaces.txt
request="$request\""

# Crear el certificado de conexión al cluster para el USER
openssl genrsa -out ${USER}.key 2048
echo $request
eval $request
export BASE64_CSR=$(cat ./${USER}.csr | base64 | tr -d '\n')
cat user-csr.yaml | envsubst | kubectl apply -f -
kubectl certificate approve ${USER}-csr
kubectl get csr ${USER}-csr -o jsonpath='{.status.certificate}'| base64 -d > ${USER}.crt

echo "Comandos para configurar la conexión en el cliente del usuario"
echo kubectl config set-cluster ${CLUSTER} --server=$server --certificate-authority=${CLUSTER}.crt --embed-certs=true
echo kubectl config set-credentials ${USER} --client-key=${USER}.key --client-certificate=${USER}.crt --embed-certs=true
echo kubectl config set-context ${USER}@${CLUSTER} --cluster=${CLUSTER} --user=${USER}
echo kubectl config use-context ${USER}@${CLUSTER}
echo kubectl config set-context --current --namespace=TU NAMESPACE
