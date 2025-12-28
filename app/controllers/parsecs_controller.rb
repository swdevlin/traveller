class ParsecsController < ApplicationController
  before_action :set_parsec, only: %i[ show edit update ]
  before_action do
    Rails.logger.warn(">>> HIT ParsecsController##{action_name} params=#{params.to_unsafe_h.inspect}")
  end

  # GET /parsecs or /parsecs.json
  def index
    @parsecs = Parsec.all
  end

  # GET /parsecs/1 or /parsecs/1.json
  def show
    puts('show parsec')
  end

  # GET /parsecs/1/edit
  def edit
    puts('editing parsec')
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
      puts('setting parsec')
      @parsec = Parsec.find(params[:id])
    end

    def parsec_params
      params.expect(parsec: [:sector_id, :x, :y])
    end
end
