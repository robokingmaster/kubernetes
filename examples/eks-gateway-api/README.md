### Configuring Gatwateway API

Make sure gatway api calss has been configured in cluster
```
cloudshell:$ kubectl get gatewayclass
NAME                               CONTROLLER                  ACCEPTED   AGE
gke-l7-global-external-managed     networking.gke.io/gateway   True       26h
gke-l7-gxlb                        networking.gke.io/gateway   True       26h
gke-l7-regional-external-managed   networking.gke.io/gateway   True       26h
gke-l7-rilb                        networking.gke.io/gateway   True       26h
cloudshell:$ 
```

Make Sure DNS Authorized SSL Certificate Created with valid domain name
```
cloudshell:$ gcloud certificate-manager certificates list
NAME: example-ssl-cert
SUBJECT_ALTERNATIVE_NAMES: *.example.com
example.com
DESCRIPTION: 
SCOPE: 
EXPIRE_TIME: 2025-04-22 07:53:25 +00:00
CREATE_TIME: 2023-05-04 14:05:21 +00:00
UPDATE_TIME: 2023-05-05 13:45:04 +00:00

NAME: example-ssl-cert
SUBJECT_ALTERNATIVE_NAMES: example.com
*.example.com
DESCRIPTION: SSL Certificate DNS Authorized
SCOPE: 
EXPIRE_TIME: 2025-04-22 07:13:28 +00:00
CREATE_TIME: 2025-01-22 07:13:27 +00:00
UPDATE_TIME: 2025-01-22 07:13:27 +00:00
```

Create Certificate Map for wild card TLS Termination
```
gcloud certificate-manager maps create example-ssl-cert-map

gcloud certificate-manager maps entries create example-map-entry-wildcard \
    --map="example-ssl-cert-map" \
    --certificates="example-ssl-cert" \
    --hostname="*.example.net"
	
gcloud certificate-manager maps entries create example-map-entry-domian \
    --map="example-ssl-cert-map" \
    --certificates="example-ssl-cert" \
    --hostname="example.net"	
```

Make sure DNS record set is set for the Loadbalancer IP address.
```
gcloud dns record-sets create redapp.example.com \
    --rrdatas=<Load Balancer IP Address>  \
    --ttl=30 \
    --type=A \
    --zone=example-com-zone

gcloud dns record-sets list --zone="example-com-zone"    
```

Deploy Color App, Gateway API And HTTP Route
```
kubectl create -f colorapp-dedicated-ns.yaml

kubectl create -f create-gateway-ssl.yaml

kubectl create -f create-http-routes-host.yaml

```

Verify Deployments
```
kubectl get deployment -n red-app

kubectl describe gcpbackendpolicy -n red-app

kubectl describe httproutes redapp-route-external -n red-app

curl -I https://blueapp.gcpeislabs.net

```