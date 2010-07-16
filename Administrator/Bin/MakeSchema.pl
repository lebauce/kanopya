use DBIx::Class::Schema::Loader qw/ make_schema_at /;

  make_schema_at(
      'AdministratorDB::Schema',
      { debug => 1,
        dump_directory => '../Lib',
      },
      [ 'dbi:mysql:administrator:10.0.0.1:3306', 'root', 'Hedera@123',
         { loader_class => 'MyLoader' } # optionally
      ],
  );

