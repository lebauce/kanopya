/*
 * Custom dialog to add a doc link in the title bar
 * Extend jquery ui dialog widget
 */
(function() {
  var _init = $.ui.dialog.prototype._init;

    $.ui.dialog.prototype._init = function() {
        _init.apply(this, arguments);
        if (this.options.docPage) {
          this.uiDialogTitlebar.append(
              $('<span>', {
                  class : 'ui-icon ui-icon-help doc-link dialog-doc-link',
                  "doc-page" : this.options.docPage
              })
          );
        }
    }

})()