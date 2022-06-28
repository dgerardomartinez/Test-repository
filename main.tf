terraform {
  required_providers {
      digitalocean = {
          source = "digitalocean/digitalocean"
          version = "~> 2.0"
      }
  }
}
#Definimos variables
variable "do_token" {}
variable "ssh_key_private" {}
variable "droplet_ssh_key_id" {}
variable "droplet_name" {}
variable "droplet_size" {}
variable "droplet_region" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
    token = "${var.do_token}"
}
#creación de vpc 
resource "digitalocean_vpc" "devopsfinal" {
    name = "devopsfinal"
    region = "nyc1"
    ip_range = "10.200.60.0/24"
}
# Create a Droplet
resource "digitalocean_droplet" "redmine" {
    image  = "ubuntu-18-04-x64"
    name   = "${var.droplet_name}"
    region = "${var.droplet_region}"
    size   = "${var.droplet_size}"
    monitoring = "true"
    vpc_uuid = digitalocean_vpc.devopsfinal.id
    ssh_keys = ["${var.droplet_ssh_key_id}"]

    # Install python on the droplet using remote-exec to execute ansible playbooks to configure the services
    provisioner "remote-exec" {
        inline = [
           "echo Done!",
        ]

         connection {
            host        = "${self.ipv4_address}"
            type        = "ssh"
            user        = "root"
            private_key = "${file("${var.ssh_key_private}")}"
        }
    }

    # Execute ansible playbooks using local-exec 
    provisioner "local-exec" {
        environment = {
            PUBLIC_IP                 = "${self.ipv4_address}"
            PRIVATE_IP                = "${self.ipv4_address_private}"
            ANSIBLE_HOST_KEY_CHECKING = "False" 
        }

        working_dir = "playbooks/"
        command     = "ansible-playbook -u root --private-key ${var.ssh_key_private} -i ${self.ipv4_address}, redmine.yml"
    }
}

