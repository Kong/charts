{{- /* Validate 'expressions' router flavor is not used with KIC < 2.10 as it's not supported */}}
{{- if and .Values.ingressController.enabled
           (eq .Values.env.router_flavor "expressions")
           (semverCompare "< 2.10" (include "kong.effectiveVersion" .Values.ingressController.image))
-}}
    {{- fail (printf `
❌ Error!

"kong/kong" chart in version 2.32.0 has introduced "env.router_flavor" value defaulting to "expressions".
"expressions" router flavor is not supported with Kong Ingress Controller %q that you're using.

✅ How to fix it (alternatives)

1. Upgrade to Kong Ingress Controller 3.0 to use this feature.

2. If you want to keep using your Kong Ingress Controller version, set "env.router_flavor" to "traditional" to
backoff to the previous router flavor in your values.yaml:

env:
  router_flavor: "traditional"` .Values.ingressController.image.tag  ) -}}
{{- end -}}

{{- /* Validate that when 'expressions' router flavor is used with KIC < 3.0, feature flag must be set. */ -}}
{{- if and (.Values.ingressController.enabled)
           (eq .Values.env.router_flavor "expressions")
           (not (contains "ExpressionRoutes=true" (default "" .Values.ingressController.env.feature_gates)))
           (semverCompare "< 3.0" (include "kong.effectiveVersion" .Values.ingressController.image)) -}}
    {{- fail (printf `
❌ Error!

"kong/kong" chart in version 2.32.0 has introduced "env.router_flavor" value defaulting to "expressions".
"expressions" router flavor is not supported with Kong Ingress Controller %q that you're using.

✅ How to fix it (alternatives)

1. Upgrade to Kong Ingress Controller 3.0 to use this feature.

2. Set "ingressController.env.feature_gates" to "ExpressionRoutes=true" to enable this feature in your values.yaml:

ingressController:
  env:
    feature_gates: "ExpressionRoutes=true"

3. Set "env.router_flavor" to "traditional" to use the previous router flavor in your values.yaml:

env:
  router_flavor: "traditional"` .Values.ingressController.image.tag) -}}
{{- end -}}
