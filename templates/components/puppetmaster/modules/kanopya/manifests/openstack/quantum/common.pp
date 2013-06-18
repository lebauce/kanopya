class kanopya::openstack::quantum::common(
    $rabbit_user        = "quantum",
    $rabbit_password    = "quantum",
    $rabbit_hosts       = [ "localhost" ],
    $rabbit_virtualhost = "/"
) {
    class { 'quantum':
        bind_host           => $admin_ip,
        rabbit_password     => "${rabbit_password}",
        rabbit_hosts        => $rabbit_hosts,
        rabbit_user         => "${rabbit_user}",
        rabbit_virtual_host => "${rabbit_virtualhost}"
    }

    quantum_plugin_ovs {
        'SECURITYGROUP/firewall_driver': value => "quantum.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver";
    }
}
