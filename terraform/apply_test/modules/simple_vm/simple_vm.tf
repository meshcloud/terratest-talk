provider google {
  region  = "europe-west1"
  version = "=3.0.0"
  project = "terratest-talk"
  zone    = "europe-west1-b"
}

resource google_compute_instance test {
  name         = "hello-terratest"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
