#!/bin/bash

set -euo pipefail

# To do
# 1. Install Opentofu
# 2. Create config.auto.tfvars
# 3. Run tofu init
# 4. Run tofu plan
# 5. Run tofu apply
# 6. Show instructions to access the application

# Environment variables
DEFAULT_COLOR="\033[0m"
YELLOW_COLOR="\033[1;33m"
RED_COLOR="\033[1;31m"
OUTPUT_DIR="/home/${USER}/uipath"
LOG_FILE="${OUTPUT_DIR}/install_asea_$(date '+%Y-%m-%d-%H-%M-%S').log"
INSTALL_LOG_FILE="${OUTPUT_DIR}/uipathctl_$(date '+%Y-%m-%d-%H-%M-%S').log"
DOWNLOAD_FILES=""
PLAN_INFRA=""
INSTALL_INFRA=""
DESTROY_INFRA=""
BYPASS_CONFIRM="false"

# Shared functions
function create_log_dir() {
    if [[ ! -d "${OUTPUT_DIR}" ]]; then
        mkdir -p "${OUTPUT_DIR}"
    fi
}

function time_echo() {
    # Print a message with a timestamp.
    local message="$1"
    local date_time=$(date +'%Y-%m-%d %H:%M:%S')
    local color="$2"
    echo -e "${color}${date_time} - ${message}${DEFAULT_COLOR}"
}

function info() {
    local message="$1"
    time_echo "INFO: ${message}" "${DEFAULT_COLOR}" | tee -a ${LOG_FILE}
}

function warn() {
    local message="$1"
    time_echo "WARN: ${message}" "${YELLOW_COLOR}" | tee -a ${LOG_FILE}
}

function error() {
    local message="$1"
    time_echo "ERROR: ${message}" "${RED_COLOR}" | tee -a ${LOG_FILE}
    return 1
}

function display_usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -d | --download       Download the opentofu binary and pull the latest files from the git repository"
  echo "  -i | --install        Install the infrastructure"
  echo "  -h | --help           Display this help message"
  echo "  -p | --plan           Run tofu plan"
  echo "  -y | --auto-approve   Bypass the confirmation prompt before installing the infrastructure"
  echo "  --destroy             Destroy the infrastructure"
  echo "##################################################"
  echo "Prerequisites:"
  echo "Please create the following files before running this script with the -i|--install option:"
  echo "1. ~/.aws/credentials"
  echo "2. ~/terraform-aws-lab-client/config.auto.tfvars" 
  echo "##################################################"
  echo "Execution:"
  echo "You can run this script with one or more options at the same time except for -i|--install option."
  echo "Example"
  echo "Download and plan the infrastructure."
  echo "$0 -d -p"
  echo "Install the infrastructure. When using '-i|--install' option, you must run this script along with '-p|--plan' option."
  echo "$0 -p -i"
}
function confirm_action() {
    if [[ "${BYPASS_CONFIRM}" == "true" ]]; then
        return 0
    fi
    
    read -p "Do you want to proceed with applying the infrastructure changes? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Operation cancelled by user"
    fi
    return 0
}


function parse_args() {
  while (("$#")); do
    case "$1" in  
    -d|--download)
      echo "Downloading the opentofu binary and pulling the latest files from the git repository"
      DOWNLOAD_FILES="true"
      shift 1
      ;;
    -i|--install)
      echo "Installing the infrastructure"
      INSTALL_INFRA="true"
      shift 1
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    -p|--plan)
      echo "Running tofu plan"
      PLAN_INFRA="true"
      shift 1
      ;;
    -y|--auto-approve)
      BYPASS_CONFIRM="true"
      shift 1
      ;;
    --destroy)
      DESTROY_INFRA="true"
      shift 1
      ;;
    -*)
      error "Unexpected option ${1}"
      ;;
    esac
  done

  # Check if any option was set instead of checking $#
  if [[ -z "${DOWNLOAD_FILES}" && -z "${PLAN_INFRA}" && -z "${INSTALL_INFRA}" && -z "${DESTROY_INFRA}" ]]; then
    error "No options provided. Please run the script with one or more options."
  fi
  if [[ -n "${INSTALL_INFRA}" && -z "${PLAN_INFRA}" ]]; then
    error "When using '-i|--install' option, you must run this script along with '-p|--plan' option."
  fi
  if [[ -n "${DESTROY_INFRA}" && -n "${INSTALL_INFRA}" ]]; then
    error "You cannot use '--destroy' option along with '-i|--install' option."
  fi
}

# Variables
OPENTOFU_VERSION="1.9.0"
OPENTOFU_URL="https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_$(uname -s)_$(dpkg --print-architecture).zip"
OPENTOFU_PATH="${HOME}/opentofu"
OPENTOFU="${OPENTOFU_PATH}/tofu"
GIT_REPO="git@github.com:teamoto/terraform-aws-lab-client.git"
GIT_PATH="${HOME}/terraform-aws-lab-client"
TOFU_WORKING_DIR="${GIT_PATH}"
TOFU_EXCLUDE_COMPONENT="module.eks.kubernetes_manifest.eni_config"

# Functions
function install_opentofu() {
    local opentofu_tmp_dir=$(mktemp -d)
    # Delete the current opentofu directory if exists
    if [[ -d "${HOME}/opentofu" ]]; then
        rm -rf "${HOME}/opentofu"
    fi
    info "Downloading Opentofu ${OPENTOFU_VERSION} to ${opentofu_tmp_dir}"
    wget -q -O ${opentofu_tmp_dir}/opentofu.zip ${OPENTOFU_URL}
    unzip -q ${opentofu_tmp_dir}/opentofu.zip -d ${OPENTOFU_PATH}
    if [[ -z "${OPENTOFU}" ]]; then
        error "Opentofu ${OPENTOFU_VERSION} installation failed"
    fi
    chmod +x ${OPENTOFU}
    # Add opentofu to the PATH
    return 0
}

function update_git_repo() {
    info "Cloning the repository ${GIT_REPO} to ${GIT_PATH}"
    if [[ ! -d "${GIT_PATH}" ]]; then
        git clone ${GIT_REPO} ${GIT_PATH}
    fi
    cd ${GIT_PATH}
    git pull
    info "Updating the submodules"
    if [[ -f "${HOME}/.ssh/id_rsa_submodule" ]]; then
        GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa_submodule' GIT_TRACE=1 git submodule update --init --recursive
    else
        error "The SSH key ~/.ssh/id_rsa_submodule does not exist. Please reach out to the repository owner regarding an absence of the key."
    fi
    return 0
}

function check_prereqs() {
    info "Checking the prerequisites for opentofu execution."
    if [[ ! -f "${HOME}/.aws/credentials" ]]; then
        error "The file ~/.aws/credentials does not exist. Please create the file and try again."
    fi
    if [[ ! -f "${HOME}/terraform-aws-lab-client/config.auto.tfvars" ]]; then
        error "The file ~/terraform-aws-lab-client/config.auto.tfvars does not exist. Please create the file and try again."
    fi
    if ${OPENTOFU} -h > /dev/null; then
        info "Opentofu is installed"
    else
        error "Opentofu is not installed. Please install Opentofu and try again."
    fi
    return 0
}

function tofu_fmt() {
    # Check the prerequisites
    check_prereqs
    # Run tofu fmt, init, validation, and plan
    info "Formatting the terraform files, initializing the working directory, and validating the configuration..."
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" fmt && \
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" init && \
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" validate || \
    error "Formatting or initialization failed. Please check terraform files."
}

function tofu_plan_no_k8s() {
    # Check formatting, initialization, and validation
    tofu_fmt
    # Run tofu plan
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" plan -out="${TOFU_WORKING_DIR}/tfplan_no_k8s" -exclude="${TOFU_EXCLUDE_COMPONENT}" || \
    error "Tofu plan failed. Please check terraform files."
}

function tofu_plan() {
    # Check formatting, initialization, and validation
    tofu_fmt
    # Run tofu plan
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" plan -out="${TOFU_WORKING_DIR}/tfplan"|| \
    error "Tofu plan failed. Please check terraform files."
}
function tofu_apply() {
    # Input: tfplan file
    local tfplan_file="$1"
    if [[ -z "${tfplan_file}" ]]; then
        error "The tfplan file is not provided. Please provide the tfplan file and try again."
    fi
    # Check the prerequisites
    check_prereqs
    # Run tofu apply
    info "Applying the infrastructure changes"
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" apply "${tfplan_file}" || \
    error "Tofu apply failed. Please check terraform files."
}

function parse_tf_output() {
    # Parse the terraform output and display the specified resource
    # This function requires `jq` so ensure it is installed.
    local resource="$1"
    if ! command -v jq > /dev/null; then
        error "jq is not installed. Please install jq and try again."
    fi
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" output -json | jq -r ".${resource}.value"
}

function is_eks_exists() {
    local eks_path="eks_cluster_name"
    local eks_cluster_name
    eks_cluster_name=$(parse_tf_output "${eks_path}")
    [[ "${eks_cluster_name}" != "null" ]] && echo "${eks_cluster_name}" || echo "null"
}

function enable_kubectl() {
  local eks_cluster_name="$1"
  local eks_cluster_region="$2"
  aws eks update-kubeconfig --region "${eks_cluster_region}" --name "${eks_cluster_name}"
}


function tofu_destroy() {
    local eks_cluster_name
    # Check the prerequisites
    check_prereqs
    # Run tofu destroy
    info "Destroying the infrastructure..."
    tofu_fmt
    info "Checking if there are any eks clusters provisioned by this user."
    eks_cluster_name=$(is_eks_exists)
    if [[ "${eks_cluster_name}" == "null" ]]; then
        info "No eks cluster found. Proceeding with destroying the infrastructure."
    else
        info "Found eks cluster ${eks_cluster_name}. Proceeding with destroying some resources on the eks cluster to avoid any dependency issues."
        info "Updating the kubeconfig to access the eks cluster."
        enable_kubectl "${eks_cluster_name}" "$(parse_tf_output eks_region)"
        info "Deleting all services using kubectl to avoid any dependency issues."
        # Delete all services using kubectl
        kubectl delete services --all --all-namespaces --force --grace-period=0
    fi
    # Before destorying the infrastructure, need to confirm:
    # - Are there any infrastcuture provisioned by this user.
    # - If yes, confirm there are any eks cluster provisioned by this user.
    # - If yes, destory all services using kubectl to avoid any dependency issues.
    # - Then run tofu destroy
    info "Destroying only K8s components..."
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" plan -out="${TOFU_WORKING_DIR}/tfdestroy" -destroy -target="${TOFU_EXCLUDE_COMPONENT}" && \
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" apply "${TOFU_WORKING_DIR}/tfdestroy" || \
    error "Tofu destroy failed. Please check terraform files."

    info "Destroying the rest of the infrastructure..."
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" plan -out="${TOFU_WORKING_DIR}/tfdestroy" -destroy -exclude="${TOFU_EXCLUDE_COMPONENT}" && \
    ${OPENTOFU} -chdir="${TOFU_WORKING_DIR}" apply "${TOFU_WORKING_DIR}/tfdestroy" || \
    error "Tofu destroy failed. Please check terraform files."
    info "The infrastructure has been successfully destroyed."
}


function output_instructions() {
    # Display the instructions to access the deployed EC2 instance and further steps
    local ec2_ip=$(parse_tf_output "ec2_instance_ip")
    local ec2_dns=$(parse_tf_output "ec2_instance_hostname")
    local eks_cluster_name=$(parse_tf_output "eks_cluster_name")
    local eks_region=$(parse_tf_output "eks_region")
    local subnet_ids=$(parse_tf_output "private_subnet_ids")
    local s3_bucket_name=$(parse_tf_output "s3_bucket_name")
    local s3_bucket_endpiont=$(parse_tf_output "s3_bucket_endpoint")
    local s3_bucket_region=$(parse_tf_output "s3_bucket_region")
    local redis_endpoint=$(parse_tf_output "redis_endpoint")
    local redis_port=$(parse_tf_output "redis_port")
    local redis_password=$(parse_tf_output "redis_password")

    # Create an example input.json file
    cat <<EOF > ${TOFU_WORKING_DIR}/input.json
{
  "kubernetes_distribution": "eks",
  "install_type": "online",
  "profile": "ha",
  "fqdn": "autosuite.uipath.local",
  "admin_username": "admin",
  "admin_password": "${redis_password}",
  "telemetry_optout": true,
  "fips_enabled_nodes": false,
  "fabric": {
    "redis": {
      "hostname": "${redis_endpoint}",
      "password": "${redis_password}",
      "port": ${redis_port},
      "tls": true
    }
  },
  "external_object_storage": {
    "enabled": true,
    "use_instance_profile": true,
    "storage_type": "s3",
    "port": 443,
    "region": "${s3_bucket_region}"
  },
  "ingress": {
    "service_annotations": {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol": "ssl",
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type": "ip",
      "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal",
      "service.beta.kubernetes.io/aws-load-balancer-type": "nlb",
      "service.beta.kubernetes.io/aws-load-balancer-internal": "true",
      "service.beta.kubernetes.io/aws-load-balancer-subnets": "$(echo ${subnet_ids}|  tr -d '[]"' | tr -d '\n\t ')",
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags": "Owner=${USER}@uipath.com,Project=Service Fabric"
    }
  },
  "sql": {
    "create_db": true,
    "server_url": "${ec2_dns}",
    "port": "1433",
    "username": "sa",
    "password": "${redis_password}"
  },
  "orchestrator": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    },
    "testautomation": {
      "enabled": true
    },
    "updateserver": {
      "enabled": true
    }
  },
  "processmining": {
    "enabled": false
  },
  "insights": {
    "enabled": true,
    "enable_realtime_monitoring": false,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "automation_hub": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "automation_ops": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "aicenter": {
    "enabled": false,
    "external_object_storage": {
      "port": 443,
      "fqdn": "s3.${s3_bucket_region}.amazonaws.com",
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "documentunderstanding": {
    "enabled": false,
    "modernProjects": {
      "enabled": false
    },
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "test_manager": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "action_center": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "apps": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "integrationservices": {
    "enabled": false,
    "account_id": "",
    "cluster_name": "",
    "queue_prefix" : "",
    "use_instance_profile": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    },
    "sql_connection_str": "SERVER=${ec2_dns},1433;DATABASE=AutomationSuite_Integration_Services;DRIVER={ODBC Driver 17 for SQL Server};UID=sa;PWD={${redis_password}};Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;hostNameInCertificate=${ec2_dns};MultiSubnetFailover=True"
  },
  "studioweb": {
    "enabled": false,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "dataservice": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "asrobots": {
    "enabled": false,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "storage_class": "ebs-sc",
  "storage_class_single_replica": "efs-sc",
  "platform": {
    "enabled": true,
    "external_object_storage": {
      "bucket_name": "${s3_bucket_name}"
    }
  },
  "namespace": "uipath",
  "sql_connection_string_template": "Server=tcp:${ec2_dns},1433;Initial Catalog=DB_NAME_PLACEHOLDER;Persist Security Info=False;User Id=sa;Password='${redis_password}';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;Max Pool Size=100;MultiSubnetFailover=False;",
  "sql_connection_string_template_jdbc": "jdbc:sqlserver://${ec2_dns}:1433;database=DB_NAME_PLACEHOLDER;user=sa;password={${redis_password}};encrypt=true;trustServerCertificate=true;loginTimeout=30;multiSubnetFailover=false;hostNameInCertificate=${ec2_dns}",
  "sql_connection_string_template_odbc": "SERVER=${ec2_dns},1433;DATABASE=DB_NAME_PLACEHOLDER;DRIVER={ODBC Driver 17 for SQL Server};UID=sa;PWD={${redis_password}};Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;hostNameInCertificate=${ec2_dns};MultiSubnetFailover=NO",
  "sql_connection_string_template_sqlalchemy_pyodbc": "mssql+pyodbc://sa:${redis_password}@${ec2_dns}:1433/DB_NAME_PLACEHOLDER?driver=ODBC+Driver+17+for+SQL+Server",
  "exclude_components": [
    "velero"
  ]
}
EOF

    info "The infrastructure has been successfully deployed. To access the provisioned resources, please follow the instructions below:"
    cat <<EOF
    ##################################################
    Access Instructions
    #### Access the EC2 instance ####
    1. Please take a note of the following IP or DNS name of the EC2 instance.
        - IP: ${ec2_ip}
        - DNS: ${ec2_dns}
    2. Login the Guacamole web interface and create a new RDP connection using the IP or DNS name of the EC2 instance.
    3. Use the same credentials to login the EC2 instance.
    #### Access the EKS cluster ####
    1. Login the EC2 instnace
    2. Run the following command to access the EKS cluster:
        - aws eks --region ${eks_region} update-kubeconfig --name ${eks_cluster_name}
    3. Confirm if the kubectl is configured correctly by running the following command:
        - kubectl get nodes
    #### Create AS config file ####
    1. Take notes of the following values:
        - Subnet IDs: ${subnet_ids}
        - S3 Bucket Name: ${s3_bucket_name}
        - S3 Bucket Endpoint: ${s3_bucket_endpiont}
        - S3 Bucket Region: ${s3_bucket_region}
        - Redis Endpoint: ${redis_endpoint}
        - Redis Port: ${redis_port}
        - Redis Password: ${redis_password}
    2. An example config file (input.json) is created in ${TOFU_WORKING_DIR}/input.json. Please copy values from the file and create a new input.json file in the EC2 instance.
    3. Should you need to make modifications to the input.json file, please refer to the following link:
       - https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-eks-aks/eks-inputjson-example
EOF

}

function main() {
    # Create the log directory
    create_log_dir
    # Parse the arguments
    parse_args "$@"
    # Check the prerequisites
    # check_prereqs
    if [[ "${DOWNLOAD_FILES}" == "true" ]]; then
        # Install Opentofu
        install_opentofu
        # Update the git repository
        update_git_repo
    fi
    # Need to run plan twice to avoid errors related to the k8s resources
    # Delete the previous plan file
    info "Deleting the previous plan file if exists"
    [[ -f "${TOFU_WORKING_DIR}/tfplan_no_k8s" ]] && rm -f "${TOFU_WORKING_DIR}/tfplan_no_k8s"
    [[ -f "${TOFU_WORKING_DIR}/tfplan" ]] && rm -f "${TOFU_WORKING_DIR}/tfplan"
    
    [[ "${PLAN_INFRA}" == "true" ]] && tofu_plan_no_k8s
    if [[ "${INSTALL_INFRA}" == "true" ]]; then
        confirm_action && tofu_apply "${TOFU_WORKING_DIR}/tfplan_no_k8s"
    fi
    [[ "${PLAN_INFRA}" == "true" ]] && tofu_plan
    if [[ "${INSTALL_INFRA}" == "true" ]]; then
        confirm_action && tofu_apply "${TOFU_WORKING_DIR}/tfplan"
        output_instructions
    fi
    if [[ "${DESTROY_INFRA}" == "true" ]]; then
        confirm_action && tofu_destroy
    fi
}

main "$@"
