package VIMRuntime;

use 5.006001;
use strict;
use warnings;

use VMware::VICommon;
use Carp qw(confess croak);

my $vmware_lib_dir = $INC{'VMware/VIMRuntime.pm'}; 
$vmware_lib_dir =~ s#(.*)/.*$#$1#; 

our %stub_class;

sub initialize {
   my ($self, $server_version) = @_;
   my $vim_stub = undef;
   my $vim_runtime = undef;
   
   if(defined($server_version) and $server_version eq '25') {
      $vim_stub = "$vmware_lib_dir/VIM25Stub.pm";
      $vim_runtime = "$vmware_lib_dir/VIM25Runtime.pm";
   }
   else {
      $vim_stub = "$vmware_lib_dir/VIM2Stub.pm";
      $vim_runtime = "$vmware_lib_dir/VIM2Runtime.pm";
   }

   local $/;

   open STUB, $vim_stub or die $!; 
   my @stub = split /\n####+?\n/, <STUB>;
   close STUB or die $!;

   open RUNTIME, $vim_runtime or die $!;
   my @runtime = split /\n####+?\n/, <RUNTIME>; 
   close RUNTIME or die $!; 

   push @stub, @runtime;
   for (@stub) {
      my ($package) = /\bpackage\s+(\w+)/;
      $stub_class{$package} = $_ if defined $package; 
   }
}

sub load {
   my $package = shift; 
   {
       no strict 'refs'; 
       # return 0 if keys %{"$package\::"};
       my @all_keys = keys(%{"$package\::"});
       if (@all_keys) {
           if ($package eq 'Event' and @all_keys == 3 and grep(/^Join::$/, @all_keys)) {
               open VHH_DEBUG, '>>/tmp/vhh_debug.log';
               print VHH_DEBUG "'Event' can do: ".join(',',@all_keys)."\n";
               print VHH_DEBUG "Found incomplete 'Event' (probably Event::Join). Loading our 'Event' anyway!\n";
               close VHH_DEBUG;
           } else {
               open VHH_DEBUG, '>>/tmp/vhh_debug.log';
               print VHH_DEBUG "already loaded: $package\n";
               print VHH_DEBUG "can do: ".join(',',@all_keys)."\n";
               close VHH_DEBUG;
               return 0;
           }
       }
   }
   die "Can't load class '$package'" unless exists $stub_class{$package};
   my ($isa) = $stub_class{$package} =~ /\@ISA\s*=\s*qw\((.*?)\)/;
   $isa = '' unless defined $isa;
   my @isa = split /\s+/, $isa;
   for (@isa) {
      load($_);
   }
   eval $stub_class{$package};
   die if $@;
   open VHH_DEBUG, '>>/tmp/vhh_debug.log';
   print VHH_DEBUG "\nJust loaded class '$package' in process $$";
   close VHH_DEBUG;
   return 1;
}

sub make_get_set {
   my $class = shift;
   for my $member (@_) {
      no strict 'refs';      
      *{$class . '::' . $member} = sub {
         my $package = shift;
         if (@_) {
            return $package->{$member} = shift;
         } else {
            return $package->{$member};
         }
      }
   }
}

sub UNIVERSAL::AUTOLOAD {
   my ($package, $sub) = $UNIVERSAL::AUTOLOAD =~ /^(.*)::(.*)/;
   return if $sub eq 'DESTROY';
   return if $package eq 'threads';
   # my $status = load($package);
   # unless ($status) {
   #     open VHH_DEBUG, '>>/tmp/vhh_debug.log';
   #     print VHH_DEBUG "LOAD FAILED: '$package' in process $$: returned $status\n";
   #     close VHH_DEBUG;
   unless (load $package) {
      croak "Undefined subroutine &$UNIVERSAL::AUTOLOAD called";
   };
   
   if ($package->can($sub)) {
      goto $package->can($sub);
   } else {
      use Carp;

      open VHH_DEBUG, '>>/tmp/vhh_debug.log';
      print VHH_DEBUG "Load worked, but CAN FAILED: '$package' '$sub' in process $$\n";
      if ($package =~ m#^RemoteTSM#) {
          print VHH_DEBUG "HostEvent can deserialize? "."HostEvent"->can('deserialize')."\n";
#          print VHH_DEBUG "Event can deserialize? "."Event"->can('deserialize')."\n";
          # print VHH_DEBUG "Let's try again\n";
          # load "Event";
      #    print VHH_DEBUG "Event can deserialize? "."Event"->can('deserialize')."\n";
      #    print VHH_DEBUG "What can 'Event' do?\n";
          # eval {
          #    no strict 'refs';
          #    for(keys %Event::) { # All the symbols in Foo's symbol table
          #        print VHH_DEBUG "$_\n" if defined &{$_}; # check if symbol is method
          #    }
          # };
#          print VHH_DEBUG "Event ISA ".join(',', @Event::ISA)."\n";
#          print VHH_DEBUG "HostEvent ISA ".join(',', @HostEvent::ISA)."\n";
          # print VHH_DEBUG "DynamicData ISA ".join(',', @DynamicData::ISA)."\n";
#          print VHH_DEBUG "DynamicData can deserialize? "."DynamicData"->can('deserialize')."\n";
#          print VHH_DEBUG "ComplexType can deserialize? "."ComplexType"->can('deserialize')."\n";
      }
#      elsif ($package =~ m#^Service#) {
      #    print VHH_DEBUG "ServiceContent ISA ".join(',', @ServiceContent::ISA)."\n";
      #    print VHH_DEBUG "DynamicData ISA ".join(',', @DynamicData::ISA)."\n";
      #    print VHH_DEBUG "DynamicData can deserialize? "."DynamicData"->can('deserialize')."\n";
      #    print VHH_DEBUG "ComplexType can deserialize? "."ComplexType"->can('deserialize')."\n";
#      }
      close VHH_DEBUG;

      croak "Undefined subroutine &$UNIVERSAL::AUTOLOAD called";
   }   
}
1;
