define([
    'jquery',
    'knockout',
], function($, ko) {
    ko.bindingHandlers.clipboard = {
        init: function(element, valueAccessor) {
            const data = valueAccessor();
            if (data.tooltip) {
                $(element).attr('data-original-title', data.beforeCopiedText);
            }
            function resetText() {
                // $(element).tooltip('hide'); CVE-2018-14042.
                $(element).attr('data-original-title', data.beforeCopiedText);
                $(element).off('mouseleave', resetText);
            };
            $(element).click(function(){                
                if (data.tooltip) {
                    $(element).attr('data-original-title', data.afterCopiedText);
                    // $(element).tooltip('show'); CVE-2018-14042.
                    $(element).on('mouseleave', resetText);
                }
                navigator.clipboard.writeText(ko.unwrap(data.value));
            });
        }
    };
    return ko.bindingHandlers.clipboard;
});
