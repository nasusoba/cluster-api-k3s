# Please prepare a management cluster before running this script
if [ -z "${AZURE_SUBSCRIPTION_ID}" ]; then
  echo "please set AZURE_SUBSCRIPTION_ID"
  exit 0
fi

if [ -z "${AZURE_TENANT_ID}" ]; then
  echo "please set AZURE_TENANT_ID"
  exit 0
fi


if [ -z "${AZURE_CLIENT_ID}" ]; then
  echo "please set AZURE_CLIENT_ID"
  exit 0
fi


if [ -z "${AZURE_CLIENT_SECRET}" ]; then
  echo "please set AZURE_CLIENT_SECRET"
  exit 0
fi

if [ -z "${CLUSTER_NAME}" ]; then
  echo "please set CLUSTER_NAME"
  exit 0
fi

export AZURE_LOCATION="eastus"
export AZURE_ENVIRONMENT="AzurePublicCloud"
export AZURE_SUBSCRIPTION_ID_B64="$(echo -n "$AZURE_SUBSCRIPTION_ID" | base64 | tr -d '\n')"
export AZURE_TENANT_ID_B64="$(echo -n "$AZURE_TENANT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_ID_B64="$(echo -n "$AZURE_CLIENT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_SECRET_B64="$(echo -n "$AZURE_CLIENT_SECRET" | base64 | tr -d '\n')"

# Setting up management cluster with k3s controllers and capz
# with cluster resource set and cluster topology enabled
export EXP_CLUSTER_RESOURCE_SET=true
export CLUSTER_TOPOLOGY=true
clusterctl init --infrastructure azure --bootstrap k3s --control-plane k3s

kubectl wait --for=condition=Available --timeout=5m -n capi-system deployment/capi-controller-manager
kubectl wait --for=condition=Available --timeout=5m -n capi-k3s-control-plane-system deployment/capi-k3s-control-plane-controller-manager
kubectl wait --for=condition=Available --timeout=5m -n capz-system deployment/capz-controller-manager
kubectl wait --for=condition=Available --timeout=5m -n capi-k3s-bootstrap-system deployment/capi-k3s-bootstrap-controller-manager

# Settings needed for AzureClusterIdentity used by the AzureCluster
export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
export CLUSTER_IDENTITY_NAME="cluster-identity"
export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"

# Create a secret to include the password of the Service Principal identity created in Azure
# This secret will be referenced by the AzureClusterIdentity used by the AzureCluster
kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"

# Install CCM resource set to management cluster
kubectl create configmap azure-ccm-addon --from-file=samples/azure/azure-ccm.yaml
kubectl create configmap azure-cn-addon --from-file=samples/azure/azure-cn.yaml
kubectl apply -f samples/azure/k3s-cluster.yaml
kubectl apply -f samples/azure/resource-set.yaml

# Generate templates
clusterctl generate yaml --from samples/azure/k3s-template.yaml > cluster.yaml

# Create the cluster
kubectl apply -f cluster.yaml

echo "once the cluster is up run clusterctl get kubeconfig $CLUSTER_NAME > k3s.yaml or kubectl scale kthreescontrolplane $CLUSTER_NAME-control-plane --replicas 3 for HA"