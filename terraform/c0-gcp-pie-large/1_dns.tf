///////////////////////////////////////////////
//////// Use Pre-Existing DNS Zone ////////////
///////////////////////////////////////////////

variable "dns_domain" {
  default = "${var.pcf_ert_domain}."
}

///////////////////////////////////////////////
//////// Add DNS Zone Records /////////////////
///////////////////////////////////////////////

resource "google_dns_record_set" "ops-manager-dns" {
  name       = "opsman.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_opsman}"]
}

resource "google_dns_record_set" "wildcard-sys-dns" {
  name       = "*.sys.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "wildcard-apps-dns" {
  name       = "*.cfapps.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "app-ssh-dns" {
  name       = "ssh.sys.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "doppler-dns" {
  name       = "doppler.sys.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "loggregator-dns" {
  name       = "loggregator.sys.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "tcp-dns" {
  name       = "tcp.${var.gcp_managed_domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.dns_domain}"

  rrdatas = ["${var.pub_ip_ssh_tcp_lb}"]
}
