provider "aws" {
	region 	= var.aws_region
	access_key = var.access_key
	secret_key = var.secret_access_key	
}


resource "aws_vpc" "main" {
	cidr_block	= var.aws_cidr_vpc
	enable_dns_hostnames	= true
	enable_dns_support		= true
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","vpc")
	}
}
 

resource "aws_subnet" "sn_private" {
	vpc_id 					=	aws_vpc.main.id
	cidr_block 				= 	var.aws_cidr_sn_private
	availability_zone 		= 	var.aws_az
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","sn-private")
		}
}		

resource "aws_subnet" "sn_public" {
	vpc_id 					=	aws_vpc.main.id
	cidr_block 				= 	var.aws_cidr_sn_public
	availability_zone 		= 	var.aws_az
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","sn-public")
		}
}		


resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","igw")
	}
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip_tce_nat.id
  subnet_id     = aws_subnet.sn_public.id

  tags = {
    	Name = format("%s-%s-%s",var.name_prefix,"tce","nat")
  }
  depends_on = [aws_internet_gateway.igw]
}

/*
resource "aws_default_route_table" "rt" {
	default_route_table_id = aws_vpc.main.default_route_table_id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
	depends_on = [aws_internet_gateway.igw]	
	tags = {
		Name = "default table"
	}
}
*/

resource "aws_route_table" "rt_public" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","rt-public")
	}  
}

resource "aws_route_table_association" "public" {
	subnet_id = aws_subnet.sn_public.id
	route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table" "rt_private" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_nat_gateway.nat.id
	}
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","rt-private")
	}
}

resource "aws_route_table_association" "private" {
	subnet_id = aws_subnet.sn_private.id
	route_table_id = aws_route_table.rt_private.id
}


#elastic ip for instance
resource "aws_eip" "eip_tce_bootstrap_node" {
	instance 	= aws_instance.tce_bootstrap_node.id
	vpc 		= true
	depends_on  = [aws_internet_gateway.igw]
}


#elastic ip for nat gateway
resource "aws_eip" "eip_tce_nat" {
	vpc 		= true
	depends_on  = [aws_internet_gateway.igw]
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"tce","eip-nat")
	}
}


# security group for bootstrap node
resource "aws_security_group" "sg_tce_bootstrap_node" {
	name 		= 	format("%s-%s",var.name_prefix,"sg-tce-bootstrap")
	description = 	"Allow TCP 22"
	//vpc_id		= 	var.aws_vpc_id
	vpc_id = aws_vpc.main.id
	ingress {
		description = "ssh"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = format("%s-%s-%s",var.name_prefix,"sg","sg-tce-bootstrap")
		}
}


# create management cluster config.yaml file with cloud provider details
resource "local_file" "tce_management_config_yaml" {
	content = templatefile("${path.module}/tanzu-management-cluster-config.tpl", { 
	tpl-credentials = base64encode(format("[default]\naws_access_key_id = %s\naws_secret_access_key = %s\nregion = %s\n\n", var.access_key, var.secret_access_key, var.aws_region))
	tpl-priv-subnet-id = aws_subnet.sn_private.id
	tpl-pub-subnet-id = aws_subnet.sn_public.id
	tpl-key = var.deploy_key
	tpl-vpc = aws_vpc.main.id
	tpl-region = var.aws_region
	tpl-az = var.aws_az
	tpl-cidr-sn-priv = var.aws_cidr_sn_private
	tpl-cidr-sn-pub = var.aws_cidr_sn_public
	tpl-cidr-vpc = var.aws_cidr_vpc
	tpl-name = format("%s-tce-mgmt",var.name_prefix)
	}
	)
	filename = "${path.module}/generated/tanzu-management-cluster-config.yaml"
}

# create guest cluster 1 config.yaml file 
resource "local_file" "tce_guest_config_yaml" {
	content = templatefile("${path.module}/tanzu-guest-cluster-config.tpl", { 
	#tpl-credentials = base64encode(format("[default]\naws_access_key_id = %s\naws_secret_access_key = %s\nregion = %s\n\n", var.access_key, var.secret_access_key, var.aws_region))
	tpl-priv-subnet-id = aws_subnet.sn_private.id
	tpl-pub-subnet-id = aws_subnet.sn_public.id
	tpl-key = var.deploy_key
	tpl-vpc = aws_vpc.main.id
	tpl-region = var.aws_region
	tpl-az = var.aws_az
	tpl-cidr-sn-priv = var.aws_cidr_sn_private
	tpl-cidr-sn-pub = var.aws_cidr_sn_public
	tpl-cidr-vpc = var.aws_cidr_vpc
	tpl-sg-bastion = aws_security_group.sg_tce_guest_bastion.id
	tpl-sg-node = aws_security_group.sg_tce_guest_node.id 
	tpl-sg-controlplane = aws_security_group.sg_tce_guest_controlplane.id
	tpl-sg-apiserver-lb =  aws_security_group.sg_tce_guest_apiserver-lb.id
	#tpl-name = format("%s-tce-guest-1",var.name_prefix)
	}
	)
	filename = "${path.module}/generated/tanzu-guest-cluster-config.yaml"
}

# re-read management_config.yaml file line-by line, remove line breaks and store in array
# template file will read each line and print with fitting spaces to keep resulting yaml valid
 locals {
	tce_management_config_yaml_lines = [
	for line in split("\n", local_file.tce_management_config_yaml.content):
	  chomp(line)
	 ]
 }

# re-read guest_config.yaml file line-by line, remove line breaks and store in array
# template file will read each line and print with fitting spaces to keep resulting yaml valid
 locals {
	tce_guest_config_yaml_lines = [
	for line in split("\n", local_file.tce_guest_config_yaml.content):
	  chomp(line)
	 ]
 }
 
# re-read portworx-spec.yaml file line-by line, remove line breaks and store in array
# template file will read each line and print with fitting spaces to keep resulting yaml valid
 locals {
	px_spec_yaml_lines = [
	for line in split("\n", local_file.px_spec_yaml.content):
	  chomp(line)
	 ]
 }

# re-read portworx-operator.yaml file line-by line, remove line breaks and store in array
# template file will read each line and print with fitting spaces to keep resulting yaml valid
 locals {
	px_operator_yaml_lines = [
	for line in split("\n", data.local_file.portworx_operator_yaml.content):
	  chomp(line)
	 ]
 }

resource "local_file" "px_spec_yaml" {
	content = templatefile("${path.module}/portworx-spec.tpl", { 
	tpl-access-key = var.access_key
	tpl-secret-access-key = var.secret_access_key
	tpl-px-clustername = format("%s-px-cluster",var.name_prefix)
	}
	)
	filename = "${path.module}/generated/portworx-spec-generated.yaml"
}

data "local_file" "portworx_operator_yaml" {
  filename = "${path.module}/portworx-operator.yaml"
}

locals {
	portworx_operator_yaml_lines = [
	for line in split("\n", data.local_file.portworx_operator_yaml.content):
	  chomp(line)
	 ]
 }


# create cloud-init file for bootstrap server on AWS
resource "local_file" "cloud_init_bootstrap_node" {
	content = templatefile("${path.module}/cloud-init-bootstrap-node.tpl", { 
	tpl-access-key = var.access_key
	tpl-secret-access-key = var.secret_access_key
	tpl-region = var.aws_region
	tpl-prefix = var.name_prefix
	tpl-license = var.px_license
	tpl-mgmt-name = format("%s-tce-mgmt",var.name_prefix)
	tpl-guest-name = format("%s-tce-guest",var.name_prefix)
	tpl-management-config-yaml = local.tce_management_config_yaml_lines
	tpl-guest-config-yaml = local.tce_guest_config_yaml_lines
	tpl-portworx-spec-yaml = local.px_spec_yaml_lines
	tpl-portworx-operator-yaml = local.portworx_operator_yaml_lines
	tpl-px-clustername = format("%s-px-cluster",var.name_prefix)
    }
	)
	filename = "${path.module}/generated/cloud-init-tce-bootstrap-node-generated.yaml"
	depends_on = [
	  local_file.tce_guest_config_yaml,
	  local_file.tce_management_config_yaml,
	  local_file.px_spec_yaml
	]
}

resource "aws_instance" "tce_bootstrap_node" {
	ami 					= 	var.aws_ami_image
	availability_zone 		= 	var.aws_az
	instance_type			=	var.aws_instance_type
	vpc_security_group_ids 	=	[aws_security_group.sg_tce_bootstrap_node.id]
	subnet_id				=	aws_subnet.sn_public.id
	source_dest_check		= 	false
	key_name = var.deploy_key
	root_block_device {
	  volume_size=16
	}
	user_data_base64 = base64gzip(local_file.cloud_init_bootstrap_node.content)
	tags = {
		Name = format("%s-%s",var.name_prefix,"tce-bootstrap")
	}
}

output "tce_bootstrap_node_aws_eip" {
	value = format("SSH using %s ssh key to ec2-user@%s",var.deploy_key,aws_eip.eip_tce_bootstrap_node.public_ip)
}
