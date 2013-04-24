class kanopya::rabbitmq ($disk_nodes) {
    $rabbitmq_repo = $operatingsystem ? {
        /(?i)(debian|ubuntu)/ => 'rabbitmq::repo::apt',
        default               => 'rabbitmq::repo::rhel'
    }
    class { "$rabbitmq_repo": }
    class { 'rabbitmq::server':
        wipe_db_on_cookie_change => true,
        config_cluster           => true,
        cluster_disk_nodes       => $disk_nodes,
        erlang_cookie            => 'rabbit',
    }
    Rabbitmq_user <<| tag == "${fqdn}" |>>
    Rabbitmq_user_permissions <<| tag == "${fqdn}" |>>
}

