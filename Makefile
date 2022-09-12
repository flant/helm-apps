all: deps
deps:
	werf helm dependency update charts/helm-apps
	werf helm dependency update tests/.helm
save_tests:
	cd tests; werf render --set "global._includes.apps-defaults.enabled=true" --env=prod --dev | sed '/werf.io\//d' > test_render.yaml
