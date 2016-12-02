require 'sinatra'
require 'nokogiri'
require 'sinatra/reloader'

require 'dotenv'

require 'erb'
require 'net/http'

Dotenv.load

set :bind, '0.0.0.0'
set :port, 9292

source = ARGV[0]
raise "No source specified!" unless source

def is_http?(source)
  source.start_with?("http://") || source.start_with?("https://")
end

unless is_http?(source)
  source = File.join(__dir__, source)

  raise "File does not exist!" unless File.exists?(source)
end

get '/' do
  @build_display_url = ENV.fetch("BUILD_DISPLAY_URL")
  @monit_status_container_url = ENV.fetch("MONIT_STATUS_CONTAINER_URL")

  renderer = ERB.new(root_template)
  renderer.result(binding)
end

get '/monit' do
  @monit_status_url = ENV.fetch("MONIT_STATUS_URL")

  renderer = ERB.new(monit_template)
  renderer.result(binding)
end

get '/monit_status' do
  @statuses = read_xml(source)

  renderer = ERB.new(monit_status_template)
  renderer.result(binding)
end

def read_xml(source)
  xml = if is_http?(source)
    get_from_http(source)
  else
    File.read(source)
  end

  @doc = Nokogiri::XML(xml)

  @doc.xpath('//service').map do |service_element|
    {
      name: service_element.xpath('name').text,
      up: service_element.xpath('status').text == '0'
    }
  end
end

def get_from_http(source)
  uri = URI(source)

  req = Net::HTTP::Get.new(uri)
  req.basic_auth(*uri.userinfo.split(':')) if uri.userinfo

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  res.body
end

def root_template
  <<-TEMPLATE
    <html>
      <head>
        <style>
          html, body {
            height: 100%;
            background-color: black;
            overflow-y: hidden;
            overflow-x: hidden;
          }
          iframe {
            height: 100%;
            margin: 0;
            padding: 0;
            border: 0;
          }
          .builds {
            width: calc(100% - 320px);
          }
          .servers {
            width: 300px;
          }
        </style>
      </head>
      <body>
        <iframe class="builds" src="<%= @build_display_url %>"></iframe>
        <iframe class="servers" src="<%= @monit_status_container_url %>"></iframe>
        <!-- iframe class="servers" src="http://10.0.4.91:9292"></iframe -->
      </body>
    </html>
  TEMPLATE
end

def monit_template
  <<-TEMPLATE
    <html>
      <head>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"></link>
        <style>
          body {
            background-color: black;
          }

          .server-list {
            margin-top: 5px;
          }

          .server-line {
            margin-top: 1px;
            margin-bottom: 0px;
          }

          .server-button {
            width: 300px;
            font-size: 20pt;
          }

          .server-button.blink-on {
            color: #d9534f;
          }
        </style>

        <script>
          function doRequest() {
            getJson('<%= @monit_status_url %>', {
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
        </script>
      </head>
      <body>
        <div class="server-list"></div>
      </body>
      <script>
        doRequest();

        setInterval(function () {
          doRequest();
        }, 30000);

        animateUnavailableServers();
      </script>
    </html>
  TEMPLATE
end

def monit_status_template
  <<-TEMPLATE
      <% @statuses.each do |status|
        button_class = status[:up] ? 'btn-success' : 'btn-danger' %>
        <p class="server-line"><button class="server-button btn <%= button_class %>"><%= status[:name] %></button></p>
      <% end %>
  TEMPLATE
end
