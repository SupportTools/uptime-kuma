#!/bin/bash

for pod in `kubectl -n uptime-kuma get pods -o go-template='{{ range  $item := .items }}{{ range .status.conditions }}{{ if (or (and (eq .type "PodScheduled") (eq .status "False")) (and (eq .type "Ready") (eq .status "False"))) }}{{ $item.metadata.name}} {{ end }}{{ end }}{{ end }}'`
do
  kubectl -n uptime-kuma delete pod $pod
done