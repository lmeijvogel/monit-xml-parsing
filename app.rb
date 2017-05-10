require 'sinatra'
require 'nokogiri'
require 'sinatra/reloader'

require 'dotenv'

require 'erb'
require 'net/http'

Dotenv.load

set :bind, '0.0.0.0'
set :port, 9292

def monit_source
  ENV.fetch("MONIT_XML_URL")
end

def is_http?
  monit_source.start_with?("http://") || monit_source.start_with?("https://")
end

unless is_http?
  monit_source = File.join(__dir__, monit_source)

  raise "File does not exist!" unless File.exists?(monit_source)
end

get '/' do
  @build_display_url = ENV.fetch("BUILD_DISPLAY_URL")
  @monit_status_display_container_url = ENV.fetch("MONIT_STATUS_DISPLAY_CONTAINER_URL")

  renderer = ERB.new(File.read('views/index.html.erb'))
  renderer.result(binding)
end

get '/monit' do
  @monit_status_display_url = ENV.fetch("MONIT_STATUS_DISPLAY_URL")

  renderer = ERB.new(File.read('views/monit_status_loader.html.erb'))
  renderer.result(binding)
end

get '/monit_status' do
  @statuses = read_xml

  renderer = ERB.new(File.read('views/monit_status.html.erb'))
  renderer.result(binding)
end

def read_xml
  xml = if is_http?
    get_from_http
  else
    File.read
  end

  @doc = Nokogiri::XML(xml)

  @doc.xpath('//service').map do |service_element|
    {
      name: service_element.xpath('name').text,
      up: service_element.xpath('status').text == '0'
    }
  end
end

def get_from_http
  uri = URI(monit_source)

  req = Net::HTTP::Get.new(uri)
  req.basic_auth(*uri.userinfo.split(':')) if uri.userinfo

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  res.body
end
