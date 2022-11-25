    terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.43.0"
    }
  }
}
provider "google" {
  # Configuration options
  project = "suswa-bigquery"
  region= "asia-south1"
  zone = "asia-south1-a"
  credentials = "keys2.json"
}

resource "google_compute_network" "vpc-tf" {
    name = "vpc-tf"
    auto_create_subnetworks = false
    routing_mode            = "GLOBAL"  
}

resource "google_compute_subnetwork" "uc1-private-subnet" {

    name = "uc1-private-subnet"
    network = google_compute_network.vpc-tf.id
    ip_cidr_range = "10.26.1.0/24"
    region = "us-central1"  
}

resource "google_compute_subnetwork" "uc1-public-subnet" {
   name = "uc1-public-subnet"
    network = google_compute_network.vpc-tf.id
    ip_cidr_range = "10.26.2.0/24"
    region = "us-central1"  
}

resource "google_compute_subnetwork" "ue1-private-subnet" {
  name = "ue1-private-subnet"
    network = google_compute_network.vpc-tf.id
    ip_cidr_range = "10.26.3.0/24"
    region = "us-east1"  
}

resource "google_compute_subnetwork" "ue1-public-subnet" {
  name = "ue1-public-subnet"
    network = google_compute_network.vpc-tf.id
    ip_cidr_range = "10.26.4.0/24"
    region = "us-east1" 

}

resource "google_compute_firewall" "allow-internal" {
    name = "allow-internal"
    network = google_compute_network.vpc-tf.id
   
    allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
      ports     = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [ "10.26.1.0/24",
  "10.26.2.0/24",
  "10.26.3.0/24",
  "10.26.4.0/24" ]

}

resource "google_compute_firewall" "allow-http" {
  name    = "fw-allow-http"
  network = google_compute_network.vpc-tf.id
allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http"] 
}

resource "google_compute_firewall" "allow-bastion" {
  name    = "fw-allow-bastion"
  network =  google_compute_network.vpc-tf.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
     
  target_tags = ["ssh"]
  }

####################################
resource "google_compute_instance" "vm1-tf" {

    name = "vm1-tf"
    machine_type = "n1-standard-1"
    zone = "us-central1-c"
    tags          = ["ssh","http"]
    
    boot_disk {
    initialize_params {
      image     =  "centos-7-v20180129"     
    }
  }
labels = {
      webserver =  "true"     
    }

metadata = {
        startup-script = <<SCRIPT
        apt-get -y update
        apt-get -y install nginx
        export HOSTNAME=$(hostname | tr -d '\n')
        export PRIVATE_IP=$(curl -sf -H 'Metadata-Flavor:Google' http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip | tr -d '\n')
        echo "Welcome to $HOSTNAME - $PRIVATE_IP" > /usr/share/nginx/www/index.html
        service nginx start
        SCRIPT
    } 
    network_interface {
      network = google_compute_network.vpc-tf.id
      subnetwork = google_compute_subnetwork.uc1-public-subnet.id
      access_config {
      // Ephemeral IP
    }
    }
}
##################################################

resource "google_compute_instance" "vm2-tf" {

    name = "vm2-tf"
    machine_type = "n1-standard-1"
    zone = "us-east1-c"
    tags          = ["ssh","http"]
    boot_disk {
    initialize_params {
      image     =  "centos-7-v20180129"     
    }
  }
labels = {
      webserver =  "true"     
    }

metadata = {
        startup-script = <<SCRIPT
        apt-get -y update
        apt-get -y install nginx
        export HOSTNAME=$(hostname | tr -d '\n')
        export PRIVATE_IP=$(curl -sf -H 'Metadata-Flavor:Google' http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip | tr -d '\n')
        echo "Welcome to $HOSTNAME - $PRIVATE_IP" > /usr/share/nginx/www/index.html
        service nginx start
        SCRIPT
    } 
    network_interface {
      network = google_compute_network.vpc-tf.id
      subnetwork = google_compute_subnetwork.ue1-public-subnet.id
      access_config {
      // Ephemeral IP
    }
    }
}

