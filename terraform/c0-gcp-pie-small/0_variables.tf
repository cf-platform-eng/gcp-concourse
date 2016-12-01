///////////////////////////////////////////////
//////// Declare Vars /////////////////////////
///////////////////////////////////////////////


variable "gcp_proj_id" {}
variable "gcp_region" {}
variable "gcp_zone_1" {}
variable "gcp_terraform_prefix" {}
variable "gcp_terraform_subnet_ops_manager" {}
variable "gcp_terraform_subnet_ert" {}
variable "gcp_terraform_subnet_services_1" {}
variable "pcf_opsman_image_name" {}
variable "pcf_ert_domain" {}
variable "pcf_ert_ssl_cert" {}
variable "pcf_ert_ssl_key" {}
variable "pub_ip_opsman" {}
variable "pub_ip_jumpbox" {}
variable "pub_ip_global_pcf" {}
variable "pub_ip_ssh_and_doppler" {}
variable "pub_ip_ssh_tcp_lb" {}
variable "ert_sql_instance_name" {}
variable "ert_sql_db_username" {}
variable "ert_sql_db_password" {}
variable "gcp_managed_zone" {}