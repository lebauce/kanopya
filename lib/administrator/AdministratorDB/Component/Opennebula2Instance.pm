package AdministratorDB::Component::Opennebula2Instance;

AdministratorDB::Schema::Result::ComponentInstance->might_have(
  "opennebula2",
  "AdministratorDB::Schema::Result::Opennebula2",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
