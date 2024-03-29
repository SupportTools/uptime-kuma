#!/bin/bash -x

CPWD=$(pwd)

help() {

  echo "Build Script
  Usage: build.sh -b DRONE_BUILD_NUMBER -e Environment
  All flags are optional
  -b    Drone build number (10)
  -e    Environment (dev|production)"

}

while getopts ":b:r:e:h" opt; do
  case $opt in
    b)
      DRONE_BUILD_NUMBER="${OPTARG}"
      ;;
    r)
      RELEASE="${OPTARG}"
      ;;
    e)
      Environment="${OPTARG}"
      ;;
    h)
      help && exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
    *)
      help && exit 0
  esac
done

if [[ -z $RELEASE ]]
then
  echo "Release must be set"
  exit 0
fi

echo "::Info::"
echo "Environment: $Environment"
echo "Release: $RELEASE"
echo "Build Number: $DRONE_BUILD_NUMBER"

echo "Setting up SSH..."
mkdir -p ~/.ssh
echo "$SSH_KEY" > ~/.ssh/id_rsa.bin
cat ~/.ssh/id_rsa.bin | base64 -d > ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "Find and replace values..."
sed -i "s|RELEASE|${RELEASE}|g" ./chart/uptime-kuma/Chart.yaml
sed -i "s|RELEASE|${RELEASE}|g" ./chart/uptime-kuma/values.yaml
sed -i "s|DRONE_BUILD_NUMBER|${DRONE_BUILD_NUMBER}|g" ./chart/uptime-kuma/Chart.yaml
sed -i "s|DRONE_BUILD_NUMBER|${DRONE_BUILD_NUMBER}|g" ./chart/uptime-kuma/values.yaml

echo "Packaging helm chart..."
helm package ./chart/uptime-kuma/ --version $RELEASE --app-version $DRONE_BUILD_NUMBER

echo "Pulling down chart repo..."
mkdir -p /drone/helm-repo
cd /drone/helm-repo
if [[ ${Environment} == "production" ]]
then
  git clone --verbose --progress git@github.com:SupportTools/helm-chart.git .
elif [[ ${Environment} == "dev" ]]
then
  git clone --verbose --progress git@github.com:SupportTools/helm-chart-dev.git .
else
  echo "Unknown Environment"
fi

echo "Copying package into repo..."
cp ${CPWD}/uptime-kuma-*.tgz .

echo "Reindexing repo..."
if [[ ${Environment} == "production" ]]
then
  helm repo index --url https://charts.support.tools/ --merge index.yaml .
elif [[ ${Environment} == "dev" ]]
then
  helm repo index --url https://charts-dev.support.tools/ --merge index.yaml .
else
  echo "Unknown Environment"
fi

echo "Publishing to Chart repo..."
git add .
git commit -m "Publishing uptime-kuma ${RELEASE}"
git push