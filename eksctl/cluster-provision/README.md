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

    Then, create a new EC2 instance in the VPC where this EKS Cluster is in.  
    Install prerequistes and access to cluster.

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

> _**Notice.**_  
> _This step takes about 5 minutes._  
> _It includes that delete all things: from the EKS Cluster to the VPC_

```bash
eksctl delete cluster \
  --region=$(yq eval ".metadata.region" cluster-config.yaml) \
  --name=$(yq eval ".metadata.name" cluster-config.yaml)
```
