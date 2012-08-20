package MasterImage;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use Entity::Operation;

prefix undef;

ajax '/uploadmasterimage' => sub {
    my $file        = request->uploads->{file};
    my $content     = $file->content;
    my $fileName    = $file->filename;
    
    $file->copy_to("/tmp/$fileName");
    Entity::Operation->enqueue(
        priority    => 200,
        type        => 'DeployMasterimage',
        params      => {
            file_path   => "/tmp/$fileName"
        }
    );

    content_type 'application/json';
    return to_json { file => $fileName };
};
