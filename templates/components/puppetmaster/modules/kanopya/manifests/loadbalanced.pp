class kanopya::loadbalanced(
  $members = []
) {
  create_resources('@@haproxy::balancermember', $members)
}
