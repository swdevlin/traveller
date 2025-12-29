# My Traveller Universe

## To Do

* Add a rogue stellar object
  * [x] Comet
    * can edit
  * [x] Gas giant
    * can edit
  * Gas cloud
    * can edit
  * Brown dwarf
    * can edit
  * Interstellar wreck
    * can edit
  * Planetoid belt
    * can edit
  * Terrestrial planet
    * can edit
  * Relic
    * can edit
  * can delete rogue object
* On-line help
* Add a star system to a hex
  * Support generating by system density
* Hex display for a subsector
* Links to the Deepnight navigation console for Travellers
* Populate a subsector
* Populate a sector
* Log in
  * Multi-tenancy
  * Start at sectors list if the user is logged in
* Export sector file that can be used by Traveller Map
* Export subsector file that can be used by Traveller Map
* In star system editing
* Enter configuration for parsec
* Enter configuration for subsector
* Enter configuration for sector
* Import default data for sector
* Import default data for subsector
* Import default data for parsec

### To do?

* Themes
* Routes
* Support generation by The Deep Space Exploration Handbook
* System generation from Deepnight book
* Communication routes
* Name generation
* Make generic for any custom Traveller universe

#### To do??

* Import Traveller Map sector specification file
* Complete edit of a stellar object
* Import of Charted Space data
  * load from github? 

## Development Notes

The site is built using Rails 8.1.1 and Ruby 3.5.7.

SQLite is used for the database.

Multi-tenacy is handled via schemas.

# Dev Notes

This for trying to figure out why a get was returning a 404


test "should get edit" do
path = edit_parsec_path(@parsec)
puts "PATH: #{path}"

    begin
      p Rails.application.routes.recognize_path(path, method: :get)
    rescue => e
      puts "recognize_path error: #{e.class}: #{e.message}"
    end

    get path
    puts "status=#{response.status}"
    puts response.body
    assert_response :success
end

