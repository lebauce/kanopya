package Entity;
use base 'BaseDB';

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

=head2 getMasterGroupName

    Class : public
    desc : retrieve the master group name associated with this entity
    return : scalar : master group name

=cut

sub getMasterGroupName {
    my $self = shift;
    my $class = ref $self || $self;
    my @array = split(/::/, "$class");
    my $mastergroup = pop(@array);
    return $mastergroup;
}

=head2 getMasterGroupEid

    Class : public
    
    desc : return entity_id of entity master group
    TO BE CALLED ONLY ON CHILD CLASS/INSTANCE
    return : scalar : entity_id

=cut

sub getMasterGroupEid {
    my $self = shift;
    my $adm = Administrator->new();
    my $mastergroup = $self->getMasterGroupName();
    my $eid = $adm->{db}->resultset('Gp')->find({ gp_name => $mastergroup })->entitylink->get_column('entity_id');
    return $eid;
}

=head2 getGroups

return groups resultset where this entity appears (only on an already saved entity)

=cut

sub getGroups {
    my $self = shift;
    if( not $self->{_dbix}->in_storage ) { return; } 
    #$log->debug("======> GetGroups call <======");
    my $mastergroup = $self->getMasterGroupEid();
    my $groups = $self->{_rightschecker}->{_schema}->resultset('Gp')->search({
        -or => [
            'ingroups.entity_id' => $self->{_dbix}->get_column('entity_id'),
            'gp_name' => $mastergroup ]},
            
        {     '+columns' => {'entity_id' => 'gp_entity.entity_id'},
            #'+columns' => [ 'gp_entity.entity_id' ], 
            join => [qw/ingroups gp_entity/] }
    );
    return $groups;
}

sub asString {
    my $self = shift;
    
    my %h = $self->getAttrs;
    my @s = map { "$_ => $h{$_}, " } keys %h;
    return ref $self, " ( ",  @s,  " )";
}

=head2 getPerms

    class : public

    desc : return a structure describing method permissions for the current authenticated user.
        If called on a class, return methods permissions holded by mastergroup only.
        Else return all methods permissions. 

    return : hash ref

=cut

sub getPerms {
    my $self = shift;
    my $class = ref $self;
    my $adm = Administrator->new();
    my $mastergroupeid = $self->getMasterGroupEid();
    my $methods = $self->methods();
    my $granted;
        
    foreach my $m (keys %$methods) {
        
        if($methods->{$m}->{'perm_holder'} eq 'mastergroup') {
            $granted = $adm->{_rightchecker}->checkPerm(entity_id => $mastergroupeid, method => $m);    
            $methods->{$m}->{'granted'} = $granted;
        }
        elsif($class and $methods->{$m}->{'perm_holder'} eq 'entity') {
            $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => $m);    
            $methods->{$m}->{'granted'} = $granted;
        }
        else {
            delete $methods->{$m};
        }
    }
    $log->debug(Dumper $methods);    
    return $methods;
}

=head2 addPerm

=cut

sub addPerm {
    my $self = shift;
    my %args = @_;
    my $class = ref $self;
    
    General::checkParams(args => \%args, required => ['method', 'entity_id']);
    
    my $adm = Administrator->new();
       
    if($class) {
        # addPerm call from an instance of type $class
          my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'setPerm');
              if(not $granted) {
               throw Kanopya::Exception::Permission::Denied(error => "Permission denied to set permission on cluster with id $args{entity_id}");
           }
           # 
        $adm->{_rightchecker}->addPerm(
            consumer_id => $args{entity_id}, 
            consumed_id => $self->{_entity_id}, 
            method         => $args{method},
        );
    }
    else {
        # addPerm call from class $self
        my @list = split(/::/, "$self");
        my $mastergroup = pop(@list);
        my $entity_id = $adm->{db}->resultset('Gp')->find({ gp_name => $mastergroup })->gp_entity->first->get_column('entity_id');
        my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'setPerm');
              if(not $granted) {
               throw Kanopya::Exception::Permission::Denied(error => "Permission denied to set permission on cluster with id $args{id}");
           }
        
        $adm->{_rightchecker}->addPerm(
            consumer_id => $args{entity_id}, 
            consumed_id => $entity_id, 
            method         => $args{method},
        );
    
    }
}

sub activate {
    my $self = shift;
    if (defined $self->ATTR_DEF->{active}) {
        $self->{_dbix}->update({active => "1"});
#        $self->setAttr(name => 'active', value => 1);
        $log->debug("Entity::Activate : Entity is activated");
    } else {
        $errmsg = "Entity->activate Entity ". ref($self) . " unable to activate !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

1;
