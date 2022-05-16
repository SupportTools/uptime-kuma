#!/bin/bash -x

if [[ "$1" == 'dev' ]];
then
  cluster='a0-rke2-devops'
  namespace='uptime-dev'
  imagetag=${BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='dev-uptime.support.tools'
  class="dev"
elif [[ "$1" == 'qas' ]];
then
  cluster='a0-rke2-devops'
  namespace='uptime-qas'
  imagetag=${BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='qas-uptime.support.tools'
  class="qas"
elif [[ "$1" == 'tst' ]];
then
  cluster='a0-rke2-devops'
  namespace='uptime-tst'
  imagetag=${BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='tst-uptime.support.tools'
  class="qas"
elif [[ "$1" == 'stg' ]];
then
  cluster='a1-rke2-devops'
  namespace='uptime-stg'
  imagetag=${BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='stg-uptime.support.tools'
  class="stg"
elif [[ "$1" == 'prd' ]];
then
  cluster='a1-rke2-devops'
  namespace='uptime-prd'
  imagetag=${BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='uptime.support.tools'
  class="prd"
else
  cluster='a0-rke2-devops'
  namespace=uptime-mst
  imagetag=${DRONE_BUILD_NUMBER}
  purge=false
  hpa=false
  minReplicas=1
  maxReplicas=1
  ingress='mst-uptime.support.tools'
  class="master"
fi

echo "Cluster:" ${cluster}
echo "Deploying to namespace: ${namespace}"
echo "Image tag: ${imagetag}"
echo "Purge: ${purge}"

bash /usr/local/bin/init-kubectl

echo "Settings up project, namespace, and kubeconfig"
wget -O rancher-projects https://raw.githubusercontent.com/SupportTools/rancher-projects/main/rancher-projects.sh
chmod +x rancher-projects
mv rancher-projects /usr/local/bin/
rancher-projects --cluster-name ${cluster} --project-name SupportTools --namespace ${namespace} --create-project true --create-namespace true --create-kubeconfig true --kubeconfig ~/.kube/config
if ! kubectl cluster-info
then
  echo "Problem connecting to the cluster"
  exit 1
fi

echo "Adding labels to namespace"
kubectl label ns ${namespace} team=SupportTools --overwrite
kubectl label ns ${namespace} app=uptime --overwrite
kubectl label ns ${namespace} ns-purge=${purge} --overwrite
kubectl label ns ${namespace} class=${class} --overwrite

echo "Creating registry secret"
kubectl -n ${namespace} create secret docker-registry harbor-registry-secret \
--docker-server=harbor.support.tools \
--docker-username=${DOCKER_USERNAME} \
--docker-password=${DOCKER_PASSWORD} \
--dry-run=client -o yaml | kubectl apply -f -

echo "Deploying recycle script"
kubectl -n ${namespace} create configmap script --from-file recycle.sh --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying uptime"
helm upgrade --install uptime ./chart \
--namespace ${namespace} \
-f ./chart/values.yaml \
--set image.tag=${DRONE_BUILD_NUMBER} \
--set ingress.host=${ingress}

echo "Waiting for deploying to become ready..."
echo "Checking statefulset"
for statefulset in `kubectl -n ${namespace} get sts -o name`
do
  echo "Checking ${statefulset}"
  kubectl -n ${namespace} rollout status ${statefulset}
done
echo "Checking Deployments"
for deployment in `kubectl -n ${namespace} get deployment -o name`
do
  echo "Checking ${deployment}"
  kubectl -n ${namespace} rollout status ${deployment}
done