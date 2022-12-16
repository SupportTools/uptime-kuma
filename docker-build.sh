#!/bin/sh

echo "Setting docker environment"
if ! docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
then
    echo "Docker login failed"
    exit 128
fi

echo "Building..."
if ! docker build -t supporttools/uptime-kuma:${DRONE_BUILD_NUMBER} --cache-from supporttools/uptime-kuma:latest -f Dockerfile .
then
    echo "Docker build failed"
    exit 127
fi

echo "Pushing..."
if ! docker push supporttools/uptime-kuma:${DRONE_BUILD_NUMBER}
then
    echo "Docker push failed"
    exit 126
fi
echo "Tagging to latest and pushing..."
if ! docker tag supporttools/uptime-kuma:${DRONE_BUILD_NUMBER} supporttools/uptime-kuma:latest
then
    echo "Docker tag failed"
    exit 123
fi

echo "Pushing latest..."
if ! docker push supporttools/uptime-kuma:latest
then
    echo "Docker push failed"
    exit 122
fi