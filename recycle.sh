#!/bin/bash

echo "Looking for failed or crashing pods"
for pod in `kubectl get pods -l app=uptime-kuma -o go-template='{{ range  $item := .items }}{{ range .status.conditions }}{{ if (or (and (eq .type "PodScheduled") (eq .status "False")) (and (eq .type "Ready") (eq .status "False"))) }}{{ $item.metadata.name}} {{ end }}{{ end }}{{ end }}'`
do
  kubectl delete pod $pod
done
echo "Done"