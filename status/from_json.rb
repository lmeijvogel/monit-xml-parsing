class FromJson

  attr_accessor :data

  def initialize(data:)
    @data = data
  end

  def [](key)
    data[key]
  end

  def id
    data['id']
  end

  def name
    data['name']
  end

end