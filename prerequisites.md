# Prerequisites for EKS

## Tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) (check [version release](https://github.com/kubernetes/kubectl/releases))
- [eksctl](https://eksctl.io/introduction/#installation) (check [version release](https://github.com/weaveworks/eksctl/releases))
- [jq](https://stedolan.github.io/jq/download/)
- [yq](https://mikefarah.gitbook.io/yq/#install)

## Settings

- [Set AWS Profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) (with [minimum IAM policies](https://eksctl.io/usage/minimum-iam-policies/))

  ```bash
  # Check your profile
  aws sts get-caller-identity
  ```
