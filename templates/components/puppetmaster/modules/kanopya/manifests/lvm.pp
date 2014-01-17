class kanopya::lvm(
  $pvs = [],
  $vgs = []
) {
  tag('kanopya::lvm')

  package { 'lvm':
    name => $operatingsystem ? {
      default => 'lvm2'
    },
    ensure => present,
  }

  create_resources('physical_volume', $pvs)
  create_resources('volume_group', $vgs)
}
