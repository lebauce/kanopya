class kanopya::openstack::quantum::common(
    $rabbit_user     = "quantum",
    $rabbit_password = "quantum",
    $rabbit_host     = "localhost"
) {
    class { 'quantum':
        rabbit_password => "${rabbit_password}",
        rabbit_host     => "${rabbit_host}",
        rabbit_user     => "${rabbit_user}"
    }

    quantum_plugin_ovs {
        'SECURITYGROUP/firewall_driver': value => "quantum.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver";
    }
}
