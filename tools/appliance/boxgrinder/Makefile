all:

centos-6-kanopya.qcow2: centos-6-kanopya.appl VBoxGuestAdditions_4.2.18.iso
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6-kanopya.appl --debug --os-config format:qcow2
	cp build/appliances/x86_64/centos/6/centos-6-kanopya/1.0/centos-plugin/centos-6-kanopya-sda.qcow2 centos-6-kanopya.qcow2

centos-6-kanopya.vmdk: centos-6-kanopya.appl VBoxGuestAdditions_4.2.18.iso
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6-kanopya.appl --debug
	qemu-img convert -f raw -O vmdk -o compat6 build/appliances/x86_64/centos/6/centos-6-kanopya/1.0/centos-plugin/centos-6-kanopya-sda.raw centos-6-kanopya.vmdk

centos-6-kanopya-vagrant.vmdk: centos-6-kanopya-vagrant.appl VBoxGuestAdditions_4.2.18.iso
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6-kanopya-vagrant.appl --debug
	qemu-img convert -f raw -O vmdk -o compat6 build/appliances/x86_64/centos/6/centos-6-kanopya-vagrant/1.0/centos-plugin/centos-6-kanopya-vagrant-sda.raw centos-6-kanopya-vagrant.vmdk

kanopya-centos-appliance.ova: centos-6-kanopya.vmdk
	VBoxManage createvm --name "Kanopya CentOS Appliance" --register --ostype RedHat_64
	VBoxManage modifyvm "Kanopya CentOS Appliance" --memory 2048
	VBoxManage modifyvm "Kanopya CentOS Appliance" --cpus 2
	VBoxManage modifyvm "Kanopya CentOS Appliance" --nic1 nat
	VBoxManage modifyvm "Kanopya CentOS Appliance" --nic2 bridged
	VBoxManage modifyvm "Kanopya CentOS Appliance" --natpf1 Front,tcp,,5000,,5000
	VBoxManage modifyvm "Kanopya CentOS Appliance" --natpf1 SSH,tcp,,2222,,22
	VBoxManage storagectl "Kanopya CentOS Appliance" --name SATA --add sata --bootable on
	VBoxManage storageattach "Kanopya CentOS Appliance" --storagectl SATA --type hdd --medium centos-6-kanopya.vmdk --port 0
	VBoxManage export "Kanopya CentOS Appliance" --output kanopya-centos-appliance.ova --vsys 0 --product "Kanopya" --producturl "http://www.kanopya.org" --vendor "Hedera Technology" --vendorurl "http://www.hederatech.com"

kanopya-centos-vagrant: centos-6-kanopya-vagrant.vmdk
	VBoxManage createvm --name "Kanopya CentOS Vagrant" --register --ostype RedHat_64
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --memory 2048
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --cpus 2
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --nic1 nat
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --nic2 bridged
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --natpf1 Front,tcp,,5000,,5000
	VBoxManage modifyvm "Kanopya CentOS Vagrant" --natpf1 SSH,tcp,,2222,,22
	VBoxManage storagectl "Kanopya CentOS Vagrant" --name SATA --add sata --bootable on
	VBoxManage storageattach "Kanopya CentOS Vagrant" --storagectl SATA --type hdd --medium centos-6-kanopya-vagrant.vmdk --port 0

kanopya-appliance-centos.box: kanopya-centos-vagrant
	vagrant package kanopya-appliance-centos --base "Kanopya CentOS Vagrant" --output kanopya-appliance-centos.box

VBoxGuestAdditions_4.2.18.iso:
	wget http://download.virtualbox.org/virtualbox/4.2.18/VBoxGuestAdditions_4.2.18.iso

libvirt:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6-amd64.appl --debug -p virtualbox

vmware:
	LIBGUESTFS_MEMSIZE=2048 boxgrinder-build centos-6-amd64.appl --debug -p vmware --platform-config type:personal,thin_disk:true

clean:
	rm -rf centos-6-kanopya.qcow2 kanopya-centos-appliance.ova centos-6-kanopya.vmdk centos-6-kanopya-vagrant.vmdk build/appliances/x86_64/centos/6/centos-6-kanopya/1.0/centos-plugin/centos-6-kanopya-sda.* centos-6-kanopya-sda.qcow2 centos-6-kanopya.appl centos-6-kanopya-vagrant.appl build log
	VBoxManage unregistervm "Kanopya CentOS Vagrant" --delete || true
	VBoxManage unregistervm "Kanopya CentOS Appliance" --delete || true

centos-6-kanopya.appl: base.fragment kanopya-base.fragment forwarding.fragment kanopya-setup.fragment debug.fragment cleanup.fragment
	FRAGMENTS="base.fragment kanopya-base.fragment forwarding.fragment kanopya-setup.fragment cleanup.fragment"; \
	[ "$$DEBUG" == "1" ] && FRAGMENTS="$$FRAGMENTS debug.fragment"; \
	./merge_dict.pl $$FRAGMENTS > centos-6-kanopya.appl
	sed -i 's/^\( *\)\(\/.*\):$$/\1"\2":/' centos-6-kanopya.appl

centos-6-kanopya-vagrant.appl: base.fragment kanopya-base.fragment debug.fragment vagrant.fragment cleanup.fragment
	FRAGMENTS="base.fragment kanopya-base.fragment vagrant.fragment cleanup.fragment"; \
	[ "$$DEBUG" == "1" ] && FRAGMENTS="$$FRAGMENTS debug.fragment"; \
	./merge_dict.pl $$FRAGMENTS > centos-6-kanopya-vagrant.appl
	sed -i 's/^\( *\)\(\/.*\):$$/\1"\2":/' centos-6-kanopya-vagrant.appl

.FORCE:
