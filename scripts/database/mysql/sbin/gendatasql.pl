#!/usr/bin/perl -W

use Template;

my $data_sql = '/opt/kanopya/scripts/database/mysql/data/Data.sql';
require 'default_data';
our %datas; # import initial data defined in "default_data" without warnings when used

my $config = {
	INCLUDE_PATH => '/opt/kanopya/scripts/database/mysql/data/',
	INTERPOLATE  => 1,
	POST_CHOMP   => 1,
	EVAL_PERL    => 1,
};
my $template = Template->new($config);
my $input = "Data.sql.tt";
$template->process($input, \%datas, $data_sql) || do {
	print "error while generating Data.sql: $!\n";
};
