$(function () {

    function waitForMutation(parentNode, isMatchFunc, handlerFunc, observeSubtree, disconnectAfterMatch) {
        var defaultIfUndefined = function (val, defaultVal) {
            return (typeof val === "undefined") ? defaultVal : val;
        };

        observeSubtree = defaultIfUndefined(observeSubtree, false);
        disconnectAfterMatch = defaultIfUndefined(disconnectAfterMatch, false);

        var domObserver = new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                if (mutation.addedNodes) {
                    for (var i = 0; i < mutation.addedNodes.length; i++) {
                        var node = mutation.addedNodes[i];
                        if (isMatchFunc(node)) {
                            handlerFunc(node);
                            if (disconnectAfterMatch) domObserver.disconnect();
                        };
                    }
                }
            });
        });

        domObserver.observe(parentNode, {
            childList: true,
            attributes: false,
            characterData: false,
            subtree: observeSubtree
        });
    }

    $('#contentwrapper').ready(function() {
        
        try {
            // Only execute on content pages
            if ($(location).attr('hash').indexOf('#/content/content') > -1) {
                $.ajax({
                        method: 'GET',
                        url: '/umbraco/backoffice/UmbracoApi/Authentication/GetCurrentUser'
                    })
                    .always(function(data) {
                        var user = JSON.parse(data.responseText.split("\n")[1]);

                        if (user.userType !== "admin") {
                            waitForMutation(
                                document.getElementById("contentwrapper"),
                                function(htmlNode) {
                                    return $(htmlNode).find("#tab0") !== null;
                                },
                                function(htmlNode) {
                                    $("#tab0").hide();
                                    $("a[href=\"#tab0\"]").parent().hide();
                                },
                                true,
                                false);
                        }
                    });
            }
        }
        catch (err) {
            // Bury it; bury it deep and never talk about it again
        }
    });

})