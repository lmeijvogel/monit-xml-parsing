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

class MonitoringApp < Sinatra::Base

  get '/' do
    renderer = ERB.new(File.read('views/index.html.erb'))
    renderer.result(binding)
  end

  get '/beta' do
    renderer = ERB.new(File.read('views/index2.html.erb'))
    renderer.result(binding)
  end

  get '/jenkins_status' do
    read_jenkins_status
  end

  get '/monit_status' do
    (read_mmonit_status + read_monit_xml).to_json
  end

  get '/status' do
    read_status
  end

  def read_jenkins_status
    jenkins_adapter = JenkinsAdapter.new(ENV.fetch("JENKINS_USER"), ENV.fetch("JENKINS_TOKEN"))

    jenkins_adapter.all_builds.to_json
  end

  def read_mmonit_status
    servers = MonitoringApp.load_servers
    if servers
      servers.map do |server|
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

  def read_status
    errors = {}
    servers = MonitoringApp.load_servers
    if servers
      servers.each do |server|
        unless server.ok?
          errors[server.name] = { }
          server.services.each do |service|
            unless service.ok?
              errors[server.name][service.name] = service.status
            end
          end
        end
      end
    end
    errors.to_json
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

  def self.load_servers
    mmonit_adapter = MMonitAdapter.new(ENV.fetch('MMONIT_USERNAME'), ENV.fetch('MMONIT_PASSWORD'),
                                       ENV.fetch('MMONIT_HOST'), ENV.fetch('MMONIT_PORT')
    )
    mmonit_adapter.connect
    servers = mmonit_adapter.statuses
    mmonit_adapter.disconnect

    servers
  end

  configure do
    if MonitoringApp.development?
      set :bind, '0.0.0.0'
      set :port, 9292
      register Sinatra::Reloader
      run!
    end
  end

end

