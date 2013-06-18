require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery.form.wizard.js');
require('jquery/jquery.qtip.min.js');
require('jquery/jquery.multiselect.min.js');
require('jquery/jquery.multiselect.filter.min.js');

var attributes_blacklist = [ 'class_type_id', 'entity_comment_id' ];


var KanopyaFormWizard = (function() {
    function KanopyaFormWizard(args) {
        this.handleArgs(args);

        this.content = $("<div>", { id : this.name }).css('overflow-x', 'hidden');

        this.validateRules    = {};
        this.validateMessages = {};

        // Check if it is a creation or an update form
        var method = 'POST';
        var action = '/api/' + this.type;
        if (this.id != null) {
            method  = 'PUT';
            action += '/' + this.id;
        }

        // Initialize the from
        this.data = {};
        this.form = $("<form>", { method : method, action : action });
        this.form.appendTo(this.content);

        // Load the form contents
        this.steps = {};
        var values = this.load();

        // We add buttons at end of the form
        var buttons = this.actionsCallback(values);
        if (buttons) {
            var actionsTable = $("<table>");
            var tr = $('<tr>');
            for (var i in buttons) {
                // To make wizard ignore them
                var button = buttons[i].addClass('wizard-ignore');
                // A new column for each action button
                var td = $('<td>');
                td.append(button);
                tr.append(td);
            }
            actionsTable.append(tr);
            var fieldset = $("<fieldset>").appendTo(this.form);
            var legend   = $("<legend>", { text : this.actionsLabel }).css('font-weight', 'bold');
            fieldset.append(legend);
            fieldset.append(actionsTable);
            this.form.appendTo(this.content).append(fieldset);
        }
    }

    KanopyaFormWizard.prototype.load = function(trigger) {
        this.attributedefs = {};

        // Retrieve data structure and values from api
        var response = this.attrsCallback(this.type, this.data, trigger);
        if (response == undefined) {
            throw new Error("KanopyaFormWizard: Could not get attributes of: " + this.type);
        }

        var attributes = response.attributes;
        var relations  = response.relations;

        // Displayed attr list can be overriden by the type attributes contents
        var displayed = $.merge([], this.displayed);
        if (response.displayed) {
            $.merge(displayed, response.displayed);
        }

        // Extract displayed 1-n relations from the displayed attr list
        var displayed_no_relations = [];
        for (var index in displayed) {
            if ($.isPlainObject(displayed[index])) {
                $.extend(true, this.relations, displayed[index]);
            } else {
                displayed_no_relations.push(displayed[index]);
            }
        }
        displayed = displayed_no_relations;

        // Firstly merge the attrdef with possible raw attrdef given in params
        jQuery.extend(true, attributes, this.rawattrdef);

        // If it is an update form, retrieve old datas from api
        var values = {};
        if (this.id) {
            values = this.valuesCallback(this.type, this.id, attributes);
        }

        // Build the form section corresponding to the object/class attributes
        this.buildFromAttrDef(attributes, displayed, values, relations);

        // For each relation 1-N, list all entries, add input to create an entry
        for (var relation_name in this.relations) if (this.relations.hasOwnProperty(relation_name)) {
            var relationdef = relations[relation_name];

            // Get the relation type attrdef
            var response;
            if (attributes[relation_name] !== undefined && attributes[relation_name].attributes !== undefined) {
                response = attributes[relation_name].attributes;
            } else {
                response = this.attrsCallback(relationdef.resource, this.data, trigger);
            }
            if (response == undefined) {
                throw new Error("KanopyaFormWizard: Could not get attributes of: " + relationdef.resource);
            }

            var rel_attributedefs = response.attributes;
            var rel_relationdefs  = response.relations !== undefined ? response.relations : {};

            // Tag attr defs as belongs to a relation
            var step = attributes[relation_name] ? attributes[relation_name].step : undefined;
            for (var name in rel_attributedefs) {
                rel_attributedefs[name].belongs_to = relation_name;
                rel_attributedefs[name].step = step;
            }

            // If creation, find the foreign key name to remove the attr from relation attrs
            var foreign;

            for (var cond in relationdef.cond) if (cond.indexOf('foreign.') >= 0) {
                foreign = cond.substring(8);
            }
            if (!foreign) {
                throw new Error("KanopyaFormWizard: Could not find the foreign key for relation " + relation_name);
            }

            if (!this.id) {
                // If it is a creation, remove the foreign key attr from new relations
                delete rel_attributedefs[foreign];

            } else {
                // If it is an update, set the foreign key attr to obj primary key for new relations
                rel_attributedefs[foreign].value = this.id;
            }

            // If the relation is editable, insert a button to add entries
            if (this.attributedefs[relation_name].is_editable == true) {
                var add_button = $("<input>", { class : 'wizard-ignore', type: 'button', id: 'add_button_' + relation_name });
                var add_button_line = $("<tr>").css('position', 'relative');
                $("<td>", { colspan : 2 }).append(add_button).appendTo(add_button_line);

                var tag = this.attributedefs[relation_name].label || relation_name;
                var table = this.findTable(this.attributedefs[relation_name].step, tag);

                table.parents('fieldset').css('display', 'block');

                table.append(add_button_line);

                var _this = this;
                var fixed_params = {
                    attributes : rel_attributedefs,
                    displayed  : _this.relations[relation_name],
                    values     : {},
                    relations  : rel_relationdefs,
                    listing    : _this.attributedefs[relation_name].label || relation_name
                };
                add_button.bind('click', fixed_params, function(event) {
                    _this.buildFromAttrDef(event.data.attributes, event.data.displayed,
                                           event.data.values, event.data.relations, event.data.listing);
                    _this.prettifyInputs();
                    _this.resizeDialog();
                });
                add_button.button({ icons : { primary : 'ui-icon-plusthick' } });
                add_button.val('Add');
            }

            // Check if values are specified in the relation attribute def
            var entries = this.attributedefs[relation_name].value || values[relation_name];

            // For each relation entries, add filled inputs in one line
            for (var entry in entries) {
                this.buildFromAttrDef(rel_attributedefs, this.relations[relation_name], entries[entry], rel_relationdefs,
                                      this.attributedefs[relation_name].label || relation_name);
            }
        }

        // Add raw steps divs if defined
        for (var name in this.rawsteps) {
            // Ignore all the raw step inputs
            this.rawsteps[name].find(":input").addClass("wizard-ignore");
            this.addStep(name, this.rawsteps[name]);
        }

        // Insert the step divs to the form content
        for (var step in this.steps) {
            $(this.steps[step].div).attr('id', this.name + '_step_' + step);

            var div = $(this.form).find('#' + this.name + '_step_' + step).get(0);
            if (div === undefined) {
                $(this.steps[step].div).appendTo(this.form);

            } else {
                var old = $(div).replaceWith($(this.steps[step].div));
                $(old).find('tr').remove();
                $(old).remove();
            }
            delete this.steps[step].div;
        }

        this.prettifyInputs();

        // Update the step to hide non visible steps
        $(this.form).formwizard("update_steps");

        this.resizeDialog();

        return values;
    }

    KanopyaFormWizard.prototype.buildFromAttrDef = function(attributes, displayed, values, relations, listing) {
        var ordered_attributes = {};

        // Building a new hash according to the orderer list of displayed attrs
        for (name in displayed) {
            ordered_attributes[displayed[name]] = attributes[displayed[name]];
            delete attributes[displayed[name]];
        }
        for (hidden in attributes) {
            // An attr can be forced to be not hidden
            if (attributes[hidden].hidden != false) {
                attributes[hidden].hidden = true;
            }
            ordered_attributes[hidden] = attributes[hidden];
        }

        // Extends the global attribute def hash with the new one.
        jQuery.extend(true, this.attributedefs, ordered_attributes);

        // For each attributes, add an input to the form
        for (var name in ordered_attributes) if (ordered_attributes.hasOwnProperty(name)) {
            /*
             * Do not insert inputs for:
             * - single_multi relations as they are displayed in a separate listing,
             * - virtual attributes as we can not set a value on,
             * - blacklisted attributes.
             */
            if (!($.inArray(name, attributes_blacklist) >= 0) &&
                !(this.attributedefs[name].type === 'relation' && this.attributedefs[name].relation === "single_multi")) {
                var value = this.attributedefs[name].value || values[name] || undefined;

                // Get options for select inputs
                if (this.attributedefs[name].type === 'relation' &&
                    (this.attributedefs[name].options === undefined || this.attributedefs[name].reload_options == true) &&
                    (this.attributedefs[name].relation === 'single' || this.attributedefs[name].relation === 'multi')) {

                    // For hidden fields, do not get possible values, add the value as option only
                    if (this.attributedefs[name].hidden && value !== undefined) {
                        this.attributedefs[name].options = $.isArray(value) ? value : [ value ];

                    } else {
                        this.attributedefs[name].options = this.getOptions(name, value, relations);
                    }
                }

                // Finally create the input field with label
                this.newFormInput(name, value, listing);
            }
        }
    };

    KanopyaFormWizard.prototype.getOptions = function(name, value, relations) {
        // Firstly call the possibly defined callback
        var cbresult = this.optionsCallback(name, value, relations);
        if (cbresult !== false) {
            return cbresult
        }

        var resource = undefined;
        var options  = undefined;

        if (relations[name]) {
            // Relation is multi to multi
            resource = this.attributedefs[name].link_to.replace(/_/g, '');

        } else {
            // Relation is single to single
            for (var relation in relations) {
                for (var prop in relations[relation].cond) if (relations[relation].cond.hasOwnProperty(prop)) {
                    if (relations[relation].cond[prop] === 'self.' + name) {
                        resource = relations[relation].resource;
                        // We should really break out of the double loop
                        // but it breaks the instance instanciation form
                        break;
                    }
                }
            }
        }
        if (resource) {
            options = ajax('GET', '/api/' + resource);
        }

        // TODO: check if we can remove this block as the case is handled in buildFromAttrDef
        // If there is no options but a fixed value,
        // add the value to options.
        if (options === undefined && value !== undefined) {
            options = [ value ];
        }
        return options !== undefined ? options : [];
    };

    KanopyaFormWizard.prototype.newFormInput = function(name, value, listing) {
        var attr = this.attributedefs[name];

        var width = 250;
        if (listing !== undefined) {
            width -= 100;
        }

        // Create input and label DOM elements
        var label = $("<label>", { for : 'input_' + name, text : name });

        // Use the label if defined
        if (attr.label !== undefined) {
            $(label).text(attr.label);
        }

        var input = undefined;
        var table = this.findTable(attr.step, listing);

        // Handle text fields
        if (toInputType(attr.type) === 'textarea') {
            input = $("<textarea>", { class : 'ui-corner-all ui-widget-content' });

        // Handle select fields
        } else if (toInputType(attr.type) === 'select') {
            input = $("<select>", { width: width });

            // If relation is multi, set the multiple select attribute
            if (attr.relation === 'multi') {
                input.attr('multiple', 'multiple');
            }

            // Get link_to attribute PK name for relation
            var link_to_attribute_pk_name = this.attributedefs[name].link_to + '_id';

            // Check if a welcome value is defined
            if (attr.welcome && $.isEmptyObject(this.data)) {
                attr.options.unshift({ pk : -1, label : attr.welcome });
                $(input).bind('change.welcome', function (event) {
                    $(this).find("option:first").remove();
                    $(this).unbind('change.welcome');
                });
            }

            // insert yes/no values for boolean select
            if (attr.type === 'boolean') {
                attr.options = { 0 : 'No', 1 : 'Yes' };
            }

            // Inserting select options
            for (var i in attr.options) if (attr.options.hasOwnProperty(i)) {
                var optiontext  = attr.options[i].label || attr.options[i].pk || attr.options[i];
                var optionvalue = attr.options[i][link_to_attribute_pk_name] || attr.options[i].pk ||
                                  ($.isArray(attr.options) ? attr.options[i] : i);

                var option = $("<option>", { value : optionvalue, text : optiontext }).appendTo(input);
                if (attr.formatter != null) {
                    $(option).text(attr.formatter($(option).text()));
                }

                // Set current option to value if defined
                if (optionvalue == value || ($.isArray(value) && $.inArray(optionvalue, value) >= 0)) {
                    $(option).attr('selected', 'selected');
                }
            }

        // Handle other field types
        } else {
            if (listing && attr.size) {
                var pixels_by_character = 13;
                width = attr.size * pixels_by_character;
            }
            input = $("<input>", { type : attr.type ? toInputType(attr.type) : 'text',
                                   class : 'ui-corner-all ui-widget-content', width: width - 1, height: 18 });
        }

        // Set the input attributes
        var id = 'input_' + name;

        // If listing mode, use the numbre of row to postfix input ids
        // avoiding inputs of each rows have the same id.
        if (listing) {
            // 3 lines are used for the button, labels and errors
            id += '_' + (table.find('tr').length - 4);
        }
        $(input).attr({ name : name, id : id, rel : name });

        // Check if the attr is mandatory
        this.validateRules[name] = {};
        if (attr.is_mandatory == true) {
            $(label).append(' *');
            if ($(input).attr('type') !== 'checkbox') {
                this.validateRules[name].required = true;
            }

        } else if ((toInputType(attr.type) === 'select' && attr.relation === 'single') ||
                   ((attr.type === 'enum' || attr.type === 'boolean') && attr.relation !== 'multi')) {
            var option = $("<option>", { value : '', text : '-' }).prependTo(input);
            if (value === undefined) {
                $(option).attr('selected', 'selected');
            }
        }

        // Check if the attr must be validated by a regular expression
        if ($(input).attr('type') !== 'checkbox' && attr.pattern !== undefined) {
            if (attr.is_mandatory != true) {
                attr.pattern = '(^$|' + attr.pattern + ')';
            }
            this.validateRules[name].regex = attr.pattern;
        }

        // Insert value if any
        if (value !== undefined) {
            if (input.is('input')) {
                if (input.attr('type') == 'checkbox') {
                    if (value == true) {
                        $(input).attr('checked', 'checked');
                    }
                } else {
                    $(input).attr('value', value);
                }
            } else if (input.is('textarea')) {
                $(input).text(value);
            }
        }

        // Disable the field if required
        if (this.mustDisableField(name, value) === true) {
            this.disableInput(input);

            // If the hideDisabled option set, hide the input
            if (this.hideDisabled) {
                attr.hidden = true;
            }
        }

        /*
         * Set the field as hidden if defined.
         * Be carefull to not move this block before the previous
         * tests on the input type, has we change the type to hidden.
         */
        if (attr.hidden) {
            input.attr('type', 'hidden');

        } else {
            table.parents('fieldset').css('display', 'block');
        }

        // Finally, insert DOM elements in the form
        this.insertInput(input, label, table, attr.help || attr.description, listing, value);

        if ($(input).attr('type') === 'date') {
            $(input).datepicker({ dateFormat : 'yy-mm-dd', constrainInput : true });
        }

        // Set reload callback on onChange event if required
        if (attr.reload && this.reloadable) {
            input.bind('change', $.proxy(this.reload, this));
        }

        /*
         * Unit management
         * - simple value to display beside attr
         * - unit selector when unit is 'byte' (MB, GB) and display current
         *   value with the more appropriate value
         *
         * See policiesform for management of unit depending on value of another attr
         */
        if (attr.unit) {
            var unit_cont = $('<span>');
            var unit_field_id = 'unit_' + $(input).attr('id');
            $(input).parent().append(unit_cont);

            var current_unit;
            var unit_input = addFieldUnit(attr, unit_cont, unit_field_id);
            if (unit_input) {
                if ($(input).attr('disabled')) {
                    this.disableInput(unit_input);
                }
                $(unit_input).addClass('unit');
                // TODO: Get the real length of the unit select box.
                $(input).width($(input).width() - 50);
            } else {
                // TODO: Get the real length of the unit select box.
                $(input).width($(input).width() - 55);
            }
            current_unit = attr.unit;

            // Set the serialize attribute to manage convertion from (selected) unit to final value
            // Warning : this will override serialize attribute if defined
            this.attributedefs[name].serialize = function(val, input) {
                return val * getUnitMultiplicator('unit_' + $(input).attr('id'));
            }

            // If exist a value then convert it in human readable
            if (current_unit === 'byte' && $(input).val()) {
                var readable_value = getReadableSize($(input).val(), 1);
                if (readable_value.value != 0) {
                    $(input).val(readable_value.value);
                    $(unit_cont).find('option:contains("' + readable_value.unit + '")').attr('selected', 'selected');
                }
            }
        }
    }

    KanopyaFormWizard.prototype.insertInput = function(input, label, table, help, listing, value) {
        var linecontainer;

        // TODO: factorize code for both mode listing or not

        // If listing mode, append the input horizontally to the last line.
        // Build the labels line if not exists
        if (listing) {
            // TODO: Handle all special caracters as accent, etc
            listing = listing.replace(/ /g, '_');

            if (input.attr('type') === 'checkbox') {
                input.width(110);
            }

            var relation_name = this.attributedefs[input.attr('name')].belongs_to;

            // Search for the line that contains labels for this listing
            var labelsline = $(table).find('tr.labels_' + listing).get(0);
            var errorsline = $(table).find('tr.errors_' + listing).get(0);
            if (! labelsline) {
                // Add an empty line if not existsset next
                labelsline = $("<tr>").css('position', 'relative').css('display', 'none');
                labelsline.addClass('labels_' + listing);
                labelsline.appendTo(table);
                // Add another line for error messages
                errorsline = $("<tr>").css('position', 'relative');
                errorsline.addClass('errors_' + listing);
                errorsline.appendTo(table);
                // Add a column for actions
                var labeltd = $("<td>", { align : 'left' });
                labeltd.appendTo(labelsline);
                var errortd = $("<td>", { align : 'left' });
                errortd.appendTo(errorsline);
            }

            var line = $(table).find('tr.' + listing).get(0);

            // Search for the label of the current field within the labels line
            var labeltd = $(labelsline).find('td.label_' + $(input).attr('name')).get(0);
            if (! labeltd) {
                // The label for this column does not exists yet,
                // we are building the first line of the listing.
                labeltd = $("<td>", { align : 'left' }).append(label);
                labeltd.addClass('label_' + $(input).attr('name'));
                labeltd.appendTo(labelsline);
                // Add a td to display possible error message for this column
                errortd = $("<td>", { align : 'left' });
                errortd.addClass('error_' + $(input).attr('name'));
                errortd.appendTo(errorsline);

            } else {
                // The labels line has been filled, so we can use
                // the number of columns to kown when swithing to next line.
                if ($(line).children('td').length >= $(labelsline).children('td').length) {
                    $(line).removeClass(listing);
                    line = undefined;
                };
            }

            // Build a new line if required
            if (! line) {
                line = $("<tr>").css('position', 'relative')
                line.addClass(listing);
                line.appendTo(table);

                var td = $("<td>", { align : 'left', width : 60 });

                if (! (relation_name && ! this.attributedefs[relation_name].is_editable)) {
                    // Add a button to remove the line
                    var removeButton = $('<a>').button({ icons : { primary : 'ui-icon-closethick' }, text : false });
                    removeButton.addClass('wizard-ignore');
                    removeButton.bind('click', function () {
                        $(line).remove();
                        if ($(table).find('tr:visible').length <= 3) {
                            $(labelsline).remove();
                            $(errorsline).remove();
                        }
                    });
                    td.append(removeButton);
                }

                if (this.attributedefs[relation_name].hide_existing && value != undefined) {
                    line.css('display', 'none');
                } else {
                    $(labelsline).css('display', '');
                }

                line.append(td);
            }

            var inputcontainer = $("<td>", { align : 'left' }).append(input);

            // Hide the line if required
            if ($(input).attr('type') === 'hidden') {
                $(inputcontainer).css('display', 'none');
                $(labeltd).css('display', 'none');
            }
            inputcontainer.appendTo(line);

        // Else insert a line with the label and the input.
        } else {
            $(label).text($(label).text() + " : ");

            // Add the line to the container
            if (input.is("textarea")) {
                var labelcontainer = $("<td>", { align : 'left', colspan : '2' }).append(label);
                var inputcontainer = $("<td>", { align : 'left', colspan : '2' }).append(input);
                var labelline = $("<tr>").append($(labelcontainer).append(this.createHelpElem(help))).appendTo(table);

                // Hide the label if required
                if ($(input).attr('type') === 'hidden') {
                    $(labelline).css('display', 'none');
                }

                linecontainer = $("<tr>").append(inputcontainer);
                $(input).css('width', '96.5%');

            } else {
                linecontainer = $("<tr>").css('position', 'relative');
                $("<td>", { align : 'left' }).append(label).appendTo(linecontainer);
                $("<td>", { align : 'right' }).append(input).append(this.createHelpElem(help)).appendTo(linecontainer);
            }
            linecontainer.appendTo(table);

            // Hide the line if required
            if ($(input).attr('type') === 'hidden') {
                $(linecontainer).css('display', 'none');
            }

            // Add a confirm password line if required
            if ($(input).attr('type') === 'password') {
                var lineclone = $(linecontainer).clone();

                var _this = this;
                lineclone.find(':input').each(function() {
                    // Update attrs
                    $(this).attr('name', $(this).attr('name') + '_confirm');
                    $(this).attr('id', $(this).attr('id') + '_confirm');
                    $(this).attr('rel', $(this).attr('rel') + '_confirm');

                    // Update label
                    lineclone.find("label").each(function() {
                        $(this).text('Confirm ' + $(this).text());
                    });
                    $(this).addClass('wizard-ignore');

                    // Set a validation rule to compare with password
                    _this.validateRules[$(this).attr('name')] = {};
                    _this.validateRules[$(this).attr('name')].confirm_password = $(input);
                });
                lineclone.appendTo(table);
            }   
        }
    }

    KanopyaFormWizard.prototype.disableInput = function(input) {
        $(input).attr('disabled', 'disabled');
        $(input).addClass('wizard-ignore').addClass("ui-state-disabled");
    }

    KanopyaFormWizard.prototype.reload = function(event) {
        // Enable fields in non visible steps as the same way while submiting
        if (Object.keys(this.steps).length > 1) {
            $(this.form).find(":input").not(".wizard-ignore").removeAttr("disabled");
        }
        this.beforeSerialize($(this.form));

        // Update the data hash as it will be given in parameter
        // to the attributtes request at reload
        this.data = this.serialize($(this.form).serializeArray());

        // Then reload the form
        this.load($(event.target).attr('name'));
    }

    KanopyaFormWizard.prototype.mustDisableField = function(name, value) {
        if (this.attributedefs[name].disabled == true) {
            return true;
        }
        if ($(this.form).attr('method').toUpperCase() === 'PUT' && this.attributedefs[name].is_editable != true &&
            !(this.attributedefs[name].is_primary == true && this.attributedefs[name].belongs_to != undefined)) {
            return true;
        }
        if (this.attributedefs[name].is_editable != true && value !== undefined &&
            (this.attributedefs[name].belongs_to === undefined || this.attributedefs[name].is_mandatory == true)) {
            return true;
        }
        if (this.attributedefs[name].belongs_to && this.attributedefs[this.attributedefs[name].belongs_to].is_editable != true) {
            return true;
        }
        return false;
    }

    KanopyaFormWizard.prototype.beforeSerialize = function(form, options) {
        var _this = this;
        $(form).find(':input').not('.wizard-ignore').not('button').each(function () {
            // Must transform all 'on' or 'off' values from checkboxes to '1' or '0'
            if (toInputType(_this.attributedefs[$(this).attr('name')].type) === 'checkbox') {
                if ($(this).attr('checked')) {
                    $(this).attr('value', '1');
                } else {
                    $(this).attr('value', '0');
                    // Check the checkbox if we want the value submited
                    $(this).attr('checked', 'checked');
                }

            // Disable password confirmation inputs
            } else if ($(this).attr('type') === 'password') {
                $('#' + $(this).attr('id') + '_confirm').attr('disabled', 'disabled');
            }

            if (_this.attributedefs[$(this).attr('name')].serialize != null) {
                var value = _this.attributedefs[$(this).attr('name')].serialize($(this).val(), $(this));
                if (value != 0) {
                    $(this).val(value);
                }
            }

            // Disable empty non mandatory fields, only if there are select or not editable.
            if ($(this).val() === '' && ! _this.attributedefs[$(this).attr('name')].is_mandatory &&
                (toInputType(_this.attributedefs[$(this).attr('name')].type) === 'select' ||
                 ! _this.attributedefs[$(this).attr('name')].is_editable)) {

                $(this).attr('disabled', 'disabled');
            }
        });
    }

    KanopyaFormWizard.prototype.serialize = function(arr) {
        // Building a hash representing the object with its relations
        var data = {};

        // Prepare an empty array for relations, because if all entries
        // for this relation has been removed, we need to send an empty list
        // to known we need to remove all entries for this relation form db.
        for (var index in this.displayed) {
            var attr = this.attributedefs[this.displayed[index]];
            if (attr.type === 'relation' && attr.relation != 'single') {
                data[this.displayed[index]] = [];
            }
        }

        var rel_attr_names = {};
        var current_multi;
        for (var index in arr) {
            var attr = arr[index];

            // If the attr is an attr of a relation,
            // move value in the corresponding sub hash
            var hash_to_fill;
            if (this.attributedefs[attr.name].belongs_to) {
                var belongs_to = this.attributedefs[attr.name].belongs_to;
                if (rel_attr_names[belongs_to] === undefined) {
                    rel_attr_names[belongs_to] = [];
                }
                var rel_list = data[belongs_to];
                if (rel_list === undefined) {
                    data[belongs_to] = [];
                    rel_list = data[belongs_to];
                }

                // If attr not in the array, we are completting an entry
                if ($.inArray(attr.name, rel_attr_names[belongs_to]) < 0 && rel_attr_names[belongs_to].length) {
                    rel_attr_names[belongs_to].push(attr.name);

                // If the attr is in the array but the type of the attr is a relation,
                // then continue to fill the array only if the last value belongs to this mutli relation.
                } else if (rel_list[rel_list.length - 1] == undefined ||
                           ! ($.isArray(rel_list[rel_list.length - 1][attr.name]) && current_multi != undefined)) {
                    rel_attr_names[belongs_to] = [attr.name];
                    rel_list.push({});
                }
                hash_to_fill = rel_list[rel_list.length - 1];

            } else {
                hash_to_fill = data;
            }
            if (this.attributedefs[attr.name].relation === 'multi') {
                if (! hash_to_fill[attr.name]) {
                    hash_to_fill[attr.name] = [];

                    // Keep the info that we are filling a multi relation
                    current_multi = attr.name;
                }
                hash_to_fill[attr.name].push(attr.value);

            } else {
                hash_to_fill[attr.name] = attr.value;

                // If current_multi is defined, this becase the last field was a value of
                // a multi relation, that ust finished to be filled.
                if (current_multi != undefined) {
                    current_multi = undefined;
                }
            }
        }

        // Once data has been serialized, browse the relation to initialize lists of
        // relations of relations if not defined.
        for (var relation in this.relations) {
            for (var index in this.relations[relation]) {
                var attr = this.attributedefs[this.relations[relation][index]];

                if (attr !== undefined && attr.type === 'relation' && attr.relation != 'single') {
                    for (var entryindex in data[relation]) {
                        if (data[relation][entryindex][this.relations[relation][index]] === undefined) {
                            data[relation][entryindex][this.relations[relation][index]] = [];
                        }
                    }
                }
            }
        }
        return data;
    }

    KanopyaFormWizard.prototype.handleBeforeSubmit = function(arr, $form, opts) {
        // Serialize values in a hash represen ting the object with this relations
        this.data = this.serialize(arr);

        // Submit the values
        this.submitCallback(this.data, $form, opts, $.proxy(this.onSuccess, this), $.proxy(this.onError, this));
        return false;
    }

    KanopyaFormWizard.prototype.submit = function(data, $form, opts) {
        // We submit the form ourself because we want the data into json,
        // as we need to submit relations in a subhash.
        $.ajax({
            url         : $(this.form).attr('action'),
            type        : $(this.form).attr('method').toUpperCase(),
            contentType : 'application/json',
            data        : JSON.stringify(data),
            success     : $.proxy(this.onSuccess, this),
            error       : $.proxy(this.onError, this)
        });
    }

    KanopyaFormWizard.prototype.getValues = function(type, id, attributes) {
        var url = '/api/' + type + '/' + id;

        // As the relations n-n are not defined in 'relation' param, we need to
        // browse the attributes to find relations attr that needs an expand to get values.
        var relations = jQuery.extend({}, this.relations);
        var multi_relations = {};
        for (var attr in attributes) {
            if (attributes[attr].type === 'relation' && attributes[attr].relation === 'multi') {
                // Save link_to attribute PK name for each relation
                multi_relations[attr] = attributes[attr].link_to + '_id';
            }
        }

        jQuery.extend(relations, multi_relations);

        // For each relation 1-N, use expand to get related entries with object values
        if (relations && ! $.isEmptyObject(relations)) {
            var expands = [];
            for (relation in relations) if (relations.hasOwnProperty(relation)) {
                expands.push(relation);
            }
            url += '?expand=' + expands.join(',');
        }
        var values = ajax('GET', url);

        for (var value in multi_relations) {
            var link_to_attribute_pk_name = multi_relations[value];
            var pk_values = [];
            for (var entry in values[value]) {
                pk_values.push(values[value][entry][link_to_attribute_pk_name]);
            }
            values[value] = pk_values;
        }
        return values;
    }

    KanopyaFormWizard.prototype.getAttributes = function(resource, data, trigger) {
        if (trigger) {
            data['trigger'] = trigger;
        }
        return ajax('GET', '/api/attributes/' + resource, data);
    }

    KanopyaFormWizard.prototype.findTable = function(step, tag) {
        // Use step as tag if defined in options
        if (this.stepsAsTags && step !== undefined) {
            if (tag === undefined) {
                tag = step;
            }
            step = undefined;
        }
        // Use the resource type if no step specified
        if (step === undefined) {
            step = this.type;
        }
        var table = tag || step;

        // Workaround to get the currently in dom table when 'Add' button of listings clicked
        if (tag && this.steps[step] != undefined && this.steps[step].tables[tag] != undefined) {
            return this.steps[step].tables[tag];
        }

        // If the div for the step does not exists, create it
        if (this.steps[step] === undefined || this.steps[step].div === undefined) {
            this.addStep(step, $("<div>"));
        }

        // If the table does not exists, create it
        if (this.steps[step].tables[table] === undefined) {
            this.steps[step].tables[table] = $("<table>");
            if (tag) {
                var fieldset = $("<fieldset>").css('border-color', '#ddd').css('display', 'none');
                fieldset.append($("<legend>", { text : tag }).css('font-weight', 'bold'));
                fieldset.append(
                        $('<div>').css('overflow', 'auto').css('width', this.width - 50)
                        .append(this.steps[step].tables[table].css('width', this.width - 50))
                );
                fieldset.appendTo(this.steps[step].div);

            } else {
                this.steps[step].tables[table].css('width', this.width);
                this.steps[step].tables[table].appendTo(this.steps[step].div);
            }
        }
        return this.steps[step].tables[table];
    }

    KanopyaFormWizard.prototype.addStep = function(name, div) {
        if (name !== this.type) {
            $(div).addClass('step').attr('rel', name);
        }
        this.steps[name] = { 'div' : $(div), 'tables' : {} };
    }

    KanopyaFormWizard.prototype.start = function() {
        $(document).append(this.content);
        // Open the modal and start the form wizard
        this.openDialog();
        this.startWizard();
    }

    KanopyaFormWizard.prototype.handleArgs = function(args) {
        if ('type' in args) {
            this.type = args.type;
            this.name = 'form_' + args.type;
        }

        this.id              = args.id;
        this.width           = args.width           || 700;
        this.displayed       = args.displayed       || [];
        this.relations       = args.relations       || {};
        this.rawattrdef      = args.rawattrdef      || {};
        this.rawsteps        = args.rawsteps        || {};
        this.callback        = args.callback        || $.noop;
        this.title           = args.title           || this.name;
        this.actionsLabel    = args.actionsLabel    || 'Actions';
        this.skippable       = args.skippable       || false;
        this.reloadable      = args.reloadable      || false;
        this.hideDisabled    = args.hideDisabled    || false;
        this.stepsAsTags     = args.stepsAsTags     || false;
        this.submitCallback  = args.submitCallback  || this.submit;
        this.valuesCallback  = args.valuesCallback  || this.getValues;
        this.attrsCallback   = args.attrsCallback   || (args.type ?
                                                        this.getAttributes :
                                                        function () { return { attributes : [], relations : [] } });
        this.optionsCallback = args.optionsCallback || function () { return false };
        this.actionsCallback = args.actionsCallback || $.noop;
        this.cancelCallback  = args.cancelCallback  || $.noop;
        this.error           = args.error           || $.noop;
    }

    KanopyaFormWizard.prototype.exportArgs = function() {
        return {
            type            : this.type,
            id              : this.id,
            width           : this.width,
            displayed       : this.displayed,
            relations       : this.relations,
            rawattrdef      : this.rawattrdef,
            rawsteps        : this.rawsteps,
            callback        : this.callback,
            title           : this.title,
            skippable       : this.skippable,
            reloadable      : this.reloadable,
            hideDisabled    : this.hideDisabled,
            stepsAsTags     : this.stepsAsTags,
            submitCallback  : this.submitCallback,
            valuesCallback  : this.valuesCallback,
            attrsCallback   : this.attrsCallback,
            cancelCallback  : this.cancelCallback,
            optionsCallback : this.optionsCallback
        };
    }

    KanopyaFormWizard.prototype.createHelpElem = function(help) {
        if (help !== undefined) {
            var helpElem = $("<span>", { class : 'ui-icon ui-icon-info' });
            $(helpElem).css({ cursor : 'help', margin : '2px 0 0 2px', float : 'right' });
            $(helpElem).qtip({
                content  : help.replace("\n", "<br />", 'g'),
                position : {
                    corner : {
                        target  : 'rightMiddle',
                        tooltip : 'leftMiddle'
                    }
                },
                style : { tip : { corner  : 'leftMiddle' } }
            });
            return helpElem;

        } else {
            return $("<span>").css({ display : 'block', width : '16px', 'margin-left' : '2px',
                                     height : '1px', float : 'right' });
        }
    }

    KanopyaFormWizard.prototype.changeStep = function(event, state) {
        var stepsdiv  = $(this.content).children("div#" + this.name + "_steps");
        if (state.previousStep != state.currentStep) {
            // Unbold the previuous step
            stepsdiv.children("label#" + state.previousStep + "_label").css('font-weight', 'normal');
        }
        stepsdiv.children("label#" + state.currentStep + "_label").css('font-weight', 'bold');

        // Update buttons state
        if (! state.isLastStep) {
            this.buttons['Ok'].addClass('next-button');
            this.buttons['Ok'].find('span').text('Next');
        }
        else {
            this.buttons['Ok'].removeClass('next-button');
            this.buttons['Ok'].find('span').text('Ok');
        }
        this.enableButtons(state);
    }

    KanopyaFormWizard.prototype.startWizard = function() {
        $(this.form).formwizard({
            disableUIStyles     : true,
            validationEnabled   : true,
            validationOptions   : {
                rules           : this.validateRules,
                messages        : this.validateMessages,
                errorClass      : 'ui-state-error',
                errorPlacement  : $.proxy(this.errorPlacement, this)
            },
            formPluginEnabled   : true,
            formOptions         : {
                beforeSerialize : $.proxy(this.beforeSerialize, this),
                beforeSubmit    : $.proxy(this.handleBeforeSubmit, this),
                success         : $.proxy(this.onSuccess, this),
                error           : $.proxy(this.onError, this)
            }
        });

        var steps = $(this.form).children("div.step");
        if (steps.length > 1) {
            // Add a div to display steps names
            var stepsdiv = $("<div>", { id : this.name + "_steps" }).css({
                width           : '100%',
                'border-bottom' : '1px solid #AAA',
                position        : 'relative'
            });

            var index = 1;
            var _this = this;
            $(steps).each(function() {
                var steplabel = $("<label>");
                steplabel.attr('id', $(this).attr('id') + '_label');
                steplabel.attr('rel', $(this).attr('id'));
                steplabel.html(index + '. ' + $(this).attr('rel'));
                steplabel.css("cursor", "pointer");
                steplabel.click(function () {
                    _this.disableButtons();
                    $(_this.form).formwizard("show", $(this).attr('rel'));
                });

                stepsdiv.append(steplabel).append($("<label>", { text : ' > '}));
                ++index;
            });

            $(this.content).prepend($("<br />"));
            $(this.content).prepend(stepsdiv);

            this.changeStep({}, $(this.form).formwizard("state"));
            $(this.form).bind('step_shown', $.proxy(this.changeStep, this));
        }
        this.resizeDialog();
    }

    KanopyaFormWizard.prototype.errorPlacement = function(error, element) {
        // Check if the input come from a listing by searching
        // a possibly defined td for the error label
        var errortd = this.form.find('td.error_' + element.attr('name')).get(0);
        if (errortd) {
            // If an error already exists for this column, do not add it.
            if ($(errortd).find('label').length <= 0) {
                error.appendTo(errortd);
            }
        } else {
            error.insertBefore(element);
        }
    }

    KanopyaFormWizard.prototype.onSuccess = function(data) {
        // Ugly but must delete all DOM elements
        // but formwizard is using the element after this
        // callback, so we delay the deletion
        this.closeDialog();
        this.callback(data, this.form);

        return data;
    }

    KanopyaFormWizard.prototype.onError = function(data) {
        var buttonsdiv = $(this.content).parents('div.ui-dialog').children('div.ui-dialog-buttonpane');
        buttonsdiv.find('button').each(function() {
            $(this).removeAttr('disabled', 'disabled');
        });
        $(this.content).find("div.ui-state-error").each(function() {
            $(this).remove();
        });
        var error = {};
        try {
            error = JSON.parse(data.responseText);
        }
        catch (err) {
            error.reason = 'An error occurs, but can not be parsed...'
        }
        $(this.content).prepend($("<div>", { text : error.reason, class : 'ui-state-error ui-corner-all ui-widget-content' }));
        this.error(data);
    }

    KanopyaFormWizard.prototype.openDialog = function() {
        var buttons = [];
        buttons.push({
            id    : "button-cancel",
            text  : "Cancel",
            click : $.proxy(this.cancel, this)
        });

        // Add a back button if there is more than one step
        if (Object.keys(this.steps).length > 1) {
            buttons.push({
                id    : "button-back",
                text  : "Back",
                click : $.proxy(this.back, this)
            });
        }

        // Always add the OK button
        buttons.push({
            id    : "button-ok",
            text  : "Ok",
            click : $.proxy(this.validateForm, this)
        });

        if (this.skippable) {
            buttons.push({
                id    : "button-skip",
                text  : "Skip",
                click :  $.proxy(function() {
                    this.closeDialog();
                    this.callback();
                }, this)
            });
        }
        this.content.dialog({
            title           : this.title,
            modal           : true,
            resizable       : false,
            dialogClass     : 'no-close',
            position        : 'top',
            width           : 'auto',
            minWidth        : 800,
//            maxHeight       : 550,
            buttons         : buttons,
            closeOnEscape   : false
        }).on('keydown', function(e) { // bind the Enter key press
            if(e.which == 13) {
                if(!$("textarea").is(":focus") && !$('.ui-button').is(':focus')){
                    $('.ui-button#button-ok:visible').first().click();
                    return false;
                }
            }
        });
        this.buttons = {
            'Ok'     : $('#button-ok'),
            'Cancel' : $('#button-cancel'),
            'Back'   : $('#button-back')
        };
        
        // If we are in the step mode, disable button as they will be
        // enabled by the changeStep method.
        if (Object.keys(this.steps).length > 1) {
            this.disableButtons();
        }
    }

    KanopyaFormWizard.prototype.cancel = function() {
        this.cancelCallback();
        this.closeDialog();
    }

    KanopyaFormWizard.prototype.back = function() {
        this.disableButtons();

        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.cancel();
        }
        else {
            $(this.form).formwizard("back");
        }
    }

    KanopyaFormWizard.prototype.disableButtons = function() {
        for (var button in this.buttons) {
            this.buttons[button].attr('disabled', 'disabled').addClass("ui-state-disabled");
        }
    }

    KanopyaFormWizard.prototype.enableButtons = function(state) {
        if (state === undefined) {
            state = $(this.form).formwizard("state");
        }
        for (var button in this.buttons) {
            if (! (state.isFirstStep && button === 'Back')) {
                this.buttons[button].removeAttr('disabled').removeClass("ui-state-disabled");
            }
        }
    }

    KanopyaFormWizard.prototype.closeDialog = function() {
        setTimeout($.proxy(function() {
            $(this).dialog("close");
            $(this).dialog("destroy");
            $(this.form).formwizard("destroy");
            $(this.content).remove();
        }, this), 10);
    }

    KanopyaFormWizard.prototype.prettifyInputs = function() {
        // Use jQuery.mutiselect (after DOM loaded)
        this.content.find('select[multiple="multiple"]').not('.multiselect').addClass('multiselect').multiselect({selectedList: 4}).each(addFilter);
        this.content.find('select[multiple!="multiple"]').not('.multiselect').not('.unit').addClass('multiselect').multiselect({
            multiple: false,
            header: false,
            selectedList: 1,
        }).each(addFilter);

        // Add a filter field if number of options is fairly high
        function addFilter(i,e) {
            if ($(e).find('option').length > 10) {
                $(e).multiselect('option', 'header', true).multiselectfilter();
            }
        }
    }

    KanopyaFormWizard.prototype.resizeDialog = function() {
        if ($(this.content).height() > $(window).innerHeight() - 200) {
            $(this.content).css('height', $(window).innerHeight() - 200);
        }
        if ($(this.content).width() > $(window).innerWidth() - 50) {
            $(this.content).css('width', $(this.content).innerWidth() - 50);
        }
        $(this.content).dialog('option', 'position', 'top');
    }

    KanopyaFormWizard.prototype.validateForm = function () {
        this.disableButtons();

        // Add validation rules for inputs inserted dynamically in the form.
        var _this = this;
        $(this.form).find(':input').each(function () {
            for (var rule in _this.validateRules[$(this).attr('name')]) {
                var rules = $(this).rules();
                if (rules[rule] === undefined) {
                    $(this).rules("add", _this.validateRules[$(this).attr('name')]);
                    break;
                }
            }
        });
        var oldstep = $(this.form).formwizard("state").currentStep;

        $(this.form).formwizard("next");

        // If the state has not changed, there was an error while
        // validation, so enable buttons.
        var state = $(this.form).formwizard("state");
        if (Object.keys(this.steps).length <= 1 || (oldstep === state.currentStep && ! state.isLastStep)) {
            this.enableButtons();
        }
    }
    return KanopyaFormWizard;
    
})();

$.validator.addMethod("regex", function(value, element, regexp) {
    var re = new RegExp(regexp);
    return this.optional(element) || re.test(value);
}, "Please check your input");

$.validator.addMethod("confirm_password", function(value, element, input) {
    return value === $(input).val();
}, "Password differs");

// Override the checkFrom validator method, to validate all fields
// that have the same name instead of the first occurrence of each.
$.validator.prototype.checkForm = function() {
    this.prepareForm();
    for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++ ) {
        if (this.findByName(elements[i].name ).length != undefined && this.findByName(elements[i].name).length > 1) {
            for (var cnt = 0; cnt < this.findByName( elements[i].name ).length; cnt++) {
                this.check(this.findByName(elements[i].name)[cnt]);
            }
        } else {
            this.check(elements[i]);
        }
    }
    return this.valid();
};
