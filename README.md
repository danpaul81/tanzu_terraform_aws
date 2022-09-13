This terraform script deploys a bootstrap vm in AWS EC2 and then deploys a Tanzu Community Edition (TCE) Management Cluster and two TCE Guest Clusters
It also installs portworx enterprise and deploys EBS Clouddrives to the guest clusters

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

In case you want the script to automatically prepare a clusterpair you'd also need to add

```
dr_bucket = "your S3 bucket"
px_license = "valid DR license key"
```

Important: S3 bucket must be in same region as your Deployment. Script will also use the same credentials to access S3 bucket

## 4. Run terraform
`terraform init`

`terraform plan -var-file .tfvars`

`terraform apply -var-file .tfvars`

when finished you can ssh into the bootstrap VM (for IP see terraform output)

Deployment of management & guest clusters will take some time (15min)

You can follow the deployment in `*-tce-mgmt.log` and `*-tce-guest-X.log` files. When init script is finished a file named `complete` will be created. 

If you want to create a clusterpair check (!) & execute the `setup_dr.sh`

## 5. Destroy Infrastructure
Login to the bootstrap node and run the `delete-all-tanzu.sh` script

This deletes the Tanzu Guest/Management Cluster, removes all Tanzu created AWS elements (e.g. Loadbalancer) and the EBS portworx cloud drives.

When finished logout of the bootstrap node and run `terraform destroy -var-file .tfvars`

When you use services consuming ELB the deletion of VPC might fail. Just delete ELB SGs manually and re-try `terraform destroy -var-file .tfvars`


