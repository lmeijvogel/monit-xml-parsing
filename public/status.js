$(document).ready(function() {
    var errors = {}

    setInterval(function() {
        $.get({
            url: '/status',
            dataType: 'json',
            success: function(data) {
               errors = data;
            }
        })
    }, 3000);


    setInterval(function() {

    }, 5000)
});