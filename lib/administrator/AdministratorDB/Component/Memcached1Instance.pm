package AdministratorDB::Component::Memcached1Instance;

AdministratorDB::Schema::Result::ComponentInstance->has_many(
  "memcached1s",
  "AdministratorDB::Schema::Result::Memcached1",
  { "foreign.component_instance_id" => "self.component_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
