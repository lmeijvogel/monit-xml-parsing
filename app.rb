require 'sinatra'
require 'nokogiri'
require 'sinatra/reloader'

require 'erb'

set :bind, '0.0.0.0'
set :port, 9292

get '/status' do
  @statuses = read_xml(File.read('monit_status.xml'))

  renderer = ERB.new(template)
  renderer.result(binding)
end

def read_xml(xml)
  @doc = Nokogiri::XML(xml)

  @doc.xpath('//service').map do |service_element|
    {
      name: service_element.xpath('name').text,
      up: service_element.xpath('status').text == '0'
    }
  end
end

def template
  <<-TEMPLATE
    <html>
      <head>
      <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"></link>
      <style>
        .server-line {
          margin: 3px 10;
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
