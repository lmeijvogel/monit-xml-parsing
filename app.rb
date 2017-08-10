require 'nokogiri'
require 'sinatra/reloader'
require 'sinatra/base'
require 'json'

require 'dotenv'

require 'erb'
require 'net/http'
require 'httparty'
require 'rufus-scheduler'

require_relative 'jenkins_adapter'
require_relative 'm_monit_adapter'

Dotenv.load

class App < Sinatra::Base

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
    if App.servers
      App.servers.map do |server|
        status = server.ok? ? 'success' : 'error'
        {
            name: server.name,
            status: status
        }
      end
    else
      []
    end
  end

  def read_monit_xml
    xml = get_from_http

    @doc = Nokogiri::XML(xml)

    @doc.xpath('//service').map do |service_element|
      status = service_element.xpath('status').text == '0' ? 'success' : 'error'
      {
          name: service_element.xpath('name').text,
          status: status
      }
    end
  end

  private

  def monit_source
    ENV.fetch("MONIT_XML_URL")
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


  def self.scheduler
    @scheduler ||= Rufus::Scheduler.new
  end

  def self.load_servers
    mmonit_adapter = MMonitAdapter.new(ENV.fetch('MMONIT_USERNAME'), ENV.fetch('MMONIT_PASSWORD'),
                                       ENV.fetch('MMONIT_HOST'), ENV.fetch('MMONIT_PORT')
    )
    mmonit_adapter.connect
    @servers = mmonit_adapter.statuses
    mmonit_adapter.disconnect
  end

  def self.servers
    @servers
  end

  configure do
    set :bind, '0.0.0.0'
    set :port, 9292
    set :scheduler, App.scheduler

    settings.scheduler.every '5s', first: :now do
      App.load_servers
    end
  end

  run!
end

