require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery-ui-timepicker-addon.js');

// For getServiceProviders and findManager
require('common/service_common.js');

$.validator.addMethod("regex", function(value, element, regexp) {
    var re = new RegExp(regexp);

    /* The following test 'this.optional' do not allow to
     * validate the pattern of non mandatory fields.
     * We need to check the role of this test and find
     * how configure the validator options to do this.
     */
    //return this.optional(element) || re.test(value);
    return re.test(value);
}, "Please check your input");


var workaroundFunctions = {
    'getServiceProviders' : getServiceProviders,
    'findManager'         : findManager
};

var PolicyForm = (function() {
    function PolicyForm(args) {
        this.handleArgs(args);

        this.content    = $("<div>", { id : this.name });

        this.validateRules      = {};
        this.validateMessages   = {};

        var method = 'POST';
        var action = '/api/' + this.baseName;
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
            this.handleField(elem);
        }

        // input_trigger is the class for select element which has a onChange event
        // The callback could modify other fields of the form so we trigger change after all fields are created
        this.form.find('.input_trigger').change();
    }

    PolicyForm.prototype.handleField = function(elem) {
        // If this is a set, add a button to allow to add elements to the set
        if (this.fields[elem].set && !this.fields[elem].composite && !this.fields[elem].triggered) {
            var set_table = $("<table>", { id: 'fieldset_' + this.fields[elem].set }).css('width', '100%');
            var set_tr = $("<tr>").css('position', 'relative');
            var set_td = $("<td>", { colspan: 2 });

            set_tr.appendTo(this.findContainer(this.fields[elem].step));
            set_tr.append(set_td);

            var fieldset = $("<fieldset>").appendTo(set_td);
            fieldset.css('border-color', '#ddd');
            fieldset.append($("<legend>", { text : this.fields[elem].set }).css('font-weight', 'bold'));
            fieldset.append(set_table);

            var add_button = $("<input>", { text : this.fields[elem].add_label, id : 'add_button_' + elem, type: 'button', class : 'wizard-ignore' });
            add_button.button();

            var that = this;
            add_button.bind('click', { elem: elem }, function(event) {
                var added = that.newElement(event.data.elem);

                that.findContainer(that.fields[event.data.elem].step).find(':input').not(':button').each(function() {
                    var fieldName = $(this).attr('rel')
                    if (! that.fields[fieldName]) return 0;

                    if (that.fields[fieldName].policy) {
                        function resetPolicyIdOnChange (event) {
                            that.resetPolicyId(fieldName);
                        }
                        $(this).bind('change.resetPolicy', resetPolicyIdOnChange);
                    }
                });
            });

            $(this.content).dialog('option', 'position', 'top');
            //$(this.content).dialog('option', 'position', $(this.content).dialog('option', 'position'));
            if ($(this.content).height() > $(window).innerHeight() - 200) {
                $(this.content).css('height', $(window).innerHeight() - 200);
            }

            fieldset.append(add_button);
            add_button.val(this.fields[elem].add_label);

            // If we have values for a set element, add the elements with values.
            if (this.values[elem]) {
                for (var set_element in this.values[elem]) {
                    var classes;
                    if (this.fields[elem].policy) {
                        classes = this.fields[elem].policy + '_policy_id_dynamic_field dynamic_field';
                        add_button.addClass(classes);
                    }
                    this.newElement(elem, this.values[elem][set_element], undefined, classes);
                }
            }
        } else if (! this.fields[elem].composite) {
            this.newElement(elem, this.values[elem] || this.fields[elem].value);
        }
    }

    PolicyForm.prototype.newElement = function(elem, value, noset, classes) {
        var added = new Array();
        if (this.fields[elem].triggered && !this.fields[elem].composite) {
            if (! this.triggeredFields[this.fields[elem].triggered]) {
                this.triggeredFields[this.fields[elem].triggered] = new Array();
            }

            this.triggeredFields[this.fields[elem].triggered].push(elem);
            return 0;
        }

        if ((this.fields[elem].type === 'select' || this.fields[elem].type === 'multiselect') && !this.fields[elem].options) {
            added.push(this.newDropdownElement(elem, undefined, value));

        } else if (this.fields[elem].type === 'composite') {
            for (var composite_field in this.fields) {
                if (this.fields[composite_field].composite === elem) {
                    this.fields[composite_field].step = this.fields[elem].step;
                    this.fields[composite_field].set = this.fields[elem].set;

                    var composite_value;
                    if (value) composite_value = value[composite_field];
                    added = added.concat(this.newElement(composite_field, composite_value, true));
                }
            }
        } else {
            added.push(this.newFormElement(elem, value));
        }

        if (classes) {
            for (var element in added) {
                added[element].addClass(classes);
            }
        }

        if (this.fields[elem].set && !noset) {
            var container = this.findContainer(this.fields[elem].step, this.fields[elem].set);

            if (! this.fields[elem].disable_filled) {
                var remove_button = $("<input>", { text : 'Remove', class : 'wizard-ignore ', type: 'button' });
                remove_button.button();

                var removebuttonline = $("<tr>", { class : classes }).css('position', 'relative');

                $("<td>", { colspan : 2 }).append(remove_button).appendTo(removebuttonline);
                container.append(removebuttonline);

                remove_button.val('Remove');
                remove_button.bind('click', function() {
                    for (var to_remove in added) {
                        $(added[to_remove]).remove();
                    }
                    removebuttonline.remove();
                    hrseprationline.remove();
                });
            }

            var need_separtion = false;
            for (var set_item in added) {
                if (! ($(added[set_item]).css('display') == 'none')) {
                    need_separtion = true;
                    break;
                }
            }
            if (need_separtion) {
                var hrseprationline  = $("<tr>", { class : classes }).css('position', 'relative');
                $("<td>", { colspan : 2 }).append($('<hr>')).appendTo(hrseprationline);
                container.append(hrseprationline);

                $(this.content).dialog('option', 'position', 'top');
                //$(this.content).dialog('option', 'position', $(this.content).dialog('option', 'position'));
                if ($(this.content).height() > $(window).innerHeight() - 200) {
                    $(this.content).css('height', $(window).innerHeight() - 200);
                }
            }
        }

        // Use jQuery.mutiselect (after DOM loading)
        this.content.find('select[multiple="multiple"]').multiselect({selectedList: 4});
//        this.content.find('select[multiple!="multiple"]').not('.wizard-ignore').multiselect({
//            multiple: false,
//            header: "Select an option",
//            noneSelectedText: "-",
//            selectedList: 1
//        });

        return added;
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

        this.id                 = args.id;
        this.callback           = args.callback         || $.noop;
        this.fields             = args.fields           || {};
        this.values             = args.values           || {};
        this.title              = args.title            || this.name;
        this.skippable          = args.skippable        || false;
        this.beforeSubmit       = args.beforeSubmit     || $.noop;
        this.cancelCallback     = args.cancel           || $.noop;
        this.error              = args.error            || $.noop;
        this.dialogParams       = args.dialogParams     || {};
        this.formwizardParams   = args.formwizardParams || {};
        this.triggeredFields    = {};
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

    PolicyForm.prototype.newFormElement = function(elementName, value, after) {
        var field = this.fields[elementName];
        var element = field;
        var input_name = elementName;

        /* Arg */
        if (! value) value = this.values[elementName];

        if (this.fields[elementName].hide_filled && (value || this.fields[elementName].type === 'radio')) {
            this.fields[elementName].type = 'hidden';
        }

        /* Use select for checkboxes because non checked checkboxes are handled as
         * non filled inputs. So fill the select with yes/no vlaues.
         */
        var type = field.type;
        var options = field.options;
        this.fields[elementName].value_shift = 0;
        if (field.type === 'checkbox') {
            type = 'select';
            options = [ 'no', 'yes' ];
            if (this.fields[elementName].is_mandatory == null ||
                this.fields[elementName].is_mandatory == false) {
                this.fields[elementName].value_shift = 1;
            }
            if (value) {
                value = parseInt(value) + this.fields[elementName].value_shift;
            }
        }

        // If type is 'set', post fix the element name with the current index
        var inputid = 'input_' + elementName;
        if (field.set) {
            input_name = elementName + '_' + this.form.find(".input_" + elementName).length;
            inputid += '_' + this.form.find(".input_" + elementName).length;
        }

        var set_element
        // Create input and label DOM elements
        var label = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (field.label !== undefined) {
            $(label).text(field.label);
        }
        if (type === undefined || (type !== 'textarea' && type !== 'select' && type !== 'multiselect')) {
            var type    = type || 'text';
            var input   = $("<input>", { type : type, name : input_name, id : inputid,  width: 246, class : 'ui-corner-all input_' + elementName, rel : elementName });

            if (type === 'radio') {
                var that = this;
                input.bind('change', { rel: elementName }, function (event) {
                    /* As we can have exclusive radio that hjace different input names,
                     * we manually uncheck other radio belonging to the same radio group.
                     */
                    if (event.target.id) {
                        that.form.find('*[rel="' + event.data.rel + '"]').not('#' + event.target.id).removeAttr('checked');

                    } else {
                        that.form.find('*[rel="' + event.data.rel + '"]').removeAttr('checked');
                    }
                });
                if (parseInt(value) === 1 || (this.form.find('*[rel="' + elementName + '"]').length == 0 && ! this.fields[elementName].policy)) {
                    input.attr('checked', 'checked');
                    input.change();
                }
            }
        } else if (type === 'textarea') {
            var type    = 'textarea';
            var input   = $("<textarea>", { type : type, name : input_name, id : inputid, class : 'ui-corner-all input_' + elementName, rel : elementName });
        }
        else if (type === 'select' || type === 'multiselect') {
            var input   = $("<select>", { width: 250, type : type, name : input_name, id : inputid, class : 'input_' + elementName, rel : elementName });
            var isArray = options instanceof Array;
            if (! this.fields[elementName].is_mandatory) {
                var option  = $("<option>", { value : 0, text : '-' });
                this.fields[elementName].value_shift = 1;
                input.append(option);
            }
            for (var i in options) if (options.hasOwnProperty(i)) {
                var optionvalue = (isArray != true) ? options[i] : parseInt(i) + this.fields[elementName].value_shift;
                var optiontext  = (isArray != true) ? i : options[i];
                var option  = $("<option>", { value : optionvalue, text : optiontext }).appendTo(input);
                if (optionvalue == value) {
                    option.attr('selected', 'selected');
                    if (this.fields[elementName].disable_filled) {
                        this.disableInput(input);
                    }
                }
            }
            if (this.fields[elementName].onChange) {
                input.change(this.fields[elementName].onChange);
                input.addClass('input_trigger');
            }
            if (type === 'multiselect') {
                input.attr('multiple', 'multiple');
            }
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
            if (type === 'text' || type === 'textarea' || type === 'hidden'
                || type === 'datetime' || type === 'time') {
                $(input).val(value);
                if (type !== 'hidden') {
                    if (this.fields[elementName].disable_filled) {
                        this.disableInput(input);
                    }
                }
            } else if (type === 'checkbox' && value == true) {
                //$(input).attr('checked', 'checked');
                $(input).val('1');
                if (this.fields[elementName].disable_filled) {
                    this.disableInput(input);
                }
            }
        }

        $(label).text($(label).text() + " : ");

        // Finally, insert DOM elements in the form
        var tr;
        var container = this.findContainer(field.step, field.set);
        if (input.is("textarea")) {
            tr = this.insertTextarea(input, label, container, field.help || element.description, after);
        } else {
            tr = this.insertTextInput(input, label, container, field.help || element.description, after);
        }

        if (this.mustDisableField(elementName, element) === true) {
            this.disableInput(input);
        }

        if ($(input).attr('type') === 'date') {
            $(input).datepicker({ dateFormat : 'yyyy-mm-dd', constrainInput : true });

        } else if ($(input).attr('type') === 'datetime') {
            $(input).datetimepicker({
                timeOnly    : false,
                hourGrid    : 4,
                minuteGrid  : 10,
                closeText   : 'Close'
            });

        } else if ($(input).attr('type') === 'time') {
            $(input).timepicker({
                hourGrid    : 4,
                minuteGrid  : 10,
                closeText   : 'Close'
            });
        }

        // manage unit
        // - simple value to display beside field
        // - unit selector when unit is 'byte' (MB, GB) and display current value with the more appropriate value
        // - unit depending on value of another field
        if (element.unit) {
            var unit_cont = $('<span>');
            var unit_field_id ='unit_' + $(input).attr('id');
            $(input).parent().append(unit_cont);

            var current_unit;
            if (typeof element.unit === 'object') {
                // the unit depends on another field
                // Get the closest input with rel = element.unit.depends, and bind change function
                var trigger_input = $(input).closest('tr').prevAll('tr').find('[rel="' + element.unit.depends + '"]').first();
                trigger_input.change( function() {
                    $(unit_cont).empty();
                    current_unit = element.unit.value[$(this).val()];
                    var unit_input = addFieldUnit({ unit : current_unit }, unit_cont, unit_field_id);
                });
                trigger_input.change();
            } else {
                var unit_input = addFieldUnit(element, unit_cont, unit_field_id);
                current_unit = element.unit;
            }

            // Set the serialize attribute to manage convertion from (selected) unit to final value
            // Warning : this will override serialize attribute if defined in policiesdefs
            this.fields[elementName].serialize = function(val, elem) {
                return val * getUnitMultiplicator('unit_' + $(elem).attr('id'));
            }

            // If exist a value then convert it in human readable
            if (current_unit === 'byte' && $(input).val()) {
                var readable_value = getReadableSize($(input).val());
                $(input).val( readable_value.value );
                $(unit_cont).find('option:contains("' + readable_value.unit + '")').attr('selected', 'selected');
            }

            // If field is disabled then disable the unit selector
            if ($(input).attr('disabled') === 'disabled') {
                $('#' + unit_field_id).attr('disabled', 'disabled');
            }
            // TODO: Get the real lenght of the unit select box.
            $(input).width($(input).width() - 50);
        }

        return tr;
    }

    PolicyForm.prototype.newDropdownElement = function(elementName, options, current, after) {
        var container = this.findContainer(this.fields[elementName].step, this.fields[elementName].set);
        var input_name = elementName;

        /* Arg */
        if (! current) {
            current = this.values[elementName];
        }

        // If type is 'set', post fix the element name with the current index
        var inputid = 'input_' + elementName;
        if (this.fields[elementName].set) {
            input_name = elementName + '_' + this.form.find(".input_" + elementName).length;
            inputid += '_' + this.form.find(".input_" + elementName).length;
        }

        // Create input and label DOM elements
        var label   = $("<label>", { for : 'input_' + elementName, text : elementName });
        if (this.fields[elementName].label !== undefined) {
            $(label).text(this.fields[elementName].label);
        }

        var input = $("<select>", { name : input_name, width: 250, id : inputid, class : 'input_' + elementName, rel : elementName });

        if (this.fields[elementName].type === 'multiselect') {
            input.attr('multiple', 'multiple');
        }

        this.validateRules[elementName] = {};
        // Check if the field is mandatory
        if (this.fields[elementName].is_mandatory == true) {
            $(label).append(' * : ');
            this.validateRules[elementName].required = true;
        } else {
            $(label).append(' : ');
        }
        // Check if the field must be validated by a regular expression
        if ($(input).attr('type') !== 'checkbox' && this.fields[elementName].pattern !== undefined) {
            this.validateRules[elementName].regex = this.fields[elementName].pattern;
        }

        /* Ugly hard coded hack to fill the service provider value, if the
         * depending fields are filled. If we are in policy edition context, we
         * have values for managers, but not for the corresponding service
         * provider that containt the manager. So if manager are defined, ask
         * for the service provider id to fill the select input.
         */
        if (current === undefined) {
            for (var depend_index in this.fields[elementName].depends) {
                var depend = this.fields[elementName].depends[depend_index];

                if (this.values[depend]) {
                    var depend_obj = this.ajaxCall('GET', '/api/' + this.fields[depend].entity + '/' + this.values[depend]);

                    /* Another hard coded name here (service_provider_id) */
                    if (depend_obj.service_provider_id) {
                        current = depend_obj.service_provider_id;
                        break;
                    }
                }
            }
        }

        var datavalues;
        if (options) {
            datavalues = options;

        } else if (this.fields[elementName].parent) {
            var parent = this.form.find("#input_" + this.fields[elementName].parent);
            this.updateFromParent(input, parent.val());

            var that = this;
            parent.change(function (event) {
                that.updateFromParent(input, event.target.value);
            });

        } else {
            var entity = this.fields[elementName].entity;

            var route = '/api/' + entity;
            var delimiter = '?';
            var method = 'GET';
            var args;

            if (this.fields[elementName].filters &&
                workaroundFunctions[this.fields[elementName].filters.func] !== undefined) {
                datavalues = workaroundFunctions[this.fields[elementName].filters.func](this.fields[elementName].filters.args);

            } else {
                if (this.fields[elementName].filters) {
                    if (this.fields[elementName].filters.func) {
                        method = 'POST';
                        route += '/' + this.fields[elementName].filters.func;
                        args = this.fields[elementName].filters.args;
                    } else {
                        for (var filter in this.fields[elementName].filters) {
                            route += delimiter + filter + '=' + this.fields[elementName].filters[filter];
                            if (delimiter === '?') {
                                delimiter = '&';
                            }
                        }
                    }
                } else if (this.fields[elementName].rawfilter) {
                    route += this.fields[elementName].rawfilter;
                }
                datavalues = this.ajaxCall(method, route, args);
            }
        }

        if (! this.fields[elementName].is_mandatory) {
            var option = $("<option>", { value : 0, text : '-' });
            input.append(option);

        } else if (this.fields[elementName].welcome_value) {
            var option = $("<option>", { value : 0, text : this.fields[elementName].welcome_value, id : 'welcome_' + elementName});
            input.append(option);

            test = options;
            var that = this;
            function updateRemoveWelcomeValueOnChange (event) {
                $('#welcome_' + input.attr('name')).remove();
            }
            input.change(updateRemoveWelcomeValueOnChange);
        }

        /* Inject all values in the select */
        for (value in datavalues) {
            var key = undefined;
            var text = undefined;
            if (typeof datavalues[value] === "object") {
                key = datavalues[value].pk;
                var display = 'pk';

                if (this.fields[elementName].display_func && this.fields[elementName].entity) {
                    text = this.ajaxCall('POST', '/api/' +  this.fields[elementName].entity + '/' + key + '/' + this.fields[elementName].display_func);

                } else {
                    text = datavalues[value][this.fields[elementName].display || 'pk'];
                }
            } else if (datavalues instanceof Array) {
                key  = datavalues[value];
                text = datavalues[value];

            } else {
                key  = value;
                text = datavalues[value];
            }

            var option = $("<option>", { value : key , text : text });

            $(input).append(option);

            if ((current !== undefined && current == key) || ($.isArray(current) && $.inArray(key, current) >= 0)) {
                option.attr('selected', 'selected');

                if (this.fields[elementName].disable_filled) {
                    this.disableInput(input);
                }
            }
        }

        if (this.mustDisableField(elementName, this.fields[elementName]) === true) {
            this.disableInput(input);
        }

        /*
         * If 'params' defined in the field, this is a field that raise dynamic
         * insertion/removal of other fields
         */
        if (this.fields[elementName].params) {
            var that = this;
            function updatePolicyParamsOnChange (event) {
                that.updatePolicyParams(input, event.target.value);
            }
            input.change(updatePolicyParamsOnChange);
        }

        // Finally, insert DOM elements in the form
        var inserted = this.insertTextInput(input, label, container, this.fields[elementName].help || this.fields[elementName].description, after);

        // Raise the onChange event to update related objects
        input.change();

        if (this.fields[elementName].hide_filled && current) {
            inserted.hide();
            if (this.fields[elementName].parent) {
                /* @ @ You never had seen the following line @ @ */
                this.form.find('#input_' + this.fields[elementName].parent).parent().parent().hide();

                this.fields[this.fields[elementName].parent].type = 'hidden';
            }
        }

        /* If 'values_func' defined in the field, this is a field that could
         * fill other fields with key/value hash returned by the given function
         * call.
         */
        if (this.fields[elementName].trigger) {
            var that = this;
            function triggerOnChange (event) {
                that.insertTriggeredElements(input, elementName);
            }
            input.change(triggerOnChange);

        } else if (this.fields[elementName].values_provider) {
            /*
             * If 'values_func' defined in the field, this is a field that could
             * fill other fields with key/value hash returned by the given
             * function call.
             */
            var that = this;
            function updateValuesOnChange (event) {
                that.updateValues(input, event.target.value);
            }
            input.change(updateValuesOnChange);
        }

        return inserted;
    }

    PolicyForm.prototype.updateValues = function (element, selected_id) {
        var datavalues = undefined;
        var name = element.attr('name');
        var step = this.fields[name].step;

        if (! (name && parseInt(selected_id))) { return; }

        element.removeClass('disabled_policy_id');
        this.removeDynamicFields(name);

        /* Unset any callback on change event handle policies update */
        var that = this;
        this.findContainer(step).find(':input').each(function() {
            $(this).unbind('.resetPolicy');
        });

        if (this.fields[name].values_provider.func) {
            /* Call the given function on the entity to get a values hash */
            datavalues = this.ajaxCall('POST',
                                       '/api/' + this.fields[name].entity + '/' + selected_id + '/' + this.fields[name].values_provider.func,
                                       this.fields[name].values_provider.args);
        }

        /* Complete the values hash with the entity attributes */
        var datavalues = jQuery.extend(datavalues, this.ajaxCall('GET', '/api/' + this.fields[name].entity + '/' + selected_id));

        /* TODO: Do not hard code this :) */
        if (this.fields[name].entity === 'policy') {
            datavalues[datavalues['policy_type'] + '_policy_name'] = datavalues['policy_name'];
            datavalues[datavalues['policy_type'] + '_policy_desc'] = datavalues['policy_desc'];
        }

        this.values = datavalues;

        var that = this;
        var update_select = function() {
        //this.form.find('select').each(function() {
            var select_name = $(this).attr('name');
            if (that.fields[select_name] && select_name !== name) {
                var reset_value;

                if (that.fields[select_name].is_mandatory) {
                    var options = $(this).find('option');
                    if (options[0]) {
                        reset_value = options[0].value;
                    }
                } else {
                    reset_value = 0;
                }

                $(this).val(reset_value);
                if (that.fields[select_name].depends) {
                    $(this).change();
                }

                if (! (that.fields[select_name].disabled)) {
                    $(this).removeAttr('disabled');
                }
                if (datavalues[select_name]) {
                    /*
                     * Firstly set the value of the the parent field if exist,
                     * to raise the onChange event that fill the current select
                     * with possibles values corresponding to the current value
                     * to set.
                     */
                    if (that.fields[select_name].parent) {
                        /*
                         * Ugly hard coded hack to fill the service provider
                         * value, if the depending fields are filled.
                         */
                        var manager = that.ajaxCall('GET', '/api/' + that.fields[select_name].entity + '/' + datavalues[select_name]);

                        // Another hard coded name here (service_provider_id)
                        if (manager.service_provider_id) {
                            var parent = that.form.find('#input_' + that.fields[select_name].parent);
                            parent.val(manager.service_provider_id);
                            parent.change();
                            that.disableInput(parent);
                        }
                    }

                    if (that.fields[select_name].value_shift) {
                        datavalues[select_name] = parseInt(datavalues[select_name]) + parseInt(that.fields[select_name].value_shift);
                    }
                    $(this).val(datavalues[select_name]);

                    if (that.fields[select_name].values_provider) {
                        $(this).change();
                    }
                    if (that.fields[select_name].disable_filled) {
                        that.disableInput($(this));
                    }

                    if (that.fields[select_name].hide_filled) {
                        $(this).parent().parent().hide();
                        if (that.fields[select_name].parent) {
                            var parent = that.form.find('#input_' + that.fields[select_name].parent);
                            parent.parent().parent().hide();
                        }
                    }
                }
            }
        };

        if (this.fields[name].fields_provided) {
            for (var provided in this.fields[name].fields_provided) {
                this.form.find('#input_' + this.fields[name].fields_provided[provided]).each(update_select);
            }
        } else {
            this.findContainer(step).find('select').each(update_select);

            this.findContainer(step).find('input').not(':button').each(function() {
                $(this).val('');

                if (! that.fields[$(this).attr('name')]) return 0;

                if (! (that.fields[$(this).attr('name')].disabled)) {
                    $(this).removeAttr('disabled');
                }
                if (datavalues[$(this).attr('name')]) {
                    $(this).val(datavalues[$(this).attr('name')]);
                    if (that.fields[$(this).attr('name')].disable_filled) {
                        that.disableInput($(this));
                    }
                    if (that.fields[$(this).attr('name')].hide_filled) {
                        $(this).parent().parent().hide();
                    }
                }
            });
            this.findContainer(step).find('textarea').each(function() {
                $(this).val('');
                if (! (that.fields[$(this).attr('name')].disabled)) {
                    $(this).removeAttr('disabled');
                }
                if (datavalues[$(this).attr('name')]) {
                    $(this).val(datavalues[$(this).attr('name')]);
                    if (that.fields[$(this).attr('name')].disable_filled) {
                        that.disableInput($(this));
                    }
                    if (that.fields[$(this).attr('name')].hide_filled) {
                        $(this).parent().parent().hide();
                    }
                }
            });
        }

        /* Ugly third loop to set a callback on change, because
         * the first loop could raise this callback on some fileds.
         * We really need to review the mecanism that fill values in fields.
         *
         * Set a callback on change event handle policies update.
         */
        var that = this;
        this.findContainer(step).find(':input').not(':button').each(function() {
            var fieldName = $(this).attr('rel')
            if (! that.fields[fieldName]) return 0;

            if (that.fields[fieldName].policy) {
                function resetPolicyIdOnChange (event) {
                    that.resetPolicyId(fieldName);
                }
                $(this).bind('change.resetPolicy', resetPolicyIdOnChange);
            }
        });

        /* Add set elements if exists in values. Unfortunately we need
         * to check if we have values for each set element.
         */
        for (var set_element in this.fields) {
            if (this.values[set_element] && this.fields[set_element].set && !this.fields[set_element].composite) {
                for (var value in this.values[set_element]) {
                    this.newElement(set_element, this.values[set_element][value]);
                }
            }
        }
    }

    PolicyForm.prototype.resetPolicyId = function (elementName) {
        this.form.find('#input_' + this.fields[elementName].policy + '_policy_id').addClass('disabled_policy_id');
    }

    PolicyForm.prototype.updateFromParent = function (element, selected_id) {
        var datavalues = undefined;
        var name = element.attr('name');

        if (! (name && selected_id)) { return; }

        /* Arg... Can not call the route according to
         * this.fields[elementName].entity, as we do not have a common parent
         * class for component and connector. So use the findManager workaround
         * method for instance.
         */
        var entity = this.fields[name].parent;

        var route;
        var method = 'GET';
        var args;

        /* Ugly workaround to replace removed api methods */
        if (this.fields[name].filters &&
            workaroundFunctions[this.fields[name].filters.func] !== undefined) {
            args = this.fields[name].filters.args ? this.fields[name].filters.args : {};

            var reg = new RegExp("^.*_provider_id", "g");
            if (this.fields[name].parent.match(reg)) {
                args['service_provider_id'] = selected_id;
            }
            else {
                args[this.fields[name].parent] = selected_id;
            }
            datavalues = workaroundFunctions[this.fields[name].filters.func](args);

        } else {
            if (this.fields[name].filters) {
                method = 'POST';
                route = '/api/' + this.fields[this.fields[name].parent].entity + '/' + selected_id;
                route += '/' + this.fields[name].filters.func;
                args = this.fields[name].filters.args ? this.fields[name].filters.args : {};

                // Arrgg, the parent field name is not 'service_provider_id', but 'storage_provider_id'...
                //args[this.fields[name].parent] = selected_id;
                var reg = new RegExp("^.*_provider_id", "g");
                if (this.fields[name].parent.match(reg)) {
                    args['service_provider_id'] = selected_id;
                }
                else {
                    args[this.fields[name].parent] = selected_id;
                }

            } else {
                var parent = this.fields[name].parent;
                var reg = new RegExp("^.*_provider_id", "g");
                if (this.fields[name].parent.match(reg)) {
                    parent = 'service_provider_id';
                }
                route = '/api/' + this.fields[name].entity + '/' + parent + '=' + selected_id;
            }
            datavalues = this.ajaxCall('POST', route, args);
        }

        // Inject all values in the select
        element.empty();
        for (var value in datavalues) {
            var display = datavalues[value][this.fields[name].display] || datavalues[value].pk;

            if (this.fields[name].display_func && this.fields[name].entity) {
                var resource_name = this.ajaxCall('POST', '/api/' +  this.fields[name].entity + '/' + datavalues[value].pk + '/' + this.fields[name].display_func);
                if (resource_name) display = resource_name;
            } else if (datavalues[value].name) {
                display = datavalues[value].name;
            }

            var option  = $("<option>", { value : datavalues[value].pk , text : display });

            element.append(option);
            if (datavalues[value].pk == this.values[name]) {
                option.attr('selected', 'selected');
                if (this.fields[name].disable_filled) {
                    this.disableInput(element);
                }
            }
        }
        element.change();
    }

    PolicyForm.prototype.updatePolicyParams = function (element, selected_id) {
        var name  = element.attr('name');
        this.removeDynamicFields(name);

        if (! selected_id) { return; }

        var datavalues = this.ajaxCall('POST',
                                       '/api/' + this.fields[name].entity + '/' + selected_id + '/' + this.fields[name].params.func,
                                       this.fields[name].params.args);

        for (var value in datavalues) {
            this.fields[datavalues[value].name] = {
                label   : datavalues[value].label,
                pattern : datavalues[value].pattern,
                step    : this.fields[name].step,
                policy  : this.fields[name].policy,
                prefix  : this.fields[name].prefix,
                disable_filled : this.fields[name].disable_filled,
                hide_filled    : this.fields[name].hide_filled,
                is_mandatory   : (this.fields[name].is_mandatory && this.fields[name].handle_mandatory)
            }

            var tr = undefined;
            if (datavalues[value].values) {
                tr = this.newDropdownElement(datavalues[value].name,
                                             datavalues[value].values,
                                             this.values[datavalues[value].name],
                                             name);
            } else {
                tr = this.newFormElement(datavalues[value].name, this.values[datavalues[value].name], name);
            }

            tr.addClass(name + '_dynamic_field');
            tr.addClass('dynamic_field');
        }
    }

    PolicyForm.prototype.removeDynamicFields = function (name) {
        var classtoremove;
        if (name) {
            classtoremove = name + '_dynamic_field';
        } else {
            classtoremove = 'dynamic_field';
        }

        var that = this;
        this.form.find("." + classtoremove).each(function  () {
            $(this).remove();
            delete that.fields[$(this).find(':input').attr('name')];
        });
    }

    PolicyForm.prototype.insertTriggeredElements = function (input, name) {
        var that = this;
        if (this.fields[name].trigger) {

            var fieldsToInsert = this.triggeredFields[name];
            this.triggeredFields[name] = new Array();

            if (this.fields[name].values_provider) {
                function updateValuesOnChange (event) {
                    that.updateValues(input, event.target.value);
                }
                input.change(updateValuesOnChange);
            }
            this.fields[name].trigger = undefined;

            input.change();

            for (var field in fieldsToInsert) {
                var elem = fieldsToInsert[field]
                this.fields[elem].triggered = undefined;

                this.handleField(elem);

                if (this.fields[elem].set) {
                    input.bind('change', { elem: elem }, function (event) {
                        that.handleField(event.data.elem);
                    });
                }
                fieldsToInsert[field] = undefined;
            }
        }

        /* This block is a hugly copy from updateValues method for quick fix. */
        var that = this;
        this.findContainer(this.fields[name].step).find(':input').not(':button').each(function() {
            var fieldName = $(this).attr('rel');
            if (! that.fields[fieldName]) return 0;

            if (that.fields[fieldName].policy) {
                function resetPolicyIdOnChange (event) {
                    that.resetPolicyId(fieldName);
                }
                $(this).bind('change.resetPolicy', resetPolicyIdOnChange);
            }
        });
    }

    PolicyForm.prototype.findContainer = function(step, set) {
        var container;
        if (step !== undefined) {
            var table = this.stepTables[step];
            if (table === undefined) {
               var table = $("<table>", { id : this.name + '_step' + step }).appendTo(this.form);
               table.attr('rel', step);
               $(table).css('width', '100%').addClass('step');
               this.stepTables[step] = table;
            }
            container = table;
        } else {
            container = this.table;
        }

        if (set !== undefined) {
            return container.find('#fieldset_' + set);
        }
        return container;
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
        var linecontainer = $("<tr>").css('position', 'relative');
        $("<td>", { align : 'left' }).append(label).appendTo(linecontainer);
        $("<td>", { align : 'right' }).append(input).append(this.createHelpElem(help)).appendTo(linecontainer);

        if (this.fields[$(input).attr('rel')].type === 'hidden') {
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
        $(input).css('width', '99%');

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
        var that = this;
        this.form.find(':input').each(function () {
            var id      = "";
            var classes = $(this).attr('class').split(' ');
            for (var i in classes) if (classes.hasOwnProperty(i)) {
                if ((new RegExp('^input_')).test(classes[i])) {
                    id  = (classes[i]).replace('input_', '');
                    break;
                }
            }

            if (that.fields[id]){
                if (that.fields[id].prefix) {
                    $(this).attr('name', that.fields[id].prefix + $(this).attr('name'));
                }
                if ((that.fields[id].type === 'select' ||
                     that.fields[id].type === 'multiselect' ||
                     that.fields[id].type === 'checkbox') && parseInt($(this).val()) == 0 ) {
                    $(this).attr('disabled', 'disabled');
                }
                if (that.fields[id].type === 'checkbox' && parseInt($(this).val())) {
                    $(this).val(parseInt($(this).val()) - that.fields[id].value_shift);
                }
                if (that.fields[id].type === 'radio' && $(this).val() === 'on') {
                    $(this).val(1);
                }
                if (that.fields[id].serialize != null && $(this).val() !== '') {
                    $(this).val(that.fields[id].serialize($(this).val(), this));
                }
            }
            $(this).removeClass('wizard-ignore');
        });
        this.form.find(".disabled_policy_id").each(function () {
            $(this).attr('disabled', 'disabled');
        });
    }

    PolicyForm.prototype.changeStep = function(event, data) {
        var steps   = $(this.form).children("table.step");
        var text    = "";
        var i       = 1;

        var that = this;

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
                text += " > " + prepend + i + ". " + $(this).attr('rel') + append;
            }

            ++i;
        });
        $(this.content).children("div#" + this.name + "_steps").html(text);

        $(this.content).dialog('option', 'position', 'top');
        //$(this.content).dialog('option', 'position', $(this.content).dialog('option', 'position'));
        if ($(this.content).height() > $(window).innerHeight() - 200) {
            $(this.content).css('height', $(window).innerHeight() - 200);
        }
    }

    PolicyForm.prototype.handleBeforeSubmit = function(arr, $form, opts) {
        var b   = this.beforeSubmit(arr, $form, opts, this);
        if (b) {
            var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
            buttonsdiv.find('button').each(function() {
                $(this).attr('disabled', 'disabled');
            });
        }
        return b;
    }

    PolicyForm.prototype.startWizard = function() {
        var that = this;
        var formwizard_params = {
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
        };

        $(this.form).formwizard(
                $.extend(true, formwizard_params, this.formwizardParams)
        );

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
        var buttons = {};
        if($(this.form).children("table").length > 1) {
            buttons['Back'] = $.proxy(this.back, this);
        }

        buttons['Cancel'] = $.proxy(this.cancel, this);
        buttons['Ok']     = $.proxy(this.validateForm, this);

        if (this.skippable) {
            buttons['Skip'] = $.proxy(function() {
                this.closeDialog();
                this.callback();
            }, this);
        }
        var dialog_default_params = {
                title           : this.title,
                modal           : true,
                resizable       : false,
                width           : 600,
                buttons         : buttons,
                closeOnEscape   : false
        };
        this.content.dialog(
                $.extend({}, dialog_default_params, this.dialogParams)
        );
        $('.ui-dialog-titlebar-close').remove();
    }

    PolicyForm.prototype.cancel = function() {
        this.cancelCallback();
        this.closeDialog();
    }

    PolicyForm.prototype.back = function() {
        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.cancel();
        } else {
            $(this.form).formwizard("back");
            this.disableCurrentStepFilled();
        }
    }

    PolicyForm.prototype.closeDialog = function() {
        setTimeout($.proxy(function() {
            this.removeDynamicFields();
            $(this).dialog("close");
            $(this).dialog("destroy");
            $(this.form).formwizard("destroy");
            $(this.content).remove();
        }, this), 10);
    }

    PolicyForm.prototype.validateForm = function () {
        var that = this;
        var remove_wizard_ignore = function() {
            $(this).removeClass('wizard-ignore');

            /* Keep the info about the filed has been desabled at least one time. */
            $(this).addClass('filled-disabled');
        }
        var addDynamicValidationRules = function() {
            try {
                var rules = {};
                if (that.fields[$(this).attr('rel')].is_mandatory) {
                    rules.required = true;
                }
                if ($(this).val() && that.fields[$(this).attr('rel')].pattern) {
                    rules.regex = that.fields[$(this).attr('rel')].pattern;
                }

                if (Object.keys(rules).length) {
                    $(this).rules("add", rules);

                } else {
                    $(this).rules("remove");
                }
            } catch (err) {
                // The form has not been validated yet.
            }
        }

        if ($(this.form).formwizard("state").currentStep) {
            var step_preffix = this.name + '_step';
            var step = $(this.form).formwizard("state").currentStep.substring(step_preffix.length);
            this.findContainer(step).find('.wizard-ignore').not(':button').each(remove_wizard_ignore);
            this.findContainer(step).find('input:text').each(addDynamicValidationRules);

        } else {
            $(this.form).find('.wizard-ignore').not(':button').each(remove_wizard_ignore);
            this.form.find('input:text').each(addDynamicValidationRules);
        }

        $(this.form).formwizard("next");
        this.disableCurrentStepFilled();
    }

    PolicyForm.prototype.disableCurrentStepFilled = function () {
        if ($(this.form).formwizard("state").currentStep) {
            var step_preffix = this.name + '_step';
            var step = $(this.form).formwizard("state").currentStep.substring(step_preffix.length);
            this.findContainer(step).find('.filled-disabled').attr('disabled', 'disabled');
        }
    }

    PolicyForm.prototype.disableInput = function (input) {
        input.attr('disabled', 'disabled');
        input.addClass('wizard-ignore');
    }

    PolicyForm.prototype.ajaxCall = function (method, route, data) {
        var response;
        $.ajax({
            type        : method,
            async       : false,
            url         : route,
            data        : data,
            dataTYpe    : 'json',
            success     : $.proxy(function(d) {
                response = d;
            }, this)
        });
        return response;
    }

    return PolicyForm;
})();
