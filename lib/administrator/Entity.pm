package Entity;
use base 'BaseDB';

use Data::Dumper;
use Log::Log4perl 'get_logger';
use EntityComment;

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    entity_comment_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};


sub getAttrDef { return ATTR_DEF; }

sub primarykey { return 'entity_id'; }

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
    my $eid = $adm->{db}->resultset('Gp')->find({ gp_name => $mastergroup })->id;
    return $eid;
}

=head2 getGroups

return groups resultset where this entity appears (only on an already stored entity)

=cut

sub getGroups {
    my $self = shift;
    if( not $self->{_dbix}->in_storage ) { return; } 
    #$log->debug("======> GetGroups call <======");
    my $mastergroup = $self->getMasterGroupEid();
    my $groups = $self->{_rightschecker}->{_schema}->resultset('Gp')->search(
		{
        -or => [
            'ingroups.entity_id' => $self->{_dbix}->id,
            'gp_name' => $mastergroup ]
        },
            
        { join => [qw/ingroups/] }
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
    #$log->debug(Dumper $methods);
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
        my $entity_id = $adm->{db}->resultset('Gp')->find({ gp_name => $mastergroup })->id;
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

sub getEntities {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['type', 'hash']);

    my $adm = Administrator->new();
    
    $rs = $adm->_getDbixFromHash( table => $args{type}, hash => $args{hash} );
    $log->debug( "_getEntityClass with type = $args{type}");
    
    my $id_name = lc($args{type}) . "_id";
    $entity_class = "Entity::$args{type}";

    while ( my $row = $rs->next ) {
        my $id = $row->get_column($id_name);
        my $obj = eval { $entity_class->get(id => $id); }; 
        if($@) {
            my $exception = $@; 
            if(Kanopya::Exception::Permission::Denied->caught()) {
                               $log->info("no right to access to object <$args{type}> with  <$id>");
                next;
            }
            else { $exception->rethrow(); } 
        }
        else { push @objs, $obj; }
    }
    return  @objs;
}

sub getComment {
    my $self = shift;
    
    my $comment_id = $self->getAttr(name => 'entity_comment_id');
    if ($comment_id) {
        return EntityComment->get(id => $comment_id)->getAttr(name => 'entity_comment');
    }
    return '';
}

sub setComment {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'comment' ]);

    my $comment_id = $self->getAttr(name => 'entity_comment_id');
    if ($comment_id) {
        my $comment = EntityComment->get(id => $comment_id);
        $comment->setAttr(name => 'entity_comment', value => $args{comment});
        $comment->save();
        $log->info($comment);
    }
    else {
        my $comment = EntityComment->new(entity_comment => $args{comment});
        $self->setAttr(name => 'entity_comment_id', value => $comment->getAttr(name => 'entity_comment_id'));
        $self->save();
    }
    
    $log->info($comment);
}

1;
