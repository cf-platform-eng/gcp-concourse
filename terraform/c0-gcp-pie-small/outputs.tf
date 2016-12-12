// Core Project Output

output "project" {
  value = "${var.gcp_proj_id}"
}

output "region" {
  value = "${var.gcp_region}"
}

output "azs" {
  value = "${var.gcp_zone_1}"
}

output "deployment-prefix" {
  value = "${var.gcp_terraform_prefix}-vms"
}

// DNS Output

output "ops_manager_dns" {
  value = "${google_dns_record_set.ops-manager-dns.name}"
}

output "sys_domain" {
  value = "sys.${var.gcp_terraform_prefix}.${var.pcf_ert_domain}"
}

output "apps_domain" {
  value = "apps.${var.gcp_terraform_prefix}.${var.pcf_ert_domain}"
}

output "tcp_domain" {
  value = "tcp.${var.gcp_terraform_prefix}.${var.pcf_ert_domain}"
}

output "ops_manager_public_ip" {
  value = "${google_compute_instance.ops-manager.network_interface.0.access_config.0.assigned_nat_ip}"
}

// Network Output

output "network_name" {
  value = "${google_compute_network.pcf-virt-net.name}"
}

output "ops_manager_gateway" {
  value = "${google_compute_subnetwork.subnet-ops-manager.gateway_address}"
}

output "ops_manager_cidr" {
  value = "${google_compute_subnetwork.subnet-ops-manager.ip_cidr_range}"
}

output "ops_manager_subnet" {
  value = "${google_compute_subnetwork.subnet-ops-manager.name}"
}

output "ert_gateway" {
  value = "${google_compute_subnetwork.subnet-ert.gateway_address}"
}

output "ert_cidr" {
  value = "${google_compute_subnetwork.subnet-ert.ip_cidr_range}"
}

output "ert_subnet" {
  value = "${google_compute_subnetwork.subnet-ert.name}"
}

output "svc_net_1_gateway" {
  value = "${google_compute_subnetwork.subnet-services-1.gateway_address}"
}

output "svc_net_1_cidr" {
  value = "${google_compute_subnetwork.subnet-services-1.ip_cidr_range}"
}

output "svc_net_1_subnet" {
  value = "${google_compute_subnetwork.subnet-services-1.name}"
}

// Http Load Balancer Output

output "http_lb_backend_name" {
  value = "${google_compute_backend_service.ert_http_lb_backend_service.name}"
}

output "tcp_router_pool" {
  value = "${google_compute_target_pool.cf-tcp.name}"
}

// Cloud Storage Bucket Output

output "buildpacks_bucket" {
  value = "${google_storage_bucket.buildpacks.name}"
}

output "droplets_bucket" {
  value = "${google_storage_bucket.droplets.name}"
}

output "packages_bucket" {
  value = "${google_storage_bucket.packages.name}"
}

output "resources_bucket" {
  value = "${google_storage_bucket.resources.name}"
}

output "director_blobstore_bucket" {
  value = "${google_storage_bucket.director.name}"
}