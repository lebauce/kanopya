all:

kanopya-1.8.tar.gz:
	mkdir -p build/SOURCES
	rm -rf build/SOURCES/kanopya-1.8.tar.gz
	# cd ../../../.. && git archive --format=tar --prefix=kanopya-1.8/ dev | gzip > tools/deployment/packaging/rpm/build/SOURCES/kanopya-1.8.tar.gz
	wget -O build/SOURCES/deployment_solver.jar http://download.kanopya.org/constraint_engine/deployment_solver/deployment_solver.jar
	cd ../../../.. && sh tools/deployment/packaging/rpm/git-archive-all.sh --format tar --prefix kanopya-1.8/ tools/deployment/packaging/rpm/build/SOURCES/kanopya-1.8.tar
	gzip build/SOURCES/kanopya-1.8.tar
	cp ../../../appliance/boxgrinder/puppet-dhcp-pxefilename.patch build/SOURCES/

rpm: kanopya-1.8.tar.gz
	rpmbuild -bb --define "_topdir `pwd`/build" kanopya.spec

srpm: kanopya-1.8.tar.gz
	rpmbuild -bs --define "_topdir `pwd`/build" kanopya.spec

