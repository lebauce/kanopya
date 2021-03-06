package KIM::WorkflowLogs;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Kanopya::Config;

my $executor_config = Kanopya::Config::get('executor');

prefix undef;

get '/workflows/:id/log' => sub {
    my $file = $executor_config->{logdir}.'/workflows/'.param('id').'.log';
    my $lines;
    
    eval {
        local $/ = undef;
        open(FILE, $file) || die "unable to open log file for workflow ".param('id'); 
        $lines = <FILE>;
        close(FILE);
        $lines =~ s/</&lt;/g;
        $lines =~ s/>/&gt;/g;
        $lines =~ s/\n/<br>/g;
    };
    
    if($@){
        return "unable to open log file for workflow ".param('id');
    } else {
        return "<html><body><pre>".$lines."</pre></body></html>";
    }
};
