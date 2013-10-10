# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Setup class implementing Win32 dependant actions

@since    2012-Jun-10
@instance hash
@self     $self

=end classdoc

=cut

package Setup::MSWin32;
use parent 'Setup';
use Data::Dumper;

# ( C:\Program\ Files\kanopya\ui\lib C:\Program\ Files\kanopya\lib\\common C:\Program\ Files\kanopya\lib\administrator C:\Program\ Files\kanopya\lib\executor C:\Program\ Files\kanopya\lib\monitor C:\Program\ Files\kanopya\lib\orchestrator );

=pod

=begin classdoc

init licence path 

=end classdoc

=cut

sub _init {
    my ($self) = @_;

    $self->{licence_path}  = $self->{installpath} . '\UserLicence';
    $self->{services_dir}  = $self->{installpath} . '\sbin\win32\\';
    $self->{services}      = ['kanopya-aggregator.pl', 'kanopya-executor.pl', 'kanopya-frontend.pl', 'kanopya-orchestrator.pl'];	
	$self->{log_directory} = 'C:\var\log\kanopya\\';
	$self->{timedata_dir}  = 'C:\tmp\monitor\TimeData\\';
    $self->{dbschema_path} = $self->{installpath} . '\scripts\database\mysql';
	$self->{PERL5LIB}      = qq[$self->{installpath}\\ui\\lib\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\common\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\administrator\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\executor\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\monitor\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\orchestrator\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\external\\];
	$self->{PERL5LIB}     .= qq[ $self->{installpath}\\lib\\external\\NetApp\\];

	$self->{parameters} = [
		{title => 'Kanopya database root password'},
		
		{ keyname   => 'mysql_root_passwd',
		  caption   => 'Please insert your mysql root password',
		  confirm   => '_confirm_password',
		  hideinput => 1,},
		  
		{title => 'Kanopya services settings'},
		
		{ keyname => 'service_login',
		  caption => 'Please enter the login used to run Kanopya services',},
		  
		{ keyname 	 => 'service_password',
		  caption    => 'Please give a password for the service account',
		  confirm    => '_confirm_password',
		  hideinput  =>  1,},
	];

    
	#Hard parameter input for mandatory things that should not bother a windows user
	$self->{parameters_values}->{mysql_host} = '127.0.0.1';
	$self->{parameters_values}->{mysql_port} = '3306';
	$self->{parameters_values}->{mysql_kanopya_passwd} = 'K4n0pY4';
	$self->{parameters_values}->{vg_name} = 'vg1';
	$self->{parameters_values}->{vg_size} = '100';
	$self->{parameters_values}->{vg_free_space} = '90';
	$self->{parameters_values}->{pvs} = [];
	$self->{parameters_values}->{admin_net_ip} = '192.168.100.100';
	$self->{parameters_values}->{admin_net_mask} = '255.255.255.0';
	$self->{parameters_values}->{admin_net_size} = '192.168.100.0';
	$self->{parameters_values}->{admin_net_gateway} = '192.168.100.1';
	$self->{parameters_values}->{admin_net_ip} = '192.168.100.100';
	$self->{parameters_values}->{domainname} = 'domain';
    $self->{parameters_values}->{hostname} = 'hostname';
    $self->{parameters_values}->{initiatorname} = 'iqn.toto';
    $self->{parameters_values}->{admin_iface_mac} = '00:00:00:00:00:00';
    $self->{parameters_values}->{admin_iface} = 'eth0';
}

=pod

=begin classdoc

Create user and database shema

=end classdoc

=cut

sub _create_database {
	my ($self) = @_;
	
    my $host 	   = $self->{parameters_values}->{mysql_host};
    my $port	   = $self->{parameters_values}->{mysql_port};
    my $passwd 	   = $self->{parameters_values}->{mysql_root_passwd};
    my $userpasswd = $self->{parameters_values}->{mysql_kanopya_passwd};
	
	# kanopya user creation
    my $query = "use mysql; SELECT user FROM mysql.user WHERE user='kanopya' LIMIT 1;";
    my $output = `mysql -h $host -P $port -u root -p$passwd -e "$query"`;
    if($output !~ /kanopya/) {
        print " - Creating kanopya mysql user\n";
        $query = "CREATE USER 'kanopya'\@'localhost' IDENTIFIED BY '$userpasswd'";
        $output = `mysql -h $host  -P $port -u root -p$passwd -e "$query"`;
    }
    else {
        print " - Mysql kanopya user already exists\n";
    }

    # kanopya user privileges
    print " - Granting all privileges on kanopya database to kanopya user\n";
    $query = "GRANT ALL PRIVILEGES ON kanopya.* TO 'kanopya' WITH GRANT OPTION";
    $output = `mysql -h $host -P $port -u root -p$passwd -e "$query"`;

    # schema creation
    # print " - Create kanopya database...";

    # system("mysql -h $host  -P $port -u kanopya -p$userpasswd < \"$self->{dbschema_path}/schemas/Schemas.sql\" ");
    # print "ok\n";

    # components schema 
    # print " - Create components schemas...";

    # open(my $FILE, '<', $self->{installpath} . '/scripts/install/components.conf');
    # my @lines = <$FILE>;
    # close($FILE);
    # LINE:
    # for my $line (@lines) {
       # chomp($line);
       # if(( ! $line ) || ( $line =~ /^#/ )) {
           # next LINE;
       # }
       # system("mysql -h $host  -P $port -u kanopya -p$userpasswd < \"$self->{dbschema_path}/schemas/components/$line.sql\" ");  
    # }
    # print "ok\n";
    
    # populate initial data
    my %datas = (
        kanopya_vg_name          => $self->{parameters_values}->{vg_name},
        kanopya_vg_size          => $self->{parameters_values}->{vg_size},
        kanopya_vg_free_space    => $self->{parameters_values}->{vg_free_space},
        kanopya_pvs              => $self->{parameters_values}->{pvs},
        poolip_addr              => $self->{parameters_values}->{admin_net_ip},
        poolip_netmask           => $self->{parameters_values}->{admin_net_mask},
        poolip_mask              => $self->{parameters_values}->{admin_net_size},
        poolip_gateway           => $self->{parameters_values}->{admin_net_gateway},
        ipv4_internal_network_ip => $self->{parameters_values}->{admin_net_ip},
        admin_domainname         => $self->{parameters_values}->{domainname},
        kanopya_hostname         => $self->{parameters_values}->{hostname},
        kanopya_initiator        => $self->{parameters_values}->{initiatorname},
        mb_hw_address            => $self->{parameters_values}->{admin_iface_mac},
        admin_interface          => $self->{parameters_values}->{admin_iface},
        admin_password           => $self->{parameters_values}->{mysql_kanopya_passwd},
        admin_kernel             => undef,
        tmstp                    => time()
    );

    require PopulateDB;
    print " - Populate database...";
    populateDB(login    => 'admin',
               password => $self->{parameters_values}->{mysql_kanopya_passwd},
               %datas);
    print "ok\n";
}

=pod

=begin classdoc

Generate kanopya config and log files

=end classdoc

=cut

sub _generate_kanopya_conf {
    my ($self) = @_;

    print "\n - Configuration files generation\n";
    my $configfiles = [
        # config files
        { path => $self->{installpath}.'/conf/executor.conf',
          template => 'templates\executor.conf.tt',
          data     => { logdir            => $self->{parameters_values}->{log_dir},
                        masterimages_dir  => $self->{parameters_values}->{masterimages_dir}, 
                        tftp_dir          => $self->{parameters_values}->{tftp_dir}, 
                        clusters_dir      => $self->{parameters_values}->{clusters_dir},
                        internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask},
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path => $self->{installpath}.'/conf/aggregator.conf',
          template => 'templates\aggregator.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path => $self->{installpath}.'/conf/orchestrator.conf',
          template => 'templates\orchestrator.conf.tt',
          data     => { admin_password => $self->{parameters_values}->{mysql_kanopya_passwd}, }
        },
        { path => $self->{installpath}.'/conf/monitor.conf',
          template => 'templates\monitor.conf.tt',
          data     => { internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask}, 
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd},}
        },
        { path => $self->{installpath}.'/conf/libkanopya.conf',
          template => 'templates\libkanopya.conf.tt',
          data     => { internal_net_add  => $self->{parameters_values}->{admin_ip},
                        internal_net_mask => $self->{parameters_values}->{admin_net_mask}, 
                        db_user           => 'kanopya',
                        dbip              => $self->{parameters_values}->{mysql_host}, 
                        dbport            => $self->{parameters_values}->{mysql_port},   
                        admin_password    => $self->{parameters_values}->{mysql_kanopya_passwd},
                        logdir            => $self->{parameters_values}->{log_dir}, 
                        crypt_salt        => $self->{parameters_values}->{crypt_salt}}
        },
        { path => $self->{installpath}.'/ui/Frontend/config.yml',
          template => 'templates\dancer_cfg.tt',
          data     => { product       => 'KIM', 
                        show_gritters => 1,
                        sessions_dir  => $self->{parameters_values}->{sessions_dir},
                        log_directory => $self->{parameters_values}->{log_dir}, }
        },
        
        # log files
        { path => $self->{installpath}.'/conf/executor-log.conf',
          template => 'templates\executor-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/state-manager-log.conf',
          template => 'templates\state-manager-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/aggregator-log.conf',
          template => 'templates\aggregator-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/collector-log.conf',
          template => 'templates\collector-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/monitor-log.conf',
          template => 'templates\monitor-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/orchestrator-log.conf',
          template => 'templates\orchestrator-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        { path => $self->{installpath}.'/conf/webui-log.conf',
          template => 'templates\webui-log.conf.tt',
          data     => { logdir => $self->{parameters_values}->{log_dir}.'/' }
        },
        
    ];
    
    my $template_config = {
        INCLUDE_PATH => $self->{template_path},
        INTERPOLATE  => 1,
        POST_CHOMP   => 1,
        EVAL_PERL    => 1,
    };
    
    my $template = Template->new($template_config);
    for my $file (@$configfiles) {
        print "$file->{path}\n";
        $template->process($file->{template}, 
                           $file->{data}, 
                           $file->{path}) || 
            die $template->error(), "\n"; 
    
    }                    
}

=pod

=begin classdoc

Complete the installation process:
- Generate configuration files
- Initialize PERL5LIB
- Create directories
- Generation du data.sql
- Creation du user kanopya dans mysql
- Creation de la base dans mysql + components
- Insert du data.sql
- Install windows services
- Generate Dancer configuration

=end classdoc

=cut

sub process {
	my ($self) = @_;
	
	my $cmd;
	my $exec;
	
	#init PERL5LIB in system
	$cmd = qq[setx PERL5LIB "$self->{PERL5LIB}"];
	eval {
        $exec = `$cmd 2>&1`;
	};
	if ($@) {
		print 'Error while setting PERL5LIB: ' . $@;
	}
	else {
		print $exec . "\n";
		print 'You will have to restart a shell session to enjoy the newly configured PERL5LIB in it' . "\n";
	}
	
	#TODO make this work..
	#export PERL5LIB in current environment 

	$cmd = '$Env:PERL5LIB = ' . $self->{PERL5LIB};
	eval {
        $exec = `$cmd 2>&1`;
	};
	if ($@) {
		print 'Error while exporting PERL5LIB: ' . $@;
	}

    #generate configuration files
    $self->_generate_kanopya_conf();

	#create directories
	$cmd  = 'mkdir ' . $self->{log_directory};
	$exec = `$cmd 2>&1`;
	
	$cmd  = 'mkdir ' . $self->{timedata_dir};
	$exec = `$cmd 2>&1`;
	
    #create and initialize database
    $self->_create_database();
    
    #install windows services
    foreach my $service_file (@{ $self->{services} }) {
        my ($service_name) = split '.pl', $file;
        print 'installing ' . "$service_name ... \n";
        $cmd = qq[perl.exe "$self->{services_dir}$service_file" -i "$self->{installpath}" $self->{parameters_values}->{service_login} $self->{parameters_values}->{service_password}];

        eval {
            system($cmd);
        };
        if ($@) {
            print "$service_name" . ' failed to be installed: ' . $@ . "\n";
            print 'Please launch again setup or install the service manually' . "\n";
        }
        else {
            print 'Launching '. $service_name . "...\n";
            my $sc = qq{sc.exe start $service_name};
            eval {
                system($sc);
            };
            if ($@) {
                print 'Error while launching ' . $service_name . ' ' . $@ . "\n";
            }
        }
    }
}

1;
