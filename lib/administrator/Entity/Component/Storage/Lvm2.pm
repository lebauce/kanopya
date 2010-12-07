# Lvm2.pm Logical volume manager component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 22 august 2010
package Entity::Component::Storage::Lvm2;
use strict;

use base "Entity::Component::Storage";
use Log::Log4perl "get_logger";
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;


my $log = get_logger("administrator");
my $errmsg;
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getMainVg{
	my $self = shift;
	my $vgname = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_name');
	my $vgid = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_id');
	$log->debug("Main VG founds, its id is <$vgid>");
	#TODO getMainVg, return id or name ?
	return {vgid => $vgid, vgname =>$vgname};
}

sub lvCreate{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_lv_size} or ! defined $args{lvm2_lv_size}) ||
		(! exists $args{lvm2_lv_filesystem} or ! defined $args{lvm2_lv_filesystem}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id})) { 
		$errmsg = "Lvm2->LvCreate need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("lvm2_lv_name is $args{lvm2_lv_name}, lvm2_lv_size is $args{lvm2_lv_size}, lvm2_lv_filesystem is $args{lvm2_lv_filesystem}, lvm2_vg_id is $args{lvm2_vg_id}");
	my $lv_rs = $self->{_dbix}->lvm2_vgs->single( {lvm2_vg_id => $args{lvm2_vg_id}})->lvm2_lvs;
	my $res = $lv_rs->create(\%args);
	
	$log->info("lvm2 logical volume $args{lvm2_lv_name} saved to database");
	return $res->get_column("lvm2_lv_id");
}

sub vgSizeUpdate{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
		(! exists $args{lvm2_vg_freespace} or ! defined $args{lvm2_vg_freespace})) { 
		$errmsg = "Lvm2->vgSizeUpdate need lvm2_vg_id and lvm2_vg_freespace named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $vg_rs = $self->{_dbix}->lvm2_vgs->single( {lvm2_vg_id => $args{lvm2_vg_id}});
	delete $args{lvm2_vg_id};
	return $vg_rs->update(\%args);
}

sub lvRemove{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id})) { 
		$errmsg = "Lvm2->LvRemove need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
# ICI Recuperer le bon vg et ensuite suivre le lien lv et new dedans
	$log->debug("lvm2_lv_name is $args{lvm2_lv_name}, lvm2_vg_id is $args{lvm2_vg_id}");
	my $lv_row = $self->{_dbix}->lvm2_vgs->find($args{lvm2_vg_id})->lvm2_lvs->single({lvm2_lv_name => $args{lvm2_lv_name}});
	$lv_row->delete();
	$log->info("lvm2 logical volume $args{lvm2_lv_name} deleted from database");
}

1;
