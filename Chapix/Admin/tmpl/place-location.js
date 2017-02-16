var map;
var marker;
var geocoder;
var locationStr = '[% place.latitude %], [% place.longitude %]';

function initMap() {
    var latNumber = -34.397;
    var lngNumber = 150.644;
    var address = '[% place.address %], [% place.city %], [% place.state %]';
    
    if(locationStr.length > 5){
        var locationArray = locationStr.split(",");
        latNumber = locationArray[0] * 1;
        lngNumber = locationArray[1] * 1;       
    }
    
    detectBrowser();
    map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: latNumber, lng: lngNumber},
        zoom: 13
    });

    marker = new google.maps.Marker({
        position: {lat: latNumber, lng: lngNumber},
        map: map
    });
 
    map.addListener('click', function(e) {
        placeMarker(e.latLng)
    });

    if(locationStr.length < 5){
        setAddress(address);
    }
}

function detectBrowser() {
    var useragent = navigator.userAgent;
    var mapdiv = document.getElementById("map");
    
    if (useragent.indexOf('iPhone') != -1 || useragent.indexOf('Android') != -1 ) {
        mapdiv.style.width = '100%';
        mapdiv.style.height = '100%';
    } else {
        mapdiv.style.width = '100%';
        mapdiv.style.height = '800px';
    }
}

function setAddress (address) {
    geocoder = new google.maps.Geocoder();
    geocoder.geocode({
        'address': address
    }, function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
            map.setCenter(results[0].geometry.location);
            marker.setPosition(results[0].geometry.location);
        }
    });
    
}

function placeMarker(location) {
    // Update marker position
    marker.setPosition(location);

    // Update place location
    $.post( "/superv/SUPERV/SetPlaceLocation",
            {
                place_id: [% place.place_id %],
                lat: location.lat(),
                lng: location.lng()
            });
}
