CLUSTER_PLAN: dev
NAMESPACE: default
CLUSTER_NAME: ${tpl-name}
CNI: antrea
CONTROL_PLANE_MACHINE_TYPE: t3.small
NODE_MACHINE_TYPE: t3.large
CONTROL_PLANE_MACHINE_COUNT: 1
WORKER_MACHINE_COUNT: 3
AWS_REGION: ${tpl-region}
AWS_NODE_AZ: ${tpl-az}
AWS_SSH_KEY_NAME: ${tpl-key}
AWS_PRIVATE_NODE_CIDR: ${tpl-cidr-sn-priv}
AWS_PRIVATE_SUBNET_ID: ${tpl-priv-subnet-id}
AWS_PUBLIC_NODE_CIDR: ${tpl-cidr-sn-pub}
AWS_PUBLIC_SUBNET_ID: ${tpl-pub-subnet-id}
AWS_VPC_CIDR: ${tpl-cidr-vpc}
AWS_VPC_ID: ${tpl-vpc}
BASTION_HOST_ENABLED: false
ENABLE_MHC: true
MHC_UNKNOWN_STATUS_TIMEOUT: 5m
MHC_FALSE_STATUS_TIMEOUT: 12m
ENABLE_AUDIT_LOGGING: false
ENABLE_DEFAULT_STORAGE_CLASS: true
CLUSTER_CIDR: 100.96.0.0/11
SERVICE_CIDR: 100.64.0.0/13
ENABLE_AUTOSCALER: false
ENABLE_CEIP_PARTICIPATION: "false"
INFRASTRUCTURE_PROVIDER: aws
OS_ARCH: amd64
OS_NAME: amazon
OS_VERSION: "2"
AWS_SECURITY_GROUP_BASTION: ${tpl-sg-bastion}
AWS_SECURITY_GROUP_NODE: ${tpl-sg-node}
AWS_SECURITY_GROUP_CONTROLPLANE: ${tpl-sg-controlplane}
AWS_SECURITY_GROUP_APISERVER_LB: ${tpl-sg-apiserver-lb}