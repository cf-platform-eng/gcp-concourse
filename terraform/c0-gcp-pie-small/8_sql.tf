///////////////////////////////////////////////
//////// SQL Instance /////////////////////////
///////////////////////////////////////////////

resource "google_sql_database_instance" "master" {
  region           = "${var.gcp_region}"
  database_version = "MYSQL_5_6"
  name             = "${var.ert_sql_instance_name}"

  settings {
    tier = "db-f1-micro"

    ip_configuration = {
      ipv4_enabled = true

      authorized_networks = [
        {
          name  = "nat-1"
          value = "${google_compute_instance.nat-gateway-pri.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "opsman"
          value = "${google_compute_instance.ops-manager.network_interface.0.access_config.0.assigned_nat_ip}"
        },
      ]
    }
  }
  count = "1"
}
