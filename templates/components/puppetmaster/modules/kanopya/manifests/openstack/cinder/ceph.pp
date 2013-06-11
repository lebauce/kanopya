class kanopya::openstack::cinder::ceph(
  $ceph_backend_section = "ceph-backend"
) {
    tag("kanopya::cinder")

    cinder_config {
        "${ceph_backend_section}/volume_driver":       value =>
            'cinder.volume.drivers.rbd.RBDDriver';
        "${ceph_backend_section}/rbd_pool":            value => "volumes";
        "${ceph_backend_section}/glance_api_version":  value => "2";
    }
}
