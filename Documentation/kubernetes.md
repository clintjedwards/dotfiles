> Deploy rolling update without having to make a change beforehand.

```bash
kubectl patch deployment web -p \
  "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"date\":\"`date +'%s'`\"}}}}}"
```

> Change an annotation for a specific pod

```bash
kubectl annotate pods some-service-7cc68b4776-4v2sn prometheus.io/path='/metrics'
```

> google logging

```bash
resource.type="k8s_container"
resource.labels.container_name="container-name-here"
```

> fortio

```
fortio load -t 500s https://url
```

> Deploy with kustomize

```bash
kubectl kustomize <folder>
```
