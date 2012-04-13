package AdministratorDB::Component::Opennebula3Instance;

AdministratorDB::Schema::Result::ComponentInstance->might_have(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
