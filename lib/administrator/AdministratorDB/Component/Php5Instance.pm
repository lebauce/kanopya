package AdministratorDB::Component::Php5Instance;

AdministratorDB::Schema::Result::ComponentInstance->has_many(
  "php5s",
  "AdministratorDB::Schema::Result::Php5",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
