# frozen_string_literal: true

module HexDistance
  def to_cube_coords(x, y)
    cube_x = x
    cube_z = -y - x / 2
    cube_y = -cube_x - cube_z
    [cube_x, cube_y, cube_z]
  end

  def cube_distance(a, b)
    (a.zip(b).sum { |ai, bi| (ai - bi).abs }) / 2
  end

  def hex_distance(a, b)
    cube_distance(to_cube_coords(*a), to_cube_coords(*b))
  end

  def neighbours(ux, uy)
    if ux.even?
      [[ux + 1, uy], [ux, uy - 1], [ux - 1, uy], [ux - 1, uy + 1], [ux, uy + 1], [ux + 1, uy + 1]]
    else
      [[ux + 1, uy - 1], [ux, uy - 1], [ux - 1, uy - 1], [ux - 1, uy], [ux, uy + 1], [ux + 1, uy]]
    end
  end
end
