///////////////////////////////////////////////
//////  Create Pivotal Opsman  ////////////////
///////////////////////////////////////////////

resource "google_compute_instance" "ops-manager" {
  name         = "${var.gcp_terraform_prefix}-ops-manager"
  depends_on   = ["google_compute_subnetwork.subnet-ops-manager"]
  machine_type = "n1-standard-2"
  zone         = "${var.gcp_zone_1}"

  tags = ["${var.gcp_terraform_prefix}-opsman", "allow-https"]

  boot_disk {
    initialize_params {
      image = "${var.pcf_opsman_image_name}"
      size  = 150
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-ops-manager.name}"

    access_config {
      nat_ip = "${var.pub_ip_opsman}"
    }
  }
}

resource "google_storage_bucket" "director" {
  name          = "${var.gcp_terraform_prefix}-director"
  force_destroy = true
}
