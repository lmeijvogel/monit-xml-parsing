require_relative 'status/server'
require 'mmonit'

class MMonitAdapter

  attr_accessor :mmonit

  def initialize(username, password, address, port)
    @username = username
    @password = password
    @address = address
    @port = port

    connect
  end

  def connect
    @mmonit ||= MMonit::Connection.new({
                                         :ssl => false,
                                         :username => @username,
                                         :password => @password,
                                         :address => @address,
                                         :port => @port
                                     })
    @mmonit.connect
  end

  def load
    servers = []
    hosts = mmonit.hosts

    hosts.each do |host|
      servers << Server.new(data: mmonit.status_detailed(host['hostname']))
    end

    servers
  end

end