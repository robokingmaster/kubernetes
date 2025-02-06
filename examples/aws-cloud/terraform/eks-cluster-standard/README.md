# Terraform resources For EKS
Make sure you have awscli, kubectl, helm, terraform and eksctl installed. Follow https://eksctl.io/installation/ for eksctl installation. You can also use brebacked docker image from robokingmaster/environments:devops

### Creating EKS Cluster
Modify values in variables.tf files as per your need and run below command

```
root@860a6e96415c:/# terraform init
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/helm...
- Finding hashicorp/time versions matching "~> 0.9"...
- Finding hashicorp/cloudinit versions matching "~> 2.3.5"...
- Finding hashicorp/aws versions matching "~> 5.75"...
- Finding hashicorp/random versions matching "~> 3.6.1"...
- Finding hashicorp/tls versions matching "~> 3.0"...
- Installing hashicorp/aws v5.82.2...
- Installed hashicorp/aws v5.82.2 (signed by HashiCorp)
- Installing hashicorp/random v3.6.3...
- Installed hashicorp/random v3.6.3 (signed by HashiCorp)
- Installing hashicorp/tls v3.4.0...
- Installed hashicorp/tls v3.4.0 (signed by HashiCorp)
- Installing hashicorp/helm v2.17.0...
- Installed hashicorp/helm v2.17.0 (signed by HashiCorp)
- Installing hashicorp/time v0.12.1...
- Installed hashicorp/time v0.12.1 (signed by HashiCorp)
- Installing hashicorp/cloudinit v2.3.5...
- Installed hashicorp/cloudinit v2.3.5 (signed by HashiCorp)
...
root@860a6e96415c:/#

root@860a6e96415c:/# terraform plan

root@860a6e96415c:/# terraform apply --auto-approve
```
After completion of above command our cluster would have been ready!!

### Deploy Metrics Server
Reference: https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html

#### Deploy with AWS console
1) Open your EKS cluster in the AWS console
2) From the "Add-ons" tab, select Get More Add-ons.
3) From the "Community add-ons" section, select Metrics Server and then Next

EKS determines the appropriate version of the add-on for your cluster. You can change the version using the Version dropdown menu.

Select Next and then Create to install the add-on.

#### Deploy the Metrics Server with the following command:
Now can now deploy Metrics Server as a community add-on using the AWS console or Amazon EKS APIs. These manifest install instructions will be archived.
```
root@860a6e96415c:/# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

root@860a6e96415c:/# kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           6m

root@860a6e96415c:/# kubectl top nodes
```

### Deploy ALB For EKS
Created cluster does not have alb configured by default. To configure ALB follow below steps.

Get EKS cluster IODC details.
Can be seen in cluster details section or by below cli command
```
root@860a6e96415c:/# aws eks describe-cluster --name eks10101-cc6778 --query "cluster.identity.oidc.issuer" --output text
https://oidc.eks.us-east-2.amazonaws.com/id/B08F9A9DXXXXXXXXXX456E6D23E1566

root@860a6e96415c:/# aws iam list-open-id-connect-providers | grep B08F9A9DXXXXXXXXXX456E6D23E1566
"Arn": "arn:aws:iam::xxxxxxxxx:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/B08F9A9DXXXXXXXXXX456E6D23E1566"

root@860a6e96415c:/#
```

Create ALB Controller IAM Policy using https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

**** Please download and review it before using it ****
```
root@860a6e96415c:/# curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

root@860a6e96415c:/# aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

```

Create service accounts
```
root@860a6e96415c:/# eksctl create iamserviceaccount \
    --cluster=eks10101-cc6778 \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn=arn:aws:iam::xxxxxx:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve
```
Make sure Policy AWSLoadBalancerControllerIAMPolicy and role AmazonEKSLoadBalancerControllerRole with attached policy exist as per below trus relationship if not then we can create it manually.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::xxxxxx:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/B08F9A9DXXXXXXXXXX456E6D23E1566"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-2.amazonaws.com/id/B08F9A9DXXXXXXXXXX456E6D23E1566:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-2.amazonaws.com/id/B08F9A9DXXXXXXXXXX456E6D23E1566:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
```


Deploy aws-load-balancer-controller on EKS Cluster Using Helm Chart
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks10101-cc6778 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

root@860a6e96415c:/# kubectl get pods -n kube-system | grep load
aws-load-balancer-controller-d4795c848-559k7   1/1     Running   0          25h
aws-load-balancer-controller-d4795c848-5mmzw   1/1     Running   0          25h
root@860a6e96415c:/#
```

Testing AWS Load Balancer 

Before deploying below sample application make sure you have valid hosted zone in AWS and a valid certificate. Replace example.com in redapp.example.com with valid domain as well.

We can deploy a sample application as below. Replace valid AWS certificate ARN with <ACM-SSL Certificate ARN> in deployment file.

```
root@860a6e96415c:/# kubectl apply -f https://github.com/robokingmaster/kubernetes/blob/main/examples/complete/colorapp-ssl-complete.yaml

root@860a6e96415c:/# kubectl get ingress --all-namespaces
NAMESPACE   NAME                CLASS   HOSTS                  ADDRESS                                                          PORTS   AGE
red-app     red-app-ingress     alb     redapp.example.com     k8s-frontend-xxxxxxxxxxx-21345432133.us-east-2.elb.amazonaws.com   80      6m7s
root@860a6e96415c:/#
```

Make sure Route53 DNA A Record is pointing to right application loadbalancer in above case it is dualstack.k8s-frontend-xxxxxxxxxxx-21345432133.us-east-2.elb.amazonaws.com.

You should be able to browse https://redapp.example.com to confirm the successful deployments.

