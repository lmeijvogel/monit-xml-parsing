require 'sinatra'
require 'nokogiri'
require 'sinatra/reloader'
require 'sinatra/base'
require 'json'

require 'dotenv'

require 'erb'
require 'net/http'
require 'httparty'

require_relative 'jenkins_adapter'
require_relative 'm_monit_adapter'

Dotenv.load


class MyApp < Sinatra::Base

  set :bind, '0.0.0.0'
  set :port, 9292

  get '/' do
    renderer = ERB.new(File.read('views/index.html.erb'))
    renderer.result(binding)
  end

  get '/jenkins_status' do
    read_jenkins_status
  end

  get '/monit_status' do
    (read_mmonit_status + read_monit_xml).to_json
  end

  def read_jenkins_status
    jenkins_adapter = JenkinsAdapter.new(ENV.fetch("JENKINS_USER"), ENV.fetch("JENKINS_TOKEN"))

    jenkins_adapter.all_builds.to_json
  end

  def read_mmonit_status
    unless @servers
      load_servers
    end

    @servers.map do |server|
      status = server.ok? ? 'success' : 'error'
      {
          name: server.name,
          status: status
      }
    end
  end

  def load_servers
    mmonit_adapter = MMonitAdapter.new(ENV.fetch('MMONIT_USERNAME'), ENV.fetch('MMONIT_PASSWORD'),
                                       ENV.fetch('MMONIT_HOST'), ENV.fetch('MMONIT_PORT')
    )
    @servers = mmonit_adapter.load
  end

  def monit_source
    ENV.fetch("MONIT_XML_URL")
  end

  def is_http?
    monit_source.start_with?("http://") || monit_source.start_with?("https://")
  end

  def read_monit_xml
    xml = if is_http?
            get_from_http
          else
            monit_source_file = File.join(__dir__, monit_source)

            File.read(monit_source_file)
          end

    @doc = Nokogiri::XML(xml)

    @doc.xpath('//service').map do |service_element|
      status = service_element.xpath('status').text == '0' ? 'success' : 'error'
      {
          name: service_element.xpath('name').text,
          status: status
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

  run!
end

