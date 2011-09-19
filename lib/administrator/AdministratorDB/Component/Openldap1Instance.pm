package AdministratorDB::Component::Openldap1Instance;

AdministratorDB::Schema::Result::ComponentInstance->might_have(
  "openldap1",
  "AdministratorDB::Schema::Result::Openldap1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
