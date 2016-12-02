#!/bin/bash
set -e

product="$1"
if [ -z "${product}" ]; then
  echo "Error: Must supply product name"
  exit 1
fi

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo " Uploading ${product} tile to @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

##Upload p-mysql Tile

om-linux --target https://opsman.$pcf_ert_domain -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
      upload-product \
      --product pivnet-${product}/${product}-*.pivotal

##Get Uploaded Tile --product-version

opsman_host="opsman.$pcf_ert_domain"
uaac target https://${opsman_host}/uaa --skip-ssl-validation > /dev/null 2>&1
uaac token owner get opsman ${pcf_opsman_admin} -s "" -p ${pcf_opsman_admin_passwd} > /dev/null 2>&1
export opsman_bearer_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')

##Find most recent avaiable product version
product_version=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${opsman_host}/api/v0/available_products" | jq " .[] | select ( .name == \"${product}\") | .product_version " | tr -d '"')
if [ -z "${product_version}" ]; then
	echo "Error: ${product} not found"
	echo "Available products are:"
	curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${opsman_host}/api/v0/available_products" | jq ' .[] | .name '
fi

##Move 'available product to 'staged'

om-linux --target https://opsman.$pcf_ert_domain -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
      stage-product \
      --product-name ${product} --product-version ${product_version}
