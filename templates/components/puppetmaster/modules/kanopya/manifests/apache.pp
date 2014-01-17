class kanopya::apache(
  $vhosts = []
) {
  class { '::apache': }
  class { 'kanopya::mod_status': }

  create_resources("apache::vhost", $vhosts)
}
