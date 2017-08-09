require_relative 'from_json'
require_relative 'service'
require_relative 'led_color'
require 'pry'

class Server < FromJson

  def name
    data['name']
  end

  def led
    data['led']
  end

  def led_color
    LEDColor.hex(led)
  end

  def status
    data['status']
  end

  # If the LED is green all services are okay. Check this instead of looping through all services.
  def ok?
    led == 2
  end

  def services
    @services ||=  Array(data.dig('services')).map do |service|
      Service.from_json(service)
    end
  end

end