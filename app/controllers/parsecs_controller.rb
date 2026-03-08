class ParsecsController < ApplicationController
  before_action :set_parsec, only: %i[ show edit update clear star_systems_table ]
  before_action do
    Rails.logger.warn(">>> HIT ParsecsController##{action_name} params=#{params.to_unsafe_h.inspect}")
  end

  # GET /parsecs or /parsecs.json
  def index
    @parsecs = Parsec.all
  end

  # GET /parsecs/1 or /parsecs/1.json
  def show
  end

  # GET /parsecs/1/edit
  def edit
  end

  def clear
    Parsec.transaction do
      @parsec.clear
    end
    redirect_to parsec_path(@parsec), notice: 'Hex cleared.'
  end

  def star_systems_table
    render layout: false
  end

  # PATCH/PUT /parsecs/1 or /parsecs/1.json
  def update
    respond_to do |format|
      if @parsec.update(parsec_params)
        format.html { redirect_to @parsec, notice: 'Parsec was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @parsec }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @parsec.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_parsec
      @parsec = Parsec.find(params[:id])
    end

    def parsec_params
      params.expect(parsec: [:note, :survey_index, :label, :label_colour, :player_visible])
    end
end
