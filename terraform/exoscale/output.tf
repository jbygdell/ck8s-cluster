# Service cluster outputs
output "sc_master_ips" {
  value = "${module.service_cluster.master_ip_addresses}"
}

output "sc_worker_ips" {
  value = "${module.service_cluster.worker_ip_addresses}"
}

output "sc_nfs_ips" {
  value = "${module.service_cluster.nfs_ip_address}"
}

output "sc_dns_name" {
  value = "${module.service_cluster.dns_record_name}"
}

output "sc_ingress_controller_lb_ip_address" {
  value = "${module.service_cluster.ingress_controller_lb_ip_address}"
}

output "sc_loadbalancer_ips" {
  value = "${module.service_cluster.control_plane_lb_ip_address}"
}

# Workload cluster cluster outputs

output "wc_master_ips" {
  value = "${module.workload_cluster.master_ip_addresses}"
}

output "wc_worker_ips" {
  value = "${module.workload_cluster.worker_ip_addresses}"
}

output "wc_nfs_ips" {
  value = "${module.workload_cluster.nfs_ip_address}"
}

output "wc_dns_name" {
  value = "${module.workload_cluster.dns_record_name}"
}

output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}

output "wc_ingress_controller_lb_ip_address" {
  value = "${module.workload_cluster.ingress_controller_lb_ip_address}"
}

output "wc_loadbalancer_ips" {
  value = "${module.workload_cluster.control_plane_lb_ip_address}"
}

output "ansible_inventory_sc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts            = <<-EOF
%{for name, data in module.service_cluster.master_ip_addresses~}
${name} ansible_host=${data.public_ip} private_ip=${data.private_ip}
%{endfor~}
EOF
    masters                 = <<-EOF
%{for name, data in module.service_cluster.master_ip_addresses~}
${name}
%{endfor~}
EOF
    worker_hosts            = <<-EOF
%{for name, data in module.service_cluster.worker_ip_addresses~}
${name} ansible_host=${data.public_ip} private_ip=${data.private_ip}
%{endfor~}
EOF
    workers                 = <<-EOF
%{for name, worker in module.service_cluster.worker_ip_addresses~}
${name}
%{endfor~}
EOF
    cluster_name            = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc
    public_endpoint         = module.service_cluster.control_plane_lb_ip_address
    private_network_cidr    = module.service_cluster.cluster_private_network_cidr
    control_plane_endpoint  = "127.0.0.1"
    control_plane_port      = "7443"
    internal_lb_children    = "nodes"
    cloud_provider          = ""
    cloud_provider_vars     = ""
    cloud_config            = ""
    calico_mtu              = "1480"
    loadbalancers           = ""
    kubeadm_init_extra_args = ""
  })
}

output "ansible_inventory_wc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts            = <<-EOF
%{for name, data in module.workload_cluster.master_ip_addresses~}
${name} ansible_host=${data.public_ip} private_ip=${data.private_ip}
%{endfor~}
EOF
    masters                 = <<-EOF
%{for name, data in module.workload_cluster.master_ip_addresses~}
${name}
%{endfor~}
EOF
    worker_hosts            = <<-EOF
%{for name, data in module.workload_cluster.worker_ip_addresses~}
${name} ansible_host=${data.public_ip} private_ip=${data.private_ip}
%{endfor~}
EOF
    workers                 = <<-EOF
%{for name, worker in module.workload_cluster.worker_ip_addresses~}
${name}
%{endfor~}
EOF
    cluster_name            = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc
    public_endpoint         = module.workload_cluster.control_plane_lb_ip_address
    private_network_cidr    = module.workload_cluster.cluster_private_network_cidr
    control_plane_endpoint  = "127.0.0.1"
    control_plane_port      = "7443"
    internal_lb_children    = "nodes"
    cloud_provider          = ""
    cloud_provider_vars     = ""
    cloud_config            = ""
    calico_mtu              = "1480"
    loadbalancers           = ""
    kubeadm_init_extra_args = ""
  })
}
