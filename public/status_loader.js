function StatusLoader(url, container, buttonClass) {
  function doRequest() {
    getJson(url, {
      success: function (data) {
        var errorButtons = container.querySelectorAll('.error-button');

        errorButtons.forEach( function (button) {
          container.removeChild(button);
        });
        createOrUpdateButtons(data);
      },

      error: function (data) {
        var serverLines = container.querySelectorAll('.server-button');

        if (serverLines.length) {
          serverLines.forEach( function (line) {
            line.innerHTML = "?";
            line.className = buttonClass + " button btn btn-warning";
          });
        } else {
          container.innerHTML = '<button class="btn btn-warning error-button">ERROR</button>';
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
          options.success(JSON.parse(request.responseText));
        }
      } else {
        if (options.error) {
          options.error(request.responseText);
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

  function createOrUpdateButtons(data) {
    data.forEach(function (entry) {
      var name = entry["name"];
      var status = entry["status"];

      createOrUpdateButton(name, status);
    });

    showSuccessCount(data);
  }

  function createOrUpdateButton(name, status) {
    var klass;
    switch (status) {
      case "success":
        klass="hidden";
        break;
      case "error":
        klass="btn-danger";
        break;
      default:
        klass="btn-primary";
        break;
    }

    var displayName = name;

    if (status === "building") {
      displayName = name + " (b)"
    }

    var existingButton = container.querySelector("[data-name='"+name+"']");
    if (existingButton) {
      existingButton.innerText = displayName;
      existingButton.className=buttonClass + " btn "+ klass;
    } else {
      var button = createButton(name, displayName, klass);
      container.appendChild(button);
    }
  }

  function showSuccessCount(data) {
    var successEntries = data.filter( function(element) {
      return element["status"] == "success";
    });

    var text = "" + successEntries.length + "/" + data.length + " entries OK";

    var existingElement = container.querySelector(".js-success-count");

    if (existingElement) {
      existingElement.innerText = text;
    } else {
      var onlySuccessesElement = document.createElement("div");
      onlySuccessesElement.className="success-count js-success-count";

      onlySuccessesElement.innerText = text;
      container.appendChild(onlySuccessesElement);
    }
  }

  function animateUnavailableServers() {
    var blinkOn = false;

    setInterval(function () {
      if (blinkOn) {
        var buttons = container.querySelectorAll(".btn");

        buttons.forEach(function (button) {
          button.className = button.className.replace("blink-on", "");
        });
      } else {
        var unavailableButtons = container.querySelectorAll(".btn-danger");

        unavailableButtons.forEach(function (button) {
          button.className = button.className + " blink-on";
        });
      }

      blinkOn = !blinkOn;
    }, 1000);
  }

  function createButton(name, displayName, klass) {
    var button = document.createElement('button');

    button.setAttribute('data-name', name);
    button.className= buttonClass + " btn "+ klass;
    button.textContent = displayName;

    return button;

  }

  return {
    doRequest: doRequest,
    animateUnavailableServers: animateUnavailableServers
  }
}
