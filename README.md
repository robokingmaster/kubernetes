# Kubernetes Examples And Samples
#### Treafik unsecure communication configuration
```sh
containers:
- name: traefik
    image: docker.io/traefik:v3.2.2
    args:
    - '--entryPoints.metrics.address=:9100/tcp'
    - '--entryPoints.traefik.address=:8080/tcp'
    - '--entryPoints.web.address=:8000/tcp'
    - '--entryPoints.websecure.address=:8443/tcp'
    - '--api.dashboard=true'
    - '--ping=true'
    - '--providers.kubernetescrd'
    - '--providers.kubernetescrd.allowEmptyServices=true'
    - '--providers.kubernetesingress'
    - '--providers.kubernetesingress.allowEmptyServices=true'
    - '--entryPoints.websecure.http.tls=false'
    - '--log.level=DEBUG'
    - '--api.insecure=true'
```