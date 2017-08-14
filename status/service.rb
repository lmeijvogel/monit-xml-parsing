require_relative 'from_json'
require_relative 'statistic'

class Service < FromJson

  def type
    data['type']
  end

  def status
    data['status']
  end

  def ok?
    status == 'OK'
  end

  def led
    data['led']
  end

  def led_color
    LEDColor.hex(led)
  end

  # The service monitoring state bitmap.
  # Possible values (can be combined with logical OR): 0x0=off, 0x1=on, 0x2=initializing, 0x4=waiting
  def monitoring?
    data['monitorstate'] > 0
  end


  def statistics
    @statistics ||=  Array(data.dig('statistics')).map do |statistic|
      Statistic.new(data: statistic)
    end
  end

end