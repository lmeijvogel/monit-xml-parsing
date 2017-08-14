require_relative 'from_json'
require_relative 'service'
require_relative 'led_color'

class Server < FromJson

  def led
    data['led']
  end

  def led_color
    conversion_hash = { 1 => :error, 2 => :warning, 3 => :ok }
    LEDColor.hex(conversion_hash.include?(led) ? conversion_hash[led] : :disabled)
  end

  def status
    data['status']
  end

  # If the LED is green all services are okay. Check this instead of looping through all services.
  def ok?
    led == 2
  end

  def services
    @services ||=  Array(data['services']).map do |service|
      Service.new(data: service)
    end
  end

end