class TourCompletionsController < ApplicationController
  allow_without_campaign

  def create
    Current.user.complete_tour!(params[:journey_name])
    head :ok
  end
end