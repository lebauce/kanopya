var ModalForm = (function() {
    
    function ModalForm(args) {
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
        
        $(document).append(this.content);
      
        // Retrieve data structure from REST
        $.ajax({
            type        : 'GET',
            url         : '/api/attributes/' + this.baseName,
            dataType    : 'json',
            async       : false,
            success     : $.proxy(function(data) {
                    var values = {};
                    // If it is an update form, retrieve old datas from REST
                    if (this.id !== undefined) {
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
                        } else { // Or retrieve all possibles values and create a select element
                            var datavalues = this.getForeignValues(data, elem);
                            this.newDropdownElement(elem, data.attributes[elem], val, datavalues);
                        }
                    }
            }, this)
        });
    }
    
    ModalForm.prototype.start = function() {
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
                    // Temporary remove '_' from relations names
                    relation = relation.replace(/_/g, "");
                    $.ajax({
                        type        : 'GET',
                        async       : false,
                        url         : '/api/' + relation + cond,
                        dataTYpe    : 'json',
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
        }
        
        this.id             = args.id;  
        this.callback       = args.callback     || $.noop;
        this.fields         = args.fields       || {};
        this.title          = args.title        || this.name;
        this.skippable      = args.skippable    || false;
        this.beforeSubmit   = args.beforeSubmit || $.noop;
    }
    
    ModalForm.prototype.newFormElement = function(elementName, element, value) {
        // Create input and label DOM elements
        var label = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (this.fields[elementName].label !== undefined) {
            $(label).text(this.fields[elementName].label);
        }
        if (this.fields[elementName].type === undefined ||
            this.fields[elementName].type !== 'textarea') {
            var type = this.fields[elementName].type || 'text'
            var input = $("<input>", { type : type, name : elementName, id : 'input_' + elementName });
        } else {
            var input = $("<textarea>", { name : elementName, id : 'input_' + elementName });
        }
        
        this.validateRules[elementName] = {};
        // Check if the field is mandatory
        if (element.is_mandatory == true) {
            $(label).append(' *');
            this.validateRules[elementName].required = true;
        }
        // Check if the field must be validated by a regular expression
        if ($(input).attr('type') === 'text' && element.pattern !== undefined) {
            this.validateRules[elementName].regex = element.pattern;
        }
        
        // Insert value if any
        if (value !== undefined) {
            if (type == 'text') {
                $(input).attr('value', value);
            } else if (type === 'checkbox' && value == true) {
                $(input).attr('checked', 'checked');
            }
        }
        
        $(label).text($(label).text() + " : ");
        
        // Finally, insert DOM elements in the form
        var container = this.findContainer(this.fields[elementName].step);
        if (input.is("textarea")) {
            this.insertTextarea(input, label, container);
        } else {
            this.insertTextInput(input, label, container);
        }
    }
    
    ModalForm.prototype.newDropdownElement = function(elementName, element, current, values) {
        // Create input and label DOM elements
        var label   = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (this.fields[elementName].label !== undefined) {
            $(label).text(this.fields[elementName].label);
        }
        var input   = $("<select>", { name : elementName, id : 'input_' + elementName });

        // Inject all values in the select
        for (value in values) {
            var display = this.fields[elementName].display || 'pk';
            var option  = $("<option>", { value : values[value].pk , text : values[value][display] });
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
    
    ModalForm.prototype.insertTextInput = function(input, label, container) {
        var linecontainer = $("<tr>").css('position', 'relative').appendTo(container);
        $("<td>", { align : 'left' }).append(label).appendTo(linecontainer);
        $("<td>", { align : 'right' }).append(input).appendTo(linecontainer);
        if (this.fields[$(input).attr('name')].type === 'hidden') {
            $(linecontainer).css('display', 'none');
        }
    }
    
    ModalForm.prototype.insertTextarea = function(input, label, container) {
        var labelcontainer = $("<td>", { align : 'left', colspan : '2' }).append(label);
        var inputcontainer = $("<td>", { align : 'left', colspan : '2' }).append(input);
        $("<tr>").append(labelcontainer).appendTo(container);
        $("<tr>").append(inputcontainer).appendTo(container);
        $(input).css('width', '100%');
    }
    
    ModalForm.prototype.beforeSerialize = function(form, options) {
        // Must transform all 'on' of 'off' values from checkboxes to '1' or '0'
        for (field in this.fields) {
            if (this.fields[field].type === 'checkbox') {
                var checkbox = $(form).find('input[name="' + field + '"]');
                if (checkbox.attr('value') === 'on' ||
                    checkbox.attr('checked') === 'checked') {
                    checkbox.attr('value', '1');
                } else {
                    checkbox.attr('value', '0');
                }
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
        return this.beforeSubmit(arr, $form, opts, this);
    }
    
    ModalForm.prototype.startWizard = function() {
        $(this.form).formwizard({
            disableUIStyles     : true,
            validationEnabled   : true,
            validationOptions   : {
                rules           : this.validateRules,
                messages        : this.validateMessages,
                errorClass      : 'ui-state-error'
            },
            formPluginEnabled   : true,
            formOptions         : {
                beforeSerialize : $.proxy(this.beforeSerialize, this),
                beforeSubmit    : $.proxy(this.handleBeforeSubmit, this),
                success         : $.proxy(function(data) {
                    // Must delete all DOM elements
                    // but formwizard is using the element after this
                    // callback, so we delay the deletion
                    setTimeout($.proxy(function() { this.closeDialog(); }, this), 10);
                    this.callback(data);
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
            draggable       : false,
            width           : 500,
            buttons         : buttons,
            closeOnEscape   : false
        });
        $('.ui-dialog-titlebar-close').remove();
    }
 
    ModalForm.prototype.cancel = function() {
        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.closeDialog();
        }
        else {
            $(this.form).formwizard("back");
        }
        
    }
 
    ModalForm.prototype.closeDialog = function() {
        $(this).dialog("close");
        $(this).dialog("destroy");
        $(this.form).formwizard("destroy");
        $(this.content).remove();
    }
 
    ModalForm.prototype.validateForm = function () {
        $(this.form).formwizard("next");
    }
    
    return ModalForm;
    
})();