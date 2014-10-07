UPDATE indicator SET indicator_oid = CONCAT('vsphere_vm.', indicator_oid) WHERE indicator_label LIKE 'vsphere vm/%';
UPDATE indicator SET indicator_oid = CONCAT('vsphere_hv.', indicator_oid) WHERE indicator_label LIKE 'vsphere hv/%';

-- DOWN --
