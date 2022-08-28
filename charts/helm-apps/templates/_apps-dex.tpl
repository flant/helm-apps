{{- define "apps-dex-authenticators" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}

  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-dex-authenticators" "name" "apps-dex-authenticators") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-dex-authenticators.render" }}
{{- $ := . }}
{{- $_ := set $ "CurrentDexAuthenticator" $.CurrentApp }}
{{- with $.CurrentApp }}
{{- if not .applicationDomain }}
{{- fail (printf "Установлено значение enabled для не настроенного '%s' в %s DexAuthenticator!" $.CurrentApp.name "apps-dexauthenticators") }}
{{- end }}
apiVersion: deckhouse.io/v1
kind: DexAuthenticator
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  {{- $specDex := dict }}
  {{- $_ = set $specDex "Lists" ( list "whitelistSourceRanges" "tolerations" "allowedGroups") }}
  {{- $_ = set $specDex "Maps" (list "nodeSelector") }}
  {{- $_ = set $specDex "Strings" (list "applicationDomain" "applicationIngressCertificateSecretName" "applicationIngressClassName" "keepUsersLoggedInFor" "signOutURL" "sendAuthorizationHeader") }}
  {{- include "apps-utils.generateSpecs" (list $ . $specDex) | trim | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "apps-dex-clients" }}
  {{- $ := index . 0 }}
  {{- $RelatedScope := index . 1 }}
    {{- if not (kindIs "invalid" $RelatedScope) }}

  {{- $_ := set $RelatedScope "__GroupVars__" (dict "type" "apps-dex-clients" "name" "apps-dex-clients") }}
  {{- include "apps-utils.renderApps" (list $ $RelatedScope) }}
{{- end -}}
{{- end -}}

{{- define "apps-dex-clients.render" }}
{{- $ := . }}
{{- with $.CurrentApp }}
{{- $_ := set $ "CurrentDexClient" . }}
{{- if not .redirectURIs }}
{{- fail (printf "Установлено значение enabled для не настроенного '%s' в %s DexAuthenticator!" $.CurrentApp.name $.Chart.Name) }}
{{- end }}
apiVersion: deckhouse.io/v1alpha1
kind: DexClient
{{- include "apps-helpers.metadataGenerator" (list $ .) }}
spec:
  redirectURIs: {{ include "fl.value" (list $ . .redirectURIs) | nindent 2 }}
{{- end }}
{{- end }}
