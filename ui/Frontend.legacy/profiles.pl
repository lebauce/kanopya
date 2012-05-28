{
    login => {
        'required' => [ qw(
            login password
        )],
    },
    public_ip_add => {
        'required' => [ qw(
            ip_address ip_mask
        )],
    },
}
