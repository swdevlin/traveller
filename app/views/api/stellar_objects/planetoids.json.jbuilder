json.count @pagy.count
json.page  @pagy.page
json.pages @pagy.pages
json.planetoids @planetoids do |planetoid|
  json.partial! 'stellar_objects/stellar_object', stellar_object: planetoid
  json.native_sophont planetoid.native_sophont == true
  json.extinct_sophont planetoid.extinct_sophont == true
  json.moons [] # planetoids can't have moons; client's SharedPData decoder requires the key
end
