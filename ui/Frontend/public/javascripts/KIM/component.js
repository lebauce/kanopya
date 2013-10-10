require('common/general.js');

var Component = (function() {
    function Component(id) {
        this.id = id;

        if (this.id) {
            var componentType = fromIdToComponentType(ajax('GET', '/api/component/' + this.id).component_type_id);
            this.type = componentType.component_name.toLowerCase() + componentType.component_version;
            this.name = componentType.component_name;

            // Work around to handle components without version number
            if (window[this.type.ucfirst()] == undefined) {
                this.type = this.name.toLowerCase();
            }
        }

        this.displayed = [];
        this.relations = {};
    }

    Component.prototype.configure = function() {
        // Instantiate a KanopyaFormWizard top open the configuration modal
        (new KanopyaFormWizard({
            title          : this.name + ' configuration',
            type           : this.type,
            id             : this.id,
            valuesCallback : $.proxy(this.valuesCallback, this),
            submitCallback : $.proxy(this.submitCallback, this),
            attrsCallback  : $.proxy(this.attrsCallback, this),
            displayed      : this.displayed,
            relations      : this.relations,
            actionsCallback: $.proxy(this.actionsCallback, this),
            optionsCallback: $.proxy(this.optionsCallback, this)
        })).start();
    };

    Component.prototype.submitCallback = function(data, $form, opts, onsuccess, onerror) {
        // Add the primary key value to data
        data[this.getPrimarykey()] = this.id;

        // Call setConf on the component
        return ajax('POST', '/api/' + this.type + '/' + this.id + '/setConf', { conf : data }, onsuccess, onerror);
    };

    Component.prototype.valuesCallback = function(type, id) {
        return ajax('POST', '/api/' + this.type + '/' + this.id + '/getConf');
    };

    Component.prototype.getPrimarykey = function() {
        var attrdef = ajax('GET', '/api/attributes/' + this.type).attributes;
        for(var attr in attrdef) {
            if(attrdef[attr].is_primary == true) {
                return attr;
            }
        }
    };

    return Component;
})();
