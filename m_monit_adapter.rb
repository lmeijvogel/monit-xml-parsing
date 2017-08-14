require_relative 'status/server'
require 'mmonit'

class MMonitAdapter

  attr_accessor :mmonit

  def initialize(username, password, address, port)
    @username = username
    @password = password
    @address = address
    @port = port
  end

  def connect
    @mmonit ||= MMonit::Connection.new(
        ssl: false,
        username: @username,
        password: @password,
        address: @address,
        port: @port
    )
    @mmonit.connect
  end

  def disconnect
    if mmonit
      mmonit.disconnect
    end
  end

  def statuses
    mmonit.hosts.map do |host|
      Server.new(data: mmonit.status_detailed(host['hostname']))
    end
  end

end