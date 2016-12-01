///////////////////////////////////////////////
//////// Use Pre-Existing DNS Zone ////////////
///////////////////////////////////////////////

variable "env_dns_zone" {
  default = {
    name = "${var.gcp_managed_zone}"
    domain = "${var.pcf_ert_domain}."
  }
}

///////////////////////////////////////////////
//////// Add DNS Zone Records /////////////////
///////////////////////////////////////////////

resource "google_dns_record_set" "ops-manager-dns" {
  name       = "opsman.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_opsman}"]
}

resource "google_dns_record_set" "wildcard-sys-dns" {
  name       = "*.sys.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "wildcard-apps-dns" {
  name       = "*.cfapps.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "app-ssh-dns" {
  name       = "ssh.sys.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "doppler-dns" {
  name       = "doppler.sys.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "loggregator-dns" {
  name       = "loggregator.sys.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "tcp-dns" {
  name       = "tcp.${var.env_dns_zone.domain}"
  type       = "A"
  ttl        = 300

  managed_zone = "${var.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_tcp_lb}"]
}
