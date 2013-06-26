class kanopya::openiscsi(
    $initiatorname
){
        file { '/etc/iscsi/initiatorname.iscsi':
            content => "InitiatorName=${initiatorname}\n"
        }
}

