module LEDColor

  COLORS = {
      0 => "#FF0000",
      1 => "#FFA500",
      2 => "#008000",
      3 => "#808080"
  }

  def self.hex(id)
    if COLORS.include?(id)
      COLORS[id]
    else
      COLORS[3]
    end
  end

end