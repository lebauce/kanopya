package AdministratorDB::Component::Keepalived1Instance;

AdministratorDB::Schema::Result::ComponentInstance->might_have(
  "keepalived1",
  "AdministratorDB::Schema::Result::Keepalived1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
