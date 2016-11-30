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

  renderer = ERB.new(template)
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
def template
  <<-TEMPLATE
    <html>
      <head>
      <meta http-equiv="refresh" content="60" />
      <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"></link>
      <style>
        body {
          background-color: black;
        }

        .server-line {
          margin-top: 5px;
        }

        .server-button {
          width: 300px;
        }
      </style>
    <body>
      <% @statuses.each do |status|
        button_class = status[:up] ? 'btn-success' : 'btn-danger' %>
        <p class="server-line"><button class="server-button btn <%= button_class %>"><%= status[:name] %></button></p>
      <% end %>
    </body>
  </html>
  TEMPLATE
end
