class kanopya::haproxy(
  $listens = []
) {
  include ::haproxy

  create_resources("haproxy::listen", $listens)
}

