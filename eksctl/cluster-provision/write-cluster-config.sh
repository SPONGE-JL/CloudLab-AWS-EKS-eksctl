#!/bin/bash
# Settings
export VARS_JSON="vars.cluster.json"
export CLUSTER_CONFIG_YAML="cluster-config.yaml"


# Functions
noti() {
  echo ""
  echo "$1"
}
enter() {
  noti "Start >> Init a basic ClusterConfig file"
  echo "         (work with '${VARS_JSON}')"
}
extractInMetadata() {
  echo $(jq ".metadata.$1" ${VARS_JSON})
}
process_setVariables() {
  noti "[..] Set variables."
  local region=$(extractInMetadata 'region')
  local name=$(extractInMetadata 'name')
  local version=$(extractInMetadata 'version')

  export AWS_REGION=${region}
  export CLUSTER_NAME=${name}
  export K8S_VERSION=${version}
  cat <<EOF

  * AWS_REGION  : ${AWS_REGION}
  * CLUSTER_NAME: ${CLUSTER_NAME}
  * K8S_VERSION : ${K8S_VERSION}
EOF
}
process_writeFile() {
  noti "[..] Write new file - ${CLUSTER_CONFIG_YAML}"
  echo ""
  cat "template.${CLUSTER_CONFIG_YAML}" | envsubst > ${CLUSTER_CONFIG_YAML}
  cat ${CLUSTER_CONFIG_YAML} | grep -v "#"
}
process() {
  process_setVariables
  process_writeFile
}
period() {
  noti "fin."
  echo ""
}


# Execution
enter
process
period
