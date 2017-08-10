module LEDColor

  COLORS = {
      error: "#FF0000",
      warning: "#FFA500",
      ok: "#008000",
      disabled: "#808080"
  }

  def self.hex(id)
    if COLORS.include?(id)
      COLORS[id]
    else
      COLORS[:disabled]
    end
  end

end