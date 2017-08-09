require_relative 'statistic_key'

class Statistic < FromJson

  def name
    StatisticKey.name(type)
  end

  def type
    data['type']
  end

  def descriptor
    data['descriptor']
  end

  def value
    data['value']
  end

end