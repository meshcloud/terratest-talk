provider google {
  region  = "europe-west1"
  version = "=3.0.0"
  project = "terratest-talk"
  zone    = "europe-west1-b"
}

locals {
  subnets = [
    "public",
    "transit",
    "private"
  ]
}

resource google_compute_network config_test {
  name                    = "terratest-config-test"
  auto_create_subnetworks = false
}

resource google_compute_subnetwork subnets {
  count         = length(local.subnets)
  name          = local.subnets[count.index]
  ip_cidr_range = cidrsubnet("10.0.0.0/16", 8, count.index)
  network       = google_compute_network.config_test.self_link

}

resource google_compute_instance test {
  count        = length(local.subnets)
  name         = "${local.subnets[count.index]}-1"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets[count.index].self_link

    # Only give public VM an externalIP
    # Note: This basically creates a access_config{} block for public but does not 
    # render the field at all for the others
    dynamic access_config {
      for_each = local.subnets[count.index] == "public" ? [local.subnets[count.index]] : []
      content {
      }
    }
  }

  tags = [
    local.subnets[count.index]
  ]
}

resource google_compute_firewall public {
  name = "public"

  network = google_compute_network.config_test.name

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  target_tags = ["public"]
}

resource google_compute_firewall private {
  name = "private"

  network = google_compute_network.config_test.name

  allow {
    protocol = "icmp"
  }

  target_tags = ["private"]
  source_tags = ["transit"]
}

resource google_compute_firewall transit {
  name = "transit"

  network = google_compute_network.config_test.name

  allow {
    protocol = "icmp"
  }

  target_tags = ["transit"]
  source_tags = ["private", "public"]
}

output public_ip {
  value = google_compute_instance.test[0].network_interface.0.access_config.0.nat_ip
}
