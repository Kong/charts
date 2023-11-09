{{- /* Validate 'expressions' router flavor is not used with KIC < 2.10 as it's not supported */}}
{{- if and .Values.controller.ingressController.enabled
           (eq .Values.gateway.env.router_flavor "expressions")
           (semverCompare "< 2.10" (include "kong.effectiveVersion" .Values.controller.ingressController.image))
-}}
    {{- fail (printf `
⚠️ Warning!

"kong/ingress" chart in version 0.10.0 has introduced "gateway.env.router_flavor" value defaulting to "expressions".
"expressions" router flavor is not supported with Kong Ingress Controller %q that you're using.

✅ How to fix it (alternatives)

1. Upgrade to Kong Ingress Controller 3.0 to use this feature.

2. If you want to keep using your Kong Ingress Controller version, set "gateway.env.router_flavor" to "traditional" to
backoff to the previous router flavor in your values.yaml:

gateway:
  env:
    router_flavor: "traditional"` .Values.controller.ingressController.image.tag  ) -}}
{{- end -}}

{{- /* Validate that when 'expressions' router flavor is used with KIC < 3.0, feature flag must be set. */ -}}
{{- if and (.Values.controller.ingressController.enabled)
           (eq .Values.gateway.env.router_flavor "expressions")
           (not (contains "ExpressionRoutes=true" (default "" .Values.controller.ingressController.env.feature_gates)))
           (semverCompare "< 3.0" (include "kong.effectiveVersion" .Values.controller.ingressController.image)) -}}
    {{- fail (printf `
⚠️ Warning!

"kong/ingress" chart in version 0.10.0 has introduced "gateway.env.router_flavor" value defaulting to "expressions".
You're using Kong Ingress Controller version %q which supports this feature only when feature flag "ExpressionRoutes=true" is set.

✅ How to fix it (alternatives)

1. Upgrade to Kong Ingress Controller 3.0 to use this feature.

2. Set "controller.ingressController.env.feature_gates" to "ExpressionRoutes=true" to enable this feature in your values.yaml:

controller:
  ingressController:
    env:
      feature_gates: "ExpressionRoutes=true"

3. Set "gateway.env.router_flavor" to "traditional" to use the previous router flavor in your values.yaml:

gateway:
  env:
    router_flavor: "traditional"` .Values.controller.ingressController.image.tag) -}}
{{- end -}}
