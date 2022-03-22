#!/bin/bash

echo "Looking for failed or crashing pods"
for pod in `kubectl -n uptime-kuma get pods -l app=uptime-kuma -o go-template='{{ range  $item := .items }}{{ range .status.conditions }}{{ if (or (and (eq .type "PodScheduled") (eq .status "False")) (and (eq .type "Ready") (eq .status "False"))) }}{{ $item.metadata.name}} {{ end }}{{ end }}{{ end }}'`
do
  kubectl -n uptime-kuma delete pod $pod
done
echo "Done"