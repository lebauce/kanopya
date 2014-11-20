function activateExpander() {

    // Expander
    $('.list-panel').css('visibility', 'hidden');

    $('.expander .icon').click(function() {

        var toCollapse;
        var $item = $(this).parents('.list-item');
        var $panel = $item.find('.list-panel');

        if ($panel.css('display') === 'none' || $panel.css('visibility') === 'hidden') {
            $item.siblings().each( function () {
                if ($(this).position().top === $item.position().top) {
                    $(this).find('.list-panel')
                        .css('display', 'block');
                }
            });
            $panel
                .css('display', 'block')
                .css('visibility', 'visible');
            $(this)
                .removeClass('fa-angle-double-down')
                .addClass('fa-angle-double-up');
        } else {
            toCollapse = true;
            $item.siblings().each( function () {
                if ($(this).position().top === $item.position().top) {
                    if ($(this).find('.list-panel').css('visibility') === 'visible') {
                        toCollapse = false;
                        return false;
                    }
                }
            });
            if (toCollapse === true) {
                $panel.css('display', 'none');
                $item.siblings().each( function () {
                    if ($(this).position().top === $item.position().top) {
                        $(this).find('.list-panel')
                            .css('display', 'none');
                    }
                });
            }
            $panel.css('visibility', 'hidden');
            $(this)
                .removeClass('fa-angle-double-up')
                .addClass('fa-angle-double-down');
        }
    });
}

function startTextButtonAnimation(button) {
    $(button)
        .addClass('transparent-text')
        .append($('<i>', {'class': 'spin fa fa-refresh fa-spin'}));
}

function stopTextButtonAnimation(button) {
    $(button).children('i').remove();
    $(button).removeClass('transparent-text');
}

function startIconButtonAnimation(button) {

    var $elt = $(button).children('i');
    var iconClass = $elt.attr('class');
    $elt.attr('class', 'fa fa-spinner fa-spin');

    return iconClass;
}

function stopIconButtonAnimation(button, iconClass) {
    $(button).children('i').attr('class', iconClass);
}
