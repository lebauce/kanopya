class kanopya::executor($password) {
    rabbitmq_user { 'executor':
        admin    => true
        password => "${password}",
        provider => "rabbitmqctl",
    }

    rabbitmq_user_permissions { "executor@/":   
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
    }
}