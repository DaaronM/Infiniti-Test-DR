function updateLog(path, userGuid, loginTimeUtc, businessUnitGuid, latitude, longitude) {
    if ('https:' === document.location.protocol) {
        path = path.replace('http:', 'https:');
    }

    $.ajax({
        type: 'POST',
        contentType: 'application/json;charset=utf-8',
        url: path + 'api/v1/log',
        data: '{"userGuid":"' +
            userGuid +
            '", "loginTimeUtc":"' +
            loginTimeUtc +
            '", "businessUnitGuid":"' +
            businessUnitGuid +
            '", "latitude":"' +
            latitude +
            '", "longitude":"' +
            longitude +
            '"}',
        dataType: 'json'
    });
}

function getGeolocation(userGuid, latitudeId, longitudeId, errorId, accurate, onchangeCallback) {
    if (window.wiz && window.wiz.isNative) {
        var arr = [];
        arr.push(latitudeId);
        arr.push(longitudeId);
        arr.push(onchangeCallback);
        arr.push(errorId);
       Native("doGetLocation", arr);
   } else {
        if (navigator &&
            navigator.geolocation &&
            ('https:' === document.location.protocol)) {
            navigator.geolocation.getCurrentPosition(
                function(position) {
                    createCookie(userGuid + "_latitude", position.coords.latitude, 1);
                    createCookie(userGuid + "_longitude", position.coords.longitude, 1);
                    $('#' + latitudeId).val(position.coords.latitude);
                    $('#' + longitudeId).val(position.coords.longitude);

                    if (onchangeCallback && typeof onchangeCallback === 'function') {
                        onchangeCallback();
                    }

                    $('#' + latitudeId).focus();
                    $('#' + longitudeId).focus();
                },
                function(err) {
                    $('#' + errorId).show();
                    console.log('geolocation: ' + err);
                },
                { enableHighAccuracy: accurate }
            );
        } else {
            $('#' + errorId).show();
        }
    }
}

function createCookie(name, value, days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + value + expires + "; path=/";
}