#!/bin/bash
set -ex

product="$1"
if [ -z "${product}" ]; then
  echo "Error: Must supply product name"
  exit 1
fi

#############################################################
#################### GCP Auth  & functions ##################
#############################################################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region

# Setup OM Tool
sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

# Set Vars

# Set JSON Config Template and insert Concourse Parameter Values
json_file_path="gcp-concourse/json-opsman/${gcp_pcf_terraform_template}"
json_file_template="${json_file_path}/${product}-template.json"
json_file="${json_file_path}/${product}.json"

cp ${json_file_template} ${json_file}

perl -pi -e "s/{{gcp_region}}/${gcp_region}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_1}}/${gcp_zone_1}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_2}}/${gcp_zone_2}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_3}}/${gcp_zone_3}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_prefix}}/${gcp_terraform_prefix}/g" ${json_file}

perl -pi -e "s/{{pcf_ert_domain}}/${pcf_ert_domain}/g" ${json_file}
perl -pi -e "s|{{gcp_storage_access_key}}|${gcp_storage_access_key}|g" ${json_file}
perl -pi -e "s|{{gcp_storage_secret_key}}|${gcp_storage_secret_key}|g" ${json_file}

if [[ ! -f ${json_file} ]]; then
  echo "Error: cant find file=[${json_file}]"
  exit 1
fi

function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-linux --target https://opsman.$pcf_ert_domain -k \
            --username \"$pcf_opsman_admin\" \
            --password \"$pcf_opsman_admin_passwd\"  \
            curl \
            --request ${curl_method} \
            --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} \
            --data '${curl_data}'"
    fi

    echo ${curl_cmd} > /tmp/rqst_cmd.log
    exec_out=$(((eval $curl_cmd | tee /tmp/rqst_stdout.log) 3>&1 1>&2 2>&3 | tee /tmp/rqst_stderr.log) &>/dev/null)

    if [[ $(cat /tmp/rqst_stderr.log | grep "Status:" | awk '{print$2}') != "200" ]]; then
      echo "Error Call Failed ...."
      echo $(cat /tmp/rqst_stderr.log)
      exit 1
    else
      echo $(cat /tmp/rqst_stdout.log)
    fi
}



echo "=============================================================================================="
echo "Deploying ${product} @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="
# Get Product Guid
product_guid=$(fn_om_linux_curl "GET" "/api/v0/staged/products" \
            | jq ".[] | select(.type == \"${product}\") | .guid" | tr -d '"' | grep "${product}-.*")

echo "=============================================================================================="
echo "Found ${product} deployment with guid of ${product_guid}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${product_guid}"
echo "=============================================================================================="

json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${product_guid}/networks_and_azs" "${json_net_and_az}"

# Set Product Properties
echo "=============================================================================================="
echo "Setting Properties for: ${product_guid}"
echo "=============================================================================================="

json_properties=$(cat ${json_file} | jq .properties)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${product_guid}/properties" "${json_properties}"

json_errands=$(cat ${json_file} | jq .errands)
if [ ! "${json_errands}" = "null" ]; then
  # Set Product Errands
  echo "=============================================================================================="
  echo "Setting Errands for: ${product_guid}"
  echo "=============================================================================================="
  fn_om_linux_curl "PUT" "/api/v0/staged/products/${product_guid}/errands" "${json_errands}"
fi

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${product_guid}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${product_guid}/jobs" | jq .)

for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do

 json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
 json_job_guid=$(eval ${json_job_guid_cmd})
 json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
 json_job_config=$(eval ${json_job_config_cmd})
 echo "---------------------------------------------------------------------------------------------"
 echo "Setting ${json_job_guid} with --data=${json_job_config}..."
 fn_om_linux_curl "PUT" "/api/v0/staged/products/${product_guid}/jobs/${json_job_guid}/resource_config" "${json_job_config}"

done
