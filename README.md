# My Traveller Universe

## feedback

* Which are the "required" fields? Get error message after, but should have an indication on the screen
* YAML error - resets screen to empty. YAML cleared and name reverted

## To Do
* start with just the foreven sector
* Add Button to create all deepnight sectors
  * create with configuration for each sector
  * Option to generate blank?
* Quickly toggle known state
* Quickly set surveyIndex
* Display error messages from background jobs
* Verify social UWP characteristic calculations for other worlds
* Display atmosphere data for worlds
* Display hydrosphere data for worlds
* UI for sectors list uses standard code
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
* Add a star system to a hex
  * [x] random
  * [x] Specific class, subtype, and luminosity
  * Support generating by system density
  * support full system specification
* Display star system map
* Paginate allegiance list
* Mongoose allegiance codes
* Log in
  * Multi-tenancy
  * Start at the sectors view if the user is logged in
  * Links to the Deepnight navigation console for Referee & Travellers
* Edit forms should show field errors at the field 
* Export sector file that can be used by Traveller Map
* Export subsector file that can be used by Traveller Map
* Edit star system
  *  Add an option to change the main world 
* store image of star system
* store image of stellar object
* Import default configuration for parsec
* Allegiances for Deepnight campaign
* Support generation by The Deep Space Exploration Handbook
* System generation from Deepnight book
  * [x] Density specification in counts block
  * [ ] Barycenter support
* Quickly set survey index for a subsector

### To do?

* Integrate into Deepnight campaign 
* Themes
  * Imperial
  * Deepnight
  * Light
  * vargr
  * Zhodani
  * Solomani
* Routes
* Communication routes
* Name generation

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

