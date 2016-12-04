#!/bin/bash
set -e

# Setup OM Tool
sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

# Apply Changes in Opsman
echo "=============================================================================================="
echo "Applying OpsMan Changes                                                                       "
echo "=============================================================================================="
om-linux --target https://opsman.$pcf_ert_domain -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
  apply-changes

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

# After successful apply, disable all post-deploy errands to save time on future changes
echo "=============================================================================================="
echo "Disabling Post-Deploy Errands                                                                 "
echo "=============================================================================================="
json_errands=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${product_guid}/errands")
json_errands=$(echo ${json_errands} | jq '( .errands[] | select(.post_deploy == true) | .post_deploy ) |= false')
fn_om_linux_curl "PUT" "/api/v0/staged/products/${product_guid}/errands" "${json_errands}"

