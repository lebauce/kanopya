package AdministratorDB::Component::Syslogng3Instance;

AdministratorDB::Schema::Result::ComponentInstance->has_many(
  "syslogng3s",
  "AdministratorDB::Schema::Result::Syslogng3",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
