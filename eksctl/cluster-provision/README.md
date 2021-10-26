# Cluster Provision Cheat Sheet using `eksctl`

## Snippets

```bash
# First, set profile
export AWS_PROFILE="my-profile"
# Second, work in this directory from root of project
cd eksctl/cluster-provision
```

### Prepare config file

1. Check settings:

   - [`vars.cluster.json`](./vars.cluster.json#L3-L5)
   - [`template.cluster-config.yaml`]((./template.cluster-config.yaml))

2. Execute `./write-cluster-config.sh`

#### References

- [EKS docs: Accessing a private only API server](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#private-access)
- [eksctl: ClusterConfig file schema support](https://eksctl.io/usage/schema/)

### Provision an EKS Cluster

1. Execute eksctl command:

    > _**Notice.**_  
    > _This step takes about 20 minutes._  
    > _It includes that create all things: from the VPC to the EKS Cluster_

    ```bash
    # Provision an EKS Cluster
    eksctl create cluster -f cluster-config.yaml
    ```

2. Check kubernetes config context of the provisioned cluster:

    ```bash
    # Check context
    kubectl config current-context

    # If not, update local .kube-config files
    eksctl utils write-kubeconfig \
      --region=$(yq eval ".metadata.region" cluster-config.yaml) \
      --cluster=$(yq eval ".metadata.name" cluster-config.yaml)
    
    # Check again
    kubectl config get-contexts
    ```

3. (option) Add identity to auth ConfigMap on other IAM User

    ```bash
    # Set target ARN
    export IAM_USER_ARN="arn:aws:iam::000077773333:user/USER_NAME"
    export MAP_USERNAME="admin-$(echo ${IAM_USER_ARN} | awk -F"/" '{print $2}')"

    # Check
    cat <<EOF

    * TARGET_CLUSTER_NAME : $(yq eval ".metadata.name" cluster-config.yaml)
    * IAM_USER_ARN : ${IAM_USER_ARN}
    * MAP_USERNAME : ${MAP_USERNAME}

    EOF
    ```

    ```bash
    # Add identity target AWS IAM ARN to EKS Auth ConfigMap
    eksctl create iamidentitymapping \
      --region=$(yq eval ".metadata.region" cluster-config.yaml) \
      --cluster=$(yq eval ".metadata.name" cluster-config.yaml) \
      --group system:masters \
      --arn ${IAM_USER_ARN} \
      --username ${MAP_USERNAME}

    # Check
    kubectl -n kube-system get cm/aws-auth -o json | jq -r ".data.mapUsers.groups"
    ```

4. (Option) Make EKS API Server Endpoint private only:

    > _**Notice.**_  
    > _This step takes about 12 minutes._

    ```bash
    eksctl utils update-cluster-endpoints \
      --region=$(yq eval ".metadata.region" cluster-config.yaml) \
      --cluster=$(yq eval ".metadata.name" cluster-config.yaml) \
      --private-access=true --public-access=false --approve
    ```

    - **Prepare bastion EC2 instance**

      Create a new EC2 instance in the VPC where this EKS Cluster is in.  
      If you choose [AL2(Amazon Linux 2) you can be easy to access with SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-install-ssm-agent.html).  
      Below bash scripts is user-data about SSM Agent to access EC2 Instance without SSH Key-pair.

      ```bash
      #!/bin/bash
      # SSM Agent
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      ```

      If ec2 instance is launched, then you need to install prerequistes and access to cluster.

    - **How can I access to private EKS cluster with authentication on token?**

      1. Check `eks.<region>.amazonaws.com`'s IP address

          ```bash
          # In bastion EC2 instance located in the VPC where EKS Cluster has been provisioned
          nslookup eks.ap-northeast-2.amazonaws.com
          # Like this...
          # Server:   10.0.0.2
          # Address:  10.0.0.2#53

          # Non-authoritative answer:
          # Name: eks.ap-northeast-2.amazonaws.com
          # Address: 3.35.154.95
          # Name: eks.ap-northeast-2.amazonaws.com
          # Address: 3.34.164.51  << Pick with copying
          ```

      2. Add below line in `/etc/hosts`

          ```bash
          # Edit with root permission
          sudo vi /etc/hosts
          ```

          ```bash
          # eks.ap-northeast-2.amazonaws.com
          3.34.164.51  eks.ap-northeast-2.amazonaws.com
          ```

          ```bash
          # Check
          cat vi /etc/hosts
          ```

      3. Set outbound rule of security group what has been attached to bastion EC2 instance

         | Port range | Protocol  | Destination         | Description                                          |
         | :--------- | :-------- | :------------------ | :--------------------------------------------------- |
         | 443        | TCP       | 3.34.164.51 (paste) | AWS CLI / EKS API / eks.ap-northeast-2.amazonaws.com |

      4. Then try to call below command

          - `aws s3 ls`: This command will be pending. Just an example for not allowed outbound traffics.
          - [`aws eks get-token`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/eks/get-token.html): This command will response generated token from private cluster. Then you can access with this token.
          - `kubectl get ns`: check kubernetest authentication is right state.

    - Read more: [Managing Access to the Kubernetes API Server Endpoints](https://eksctl.io/usage/vpc-networking/#managing-access-to-the-kubernetes-api-server-endpoints)

5. Check provisioned managed node group:

    ```bash
    kubectl get nodes -L position --sort-by=.metadata.labels.position
    ```

6. Set IdP federation for OIDC Provider associated with cluster:

    ```bash
    # Manual federation
    eksctl utils associate-iam-oidc-provider --approve \
      --region=$(yq eval ".metadata.region" cluster-config.yaml) \
      --cluster=$(yq eval ".metadata.name" cluster-config.yaml)
    ```

    - Read more: [How to find the federated OIDC Provider?](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)

### Clean up

#### Uninstall all helm charts

```bash
# Current Helm Charts
helm list -A

# Remove All Charts
helm list -A |grep -v NAME |awk -F" " '{print "helm -n "$2" uninstall "$1}' |xargs -I {} sh -c '{}'

# Check Empty
helm list -A
```

#### Delete EKS Cluster

> _**Notice.**_  
> _This step takes about 5 minutes._  
> _It includes that delete all things: from the EKS Cluster to the VPC_

```bash
eksctl delete cluster \
  --region=$(yq eval ".metadata.region" cluster-config.yaml) \
  --name=$(yq eval ".metadata.name" cluster-config.yaml)
```

The `eksctl` work automatically remove local kube-config data.
