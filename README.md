# Store Delivery on AKS

A DevOps portfolio project for a containerized store. The storefront routes orders to a Node.js API and catalog requests to a Rust API. RabbitMQ buffers new orders. The Go makeline service processes the queue and stores order state in DocumentDB. A separate admin UI exposes the catalog and order operations.

| Path | Purpose |
| --- | --- |
| `docker-compose.yml` | Build and run the application locally from source |
| `kustomize/overlays/portfolio` | Deploy the store with internal Kubernetes services |
| `infra/terraform`, `infra/bicep` | Azure infrastructure options for AKS and managed integrations |
| `.github/workflows/validate.yml` | Validate service exposure, block committed secrets, report dependency advisories and smoke-test the Compose deployment |

## Run locally

```sh
docker compose up --build --wait
bash scripts/smoke-test.sh
docker compose down
```

Open the storefront at http://127.0.0.1:8080 and the admin UI at http://127.0.0.1:8081 while Compose is running. The smoke test requires Bash, curl and jq. Enable the `simulation` profile for synthetic orders. Enable the `ai` profile only after configuring the sample AI service.

## Deploy to a test AKS cluster

Connect kubectl to the intended test cluster, then run the following commands.

```sh
kubectl create namespace store --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k kustomize/overlays/portfolio
kubectl -n store rollout status deployment/store-front --timeout=5m
kubectl -n store rollout status deployment/store-admin --timeout=5m
kubectl -n store port-forward service/store-front 8080:80
```

In a second terminal, run `kubectl -n store port-forward service/store-admin 8081:80`. Port forwarding binds to loopback by default. The overlay consumes published Microsoft sample images from the upstream base. To deploy changes from this repository, build and publish the service images to your own registry and override the image references in the overlay before applying it.

For an Azure Container Registry release, first grant the test cluster pull access to the registry and sign Docker in with the Azure CLI. Run the following from a clean checkout using Bash and standalone Kustomize. Set the login server to the registry you control.

~~~sh
registry=myregistry.azurecr.io
tag=$(git rev-parse --short=12 HEAD)
for service in order-service makeline-service product-service store-front store-admin; do
  image="$registry/$service:$tag"
  docker build --tag "$image" "src/$service" && docker push "$image" || exit 1
  (cd kustomize/overlays/portfolio &&
    kustomize edit set image "ghcr.io/azure-samples/aks-store-demo/$service=$image") || exit 1
done
kubectl apply -k kustomize/overlays/portfolio
~~~

Keep the rendered manifest or its image digests with each release. Restore the previous release's image references and reapply the overlay to roll back the application.

The overlay uses the sample RabbitMQ and DocumentDB configuration with demo credentials and ephemeral data. Use an isolated cluster for this profile. Before a shared or production deployment, configure workload identities and managed data services, enforce network and identity controls, and add authentication and TLS for any exposed UI. The infrastructure samples and Azure Developer CLI configurations are available for adapting to a dedicated subscription.

## Troubleshooting

- If a UI is unhealthy in Compose, run `docker compose ps` and inspect the UI and API logs using `docker compose logs`.
- If orders are delayed, check RabbitMQ and makeline logs and confirm DocumentDB readiness before restarting services.
- If a Kubernetes rollout stalls, run `kubectl -n store get pods`, inspect events with `kubectl -n store describe pod <pod>` and review logs using `kubectl -n store logs deployment/<service>`.
- To remove demo workloads, use `kubectl delete -k kustomize/overlays/portfolio`. If you provisioned a standalone Azure environment, decommission it using the same IaC configuration after checking the target subscription.

## License

Adapted from [Microsoft AKS Store Demo](https://github.com/Azure-Samples/aks-store-demo). See [LICENSE.md](LICENSE.md) for the original MIT license and copyright notice.
