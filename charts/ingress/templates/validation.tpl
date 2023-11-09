{{- /* Validate 'expressions' router flavor is not used with KIC < 3.0 */}}
{{- if and .Values.controller.ingressController.enabled
           (eq .Values.gateway.env.router_flavor "expressions")
           (semverCompare "< 3.0" (include "kong.effectiveVersion" .Values.controller.ingressController.image))
-}}
    {{- fail (printf "expressions router flavor is not supported with ingress controller %s" .Values.controller.ingressController.image.tag ) -}}
{{- end -}}
