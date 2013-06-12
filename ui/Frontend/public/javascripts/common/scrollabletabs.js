(function ($) {
    var settings = {
        barheight: 38
    }    

    $.fn.scrollabletab = function (options) {

        var ops = $.extend(settings, options);

        var ul = this.children('ul').first();
        var ulHtmlOld = ul.html();
        var tabBarWidth = parseInt($(this).width()-100);
        ul.wrapInner('<div class="fixedContainer" style="height: ' + ops.barheight + 'px; width: ' + tabBarWidth + 'px; overflow: hidden; float: left;"><div class="moveableContainer" style="height: ' + ops.barheight + 'px; width: 5000px; position: relative; left: 0px;"></div></div>');
        ul.find('li').first().css({
            'border-top-left-radius' : 0,
            'border-bottom-left-radius' :0,
            'border-left' : 0
        });
        ul.prepend('<div class="scrollarrow scrollarrowleft" style="height: ' + (ops.barheight - 2) + 'px;"></div>');
        var leftArrow = ul.children().first();
        leftArrow.button({ icons: { secondary: "ui-icon ui-icon-carat-1-w" } });
        leftArrow.children('.ui-icon-carat-1-w').first().css('left', '2px');

        ul.append('<div class="scrollarrow scrollarrowright" style="height: ' + (ops.barheight - 2) + 'px;"></div>');
        var rightArrow = ul.children().last();
        rightArrow.button({ icons: { secondary: "ui-icon ui-icon-carat-1-e" } });
        rightArrow.children('.ui-icon-carat-1-e').first().css('left', '2px');        

        var moveable = ul.find('.moveableContainer').first();
        leftArrow.click(function () {
            var offset = tabBarWidth / 6;
            var currentPosition = moveable.css('left').replace('px', '') / 1;

            if (currentPosition + offset >= 0) {
                moveable.stop().animate({ left: '0' }, 'slow');
            }
            else {
                moveable.stop().animate({ left: currentPosition + offset + 'px' }, 'slow');
            }
        });

        rightArrow.click(function () {
            var offset = tabBarWidth / 6;
            var currentPosition = moveable.css('left').replace('px', '') / 1;
            var tabsRealWidth = 0;
            ul.find('li').each(function (index, element) {
                tabsRealWidth += $(element).width();
                tabsRealWidth += ($(element).css('margin-right').replace('px', '') / 1);
            });

            tabsRealWidth *= -1;
            if (currentPosition - tabBarWidth > tabsRealWidth) {
                if (currentPosition - offset < tabsRealWidth + tabBarWidth) {
                    moveable.stop().animate({ left: tabsRealWidth + tabBarWidth + 'px' }, 'slow');
                }
                else {
                    moveable.stop().animate({ left: currentPosition - offset + 'px' }, 'slow');
                }
            }
        });


        return this;
    };

})(jQuery);
