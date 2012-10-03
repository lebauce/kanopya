require('KIM/component.js');

var Apache2 = (function(_super) {
    Apache2.prototype = new _super();

    function Apache2(id) {
        _super.call(this, id);

        this.displayed = [ 'apache2_serverroot', 'apache2_loglevel', 'apache2_ports', 'apache2_sslports'];

        this.relations = {
            'apache2_virtualhosts' : [
                'apache2_virtualhost_servername', 'apache2_virtualhost_sslenable',
                'apache2_virtualhost_serveradmin', 'apache2_virtualhost_documentroot',
                'apache2_virtualhost_log', 'apache2_virtualhost_errorlog'
            ],
        };
    };

    return Apache2;

})(Component);
