# My Traveller Universe

## feedback

* Which are the "required" fields? Get error message after, but should have an indication on the screen
* YAML error - resets screen to empty. YAML cleared and name reverted
* Ability to edit data/adjust orbits etc would be valuable for known systems or just tweaking for story/plot. This might be fixed using the orbit number.
* Ability to "lock in" generation of specific details like diameter and temperature so that future generations (e.g. other systems) did not overwrite them
* Need ability to include all the specific data in the YAML for that "body" like trade codes
* System level  allegiance does not seem to be taken from "systems" element. Tried to remove Global Allegiance but it is required in yaml. So everything was the global not the system setting
* Allegiance not carried through to planet details - should default to system allegiance

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
  * Import from TravellerMap
    * Add Mongoose ones to seed
* Log in
  * Multi-tenancy
  * Start at the sectors view if the user is logged in
  * Links to the Deepnight navigation console for Referee & Travellers
* Export sector file that can be used by Traveller Map
* Export subsector file that can be used by Traveller Map
* Edit star system
  *  Add an option to change the main world 
* store image of star system
* store image of stellar object
* Import default configuration for parsec
* Allegiances for Deepnight campaign
* import allegiances from TravellerMap
* [x] Settings page

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

