package AdministratorDB::Component::Iptables1Instance;

AdministratorDB::Schema::Result::ComponentInstance->might_have(
  "iptables1_sec_rule",
  "AdministratorDB::Schema::Result::Iptables1SecRule",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
