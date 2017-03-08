//// Allow IPSec
resource "google_compute_firewall" "cf-allow-ipsec" {
  name       = "${var.gcp_terraform_prefix}-allow-ipsec"
  depends_on = ["google_compute_network.pcf-virt-net"]
  network    = "${google_compute_network.pcf-virt-net.name}"

  allow {
    protocol = "udp"
    ports    = ["500"]
  }

  allow {
    protocol = "ah"
  }

  allow {
    protocol = "esp"
  }

  source_ranges = ["0.0.0.0/0"]
}
