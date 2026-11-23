# Contributing to Store Delivery on AKS

Use an issue to describe ordinary bugs or proposed changes. For security issues, see [the security policy](SECURITY.md).

Before opening a pull request, run the Compose smoke test and render the Kubernetes portfolio overlay:

~~~sh
docker compose up --build --wait
bash scripts/smoke-test.sh
docker compose down
kubectl kustomize kustomize/overlays/portfolio > store.yaml
ruby scripts/check-services.rb store.yaml
~~~

Describe the behavior change and any configuration or deployment impact in the pull request. Keep the upstream license notice with reused code.
