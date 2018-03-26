#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Configuring Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="gcp-concourse/json-opsman/${gcp_pcf_terraform_template}"
json_file_template="${json_file_path}/opsman-template.json"
json_file="${json_file_path}/opsman.json"

cp ${json_file_template} ${json_file}

perl -pi -e "s/{{gcp_region}}/${gcp_region}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_1}}/${gcp_zone_1}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_2}}/${gcp_zone_2}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_3}}/${gcp_zone_3}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_prefix}}/${gcp_terraform_prefix}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_ops_manager}}|${gcp_terraform_subnet_ops_manager}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_reserved}}/${gcp_terraform_subnet_ops_manager_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_dns}}/${gcp_terraform_subnet_ops_manager_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_gw}}/${gcp_terraform_subnet_ops_manager_gw}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_ert}}|${gcp_terraform_subnet_ert}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_reserved}}/${gcp_terraform_subnet_ert_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_dns}}/${gcp_terraform_subnet_ert_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_gw}}/${gcp_terraform_subnet_ert_gw}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_services_1}}|${gcp_terraform_subnet_services_1}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_reserved}}/${gcp_terraform_subnet_services_1_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_dns}}/${gcp_terraform_subnet_services_1_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_gw}}/${gcp_terraform_subnet_services_1_gw}/g" ${json_file}

export OPSMAN_DOMAIN_OR_IP_ADDRESS="opsman.${pcf_ert_domain}"

iaas_configuration=$(
  jq -n \
    --arg gcp_project "$gcp_proj_id" \
    --arg default_deployment_tag "$terraform_prefix" \
    --arg auth_json "$gcp_svc_acct_key" \
    '
    {
      "project": $gcp_project,
      "default_deployment_tag": $default_deployment_tag,
      "auth_json": $auth_json
    }
    '
)

availability_zones=$(cat ${json_file} | jq -r '.[0].availability_zones.availability_zones[]')
availability_zones=${availability_zones#[}
availability_zones=${availability_zones/]}

az_configuration=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    '
    {
      "availability_zones": ($availability_zones | split(",") | map({name: .}))
    }'
)

network_configuration=$(
  jq -n \
    --argjson icmp_checks_enabled false \
    --arg infra_network_name "infrastructure" \
    --arg infra_vcenter_network "${terraform_prefix}-virt-net/${terraform_prefix}-subnet-infrastructure-${gcp_region}/${gcp_region}" \
    --arg infra_network_cidr "192.168.101.0/26" \
    --arg infra_reserved_ip_ranges "192.168.101.1-192.168.101.9" \
    --arg infra_dns "192.168.101.1,8.8.8.8" \
    --arg infra_gateway "192.168.101.1" \
    --arg infra_availability_zones "$availability_zones" \
    --arg deployment_network_name "ert" \
    --arg deployment_vcenter_network "${terraform_prefix}-virt-net/${terraform_prefix}-subnet-ert-${GCP_REGION}/${GCP_REGION}" \
    --arg deployment_network_cidr "192.168.16.0/22" \
    --arg deployment_reserved_ip_ranges "192.168.16.1-192.168.16.9" \
    --arg deployment_dns "192.168.16.1,8.8.8.8" \
    --arg deployment_gateway "192.168.16.1" \
    --arg deployment_availability_zones "$availability_zones" \
    --arg services_network_name "services-1" \
    --arg services_vcenter_network "${terraform_prefix}-virt-net/${terraform_prefix}-subnet-services-1-${GCP_REGION}/${GCP_REGION}" \
    --arg services_network_cidr "192.168.20.0/22" \
    --arg services_reserved_ip_ranges "192.168.20.1-192.168.20.9" \
    --arg services_dns "192.168.20.1,8.8.8.8" \
    --arg services_gateway "192.168.20.1" \
    --arg services_availability_zones "$availability_zones" \
    '
    {
      "icmp_checks_enabled": $icmp_checks_enabled,
      "networks": [
        {
          "name": $infra_network_name,
          "subnets": [
            {
              "iaas_identifier": $infra_vcenter_network,
              "cidr": $infra_network_cidr,
              "reserved_ip_ranges": $infra_reserved_ip_ranges,
              "dns": $infra_dns,
              "gateway": $infra_gateway,
              "availability_zones": ($infra_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $deployment_network_name,
          "subnets": [
            {
              "iaas_identifier": $deployment_vcenter_network,
              "cidr": $deployment_network_cidr,
              "reserved_ip_ranges": $deployment_reserved_ip_ranges,
              "dns": $deployment_dns,
              "gateway": $deployment_gateway,
              "availability_zones": ($deployment_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $services_network_name,
          "subnets": [
            {
              "iaas_identifier": $services_vcenter_network,
              "cidr": $services_network_cidr,
              "reserved_ip_ranges": $services_reserved_ip_ranges,
              "dns": $services_dns,
              "gateway": $services_gateway,
              "availability_zones": ($services_availability_zones | split(","))
            }
          ]
        }
      ]
    }'
)

director_config=$(cat <<-EOF
{
  "ntp_servers_string": "0.pool.ntp.org",
  "resurrector_enabled": true,
  "retry_bosh_deploys": true,
  "database_type": "internal",
  "blobstore_type": "local"
}
EOF
)

resource_configuration=$(cat <<-EOF
{
  "director": {
    "internet_connected": false
  },
  "compilation": {
    "internet_connected": false
  }
}
EOF
)

network_assignment=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    --arg network "infrastructure" \
    '
    {
      "singleton_availability_zone": ($availability_zones | split(",") | .[0]),
      "network": $network
    }'
)

echo "Configuring IaaS and Director..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$pcf_opsman_admin" \
  --password "$pcf_opsman_admin_passwd" \
  configure-bosh \
  --iaas-configuration "$iaas_configuration" \
  --director-configuration "$director_config" \
  --az-configuration "$az_configuration" \
  --networks-configuration "$network_configuration" \
  --network-assignment "$network_assignment" \
  --resource-configuration "$resource_configuration"
