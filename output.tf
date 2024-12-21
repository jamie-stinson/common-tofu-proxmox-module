output "node_hostnames" {
  value = { for key, value in random_string.this : key => value.result }
}
