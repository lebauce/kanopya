class kanopya::rabbitmq {
    $rabbitmq_repo = $operatingsystem ? {
        /(?i)(debian|ubuntu)/ => 'rabbitmq::repo::apt',
        default               => 'rabbitmq::repo::rhel'
    }
    class { "$rabbitmq_repo": }
    class { 'rabbitmq::server': }
    Rabbitmq_user <<| tag == "${fqdn}" |>>
    Rabbitmq_user_permissions <<| tag == "${fqdn}" |>>
}

