kind: StorageCluster
apiVersion: core.libopenstorage.org/v1
metadata:
  name: ${tpl-px-clustername}
  namespace: portworx
  annotations:
spec:
  image: portworx/oci-monitor:2.11.1
  imagePullPolicy: Always
  kvdb:
    internal: true
  cloudStorage:
    deviceSpecs:
    - type=gp2,size=150
    kvdbDeviceSpec: type=gp2,size=150
  secretsProvider: k8s
  stork:
    enabled: true
    args:
      webhook-controller: "true"
  autopilot:
    enabled: true
  csi:
    enabled: true
  monitoring:
    prometheus:
      enabled: true
      exportMetrics: true
  env:
  - name: "AWS_ACCESS_KEY_ID"
    value: "${tpl-access-key}"
  - name: "AWS_SECRET_ACCESS_KEY"
    value: "${tpl-secret-access-key}"