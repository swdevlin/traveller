# My Traveller Universe

## To Do

* Add a rogue stellar object
  * Brown dwarf
    * can edit
  * [x] Comet
    * can edit
  * [x] Gas cloud
    * can edit
  * [x] Gas giant
    * can edit
  * [x] Gravity anomaly
    * can edit
  * [x] Interstellar wreck
    * can edit
  * Planetoid belt
    * can edit
  * [x] Radiation cloud
    * can edit
  * [x] Relic
    * can edit
  * Terrestrial planet
    * can edit uwp
  * [x] Unusual Object
    * can edit
  * can delete rogue object
* On-line help
* Add a star system to a hex
  * [x] random
  * [x] Specific class, subtype, and luminosity
  * Support generating by system density
  * support full system specification
* Hex display for a subsector
* [x] Allegiance CRUD
  * paginate the list
* Populate a subsector
  * [x] Basic populate
  * Add populated option for generate
    * [x] allegiance
    * [x] tech limits
    * [x] pop limits
    * [x] survey index
    * [x] bases
  * Add star definition
  * Add system definition
    * hot, habital, goldilocks, cold zones
  * UI updates as systems are added
* Populate a sector
  * [x] verify each subsector has a build plan
  * [x] create a job for each subsector
  * Load default plan
* Log in
  * Multi-tenancy
  * Start at the sectors view if the user is logged in
  * Links to the Deepnight navigation console for Referee & Travellers
* Export sector file that can be used by Traveller Map
* Export subsector file that can be used by Traveller Map
* Edit star system
  *  Add an option to change the main world 
* [x] Enter configuration for subsector
* Import default data for sector
* Import default data for subsector
* Import default data for parsec
* store image of star system
* store image of stellar object
* Import default configuration for sector
* Import default configuration for subsector
* Import default configuration for parsec
* Allegiances for Deepnight campaign
* import allegiances from TravellerMap
* CRUD on Allegiances
* Settings page

### To do?

* Themes
  * Imperial
  * Deepnight
  * Light
  * vargr
  * Zhodani
  * Solomani
* Routes
* Support generation by The Deep Space Exploration Handbook
* System generation from Deepnight book
* Communication routes
* Name generation
* Make generic for any custom Traveller universe

#### To do??

* Foundry VTT integration
* T5
* Cepheus Engine
* Clement Sector
* Import Traveller Map sector specification file
* Complete edit of a stellar object
* Import of Charted Space data
  * load from github? 

## Development Notes

The site is built using Rails 8.1.1 and Ruby 3.5.7.

SQLite is used for the database.

Multi-tenacy will be handled via schemas.

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

