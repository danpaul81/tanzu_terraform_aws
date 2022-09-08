#cloud-config
write_files:
  - content: |
      [default]
      aws_access_key_id = ${tpl-access-key}
      aws_secret_access_key = ${tpl-secret-access-key}
    path: /home/ec2-user/.aws/credentials
    permissions: '0600'
  - content: |
      #!/bin/bash
      export PATH=$PATH:/usr/local/bin
      # create portworx ns
      kubectl create namespace portworx
      # install operator
      kubectl apply -f /home/ec2-user/portworx-operator.yaml
      # wait for operator pod ready
      while ! kubectl wait --for=condition=ready pod -lname=portworx-operator -n kube-system; do
        sleep 2 
      done
      # install portworx spec
      kubectl apply -f /home/ec2-user/portworx-spec.yaml
      # wait for portworx stc ready
      while ! kubectl wait stc ${tpl-px-clustername} -nportworx --for=jsonpath='{.status.phase}'=Online; do
        sleep 2
      done
      #install license
      export license="${tpl-license}"
      if [ ! -z $license ]; then
       kubectl exec -n portworx --context $1 -it $(kubectl get pods -n portworx -lname=portworx --context $1 --field-selector=status.phase=Running | tail -1 | cut -f 1 -d " ") -- /opt/pwx/bin/pxctl license activate  ${tpl-license}
      fi
    path: /home/ec2-user/install_px.sh
    permissions: '0700'
  - content: |
      [default]
      region = ${tpl-region}
    path: /home/ec2-user/.aws/config
    permissions: '0600'
  # this is the tanzu delete script which will be placed on node
  - content: |
      #!/bin/bash
      export AWS_ACCESS_KEY_ID=${tpl-access-key}
      export AWS_SECRET_ACCESS_KEY=${tpl-secret-access-key}
      export AWS_REGION=${tpl-region}
      
      # delete all deployed guest clusters and wait until finished
      echo "deleting all guest cluster(s). this can take more than 5min"
      for cluster in $(tanzu cluster list -o json |jq -r '.[] | .name'); do
        tanzu cluster delete $${cluster} -y
      done
      
      COUNT=$(tanzu cluster list -o json |jq -r '.[] | .name'| wc -l)
      while [[ $COUNT != 0 ]]; do
        #tanzu cluster list -o json |jq -r '.[] | .name, .status'
        echo "still $COUNT cluster(s) online, wait 30 sec. You can check details with 'tanzu cluster list'"
        sleep 30
        COUNT=$(tanzu cluster list -o json |jq -r '.[] | .name'| wc -l)
      done
      echo "guest cluster(s) deleted."
      echo "deleting mangement cluster"
      tanzu management-cluster delete ${tpl-mgmt-name} -y
      # delete all non-attached px volumes with tag PWX_CLUSTER_ID / ${tpl-px-clustername}
      VOLUMES=$(aws ec2 describe-volumes --filters Name=status,Values=available Name=tag:PWX_CLUSTER_ID,Values=${tpl-px-clustername} --query 'Volumes[*].{a:VolumeId}' --output text)
      for i in $VOLUMES; do
        aws ec2 delete-volume --volume-id $i
      done
    path: /home/ec2-user/delete-all-tanzu.sh
    permissions: '0700'
  # this is the management cluster config yaml file
  - content: |
%{ for line in tpl-management-config-yaml ~}
      ${line}
%{ endfor ~}
    path: /home/ec2-user/management-cluster-config.yaml
    permissions: '0600'
  # this is the guest cluster config yaml file
  - content: |
%{ for line in tpl-guest-config-yaml ~}
      ${line}
%{ endfor ~}
    path: /home/ec2-user/guest-cluster-config.yaml
    permissions: '0600'
  # this is the management cluster creation script
  - content: |
     #!/bin/bash
     export PATH=$PATH:/usr/local/bin
     /usr/local/bin/tanzu management-cluster create ${tpl-mgmt-name} -f /home/ec2-user/management-cluster-config.yaml -v6 --log-file /home/ec2-user/${tpl-mgmt-name}.log
     echo "Access to mgmt cluster: kubectl config use-context ${tpl-mgmt-name}-admin@${tpl-mgmt-name}" >> /home/ec2-user/README.txt
    path: /home/ec2-user/create_mgmt_cluster.sh
    permissions: '0700'
  # this is the guest cluster creation script
  - content: |
     #!/bin/bash
     export PATH=$PATH:/usr/local/bin
     
     /usr/local/bin/tanzu cluster create ${tpl-guest-name}-1 -f /home/ec2-user/guest-cluster-config.yaml -v6 --log-file /home/ec2-user/${tpl-guest-name}-1.log
     /usr/local/bin/tanzu cluster kubeconfig get ${tpl-guest-name}-1 --admin
     
     /usr/local/bin/tanzu cluster create ${tpl-guest-name}-2 -f /home/ec2-user/guest-cluster-config.yaml -v6 --log-file /home/ec2-user/${tpl-guest-name}-2.log
     /usr/local/bin/tanzu cluster kubeconfig get ${tpl-guest-name}-2 --admin
     
     #/usr/local/bin/kubectl config use-context ${tpl-guest-name}-admin@${tpl-guest-name}
     echo "Access to guest cluster: kubectl config use-context ${tpl-guest-name}-admin@${tpl-guest-name}" >> /home/ec2-user/README.txt
    path: /home/ec2-user/create_guest_clusters.sh
    permissions: '0700'
  # this is the portworx cluster spec yaml file
  - content: |
%{ for line in tpl-portworx-spec-yaml ~}
      ${line}
%{ endfor ~}
    path: /home/ec2-user/portworx-spec.yaml
    permissions: '0600'
    # this is the portworx operator yaml file
  - content: |
%{ for line in tpl-portworx-operator-yaml ~}
      ${line}
%{ endfor ~}
    path: /home/ec2-user/portworx-operator.yaml
    permissions: '0600'

runcmd:
- yum install docker jq -y
- systemctl enable docker
- systemctl start docker
- curl -LO https://dl.k8s.io/release/v1.24.3/bin/linux/amd64/kubectl
- install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
- usermod -aG docker ec2-user
# setup pxctl
- curl -sL https://github.com/portworx/pxc/releases/download/v0.33.0/pxc-v0.33.0.linux.amd64.tar.gz | tar xvz -C /tmp
- curl -so /usr/local/bin/pxc-pxctl https://raw.githubusercontent.com/portworx/pxc/master/component/pxctl/pxc-pxctl
- mv /tmp/pxc/kubectl-pxc /usr/bin
- chmod +x /usr/local/bin/pxc-pxctl
- echo "alias pxctl='kubectl pxc pxctl'" >>/home/ec2-user/.bash_profile
- echo "alias k=kubectl" >>/home/ec2-user/.bash_profile
# setup storkctl
#- stork_image=$(curl -sk https://install.portworx.com/$px_version?comp=stork | awk '/image: openstorage.stork/{print$2}')
#- id=$(docker create $stork_image)
#- docker cp $id:/storkctl/linux/storkctl /usr/bin
# download tce
- wget https://github.com/vmware-tanzu/community-edition/releases/download/v0.12.1/tce-linux-amd64-v0.12.1.tar.gz -P /home/ec2-user/
- tar xzvf /home/ec2-user/tce-linux-amd64-v0.12.1.tar.gz -C /home/ec2-user/
- chown -R ec2-user.ec2-user /home/ec2-user
- sudo -u ec2-user /usr/bin/kubectl-pxc config cluster set --portworx-service-namespace=portworx
- sudo -u ec2-user /home/ec2-user/tce-linux-amd64-v0.12.1/install.sh
- sudo -u ec2-user /usr/local/bin/tanzu init
- sudo -u ec2-user /home/ec2-user/create_mgmt_cluster.sh
- sudo -u ec2-user /home/ec2-user/create_guest_clusters.sh
- sudo -u ec2-user /home/ec2-user/install_px.sh
#- sudo -u ec2-user /usr/local/bin/kubectl apply -f /home/ec2-user/portworx-operator.yaml
#- sudo -u ec2-user /usr/local/bin/kubectl apply -f /home/ec2-user/portworx-spec.yaml
- sudo -u ec2-user touch /home/ec2-user/complete
#tanzu management-cluster permissions aws set -f ./config.yaml  -> these roles should be applied to userrole