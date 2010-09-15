use DBIx::Class::Schema::Loader qw/ make_schema_at /;

use lib '/workspace/mcs/Administrator/Lib';

  make_schema_at(
      'AdministratorDB::Schema',
      { debug => 1,
        dump_directory => '/workspace/mcs/Administrator/Lib',
        components => '+AdministratorDB::EntityBase',
        #additional_base_classes => '+AdministratorDB::EntityBase',
      },
      [ 'dbi:mysql:administrator:localhost:3306', 'root', 'Hedera@123'],
  );

