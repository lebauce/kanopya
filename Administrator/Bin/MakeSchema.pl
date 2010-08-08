use DBIx::Class::Schema::Loader qw/ make_schema_at /;

use lib '../Lib';

  make_schema_at(
      'AdministratorDB::Schema',
      { debug => 1,
        dump_directory => '../Lib',
        components => '+AdministratorDB::EntityBase',
        #additional_base_classes => '+AdministratorDB::EntityBase',
      },
      [ 'dbi:mysql:administrator:localhost:3306', 'root', 'Hedera@123',
         { loader_class => 'MyLoader' } # optionally
      ],
  );

