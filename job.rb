class Job < Struct.new(:name, :color)
  def status
    case color
    when "blue"
      "success"
    when "red"
      "error"
    when "blue_anime", "red_anime"
      "building"
    end
  end

  def to_json(options = {})
    as_json.to_json
  end

  def as_json
    {
      name: name,
      status: status
    }
  end
end
