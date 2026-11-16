class Api::RulebooksController < Api::BaseController
  def index
    @rulebooks = Rulebook.available_to_campaign(referee: Current.referee_access?)
  end
end
