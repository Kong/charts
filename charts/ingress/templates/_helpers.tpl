{{- define "ingressController.enforceGatewayRouterFlavorFor3_0AndUp" -}}
{{ $gatewayValues := .Subcharts.gateway.Values }}
{{ $controllerValues := .Subcharts.controller.Values }}
{{- if semverCompare ">=3.0.0" (include "kong.effectiveVersion" $controllerValues.ingressController.image ) -}}
  {{- if (not (eq $gatewayValues.env.router_flavor "expressions")) -}}
    {{- fail (printf "Can't use KIC v3.0+ with Gateway router flavor different than expressions (currently used: %s)" $gatewayValues.env.router_flavor) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
