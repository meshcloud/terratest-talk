
resource google_compute_forwarding_rule test {
  name   = "hello-terratest"
  target = google_compute_target_pool.test.self_link
}

# resource google_compute_target_pool test {
#   name = "hello-terratest"

#   instances = [
#     google_compute_instance.test.self_link
#   ]
# }
