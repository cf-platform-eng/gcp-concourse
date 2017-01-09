///////////======================//////////////
//// Load Balancing =============//////////////
///////////======================//////////////


///////////////////////////////////////////////
//////// Instance Group ///////////////////////
///////////////////////////////////////////////

resource "google_compute_instance_group" "ert-http-lb" {
  count       = 1
  name        = "${var.gcp_terraform_prefix}-http-lb"
  description = "terraform generated pcf instance group that is multi-zone for http/https load balancing"
  zone        = "${element(list(var.gcp_zone_1), count.index)}"
}

///////////////////////////////////////////////
//////// HTTP Backend /////////////////////////
///////////////////////////////////////////////

resource "google_compute_backend_service" "ert_http_lb_backend_service" {
  name        = "${var.gcp_terraform_prefix}-http-lb-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 60
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group.ert-http-lb.0.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.cf.self_link}"]
}

///////////////////////////////////////////////
//////// URL Maps & Proxy /////////////////////
///////////////////////////////////////////////

resource "google_compute_url_map" "https_lb_url_map" {
  name = "${var.gcp_terraform_prefix}-global-pcf"
  default_service = "${google_compute_backend_service.ert_http_lb_backend_service.self_link}"
}

resource "google_compute_target_http_proxy" "http_lb_proxy" {
  name        = "${var.gcp_terraform_prefix}-http-proxy"
  description = "Load balancing front end http"
  url_map     = "${google_compute_url_map.https_lb_url_map.self_link}"
}

resource "google_compute_target_https_proxy" "https_lb_proxy" {
  name             = "${var.gcp_terraform_prefix}-https-proxy"
  description      = "Load balancing front end https"
  url_map          = "${google_compute_url_map.https_lb_url_map.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.ssl-cert.self_link}"]
}

///////////////////////////////////////////////
//////// SSL Certificate(s) ///////////////////
///////////////////////////////////////////////


resource "google_compute_ssl_certificate" "ssl-cert" {
  name        = "${var.gcp_terraform_prefix}-lb-cert"
  description = "user provided ssl private key / ssl certificate pair"
  certificate = "${var.pcf_ert_ssl_cert}"
  private_key = "${var.pcf_ert_ssl_key}"
}

///////////////////////////////////////////////
//////// Health Checks ////////////////////////
///////////////////////////////////////////////

resource "google_compute_http_health_check" "cf" {
  name                = "${var.gcp_terraform_prefix}-cf-public"
//  host                = "api.sys.${var.pcf_ert_domain}."
  port                = 8080
  request_path        = "/health"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 10
  unhealthy_threshold = 2
}

///////////////////////////////////////////////
//////// Global Forwarding Rules //////////////
///////////////////////////////////////////////

resource "google_compute_global_forwarding_rule" "cf-http" {
  name       = "${var.gcp_terraform_prefix}-cf-lb-http"
  ip_address = "${var.pub_ip_global_pcf}"
  target     = "${google_compute_target_http_proxy.http_lb_proxy.self_link}"
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "cf-https" {
  name       = "${var.gcp_terraform_prefix}-cf-lb-https"
  ip_address = "${var.pub_ip_global_pcf}"
  target     = "${google_compute_target_https_proxy.https_lb_proxy.self_link}"
  port_range = "443"
}
