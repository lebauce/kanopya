package Mcsui::Messager;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub view_messages : StartRunmode {
    my $self = shift;
    my $query = $self->query();
    my $output = '';
    my $userid = $query->param('userid');
    my $loopparams = [
		{ 'TYPE' => '/images/info.png', 'DATE' => '31-08-2010', 'TIME' => '12:00:34', 'CONTENT' => 'et blablablabl' },
		{ 'TYPE' => '/images/error.png', 'DATE' => '31-08-2010', 'TIME' => '12:44:34', 'CONTENT' => 'une erreur' },
		{ 'TYPE' => '/images/info.png', 'DATE' => '31-08-2010', 'TIME' => '12:00:34', 'CONTENT' => 'et blablablabl' },
		{ 'TYPE' => '/images/success.png', 'DATE' => '31-08-2010', 'TIME' => '12:44:34', 'CONTENT' => "c est trop dla balle ces messages! <br/>sur plusieurs lignes" },
		{ 'TYPE' => '/images/info.png', 'DATE' => '31-08-2010', 'TIME' => '12:00:34', 'CONTENT' => 'et blablablabl' },
		{ 'TYPE' => '/images/error.png', 'DATE' => '31-08-2010', 'TIME' => '12:44:34', 'CONTENT' => 'une erreur' },
		{ 'TYPE' => '/images/info.png', 'DATE' => '31-08-2010', 'TIME' => '12:00:34', 'CONTENT' => 'et blablablabl' },
		{ 'TYPE' => '/images/success.png', 'DATE' => '31-08-2010', 'TIME' => '12:44:34', 'CONTENT' => 'ok !' },
    ];
    
    my $tmpl = $self->load_tmpl('view_messages.tmpl');
    
    #$tmpl->param(USERID => $userid);
    $tmpl->param(MESSAGES => $loopparams);
    
	$output .= $tmpl->output();
        
    return $output;
}



1;
