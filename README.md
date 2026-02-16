# My Traveller Universe

## feedback

* Which are the "required" fields? Get error message after, but should have an indication on the screen
* YAML error - resets screen to empty. YAML cleared and name reverted

## To Do
* Add a rogue stellar object
  * Planetoid belt - no need to generate, just use edit form
  * Terrestrial planet - no need to generate, just use edit form
* Quickly toggle known state
* Quickly set surveyIndex
* Display error messages from background jobs
* Verify social UWP characteristic calculations for other worlds
* edit star system
  * [] edit details
  * [] delete orbiting body
  * [] delete secondary or companion stars
  * [] reorder secondary stars
  * [] reorder orbiting bodies
* edit terrestrial planet
  * [] edit details
* edit gas giant
    * [] edit details
* edit star
  * [] edit details
    * includes WBH values like spread, baseline, and baseline orbit number
  * [] reorder orbiting bodies
  * [] delete orbiting body
* edit planetoid belt
    * [] edit details
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
* System generation from Deepnight book
  * [x] Density specification in counts block
  * [ ] Barycenter support
* Quickly set survey index for a subsector
* start with just the foreven sector
* Add Button to create all deepnight sectors
    * create with configuration for each sector
    * Option to generate blank?

### To do?

* Moons
* significant bodies for planetoid belts
* Support generation by CRB
* Support generation by The Deep Space Exploration Handbook
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
* Labels
* Regions

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

