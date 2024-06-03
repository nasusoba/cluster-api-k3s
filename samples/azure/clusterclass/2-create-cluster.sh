export CLUSTER_NAME="<ClusterName>"
export RESOURCE_GROUP=${CLUSTER_NAME}-rg

clusterctl generate yaml --from ./clusterclass-azure.yaml > clusterclass.yaml
clusterctl generate yaml --from ./cluster-template-topology.yaml > cluster.yaml

kubectl apply -f clusterclass.yaml
kubectl apply -f cluster.yaml
