provider "smartos-cluster" {
    hosts = {
        "r620": "10.99.50.1",
        "r320": "10.99.50.2",
        "r710": "10.99.50.3",
    }
    user = "root"
}

data "smartos-cluster_image" "illumos" {
    node_name = "r620"
    name = "base-64-lts"
    version  = "18.4.0"
}

variable "node_configurations" {
  default = {
      "r620" = {
        "ip" = "10.0.222.225"          
        "cpu_cap" = 400
      }
      "r710" = {
        "ip" = "10.0.222.226"          
        "cpu_cap" = 200
      }
      "r710" = {
        "ip" = "10.0.222.227"          
        "cpu_cap" = 300
      }
  }
}

resource "smartos-cluster_machine" "illumos" {
    for_each = var.node_configurations

    node_name = each.key
    alias = "cluster_test"
    brand = "joyent"
    cpu_cap = each.value["cpu_cap"]

    customer_metadata = {
        # Note: this is my public SSH key...use your own.  :-)
        "root_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/eqBF4qIn6LVLAXhTajccYtB/7m0vZ4qEqNSFKjkyrBCPxfs5jxOnp6Vwp+LdqBm+ZMeCr0t+U0yyayCVGjiTEFYYVT5VyZKyC+M/RJni/lo8nOi4Ah+GxuKyLzQnIAfTm8oeKZ8uyWY++RMZ9mOMBwaHfW97qZApAL+13A93N1Z31K68Siqd6nZojQ1Cvp3/zd+irwjYI7qNbNggMXsMNWYlZOZOxfxVx3jnS0e4b6Hr+L/ChbbTXqi13G3J3LUFFn+k76Pw5+QznOcWtkHq2RctpEhnWl+Px1WjK6blsZ2+pzHK+TAcqZd3vyPfW8tKriyOtwuCKkllDI8TqDe/JW8iGBtglB/8m2L0rmTHGnGjaai6Gk93c92NW2+NB4y8URGENTT0utkpWMxNqtteq40fpLEvPtB2Hop3hViz8RffLdAsbT0B3OrsDE9HXIPtEneLtymvff7we/vtIqw02H3kFUlHP+I623MpjvtTVcWx36c2Fp6nwufl59QvFb0="
        "user-script" = "/usr/sbin/mdata-get root_authorized_keys > ~root/.ssh/authorized_keys"
    }

    image_uuid = data.smartos-cluster_image.illumos.id
    maintain_resolvers = true
    max_physical_memory = 512
    nics {
        nic_tag = "external"
        ips = ["${each.value["ip"]}/16"]
        gateways = ["10.0.0.1"]
        interface = "net4"
    }

    quota = 25

    resolvers = ["1.1.1.1", "1.0.0.1"]

    connection {
        host = each.value["ip"]
    }

    provisioner "remote-exec" {
        inline = [
            "pkgin -y update",
            "pkgin -y in htop",
        ]
    }
}
