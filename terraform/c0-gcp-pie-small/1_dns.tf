///////////////////////////////////////////////
//////// Add DNS Zone Records /////////////////
///////////////////////////////////////////////

resource "google_dns_record_set" "ops-manager-dns" {
  name       = "opsman.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_opsman}"]
}

resource "google_dns_record_set" "wildcard-sys-dns" {
  name       = "*.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "wildcard-apps-dns" {
  name       = "*.cfapps.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "app-ssh-dns" {
  name       = "ssh.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "doppler-dns" {
  name       = "doppler.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "loggregator-dns" {
  name       = "loggregator.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "elasticsearch-logqueue-dns" {
  name       = "elasticsearch-logqueue.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "mysql-logqueue-dns" {
  name       = "mysql-logqueue.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "metrics-dns" {
  name       = "metrics.sys.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "tcp-dns" {
  name       = "tcp.${var.pcf_ert_domain}."
  type       = "A"
  ttl        = 300

  managed_zone = "${var.gcp_managed_zone}"

  rrdatas = ["${var.pub_ip_ssh_tcp_lb}"]
}
