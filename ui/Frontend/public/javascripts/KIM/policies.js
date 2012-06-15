require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery.form.wizard.js');
require('KIM/policiesdefs.js');

function load_policy_content (container_id) {
    var policy_type = container_id.split('_')[1];

    function createAddPolicyButton(cid, grid) {
        var policy_opts = {
            title       : 'Add a ' + policy_type + ' policy',
            name        : 'policy',
            fields      : policies[policy_type],
            callback    : function () { grid.trigger("reloadGrid"); }
        };

        var button = $("<button>", {html : 'Add a ' + policy_type + ' policy'});
        button.bind('click', function() {
            new PolicyForm(policy_opts).start();
        });
        $('#' + cid).append(button);
    };

    var container = $('#' + container_id);
    var grid = create_grid( {
        url: '/api/policy?policy_type=' + policy_type,
        content_container_id: container_id,
        grid_id: policy_type + '_policy_list',
        colNames: [ 'ID', 'Name', 'Description' ],
        colModel: [ { name:'policy_id',   index:'policy_id',   width:60, sorttype:"int", hidden:true, key:true},
                    { name:'policy_name', index:'policy_name', width:300 },
                    { name:'policy_desc', index:'policy_desc', width:500 } ]
    } );

    createAddPolicyButton(container_id, grid);
}

function load_policy_details (elem_id, row_data, grid_id) {
    var policy;
    $.ajax({
        type     : 'GET',
        async    : false,
        url      : '/api/policy/' + elem_id,
        dataTYpe : 'json',
        success  : $.proxy(function(d) {
            policy = d;
        }, this)
    });

    var flattened_policy;
    $.ajax({
        type     : 'POST',
        async    : false,
        url      : '/api/policy/' + elem_id + '/getFlattenedHash',
        dataTYpe : 'json',
        success  : $.proxy(function(d) {
            flattened_policy = d;
        }, this)
    });

    jQuery.extend(flattened_policy, policy);

    var fields = policies[policy.policy_type];
    fields['policy_id'] = {
        label        : 'Policy id',
        type         : 'hidden',
        value        : policy.policy_id,
    };

    var policy_opts = {
        title       : 'Edit the ' + policy.policy_type + ' policy: ' + policy.policy_name,
        name        : 'policy',
        fields      : policies[policy.policy_type],
        values      : flattened_policy,
        callback    : function () { $('#' + grid_id).trigger("reloadGrid"); }
    };

    new PolicyForm(policy_opts).start();
}

var PolicyForm = (function() {
    function PolicyForm(args) {
        this.handleArgs(args);

        this.content    = $("<div>", { id : this.name });

        this.validateRules      = {};
        this.validateMessages   = {};

        var method      = 'POST';
        var action      = '/api/' + this.baseName;
        // Check if it is a creation or an update form
        if (this.id !== undefined) {
            method  = 'PUT';
            action  += '/' + this.id;
        }
        if (args.prependElement !== undefined) {
            this.content.prepend($(args.prependElement));
        }
        this.form       = $("<form>", { method : method, action : action}).appendTo(this.content).append(this.table);
        this.table      = $("<table>").css('width', '100%').appendTo($(this.form));
        this.stepTables = [];

        // For each element in fields, add an input to the form
        for (var elem in this.fields) {
            if (this.fields[elem].type === 'select') {
                this.newDropdownElement(elem, undefined, this.values[elem]);
            }
            else {
                this.newFormElement(elem);
            }
        }
    }

    PolicyForm.prototype.start = function() {
        $(document).append(this.content);
        // Open the modal and start the form wizard
        this.openDialog();
        this.startWizard();
    }

    PolicyForm.prototype.handleArgs = function(args) {
        if ('name' in args) {
            this.baseName   = args.name;
            this.name       = 'form_' + args.name;
        }

        this.id             = args.id;
        this.callback       = args.callback     || $.noop;
        this.fields         = args.fields       || {};
        this.values         = args.values       || {};
        this.title          = args.title        || this.name;
        this.skippable      = args.skippable    || false;
        this.beforeSubmit   = args.beforeSubmit || $.noop;
        this.cancelCallback = args.cancel       || $.noop;
        this.error          = args.error        || $.noop;

        this.dynamicFields  = new Array();
    }

    PolicyForm.prototype.mustDisableField = function(elementName, element) {
        if (this.fields[elementName].disabled == true) {
            return true;
        }
        if ($(this.form).attr('method').toUpperCase() === 'PUT' && element.is_editable == false) {
            return true;
        }
        return false;
    }

    PolicyForm.prototype.newFormElement = function(elementName, after) {
        var field = this.fields[elementName];
        var element = field;
        var value   = this.values[elementName] || field.value;

        // Create input and label DOM elements
        var label = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (field.label !== undefined) {
            $(label).text(field.label);
        }
        if (field.type === undefined ||
            (field.type !== 'textarea' && field.type !== 'select')) {
            var type    = field.type || 'text';
            var input   = $("<input>", { type : type });
        } else if (field.type === 'textarea') {
            var type    = 'textarea';
            var input   = $("<textarea>");
        }
        else if (field.type === 'select') {
            var input   = $("<select>");
            var isArray = field.options instanceof Array;
            for (var i in field.options) if (field.options.hasOwnProperty(i)) {
                var optionvalue = field.options[i];
                var optiontext  = (isArray != true) ? i : field.options[i];
                var option  = $("<option>", { value : optionvalue, text : optiontext }).appendTo(input);
                if (optionvalue === value) {
                    $(option).attr('selected', 'selected');
                }
            }
        }
        $(input).attr({ name : elementName, id : 'input_' + elementName });

        this.validateRules[elementName] = {};
        // Check if the field is mandatory
        if (element.is_mandatory == true) {
            $(label).append(' *');
            this.validateRules[elementName].required = true;
        }
        // Check if the field must be validated by a regular expression
        if ($(input).attr('type') !== 'checkbox' && element.pattern !== undefined) {
            this.validateRules[elementName].regex = element.pattern;
        }

        // Insert value if any
        if (value !== undefined) {
            if (type === 'text' || type === 'textarea' || type === 'hidden') {//patched for hidden fields
                $(input).attr('value', value);
            } else if (type === 'checkbox' && value == true) {
                $(input).attr('checked', 'checked');
            }
        }

        $(label).text($(label).text() + " : ");

        // Finally, insert DOM elements in the form
        var tr;
        var container = this.findContainer(field.step);
        if (input.is("textarea")) {
            tr = this.insertTextarea(input, label, container, field.help || element.description, after);
        } else {
            tr = this.insertTextInput(input, label, container, field.help || element.description, after);
        }

        if (this.mustDisableField(elementName, element) === true) {
            $(input).attr('disabled', 'disabled');
        }

        if ($(input).attr('type') === 'date') {
            $(input).datepicker({ dateFormat : 'yyyy-mm-dd', constrainInput : true });
        }

        return tr;
    }

    PolicyForm.prototype.newDropdownElement = function(elementName, values, current, after) {
        var container = this.findContainer(this.fields[elementName].step);

        // Create input and label DOM elements
        var label   = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (this.fields[elementName].label !== undefined) {
            $(label).text(this.fields[elementName].label);
        }
        var input = $("<select>", { name : elementName, id : 'input_' + elementName });

        if (this.fields[elementName].depends) {
            var that = this;

            input.change(function (event) {
                for (var depend in that.fields[elementName].depends) {
                    that.updateFromParent(that.form.find("#input_" + that.fields[elementName].depends[depend]), event.target.value);
                }
            });
        }

        if (this.fields[elementName].params) {
            var that = this;
            function updatePolicyParamsOnChange (event) {
                that.updatePolicyParams(input, event.target.value);
            }
            input.change(updatePolicyParamsOnChange);
        }

        if (this.fields[elementName].parent) {
            var parent = this.form.find("#input_" + this.fields[elementName].parent);
            this.updateFromParent(input, parent.val());

        } else if (! values) {
            var values = undefined;
            $.ajax({
                type        : 'GET',
                async       : false,
                url         : '/api/' + this.fields[elementName].entity,
                dataTYpe    : 'json',
                success     : $.proxy(function(d) {
                    values = d;
                }, this)
            });
        }

        if (! this.fields[elementName].is_mandatory) {
            var option = $("<option>", { value : -1 , text : '-' });
            $(input).append(option);
        }

        // Inject all values in the select
        for (value in values) {
            var key = undefined;
            var text = undefined;
            if (typeof values[value] === "object") {
                var display = 'pk';

                /* Ugly hack for getting the name of the service provider,
                 * whatever its type. Please do not blam me...
                 */
                if (this.fields[elementName].entity === 'serviceprovider') {
                    for (var attr in values[value]) {
                        if (attr.indexOf("_name", attr.length - "_name".length) !== -1) {
                            display = attr;
                        }
                    }
                } else {
                    display = this.fields[elementName].display || 'pk';
                }
                key = values[value].pk;
                text = values[value][display];

            } else {
                key = values[value];
                text = values[value];
            }

            var option = $("<option>", { value : key , text : text });
            $(input).append(option);
            if (current !== undefined && current == key) {
                $(option).attr('selected', 'selected');
            }
        }
        // Finally, insert DOM elements in the form
        var inserted = this.insertTextInput(input, label, container, this.fields[elementName].help || this.fields[elementName].description, after);

        // Raise the onChange event to update related objects
        input.change();

        return inserted;
    }

    PolicyForm.prototype.updateFromParent = function (element, selected_id) {
        var datavalues = undefined;
        var name = element.attr('name');

        if (! name) { return; }

        /* Arg... Can not call the route according to this.fields[elementName].entity,
         * as we do not have a common parent class for component and connector.
         * So use the findManager workaround method for instance.
         */
        $.ajax({
            type     : 'POST',
            async    : false,
            url      : '/api/serviceprovider/' + selected_id + '/findManager',
            data     : { category: this.fields[name].category, service_provider_id: selected_id },
            dataTYpe : 'json',
            success  : $.proxy(function(d) {
                datavalues = d;
            }, this)
        });

        element.empty();
        // Inject all values in the select
        for (var value in datavalues) {
            var display = 'name';
            var option  = $("<option>", { value : datavalues[value].id , text : datavalues[value][display] });
            element.append(option);
        }
        element.change();
    }

    PolicyForm.prototype.updatePolicyParams = function (element, selected_id) {
        var name  = element.attr('name');
        this.removeDynamicFields();

        if (! selected_id) { return; }

        var componentvalues = undefined;
        $.ajax({
            type        : 'POST',
            async       : false,
            url         : '/api/' + this.fields[name].entity + '/' + selected_id + '/' + this.fields[name].params.func,
            data        : this.fields[name].params.args,
            dataType    : 'json',
            success     : $.proxy(function(d) {
                datavalues = d;
            }, this)
        });

        for (var value in datavalues) {
            this.fields[datavalues[value].name] = {
                label : datavalues[value].label,
                step  : this.fields[name].step
            }

            var tr = undefined;
            if (datavalues[value].values) {
                tr = this.newDropdownElement(datavalues[value].name,
                                             datavalues[value].values,
                                             this.values[datavalues[value].name],
                                             name);
            } else {
                tr = this.newFormElement(datavalues[value].name, name);
            }
            this.dynamicFields.push(tr);
        }
    }

    PolicyForm.prototype.removeDynamicFields = function () {
        for (var field in this.dynamicFields) {
            this.dynamicFields[field].remove();
        }
        this.dynamicFields = new Array();
    }

    PolicyForm.prototype.findContainer = function(step) {
        if (step !== undefined) {
            var table = this.stepTables[step];
            if (table === undefined) {
               var table = $("<table>", { id : this.name + '_step' + step }).appendTo(this.form);
               table.attr('rel', step);
               $(table).css('width', '100%').addClass('step');
               this.stepTables[step] = table;
            }
            return table;
        } else {
            return this.table;
        }
    }

    PolicyForm.prototype.createHelpElem = function(help) {
        if (help !== undefined) {
            var helpElem        = $("<span>", { class : 'ui-icon ui-icon-info' });
            $(helpElem).css({
                cursor  : 'pointer',
                margin  : '2px 0 0 2px',
                float   : 'right'
            });
            $(helpElem).qtip({
                content : help,
                position: {
                    corner  : {
                        target  : 'rightMiddle',
                        tooltip : 'leftMiddle'
                    }
                },
                style   : {
                    tip : { corner  : 'leftMiddle' }
                }
            });
            return helpElem;
        } else {
            return undefined;
        }
    }

    PolicyForm.prototype.insertTextInput = function(input, label, container, help, after) {
        var linecontainer   = $("<tr>").css('position', 'relative').appendTo(container);
        $("<td>", { align : 'left' }).append(label).appendTo(linecontainer);
        $("<td>", { align : 'right' }).append(input).append(this.createHelpElem(help)).appendTo(linecontainer);
        if (this.fields[$(input).attr('name')].type === 'hidden') {
            $(linecontainer).css('display', 'none');
        }

        if (after) {
            this.form.find("#input_" + after).parent().parent().after(linecontainer);
        } else {
            linecontainer.appendTo(container);
        }
        return linecontainer;
    }

    PolicyForm.prototype.insertTextarea = function(input, label, container, help, after) {
        var labelcontainer = $("<td>", { align : 'left', colspan : '2' }).append(label);
        var inputcontainer = $("<td>", { align : 'left', colspan : '2' }).append(input);
        var labelline = $("<tr>").append($(labelcontainer).append(this.createHelpElem(help)));
        var arealine = $("<tr>").append(inputcontainer);
        $(input).css('width', '100%');

        if (after) {
            this.form.find("#input_" + after).after(arealine);
            this.form.find("#input_" + after).after(labelline);
        } else {
            labelline.appendTo(container);
            arealine.appendTo(container);
        }
        return labelcontainer;
    }

    PolicyForm.prototype.beforeSerialize = function(form, options) {
        // Must transform all 'on' or 'off' values from checkboxes to '1' or '0'
        for (field in this.fields) {
            var input = $(form).find('#input_' + field);
            console.log(input);
            if (this.fields[field].type === 'checkbox') {
                if (input.attr('checked') === 'checked') {
                    input.attr('value', '1');
                } else {
                    input.attr('checked', 'checked');
                    input.attr('value', '0');
                }
            } else if (input.attr('value') == -1) {
                input.attr('value', '');
            }
        }
    }

    PolicyForm.prototype.changeStep = function(event, data) {
        var steps   = $(this.form).children("table.step");
        var text    = "";
        var i       = 1;
        $(steps).each(function() {
            var prepend = "";
            var append  = "";
            if ($(this).attr("id") == data.currentStep) {
                prepend = "<b>";
                append  = "</b>";
            }
            if (text === "") {
                text += prepend + i + ". " + $(this).attr('rel') + append;
            } else {
                text += " >> " + prepend + i + ". " + $(this).attr('rel') + append;
            }
            ++i;
        });
        $(this.content).children("div#" + this.name + "_steps").html(text);
    }

    PolicyForm.prototype.handleBeforeSubmit = function(arr, $form, opts) {
        var b   = this.beforeSubmit(arr, $form, opts, this) || true;
        if (b) {
            var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
            buttonsdiv.find('button').each(function() {
                $(this).attr('disabled', 'disabled');
            });
        }
        return b;
    }

    PolicyForm.prototype.startWizard = function() {
        $(this.form).formwizard({
            disableUIStyles     : true,
            validationEnabled   : true,
            validationOptions   : {
                rules           : this.validateRules,
                messages        : this.validateMessages,
                errorClass      : 'ui-state-error',
                errorPlacement  : function(error, element) {
                    error.insertBefore(element);
                }
            },
            formPluginEnabled   : true,
            formOptions         : {
                //beforeSerialize : $.proxy(this.beforeSerialize, this),
                beforeSubmit    : $.proxy(this.handleBeforeSubmit, this),
                success         : $.proxy(function(data) {
                    // Ugly but must delete all DOM elements
                    // but formwizard is using the element after this
                    // callback, so we delay the deletion
                    setTimeout($.proxy(function() { this.closeDialog(); }, this), 10);
                    this.callback(data);
                }, this),
                error           : $.proxy(function(data) {
                    var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
                    buttonsdiv.find('button').each(function() {
                        $(this).removeAttr('disabled', 'disabled');
                    });
                    $(this.content).find("div.ui-state-error").each(function() {
                        $(this).remove();
                    });
                    var error = JSON.parse(data.responseText);
                    $(this.content).prepend($("<div>", { text : error.reason, class : 'ui-state-error ui-corner-all' }));
                    this.error(data);
                }, this)
            }
        });

        var steps = $(this.form).children("table");
        if (steps.length > 1) {
            $(steps).each(function() {
                if (!$(this).html()) {
                    $(this).remove();
                }
            });
            $(this.content).prepend($("<br />"));
            $(this.content).prepend($("<div>", { id : this.name + "_steps" }).css({
                width           : '100%',
                'border-bottom' : '1px solid #AAA',
                position        : 'relative'
            }));
            this.changeStep({}, $(this.form).formwizard("state"));
            $(this.form).bind('step_shown', $.proxy(this.changeStep, this));
        }
    }

    PolicyForm.prototype.openDialog = function() {
        var buttons = {
            'Cancel'    : $.proxy(this.cancel, this),
            'Ok'        : $.proxy(this.validateForm, this)
        };
        if (this.skippable) {
            buttons['Skip'] = $.proxy(function() {
                this.closeDialog();
                this.callback();
            }, this);
        }
        this.content.dialog({
            title           : this.title,
            modal           : true,
            resizable       : false,
            draggable       : false,
            width           : 500,
            buttons         : buttons,
            closeOnEscape   : false,
        });
        $('.ui-dialog-titlebar-close').remove();
    }

    PolicyForm.prototype.cancel = function() {
        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.cancelCallback();
            this.closeDialog();
        }
        else {
            $(this.form).formwizard("back");
        }
    }

    PolicyForm.prototype.closeDialog = function() {
        this.removeDynamicFields();

        $(this).dialog("close");
        $(this).dialog("destroy");
        $(this.form).formwizard("destroy");
        $(this.content).remove();
    }

    PolicyForm.prototype.validateForm = function () {
        // Call before submit here to transform checkboxes values.
        this.beforeSerialize(this.form);

        $(this.form).formwizard("next");
    }

    return PolicyForm;
    
})();