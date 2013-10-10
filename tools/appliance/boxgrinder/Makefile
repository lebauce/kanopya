all:	

centos-6.4-kanopya.qcow2:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6.4-amd64.appl --debug --os-config format:qcow2
	cp build/appliances/x86_64/centos/6/centos-6.4-kanopya/1.0/centos-plugin/centos-6.4-kanopya-sda.qcow2 centos-6.4-kanopya.qcow2

centos-6.4-kanopya.vmdk:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6.4-amd64.appl --debug -p virtualbox
	cp build/appliances/x86_64/centos/6/centos-6.4-kanopya/1.0/virtualbox-plugin/centos-6.4-kanopya.vmdk centos-6.4-kanopya.vmdk

virtualbox: centos-6.4-kanopya.vmdk
	VBoxManage createvm --name "Kanopya CentOS Appliance" --register --ostype Linux
	VBoxManage modifyvm "Kanopya CentOS Appliance" --memory 2048
	VBoxManage modifyvm "Kanopya CentOS Appliance" --cpus 2
	VBoxManage modifyvm "Kanopya CentOS Appliance" --nic1 nat
	VBoxManage modifyvm "Kanopya CentOS Appliance" --nic2 bridged
	VBoxManage storagectl "Kanopya CentOS Appliance" --name SATA --add sata --bootable on
	VBoxManage storageattach "Kanopya CentOS Appliance" --storagectl SATA --type hdd --medium centos-6.4-kanopya.vmdk --port 0
	VBoxManage export "Kanopya CentOS Appliance" --output kanopya-centos-appliance.ova --vsys 0 --product "Kanopya" --producturl "http://www.kanopya.org" --vendor "Hedera Technology" --vendorurl "http://www.hederatech.com"

libvirt:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6.4-amd64.appl --debug -p virtualbox

vmware:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6.4-amd64.appl --debug -p vmware --platform-config type:personal,thin_disk:true

clean:
	rm -rf centos-6.4-kanopya.qcow2 kanopya-centos-appliance.ova centos-6.4-kanopya.vmdk build/appliances/x86_64/centos/6/centos-6.4-kanopya/1.0/centos-plugin/centos-6.4-kanopya-sda.* centos-6.4-kanopya-sda.qcow2
	VBoxManage unregistervm "Kanopya CentOS Appliance" --delete

