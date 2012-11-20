require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery.form.wizard.js');
require('jquery/jquery.qtip.min.js');


var KanopyaFormWizard = (function() {
    function KanopyaFormWizard(args) {
        this.handleArgs(args);

        this.content = $("<div>", { id : this.name });

        this.validateRules    = {};
        this.validateMessages = {};

        // Check if it is a creation or an update form
        var method = 'POST';
        var action = '/api/' + this.type;
        if (this.id != null) {
            method  = 'PUT';
            action += '/' + this.id;
        }

        if (args.prependElement !== undefined) {
            this.content.prepend($(args.prependElement));
        }

        // Initialize the from
        this.form   = $("<form>", { method : method, action : action });
        this.table  = $("<table>").css('width', 650);
        this.tables = [];

        this.form.appendTo(this.content).append(this.table);

        this.attributedefs = {};

        // Retrieve data structure and values from api
        var response = this.attrsCallback(this.type);
        if (response == undefined) {
            throw new Error("KanopyaFormWizard: Could not get attributes of: " + this.type);
        }

        var attributes = response.attributes;
        var relations  = response.relations;

        // Firstly merge the attrdef with possible raw attrdef given in params
        jQuery.extend(true, attributes, this.rawattrdef);

        // If it is an update form, retrieve old datas from api
        var values = {};
        if (this.id) {
            values = this.valuesCallback(this.type, this.id, attributes);
        }

        // Build the form section corresponding to the object/class attributes
        this.buildFromAttrDef(attributes, this.displayed, values, relations);

        // For each relation 1-N, list all entries, add input to create an entry
        for (relation_name in this.relations) if (this.relations.hasOwnProperty(relation_name)) {
            var relationdef = relations[relation_name];

            // Get the relation type attrdef
            var response = this.attrsCallback(relationdef.resource);
            if (response == undefined) {
                throw new Error("KanopyaFormWizard: Could not get attributes of: " + relationdef.resource);
            }

            var rel_attributedefs = response.attributes;
            var rel_relationdefs  = response.relations;

            // Tag attr defs as belongs to a relation
            for (var name in rel_attributedefs) {
                rel_attributedefs[name].belongs_to = relation_name;
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
                var add_button = $("<input>", { text : 'Add', class : 'wizard-ignore', type: 'button', id: 'add_button_' + relation_name });
                var add_button_line = $("<tr>").css('position', 'relative');
                $("<td>", { colspan : 2 }).append(add_button).appendTo(add_button_line);
                this.findTable(this.attributedefs[relation_name].label || relation_name, this.attributedefs[relation_name].step).append(add_button_line);

                var _this = this;
                var fixed_params = {
                    attributes : rel_attributedefs,
                    displayed  : _this.relations[relation_name],
                    values     : {},
                    relations  : rel_relationdefs,
                    listing    : _this.attributedefs[relation_name].label || relation_name,
                };
                add_button.bind('click', fixed_params, function(event) {
                    _this.buildFromAttrDef(event.data.attributes, event.data.displayed,
                                           event.data.values, event.data.relations, event.data.listing);
                });
                add_button.button({ icons : { primary : 'ui-icon-plusthick' } });
                add_button.val('Add');
            }

            // For each relation entries, add filled inputs in one line
            for (var entry in values[relation_name]) {
                this.buildFromAttrDef(rel_attributedefs, this.relations[relation_name],
                                      values[relation_name][entry], rel_relationdefs,
                                      this.attributedefs[relation_name].label || relation_name);
            }
        }
    }

    KanopyaFormWizard.prototype.buildFromAttrDef = function(attributes, displayed, values, relations, listing) {
        var ordered_attributes = {};

        // Building a new hash according to the orderer list of displayed attrs
        for (name in displayed) {
            ordered_attributes[displayed[name]] = attributes[displayed[name]];
            delete attributes[displayed[name]];
        }
        for (hidden in attributes) {
            attributes[hidden].hidden = true;
            ordered_attributes[hidden] = attributes[hidden];
        }

        // Extends the global attribute def hash with the new one.
        jQuery.extend(true, this.attributedefs, ordered_attributes);

        // For each attributes, add an input to the form
        for (var name in ordered_attributes) if (ordered_attributes.hasOwnProperty(name)) {
            var value = this.attributedefs[name].value || values[name] || undefined;

            // Get options for select inputs
            if (this.attributedefs[name].type === 'relation' && this.attributedefs[name].options === undefined &&
                (this.attributedefs[name].relation === 'single' || this.attributedefs[name].relation === 'multi')) {
                this.attributedefs[name].options = this.buildSelectOptions(name, value, relations);
            }

            // Finally create the input field with label
            this.newFormInput(name, value, listing);
        }

        if ($(this.content).height() > $(window).innerHeight() - 200) {
            $(this.content).css('height', $(window).innerHeight() - 200);
            $(this.content).css('width', $(this.content).width() + 15);
        }
        $(this.content).dialog('option', 'position', 'top');
    };

    KanopyaFormWizard.prototype.buildSelectOptions = function(name, value, relations) {
        var resource = undefined;
        var options  = undefined;

        if (relations[name]) {
            // Relation is multi to multi
            resource = this.attributedefs[name].link_to;

        } else {
            // Relation is single to single
            for (relation in relations) {
                for (prop in relations[relation].cond) if (relations[relation].cond.hasOwnProperty(prop)) {
                    if (relations[relation].cond[prop] === 'self.' + name) {
                        resource = relations[relation].resource;
                        break;
                    }
                }
            }
        }
        if (resource) {
            options = ajax('GET', '/api/' + resource);
        }

        // If there is no options but a fixed value,
        // add the value to options.
        if (options === undefined && value !== undefined) {
            options = [ value ];
        }
        return options !== undefined ? options : [];
    };

    KanopyaFormWizard.prototype.newFormInput = function(name, value, listing) {
        var attr = this.attributedefs[name];

        // Create input and label DOM elements
        var label = $("<label>", { for : 'input_' + name, text : name });

        // Use the label if defined
        if (attr.label !== undefined) {
            $(label).text(attr.label);
        }

        var input = undefined;

        // Handle text fields
        if (toInputType(attr.type) === 'textarea') {
            input = $("<textarea>");

        // Handle select fields
        } else if (toInputType(attr.type) === 'select') {
            input = $("<select>", { width: 250 });

            // If relation is multi, set the multiple select attribute
            if (attr.relation === 'multi') {
                input.attr('multiple', 'multiple');
            }

            // Inserting select options
            for (var i in attr.options) if (attr.options.hasOwnProperty(i)) {

                var optionvalue = attr.options[i].pk || attr.options[i];
                var optiontext  = attr.options[i].label || attr.options[i].pk || attr.options[i];
                var option = $("<option>", { value : optionvalue, text : optiontext }).appendTo(input);
                if (attr.formatter != null) {
                    $(option).text(attr.formatter($(option).text()));
                }

                // Set current option to value if defined
                if (optionvalue === value || ($.isArray(value) && $.inArray(optionvalue, value) >= 0)) {
                    $(option).attr('selected', 'selected');
                }
            }

        // Handle other field types
        } else {
            input = $("<input>", { type : attr.type ? toInputType(attr.type) : 'text', width: 246 });
        }

        // Set the input attributes
        $(input).attr({ name : name, id : 'input_' + name, rel : name });

        // Check if the attr is mandatory
        this.validateRules[name] = {};
        if (attr.is_mandatory == true) {
            $(label).append(' *');
            if ($(input).attr('type') !== 'checkbox') {
                this.validateRules[name].required = true;
            }

        } else if (toInputType(attr.type) === 'select' && attr.relation === 'single') {
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

        // Set the field as hidden if defined.
        // Be carefull to not move this block before the previous
        // tests on the input type, has we change the type to hidden.
        if (attr.hidden) {
            input.attr('type', 'hidden');
        }

        // Finally, insert DOM elements in the form
        this.insertInput(input, label, this.findTable(listing, attr.step), attr.help || attr.description, listing);

        // Disable the field if required
        if (this.mustDisableField(name) === true) {
            $(input).attr('disabled', 'disabled');
        }

        if ($(input).attr('type') === 'date') {
            $(input).datepicker({ dateFormat : 'yyyy-mm-dd', constrainInput : true });
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
            unit_input.addClass('wizard-ignore');
            if ($(input).attr('disabled')) {
                unit_input.attr('disabled', 'disabled');
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
                $(input).val( readable_value.value );
                $(unit_cont).find('option:contains("' + readable_value.unit + '")').attr('selected', 'selected');
            }

            // TODO: Get the real lenght of the unit select box.
            $(input).width($(input).width() - 50);
        }
    }

    KanopyaFormWizard.prototype.insertInput = function(input, label, table, help, listing) {
        var linecontainer;

        // If listing mode, append the input horizontally to the last line.
        // Build the labels line if not exists
        if (listing) {
            // TOTO: Handle all special caracters as accent, etc
            listing = listing.replace(/ /g, '_');

            if (input.attr('type') === 'checkbox') {
                input.width(50);
            } else {
                input.width(input.width() - 50);
            }

            // Search for the line that contains labels for this listing
            var labelsline = $(table).find('tr.labels_' + listing).get(0);
            var errorsline = $(table).find('tr.errors_' + listing).get(0);
            if (! labelsline) {
                // Add an empty line if not exists
                labelsline = $("<tr>").css('position', 'relative');
                labelsline.addClass('labels_' + listing);
                labelsline.appendTo(table);
                // Ann another line for error messages
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

                var relation_name = this.attributedefs[input.attr('name')].belongs_to;
                if (! (relation_name && ! this.attributedefs[relation_name].is_editable)) {
                    // Add a button to remove the line
                    var removeButton = $('<a>').button({ icons : { primary : 'ui-icon-closethick' }, text : false });
                    removeButton.addClass('wizard-ignore');
                    removeButton.bind('click', function () {
                        $(line).remove();
                        if ($(table).find('tr').length <= 2) {
                            $(labelsline).remove();
                        }
                    });
                    td.append(removeButton);
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
                $(input).css('width', '100%');

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

    KanopyaFormWizard.prototype.mustDisableField = function(name) {
        if (this.attributedefs[name].disabled == true) {
            return true;
        }
        if ($(this.form).attr('method').toUpperCase() === 'PUT' && this.attributedefs[name].is_editable != true &&
            !(this.attributedefs[name].is_primary == true && this.attributedefs[name].belongs_to != undefined)) {
            return true;
        }
        if (this.attributedefs[name].belongs_to &&
            this.attributedefs[this.attributedefs[name].belongs_to].is_editable != true) {
            return true;
        }
        return false;
    }

    KanopyaFormWizard.prototype.beforeSerialize = function(form, options) {
        var _this = this;
        $(form).find(':input').not('.wizard-ignore').each(function () {
            // Must transform all 'on' or 'off' values from checkboxes to '1' or '0'
            if (toInputType(_this.attributedefs[$(this).attr('name')].type) === 'checkbox') {
                //if ($(this).attr('value') === 'on' && $(this).attr('checked')) {
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
                $(this).val(_this.attributedefs[$(this).attr('name')].serialize($(this).val(), $(this)));
            }

            // Disable empty non mandatory fields, only if there are select or not editable.
            if ($(this).val() === '' && ! _this.attributedefs[$(this).attr('name')].is_mandatory &&
                (toInputType(_this.attributedefs[$(this).attr('name')].type) === 'select' ||
                 ! _this.attributedefs[$(this).attr('name')].is_editable)) {

                $(this).attr('disabled', 'disabled');
            }
        });
    }

    KanopyaFormWizard.prototype.handleBeforeSubmit = function(arr, $form, opts) {
        // Building a hash representing the object with its relations
        var data = {};
        var rel_attr_names = [];
        for (var index in arr) {
            var attr = arr[index];

            // If the attr is an attr of a relation,
            // move value in the corresponding sub hash
            var hash_to_fill;
            if (this.attributedefs[attr.name].belongs_to) {
                var rel_list = data[this.attributedefs[attr.name].belongs_to];

                if (rel_list === undefined) {
                    data[this.attributedefs[attr.name].belongs_to] = [];
                    rel_list = data[this.attributedefs[attr.name].belongs_to];
                }

                // If attr not in the array, we are completing an entry
                if ($.inArray(attr.name, rel_attr_names) < 0 && rel_attr_names.length) {
                    rel_attr_names.push(attr.name);

                // If not, we are starting a new entry
                } else {
                    rel_attr_names = [attr.name]
                    rel_list.push({});
                }
                hash_to_fill = rel_list[rel_list.length - 1];

            } else {
                hash_to_fill = data;
            }
            if (this.attributedefs[attr.name].relation === 'multi') {
                if (! hash_to_fill[attr.name]) {
                    hash_to_fill[attr.name] = [];
                }
                hash_to_fill[attr.name].push(attr.value);

            } else {
                hash_to_fill[attr.name] = attr.value;
            }
        }
        this.submitCallback(data, $form, opts, $.proxy(this.onSuccess, this), $.proxy(this.onError, this));

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
            error       : $.proxy(this.onError, this),
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
                multi_relations[attr] = [];
            }
        }

        jQuery.extend(relations, multi_relations);

        // For each relation 1-N, use expand to get related entries with object values
        if (relations) {
            var expands = [];
            for (relation in relations) if (relations.hasOwnProperty(relation)) {
                expands.push(relation);
            }
            url += '?expand=' + expands.join(',');
        }
        var values = ajax('GET', url);

        for (var value in multi_relations) {
            var pk_values = []
            for (var entry in values[value]) {
                pk_values.push(values[value][entry].pk);
            }
            values[value] = pk_values;
        }
        return values;
    }

    KanopyaFormWizard.prototype.getAttributes = function(resource) {
        return ajax('GET', '/api/attributes/' + resource);
    }

    KanopyaFormWizard.prototype.findTable = function(tag, step) {
        if (tag !== undefined) {
            tag.replace(/ /g, '_');

            var table = this.tables[tag];
            if (table === undefined) {
                var table = $("<table>", { id : this.name + '_tag_' + tag });

                var fieldset = $("<fieldset>").appendTo(this.form);
                var legend   = $("<legend>", { text : tag }).css('font-weight', 'bold');
                fieldset.css('border-color', '#ddd');
                fieldset.append(legend);
                fieldset.append(table);

                $(table).css('width', '100%');
                if (step !== undefined) {
                    table.attr('rel', step);
                    $(table).addClass('step');
                }
                this.tables[tag] = table;
            }
            return table;

        } else {
            return this.table;
        }
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
        } else {
            throw new Error("KanopyaFormWizard : Must provide a type");
        }

        this.id             = args.id;
        this.displayed      = args.displayed      || [];
        this.relations      = args.relations      || {};
        this.rawattrdef     = args.rawattrdef     || {};
        this.callback       = args.callback       || $.noop;
        this.title          = args.title          || this.name;
        this.skippable      = args.skippable      || false;
        this.submitCallback = args.submitCallback || this.submit;
        this.valuesCallback = args.valuesCallback || this.getValues;
        this.attrsCallback  = args.attrsCallback  || this.getAttributes;
        this.cancelCallback = args.cancel         || $.noop;
        this.error          = args.error          || $.noop;
    }

    KanopyaFormWizard.prototype.exportArgs = function() {
        return {
            type            : this.type,
            id              : this.id,
            displayed       : this.displayed,
            relations       : this.relations,
            rawattrdef      : this.rawattrdef,
            callback        : this.callback,
            title           : this.title,
            skippable       : this.skippable,
            submitCallback  : this.submitCallback,
            valuesCallback  : this.valuesCallback,
            attrsCallback   : this.attrsCallback,
            cancel          : this.cancelCallback
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

    KanopyaFormWizard.prototype.changeStep = function(event, data) {
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

    KanopyaFormWizard.prototype.startWizard = function() {
        $(this.form).formwizard({
            disableUIStyles     : true,
            validationEnabled   : true,
            validationOptions   : {
                rules           : this.validateRules,
                messages        : this.validateMessages,
                errorClass      : 'ui-state-error',
                errorPlacement  : $.proxy(this.errorPlacement, this),
            },
            formPluginEnabled   : true,
            formOptions         : {
                beforeSerialize : $.proxy(this.beforeSerialize, this),
                beforeSubmit    : $.proxy(this.handleBeforeSubmit, this),
                success         : $.proxy(this.onSuccess, this),
                error           : $.proxy(this.onError, this),
            }
        });

        var steps = $(this.form).children("table.step");
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

    KanopyaFormWizard.prototype.errorPlacement = function(error, element) {
        // Check if the input come from a listing by searching
        // a possibly defined td for the error label
        var errortd = this.form.find('td.error_' + element.attr('name')).get(0);
        if (errortd) {
            error.appendTo(errortd);
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
        $(this.content).prepend($("<div>", { text : error.reason, class : 'ui-state-error ui-corner-all' }));
        this.error(data);
    }

    KanopyaFormWizard.prototype.openDialog = function() {
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
            position        : 'top',
            width           : 'auto',
            minWidth        : 700,
//            maxHeight       : 550,
            buttons         : buttons,
            closeOnEscape   : false
        });
        $('.ui-dialog-titlebar-close').remove();
    }

    KanopyaFormWizard.prototype.cancel = function() {
        var state = $(this.form).formwizard("state");
        if (state.isFirstStep) {
            this.cancelCallback();
            this.closeDialog();
        }
        else {
            $(this.form).formwizard("back");
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

    KanopyaFormWizard.prototype.validateForm = function () {
        var _this = this;

        // Add validation rules for inputs inserted dynamically in the form.
        $(this.form).find(':input').each(function () {
            for (var rule in _this.validateRules[$(this).attr('name')]) {
                var rules = $(this).rules();
                if (rules[rule] === undefined) {
                    $(this).rules("add", _this.validateRules[$(this).attr('name')]);
                    break;
                }
            }
        });

        $(this.form).formwizard("next");
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
