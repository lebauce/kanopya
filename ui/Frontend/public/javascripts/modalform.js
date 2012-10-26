require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery.form.wizard.js');
require('jquery/jquery.qtip.min.js');

$.validator.addMethod("regex", function(value, element, regexp) {
    var re = new RegExp(regexp);
    return this.optional(element) || re.test(value);
}, "Please check your input");

$.validator.addMethod("confirm_password", function(value, element, input) {
    return value === $(input).val();
}, "Password differs");

var ModalForm = (function() {
    function ModalForm(args) {
        this.handleArgs(args);
        
        this.content = $("<div>", { id : this.name });
        
        this.validateRules    = {};
        this.validateMessages = {};
        
        var method      = 'POST';
        var action      = '/api/' + this.baseName;
        // Check if it is a creation or an update form
        if (this.id != null) {
            method  = 'PUT';
            action  += '/' + this.id;
        }
        if (args.prependElement !== undefined) {
            this.content.prepend($(args.prependElement));
        }
        this.form       = $("<form>", { method : method, action : action}).appendTo(this.content).append(this.table);
        this.table      = $("<table>").css('width', '100%').appendTo($(this.form));
        this.stepTables = [];
        
        // Retrieve data structure from REST
        $.ajax({
            type        : 'GET',
            // no_relations option allow to keep old field management (see below)
            // TODO : review fields management and use generic KanopyaFormWizard instead of this class (ModalForm)
            url         : '/api/attributes/' + this.baseName + '?no_relations=1',
            dataType    : 'json',
            async       : false,
            success     : $.proxy(function(data) {
                    var values = {};
                    // If it is an update form, retrieve old datas from REST

                    if (this.id != null) {
                        $.ajax({
                            type        : 'GET',
                            async       : false,
                            url         : '/api/' + this.baseName + '/' + this.id,
                            dataType    : 'json',
                            success     : function(data) {
                                values = data;
                            }
                        });
                    }
                    
                    // For each element in the data structure, add an input
                    // to the form
                    for (elem in this.fields) if (this.fields.hasOwnProperty(elem)) {
                        var val = values[elem] || this.fields[elem].value;
                        if (elem in data.attributes) { // Whether just an input
                            this.newFormElement(elem, data.attributes[elem], val);
                        } else if (this.fields[elem].skip == true || this.fields[elem].options) { // want to skip or select element with provided options
                            this.newFormElement(elem, {}, val);
                        } else { // Or retrieve all possibles values and create a select element
                            var datavalues = this.getForeignValues(data, elem);
                            this.newDropdownElement(elem, data.attributes[elem], val, datavalues);
                        }
                    }
            }, this)
        });
    }
    
    ModalForm.prototype.start = function() {
        $(document).append(this.content);
        // Open the modal and start the form wizard
        this.openDialog();
        this.startWizard();
    }
    
    ModalForm.prototype.getForeignValues = function(data, elem) {
        var datavalues = undefined;
        for (relation in data.relations) {
            for (prop in data.relations[relation].cond)
            if (data.relations[relation].cond.hasOwnProperty(prop)) {
                if (data.relations[relation].cond[prop] === 'self.' + elem) {
                    var cond = this.fields[elem].cond || "";
                    relation    = data.relations[relation].resource;
                    $.ajax({
                        type        : 'GET',
                        async       : false,
                        url         : '/api/' + relation + cond,
                        dataType    : 'json',
                        success     : $.proxy(function(d) {
                            datavalues = d;
                        }, this)
                    });
                    break;
                }
                break;
            }
        }
        return datavalues;
    }
    
    ModalForm.prototype.handleArgs = function(args) {
        
        if ('name' in args) {
            this.baseName   = args.name;
            this.name       = 'form_' + args.name;
        } else {
            throw new Error("ModalForm : Must provide a name");
        }
        
        this.id             = args.id;
        this.callback       = args.callback     || $.noop;
        if (args.fields) {
            this.fields         = args.fields;
        } else {
            throw new Error("ModalForm : Must provide at least one field");
        }
        this.title          = args.title        || this.name;
        this.skippable      = args.skippable    || false;
        this.beforeSubmit   = args.beforeSubmit || $.noop;
        this.cancelCallback = args.cancel       || $.noop;
        this.error          = args.error        || $.noop;
    }
 
    ModalForm.prototype.exportArgs = function() {
        return {
            name            : this.name,
            id              : this.id,
            callback        : this.callback,
            fields          : this.fields,
            title           : this.title,
            skippable       : this.skippable,
            beforeSubmit    : this.beforeSubmit,
            cancel          : this.cancelCallback
        };
    }
    
    ModalForm.prototype.mustDisableField = function(elementName, element) {
        if (this.fields[elementName].disabled == true) {
            return true;
        }
        if ($(this.form).attr('method').toUpperCase() === 'PUT' && element.is_editable == false) {
            return true;
        }
        return false;
    }

    ModalForm.prototype.newFormElement = function(elementName, element, value) {
        var field = this.fields[elementName];
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
        } else if (field.type === 'select') {
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
        $(input).attr({ name : elementName, id : 'input_' + elementName, rel : elementName });
        if (this.fields[elem].skip == true) {
            $(input).addClass('wizard-ignore');
            $(input).attr('name', '');
        }
        
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
            if (type === 'text' || type === 'hidden') {//patched for hidden fields
                $(input).attr('value', value);
            } else if (type === 'checkbox' && value == true) {
                $(input).attr('checked', 'checked');
            } else if (type === 'textarea') {
                $(input).text(value);
            }
        }
        
        $(label).text($(label).text() + " : ");
        
        // Finally, insert DOM elements in the form
        var container = this.findContainer(field.step);
        if (input.is("textarea")) {
            this.insertTextarea(input, label, container, field.help || element.description);
        } else {
            this.insertTextInput(input, label, container, field.help || element.description);
        }

        if (this.mustDisableField(elementName, element) === true) {
            $(input).attr('disabled', 'disabled');
        }

        if ($(input).attr('type') === 'date') {
            $(input).datepicker({ dateFormat : 'yyyy-mm-dd', constrainInput : true });
        }

        // manage unit
        // - simple value to display beside field
        // - unit selector when unit is 'byte' (MB, GB) and display current value with the more appropriate value
        // See policiesform for management of unit depending on value of another field
        if (field.unit) {
            var unit_cont = $('<span>');
            var unit_field_id ='unit_' + $(input).attr('id');
            $(input).parent().append(unit_cont);

            var current_unit;
            addFieldUnit(field, unit_cont, unit_field_id);
            current_unit = field.unit;

            // Set the serialize attribute to manage convertion from (selected) unit to final value
            // Warning : this will override serialize attribute if defined
            this.fields[elementName].serialize = function(val, elem) {
                return val * getUnitMultiplicator('unit_' + $(elem).attr('id'));
            }

            // If exist a value then convert it in human readable
            if (current_unit === 'byte' && $(input).val()) {
                var readable_value = getReadableSize($(input).val(), 1);
                $(input).val( readable_value.value );
                $(unit_cont).find('option:contains("' + readable_value.unit + '")').attr('selected', 'selected');
            }
        }
    }
    
    ModalForm.prototype.newDropdownElement = function(elementName, element, current, values) {
        // Create input and label DOM elements
        var label   = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (this.fields[elementName].label !== undefined) {
            $(label).text(this.fields[elementName].label);
        }
        $(label).text($(label).text() + ' * :');
        var input   = $("<select>", { name : elementName, id : 'input_' + elementName, rel : elementName });

        // Inject all values in the select
        for (value in values) {
            var display = this.fields[elementName].display || 'pk';
            var option  = $("<option>", { value : values[value].pk , text : values[value][display] });
            if (this.fields[elementName].formatter != null) {
                $(option).text(this.fields[elementName].formatter($(option).text()));
            }
            $(input).append(option);
            if (current !== undefined && current == values[value].pk) {
                $(option).attr('selected', 'selected');
            }
        }
        
        // Finally, insert DOM elements in the form
        var container = this.findContainer(this.fields[elementName].step);
        this.insertTextInput(input, label, container);
    }
    
    ModalForm.prototype.findContainer = function(step) {
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

    ModalForm.prototype.createHelpElem = function(help) {
        if (help !== undefined) {
            var helpElem        = $("<span>", { class : 'ui-icon ui-icon-info' });
            $(helpElem).css({
                cursor  : 'help',
                margin  : '2px 0 0 2px',
                float   : 'right'
            });
            $(helpElem).qtip({
                content : help.replace("\n", "<br />", 'g'),
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
            return $("<span>").css({ display : 'block', width : '16px', 'margin-left' : '2px', height : '1px', float : 'right' });
        }
    }

    ModalForm.prototype.insertTextInput = function(input, label, container, help) {
        var linecontainer   = $("<tr>").css('position', 'relative').appendTo(container);
        $("<td>", { align : 'left' }).append(label).appendTo(linecontainer);
        $("<td>", { align : 'right' }).append(input).append(this.createHelpElem(help)).appendTo(linecontainer);
        if (this.fields[$(input).attr('rel')].type === 'hidden') {
            $(linecontainer).css('display', 'none');
        }
    }
    
    ModalForm.prototype.insertTextarea = function(input, label, container, help) {
        var labelcontainer = $("<td>", { align : 'left', colspan : '2' }).append(label);
        var inputcontainer = $("<td>", { align : 'left', colspan : '2' }).append(input);
        $("<tr>").append($(labelcontainer).append(this.createHelpElem(help))).appendTo(container);
        $("<tr>").append(inputcontainer).appendTo(container);
        $(input).css('width', '100%');
    }
    
    ModalForm.prototype.beforeSerialize = function(form, options) {
        // Must transform all 'on' or 'off' values from checkboxes to '1' or '0'
        for (field in this.fields) {
            if (this.fields[field].type === 'checkbox') {
                var checkbox = $(form).find('input[name="' + field + '"]');
                if (checkbox.attr('value') === 'on') {
                    if (checkbox.attr('checked')) {
                        checkbox.attr('value', '1');
                    } else {
                        checkbox.attr('value', '0');
                    }
                } else if (checkbox.attr('value') === 'off') {
                    checkbox.attr('value', '0');
                }
            }
            if (this.fields[field].serialize != null) {
                var input = $(form).find('input[name="' + field + '"]');
                $(input).val(this.fields[field].serialize($(input).val(), input));
            }
        }
    }
    
    ModalForm.prototype.changeStep = function(event, data) {
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
    
    ModalForm.prototype.handleBeforeSubmit = function(arr, $form, opts) {
        // Add data to submit for each unchecked checkbox
        // Because by default no data are posted for unchecked box
        $form.find(':checkbox').each(function() {
            if ($(this).val() == 0) {
                arr.push({name: $(this).attr('name'), value: 0});
            }
        });

        var b   = this.beforeSubmit(arr, $form, opts, this);
        if (b) {
            var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
            buttonsdiv.find('button').each(function() {
                $(this).attr('disabled', 'disabled');
            });
        }
        return b;
    }
    
    ModalForm.prototype.startWizard = function() {
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
                beforeSerialize : $.proxy(this.beforeSerialize, this),
                beforeSubmit    : $.proxy(this.handleBeforeSubmit, this),
                success         : $.proxy(function(data) {
                    // Ugly but must delete all DOM elements
                    // but formwizard is using the element after this
                    // callback, so we delay the deletion
                    this.closeDialog();
                    this.callback(data, this.form);
                }, this),
                error           : $.proxy(function(data) {
                    var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
                    buttonsdiv.find('button').each(function() {
                        $(this).removeAttr('disabled', 'disabled');
                    });
                    $(this.content).find("div.ui-state-error").each(function() {
                        $(this).remove();
                    });
                    var error;
                    try {
                        error = JSON.parse(data.responseText);
                    }
                    catch (err) {
                        error = 'An error occurs, but can not be parsed...'
                    }
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
    
    ModalForm.prototype.openDialog = function() {
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
            width           : 500,
            buttons         : buttons,
            closeOnEscape   : false
        });
        $('.ui-dialog-titlebar-close').remove();
    }

    ModalForm.prototype.cancel = function() {
        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.cancelCallback();
            this.closeDialog();
        }
        else {
            $(this.form).formwizard("back");
        }
        
    }
 
    ModalForm.prototype.closeDialog = function() {
        setTimeout($.proxy(function() {
            $(this).dialog("close");
            $(this).dialog("destroy");
            $(this.form).formwizard("destroy");
            $(this.content).remove();
        }, this), 10);
    }
 
    ModalForm.prototype.validateForm = function () {
        $(this.form).formwizard("next");
    }
    
    return ModalForm;
    
})();
