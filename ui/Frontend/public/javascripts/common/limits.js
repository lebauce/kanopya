require('jquery/fullcalendar/fullcalendar.js');

function Periods() {
    Periods.prototype.add = function (e) {
        var date = new Date();
        var d = date.getDate();
        var m = date.getMonth();
        var y = date.getFullYear();
        var that = this;

        // When called from grid, e is the time period, otherwise e is an event
        var displayed = [ "time_period_name" ];
        var relations;
        var grid;

        (new KanopyaFormWizard({
            title      : 'Add a time period',
            type       : 'timeperiod',
            id         : (!(e instanceof Object)) ? e : undefined,
            displayed  : displayed,
            callback   : function () {
                handleCreate(grid);
            },
            actionsLabel : 'Periods',
            actionsCallback : function (values) {
                return [ that.showCalendar(values.limits) ];
            },
            submitCallback : function (data, form, opts) {
                that.submit(opts, data);
                this.closeDialog();
            }
        })).start();

        this.calendar.fullCalendar("render");
    }

    Periods.prototype.load = function (container_id, elem_id) {
        // this.values = [ "RAM", "CPU" ];
        // this.type = "string";
        this.values = [ "State" ];
        this.type = "boolean";

        var grid = create_grid({
            url: '/api/timeperiod?expand=param_preset',
            elem_name: 'timeperiod',
            content_container_id: container_id,
            grid_id: 'users_list',
            details: { onSelectRow : $.proxy(this.add, this) },
            colNames: [ 'time_period_id', 'time_period_name' ],
            colModel: [ {
                name: 'time_period_id',
                index: 'time_period_id',
                width: 60,
                sorttype: "int",
                hidden: true,
                key: true
            }, {
                name: 'time_period_name',
                index: 'time_period_name',
                width: 60,
                sorttype: "string",
                hidden: false,
                key: false
            } ]
        });
 
        var action_div = $('#' + container_id).prevAll('.action_buttons');
        var period_addbutton = $('<a>', { text : 'Add a time period' })
                                   .appendTo(action_div)
                                   .button({ icons : { primary : 'ui-icon-plusthick' } });

        $(period_addbutton).bind('click', { }, $.proxy(this.add, this));
    };

    Periods.prototype.selectRecurrentFilter = function (success) {
        $('<div>', { id : 'edit-event-dialog' })
            .append($("<input type='radio' name='recurring-delete' value='instance' checked>"))
            .append($("<span>Only this instance</span><br>"))
            .append($("<input type='radio' name='recurring-delete' value='following'>"))
            .append($("<span>All following</span><br>"))
            .append($("<input type='radio' name='recurring-delete' value='all'>"))
            .append($("<span>All events in the series</span><br>"))
            .dialog({
                title     : "Delete recurring event",
                resizable : false,
                modal     : true,
                width     : 450,
                buttons   : {
                    'Ok' : function () {
                         success($(this).find('input[name="recurring-delete"]:checked').val());
                     }
                },
                close     : function() { $(this).remove(); }
            });
    }

    Periods.prototype.showCalendar = function (limits) {
        var that = this;
        this.limits = limits || [];
        this.calendar = $('<div class="fullcalendar"></div>').fullCalendar({
            header: {
                left: 'prev,next today',
                center: 'title',
                right: 'month,agendaWeek,agendaDay'
            },
            firstDay: 1,
            defaultView: 'agendaWeek',
            selectable: true,
            selectHelper: true,
            columnFormat: {
                month: 'ddd',
                week: 'ddd d/M',
                day: 'dddd d/M',
            },
            eventDragStart: function (event, jsEvent, ui, view) {
            },
            eventResize: function (event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) {
                event.limit.start = event.start;
                event.limit.end = event.end;
            },
            eventMouseover: function (event, jsEvent, view) {
                var close = $("<div class='close-box ui-icon ui-icon-close'></div>");
                close.click(function (e) {
                    if (event.limit.repeat) {
                        var sel = that.selectRecurrentFilter(function (sel) {
                            if (sel == "instance") {
                                event.limit.except.push(event.index);
                                event.backgroundColor = "#888888";
                                that.calendar.fullCalendar('renderEvent', event);
                            }
                            else if (sel == "following") {
                                for (var i = event.index; i < event.count; i++) {
                                    event.limit.except.push(i);
                                }
                                that.calendar.fullCalendar('refetchEvents');
                            }
                            else if (sel == "all") {
                                var index = that.limits.indexOf(event.limit);
                                that.limits.splice(index, 1);
                                that.calendar.fullCalendar('refetchEvents');
                            }
                            $('#edit-event-dialog').dialog('close');
                        });
                    }
                    return false;
                });
                $(jsEvent.currentTarget).append(close);
            },
            eventMouseout: function(limit, jsEvent, view) {
                $(jsEvent.currentTarget).children(".close-box").remove();
            },
            eventClick: function(limit, jsEvent, view) {
                that.createEvent(limit);
            },
            select: function(start, end, allDay) {
                that.createEvent({ start: start, end: end, allDay: allDay });
                that.calendar.fullCalendar('unselect');
            },
            eventAfterRender: function (event, element, view) {
                if (event.disabled) {
                    element.css("background-color", "grey");
                }
            },
            editable: true,
            events: function(start, end, callback) {
                var sl = [];
                var range = { start: start, end: end };
                for (var i = 0; i < that.limits.length; i++) {
                    var limit = that.limits[i];
                    sl = sl.concat(that.getEvents(limit, range));
                }
                callback(sl);
            }
        });

        return this.calendar;
    }

    Periods.prototype.createEvent = function (limit) {
        var that = this;
        var start = limit.start;
        var end = limit.end;
        var allDay = limit.allDay;
        (new KanopyaFormWizard({
            title      : 'Add a time period',
            displayed  : [ ],
            reloadable : true,
            attrsCallback : function (resource, data, trigger) {
                var rawattrdef = {
                    value : {
                        label        : 'Value',
                        pattern      : '^.*$',
                        type         : that.type,
                        pattern      : '^[a-zA-Z_0-9]+$',
                        is_mandatory : 1,
                        is_editable  : 1,
                        value        : data.value === undefined ? true : data.value
                    }
                };
                if (data.id === undefined) {
                    $.extend(rawattrdef, {
                        type : {
                            label        : 'Limit type',
                            type         : 'enum',
                            options      : that.values,
                            is_mandatory : true,
                            is_editable  : true,
                            value        : data.type
                        },
                        repeat : {
                            label        : 'Repeat',
                            type         : 'enum',
                            options      : [ 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Every weekday' ],
                            is_mandatory : false,
                            is_editable  : true,
                            reload       : true,
                            value        : data.repeat
                        },
                        every : {
                            label        : 'Repeat every',
                            type         : 'enum',
                            options      : every,
                            is_mandatory : false,
                            is_editable  : true,
                            value        : data.every
                        },
                        ends : {
                            label        : 'Ends',
                            type         : 'enum',
                            options      : [ 'Never', 'After', 'On' ],
                            is_mandatory : false,
                            is_editable  : true,
                            reload       : true,
                            value        : data.ends
                        },
                        count : {
                            label        : 'Number of occurences',
                            type         : 'integer',
                            is_mandatory : false,
                            is_editable  : true,
                            value        : data.count
                        },
                        ends_on : {
                            label        : 'End date',
                            type         : 'date',
                            is_mandatory : false,
                            is_editable  : true,
                            value        : data.ends_on
                        }
                    });
                }

                var repetition = {
                    "Daily"   : "day",
                    "Weekly"  : "week",
                    "Monthly" : "month",
                    "Yearly"  : "year"
                };

                var displayed = [ "value", "repeat" ];
                if (data.repeat) {
                    var index = 2;
                    if ($.inArray(data.repeat, [ 'Daily' , 'Weekly', 'Monthly', 'Yearly' ]) != -1) {
                        displayed.splice(index++, 0, "every");
                    }

                    displayed.splice(index++, 0, "ends");

                    if (data.ends == "After") {
                        displayed.splice(index++, 0, "count");
                    }
                    if (data.ends == "On") {
                        displayed.splice(index++, 0, "ends_on");
                    }
                    var every = {};
                    for (var i = 1; i <= 30; i++) {
                        every[i] = i + " " + repetition[data.repeat] + (i > 1 ? "s" : "");
                    }
                    rawattrdef["every"]["options"] = every;
                }

                return { attributes : rawattrdef,
                         relations  : [],
                         displayed  : displayed };
            },
            submitCallback : function (data, form, opts) {
                var limit = data;
                $.extend(limit, {
                    id: start.getTime() + "-" + data.type + "-" + data.value,
                    title: data.type + " " + data.value,
                    allDay: false,
                    frequency: data.frequency,
                    type: data.type,
                    value: data.value,
                    start: start,
                    end: end,
                    except: []
                } );

                var events = that.getEvents(limit);

                for (var i = 0; i < events.length; i++) {
                    that.calendar.fullCalendar('renderEvent',
                        events[i],
                        false // make the event "stick"
                    );
                }

                that.limits.push(limit);
                that.limits.sort(that.cmdLimit);

                this.closeDialog();
            }
        })).start();
    }
        
    Periods.prototype.getEvents = function (limit, range) {
        var events = new Array();

        $.ajax({
            url: "/api/timeperiod/normalizeEvents",
            type: 'POST',
            async: false,
            contentType: 'application/json',
            data: JSON.stringify({
                "from" : "2013-04-03T04:00:00.000Z",
                "to" : "2013-04-03T04:00:00.000Z",
                "limits" : [ limit ]
            }),
            success: function (spans) {
                for (var i = 0; i < spans.length; i++) {
                    var span = spans[i];
                    events.push( {
                        index: i,
                        id: i == 0 ? limit.id : undefined,
                        parent: i == 0 ? this : events[0],
                        limit: limit,
                        title: "",
                        start: span.start,
                        end: span.end,
                        allDay: false,
                        count: spans.length,
                        backgroundColor: $.inArray(i, limit.except) != -1 ? "#888888" : undefined
                    } );
                }
            }
        });

        return events;
    }

    Periods.prototype.overlap = function (l1, l2) {
        return l1.start <= l2.end && l2.start <= l1.end;
    }

    Periods.prototype.submit = function (opts, data) {
        for (var i = 0; i < this.limits.length; i++) {
            delete this.limits[i]._id;
        }

        $.ajax({
            url: opts.url,
            type: opts.type,
            contentType : 'application/json',
            data: JSON.stringify({
                "time_period_name" : data.time_period_name,
                "param_preset": { 
                    params : {
                        limits: this.limits
                    }
                }
            })
        });
    }

    Periods.prototype.getLimit = function (id) {
        for (var i = 0; i < limits.length; i++) {
            if (this.limits[i].id == id) {
                return this.limits[i];
            }
        }
    }

    Periods.prototype.cmdLimit = function (l1, l2) {
        return l1.start - l2.start;
    }
}

var timePeriods = new Periods();
