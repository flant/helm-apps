all: deps
deps:
	werf helm dependency update charts/helm-apps
	werf helm dependency update .helm