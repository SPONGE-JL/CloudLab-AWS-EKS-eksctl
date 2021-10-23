# Prerequisites for EKS

## Tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) (check [version release](https://github.com/kubernetes/kubectl/releases))
- [eksctl](https://eksctl.io/introduction/#installation) (check [version release](https://github.com/weaveworks/eksctl/releases))
- [jq](https://stedolan.github.io/jq/download/)
- [yq](https://mikefarah.gitbook.io/yq/#install)

### Snippets

- [`kubectl` installation for AL2](https://gist.github.com/SPONGE-JL/405a9bcece9e7b5fef1e4fd1696f433c#file-kubectl-installation-snippet_for-amazon-linux-2-sh)

- [`yq` installation for AL2](https://gist.github.com/SPONGE-JL/e9f2bb44638a8170eff1bfe955b8fa37#file-yq-installation-snippet_for-amazon-linux-2-sh)

- [Set AWS Profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) (with [minimum IAM policies](https://eksctl.io/usage/minimum-iam-policies/))

  ```bash
  # Check your profile
  aws sts get-caller-identity | jq
  ```
