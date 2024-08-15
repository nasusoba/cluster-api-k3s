export CLUSTER_NAME=demok3s
export CLUSTER_CLASS_NAME=${CLUSTER_NAME}-class
export KUBERNETES_VERSION=v1.28.6+k3s2
export KUBERNETES_VERSION_UPGRADE_TO=v1.28.7+k3s1

clusterctl generate yaml --from ./clusterclass-azure.yaml > clusterclass.yaml
clusterctl generate yaml --from ./cluster-template-topology.yaml > cluster.yaml

kubectl apply -f clusterclass.yaml
kubectl apply -f cluster.yaml

# Describe cluster
clusterctl describe cluster $CLUSTER_NAME

# Connect to cluster
clusterctl get kubeconfig ${CLUSTER_NAME} > ${CLUSTER_NAME}.kubeconfig
kubectl get nodes --kubeconfig ${CLUSTER_NAME}.kubeconfig