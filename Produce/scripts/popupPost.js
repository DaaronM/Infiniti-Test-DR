function popupPost(form) {
    return parent.window.postWizardUrl(
        function () {
            var formData = $(form).serialize();
            var source = $('button[name]:focus,input[type="submit"][name]:focus');

            if (source.length > 0) {
                formData += '&' + encodeURIComponent(source.attr('name')) + '=' + encodeURIComponent(source.val());
            }

            return {
                "url": form.action,
                "formData": formData
            };
        },
        function (result) {
            $(window.frameElement).attr('srcdoc', result);
        });
}
