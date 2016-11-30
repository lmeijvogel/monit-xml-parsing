require 'sinatra'
require 'nokogiri'
require 'sinatra/reloader'

require 'erb'
require 'net/http'

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
  @statuses = read_xml(source)

  renderer = ERB.new(root_template)
  renderer.result(binding)
end

get '/status' do
  @statuses = read_xml(source)

  renderer = ERB.new(status_template)
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
      </style>

      <script>
        function doRequest() {
          getJson('/status', {
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
    </script>
  </html>
  TEMPLATE
end

def status_template
  <<-TEMPLATE
      <% @statuses.each do |status|
        button_class = status[:up] ? 'btn-success' : 'btn-danger' %>
        <p class="server-line"><button class="server-button btn <%= button_class %>"><%= status[:name] %></button></p>
      <% end %>
  TEMPLATE
end
