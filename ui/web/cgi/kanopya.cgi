#!/usr/bin/perl -w
#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use lib qw(/opt/kanopya/ui/web /opt/kanopya/lib/administrator /opt/kanopya/lib/common);
use CGI::Fast();
use CGI::Application::Dispatch;
use Log::Log4perl;

Log::Log4perl->init('/opt/kanopya/conf/webui-log.conf');
use Administrator;

while(my $q = new CGI::Fast) {

    CGI::Application::Dispatch->dispatch(
	prefix => 'KanopyaUI',
	args_to_new => { 
		TMPL_PATH => '/opt/kanopya/ui/web/KanopyaUI/templates/',
		QUERY => $q
	},
	default => 'Login',
	debug => 1,
     );
}



