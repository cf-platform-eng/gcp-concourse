#!/bin/bash
set -e

# Getting Opsmanager Image name in use from previous task upload-opsman.sh
pcf_opsman_image_name=$(cat opsman-metadata/name)

# Copy base template with no clobber if not using the base template
if [[ ! ${gcp_pcf_terraform_template} == "c0-gcp-base" ]]; then
  cp -rn gcp-concourse/terraform/c0-gcp-base/* gcp-concourse/terraform/${gcp_pcf_terraform_template}/
fi

# Test if a GCP_Terraform_Template is using 'Init' folder to process with pre-existing IPs
if [[ -d gcp-concourse/terraform/${gcp_pcf_terraform_template}/init ]]; then
  echo "=============================================================================================="
  echo "This gcp_pcf_terraform_template has an 'Init' set of terraform that has pre-created IPs..."
  echo "=============================================================================================="
  echo $gcp_svc_acct_key > /tmp/blah
  gcloud auth activate-service-account --key-file /tmp/blah
  rm -rf /tmp/blah

  gcloud config set project $gcp_proj_id
  gcloud config set compute/region $gcp_region

  function fn_get_ip {
       gcp_cmd="gcloud compute addresses list  --format json | jq '.[] | select (.name == \"$gcp_terraform_prefix-$1\") | .address '"
       api_ip=$(eval $gcp_cmd | tr -d '"')
       echo $api_ip
  }

  pub_ip_global_pcf=$(fn_get_ip "global-pcf")
  pub_ip_ssh_tcp_lb=$(fn_get_ip "tcp-lb")
  pub_ip_ssh_and_doppler=$(fn_get_ip "ssh-and-doppler")
  pub_ip_jumpbox=$(fn_get_ip "jumpbox")
  pub_ip_opsman=$(fn_get_ip "opsman")
fi

# Test if the ssl cert var from concourse is set to 'genrate'.  If so, script will gen a self signed, otherwise will assume its a cert
if [[ ${pcf_ert_ssl_cert} == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for sys.${pcf_ert_domain} & cfapps.${pcf_ert_domain} ..."
  echo "=============================================================================================="
  ert-concourse/scripts/ssl/gen_ssl_certs.sh "sys.${pcf_ert_domain}" "cfapps.${pcf_ert_domain}"
  export pcf_ert_ssl_cert=$(cat sys.${pcf_ert_domain}.crt)
  export pcf_ert_ssl_key=$(cat sys.${pcf_ert_domain}.key)
fi

# Test if SQL exists and inculdes terraform actions, if true generate a unique name
if [[ $(cat gcp-concourse/terraform/c0-gcp-base/8_sql.tf | wc -c) -gt 0 ]]; then
  ert_sql_instance_name="${gcp_terraform_prefix}-sql-$(cat /proc/sys/kernel/random/uuid)"
fi


##########################################################
# Terraforming
##########################################################

# Install Terraform cli until we can update the Docker image
wget $(wget -q -O- https://www.terraform.io/downloads.html | grep linux_amd64 | awk -F '"' '{print$2}') -O /tmp/terraform.zip
if [ -d /opt/terraform ]; then
  rm -rf /opt/terraform
fi

unzip /tmp/terraform.zip
sudo cp terraform /usr/local/bin
export PATH=/opt/terraform/terraform:$PATH


function fn_exec_tf {
    echo "=============================================================================================="
    echo "Executing Terraform ${1} ..."
    echo "=============================================================================================="

    echo $gcp_svc_acct_key > /tmp/svc-acct.json

    terraform ${1} \
      -var "gcp_proj_id=${gcp_proj_id}" \
      -var "gcp_region=${gcp_region}" \
      -var "gcp_zone_1=${gcp_zone_1}" \
      -var "gcp_zone_2=${gcp_zone_2}" \
      -var "gcp_zone_3=${gcp_zone_3}" \
      -var "gcp_terraform_prefix=${gcp_terraform_prefix}" \
      -var "gcp_terraform_subnet_ops_manager=${gcp_terraform_subnet_ops_manager}" \
      -var "gcp_terraform_subnet_ert=${gcp_terraform_subnet_ert}" \
      -var "gcp_terraform_subnet_services_1=${gcp_terraform_subnet_services_1}" \
      -var "pcf_opsman_image_name=${pcf_opsman_image_name}" \
      -var "pcf_ert_domain=${pcf_ert_domain}" \
      -var "pcf_ert_ssl_cert=${pcf_ert_ssl_cert}" \
      -var "pcf_ert_ssl_key=${pcf_ert_ssl_key}" \
      -var "pub_ip_global_pcf=${pub_ip_global_pcf}" \
      -var "pub_ip_ssh_tcp_lb=${pub_ip_ssh_tcp_lb}" \
      -var "pub_ip_ssh_and_doppler=${pub_ip_ssh_and_doppler}" \
      -var "pub_ip_jumpbox=${pub_ip_jumpbox}" \
      -var "pub_ip_opsman=${pub_ip_opsman}" \
      -var "ert_sql_instance_name=${ert_sql_instance_name}" \
      -var "ert_sql_db_username=${pcf_opsman_admin}" \
      -var "ert_sql_db_password=${pcf_opsman_admin_passwd}" \
      gcp-concourse/terraform/$gcp_pcf_terraform_template
}

fn_exec_tf "plan"
fn_exec_tf "apply"
