# frozen_string_literal: true
Coordinate = Struct.new(:x, :y) do
  def subsector_corners(subsector)
    ul = self.clone
    lr = self.clone
    ul.x += (subsector.x - 1) * 8
    ul.y -= (subsector.y - 1) * 10
    lr.x += subsector.x * 8
    lr.y -= subsector.y * 10
    return ul, lr
  end
end

