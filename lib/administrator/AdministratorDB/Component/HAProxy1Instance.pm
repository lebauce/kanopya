package AdministratorDB::Component::HAProxy1Instance;

AdministratorDB::Schema::Result::ComponentInstance->has_many(
  "haproxy1s",
  "AdministratorDB::Schema::Result::HAProxy1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
