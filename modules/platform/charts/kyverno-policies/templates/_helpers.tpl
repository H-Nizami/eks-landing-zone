{{- define "kyverno-policies.common" -}}
validationActions:
  - {{ .Values.validationAction }}
evaluation:
  background:
    enabled: true
matchConstraints:
  namespaceSelector:
    matchExpressions:
      - key: kubernetes.io/metadata.name
        operator: NotIn
        values: {{ toJson .Values.excludedNamespaces }}
  resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
autogen:
  podControllers:
    controllers: ["deployments", "statefulsets", "daemonsets", "jobs", "cronjobs"]
variables:
  - name: containers
    expression: "object.spec.containers + object.spec.?initContainers.orValue([])"
{{- end -}}
