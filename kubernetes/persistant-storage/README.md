## Example: How to create and use a Persistent Volume

### Step 1: Check your cluster’s storage classes
```
$ kubectl get storageclass
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  7d2h
```

### Step 2: Create a Persistent Volume
Copy the following PV Kubernetes manifest and save it to pv.yaml
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-pv
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  storageClassName: standard
  hostPath:
    path: /tmp/demo-pv
```

Run the following command to create your Persistent Volume:
```
$ kubectl apply -f pv.yaml
persistentvolume/demo-pv created
```

The PV will now exist in your cluster. It will show as Available as it’s unused and unclaimed:

```
$ kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
demo-pv   1Gi        RWO            Retain           Available           standard                113s
```

### Step 3: Create a Persistent Volume Claim
Create a PVC for your volume. Copy the following manifest to pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
  volumeName: demo-pv
```

```
$ kubectl apply -f pvc.yaml
persistentvolumeclaim/demo-pvc created
```

The PV will now show as Bound because it’s claimed by the PVC:
```
$ kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   REASON   AGE
demo-pv   1Gi        RWO            Retain           Bound    default/demo-pvc   standard                6m40s
```

### Step 4: Dynamically provisioning PVs
Static provisioning of PVs, as shown above, is cumbersome: you must create the PV, then the PVC while ensuring their properties match. You also have to supply the PV configuration data required by the storage provisioner.

Dynamic provisioning is simpler and the more popular option for real-world use. The PV is created for you based on your PVC’s configuration.

Copy the following manifest to pvc-dynamic.yaml:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

```
$ kubectl apply -f pvc-dynamic.yaml
persistentvolumeclaim/pvc-dynamic created

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   REASON   AGE
demo-pv                                    1Gi        RWO            Retain           Bound    default/demo-pvc      standard                33m
pvc-fd022049-eabf-415c-937a-94927c84ef6f   1Gi        RWO            Delete           Bound    default/pvc-dynamic   standard                
```

### Step 5: Attach PVCs to Pods
Once you’ve provisioned and bound your PV, it’s time to attach the PVC to a Pod. This will mount your PV into the Pod’s filesystem, allowing the Pod to read and write files with full persistence.

Copy the following manifest to pod.yaml:
```
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
    - name: pvc-pod-container
      image: nginx:latest
      volumeMounts:
        - mountPath: /data
          name: data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: pvc-dynamic
```
What’s happening here?

First, the spec.containers.volumeMounts field sets up a volume for the Pod called data. It’s mounted to /data within the Pod’s containers.
Next, the spec.volumes field defines the data volume as referring to the PVC called pvc-dynamic.
This results in the PV claimed by pvc-dynamic being mounted to /data inside the container.
Create your Pod, then try writing some files to /data:
```
$ kubectl apply -f pod.yaml
pod/pvc-pod created

# Get a shell inside the Pod
$ kubectl exec -it pod/pvc-pod -- bash

# No files in the volume yet
root@pvc-pod:/# ls /data

# Write a file to the volume
root@pvc-pod:/# echo "bar" > /data/foo

# The file now shows in the volume
root@pvc-pod:/# ls /data
foo
```
The files written to the volume are now stored independently of the Pod. You can delete the Pod and recreate it – your data will still be intact within the PV:

```
$ kubectl delete pod/pvc-pod
pod "pvc-pod" deleted

$ kubectl apply -f pod.yaml
pod/pvc-pod created

$ kubectl exec -it pod/pvc-pod -- bash

root@pvc-pod:/# cat /data/foo
bar
```
Similarly, you can simultaneously attach the PVC to additional Pods to share files between them.

### Persistent Volumes best practices
PVs and PVCs are sometimes confusing to newcomers. The terminology and lifecycle model are unique to Kubernetes, but the high level of abstraction provides great flexibility when configuring your storage.

Here are some best practices to follow.

- Always specify a storage class for your PVs. PVs without a storageClassName will use the default storage class in your cluster, which can cause unpredictable behavior if the value’s changed or not set.
- Anticipate future storage requirements. It’s usually beneficial to provision the largest amount of storage you think you’ll need. It’s not always possible to resize a volume after creation – your options will depend on the storage driver being used.
- Avoid static provisioning of Persistent Volumes. Statically provisioning and binding PVs increases the workload for administrators and can be more challenging to scale. Dynamic provisioning ensures usable PVs will be automatically created for your PVCs, simplifying the set up procedure.
- Select an appropriate reclaim policy. It’s vital to select the correct reclaim policy for each of your PVs. Consider using the Retain policy for critical data. It means you’ll need to manually delete the volume after it’s reclaimed, but ensures your data will be recoverable in the event of accidental deletion.
- Use RBAC to protect storage resources. Configure your cluster’s RBAC authorization policies to help protect your PVs and PVCs from accidental or malicious changes and deletions. Incorrect operations applied to storage objects are likely to cause irrecoverable data loss, unlike stateless Kubernetes object types, which you can rollback or recreate.