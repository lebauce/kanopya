package AdministratorDB::Component::Iptables1Instance;

AdministratorDB::Schema::Result::ComponentInstance->has_many(
  "iptables1s",
  "AdministratorDB::Schema::Result::Iptables1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
