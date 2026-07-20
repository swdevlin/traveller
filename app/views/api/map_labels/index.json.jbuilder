json.array! @map_labels do |parsec|
  json.id    parsec.id
  json.x     parsec.x
  json.y     parsec.y
  json.known parsec.known

  known_to_viewer = @is_referee || parsec.known
  icon = known_to_viewer ? parsec.icon : nil

  json.text            known_to_viewer ? parsec.label : nil
  json.colour          known_to_viewer ? parsec.label_colour : nil
  json.icon_view_box   icon&.view_box
  json.icon_path_data  icon&.path_data
end
