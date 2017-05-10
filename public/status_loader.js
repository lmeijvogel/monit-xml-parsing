function doRequest(url) {
  getJson(url, {
    success: function (data) {
      document.querySelector('.server-list').innerHTML = data;
    },

    error: function (data) {
      var serverLines = document.querySelectorAll('.server-button');

      if (serverLines) {
        serverLines.forEach( function (line) {
          line.innerHTML = "?";
          line.className = "server-button btn btn-warning";
        });
      } else {
        document.querySelector('.server-list').innerHTML = '<button class="btn btn-warning">ERROR</button>';
      }
    }
  });
}

function getJson(uri, options) {
  var request = new window.XMLHttpRequest();

  request.open('GET', uri, true);

  request.onload = function () {
    if (request.status >= 200 && request.status < 400) {
      if (options.success) {
        options.success(request.responseText);
      }
    } else {
      if (options.error) {
        options.error(data);
      }
    }
  };

  request.onerror = function () {
    if (options.error) {
      options.error();
    }
  };

  request.send();
}

function animateUnavailableServers() {
  var blinkOn = false;

  setInterval(function () {
    if (blinkOn) {
      var buttons = document.querySelectorAll(".btn");

      buttons.forEach(function (button) {
        button.className = button.className.replace("blink-on", "");
      });
    } else {
      var unavailableButtons = document.querySelectorAll(".btn-danger");

      unavailableButtons.forEach(function (button) {
        button.className = button.className + " blink-on";
      });
    }

    blinkOn = !blinkOn;
  }, 1000);
}
