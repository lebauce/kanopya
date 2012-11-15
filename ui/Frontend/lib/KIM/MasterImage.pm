package MasterImage;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Administrator;
use Entity::Masterimage;

prefix undef;

ajax '/uploadmasterimage' => sub {
    my $file        = request->uploads->{file};
    my $content     = $file->content;
    my $fileName    = $file->filename;
    
    $file->copy_to("/tmp/$fileName");
    Entity::Masterimage->create(file_path => "/tmp/$fileName");

    content_type 'application/json';
    return to_json { file => $fileName };
};
