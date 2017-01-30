
///////////======================//////////////
//// Network(s) =================//////////////
///////////======================//////////////

  //// Create GCP Virtual Network
  resource "google_compute_network" "pcf-virt-net" {
    name       = "${var.gcp_terraform_prefix}-virt-net"
  }


///////////======================//////////////
//// Subnet(s) ==================//////////////
///////////======================//////////////

  //// Create Subnet for the Ops Manager & Jumpbox
  resource "google_compute_subnetwork" "subnet-ops-manager" {
    name          = "${var.gcp_terraform_prefix}-subnet-infrastructure-${var.gcp_region}"
    ip_cidr_range = "${var.gcp_terraform_subnet_ops_manager}"
    network       = "${google_compute_network.pcf-virt-net.self_link}"
  }

  //// Create Subnet for ERT
  resource "google_compute_subnetwork" "subnet-ert" {
    name          = "${var.gcp_terraform_prefix}-subnet-ert-${var.gcp_region}"
    ip_cidr_range = "${var.gcp_terraform_subnet_ert}"
    network       = "${google_compute_network.pcf-virt-net.self_link}"
  }

  //// Create Subnet for Services Tile 1
  resource "google_compute_subnetwork" "subnet-services-1" {
    name          = "${var.gcp_terraform_prefix}-subnet-services-1-${var.gcp_region}"
    ip_cidr_range = "${var.gcp_terraform_subnet_services_1}"
    network       = "${google_compute_network.pcf-virt-net.self_link}"
  }
