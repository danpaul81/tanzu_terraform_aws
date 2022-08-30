This terraform script deploys a bootstrap vm in AWS EC2 and then deploys a Tanzu Community Edition (TCE) Management Cluster and a TCE Guest Cluster

It also places customized yaml spec files on the bootstrap node to deploy px-enterprise


## 1. create Cloud Formation Stack
If it not already exists you need to create a Tanzu cloud formation stack "tkg-cloud-vmware-com" in your AWS Account 

`aws cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM --stack-name tkg-cloud-vmware-com --template-body file://cloud-formation.json`

If this not exists deployment will fail.

## 2. check you role permissions
The role which credentials are used in the .tfvars file should have the following permissions
* AmazonEC2FullAccess
* AmazonVPCFullAccess
* a user-defined permission allowing "ec2:DescribeInstanceTypeOfferings" and "ec2:DescribeInstanceTypes"
* controllers.tkg.cloud.vmware.com 
* control-plane.tkg.cloud.vmware.com 
* nodes.tkg.cloud.vmware.com 

## 3. Create custom .tfvars file
Minimum needed options in .tfvars:

```
access_key = "YOUR_AWS_ACCESS_KEY"
secret_access_key = "YOUR_SECRET_AWS_KEY"
deploy_key = "existing AWS key pair name"
name_prefix = "naming prefix for all elements"
```

## 4. Run terraform
`terraform init`

`terraform plan -var-file .yourvarfile`

`terraform apply -var-file .yourvarfile`

when finished you can ssh into the bootstrap VM (for IP see terraform output)

Deployment of management & guest cluster will take some time

You can follow the deployment in `*-tce-mgmt.log` and `*-tce-guest.log` files. When init script is finished a file named `complete` will be created. 

Now you can create the portworx cluster. Sample yaml specs including your aws credentials (to create cloud drives) are placed in the home directory

## 5. Destroy Infrastructure
Before running `terrform destroy` you need to login to the bootstrap node and run the `delete-all-tanzu.sh` script. 

This deletes the Tanzu Guest/Management Cluster, removes all Tanzu created AWS elements (e.g. Loadbalancer) and the EBS portworx cloud drives.
