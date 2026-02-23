class TradeCodesController < ApplicationController
  before_action :set_trade_code, only: %i[ show edit update destroy ]

  # GET /trade_codes or /trade_codes.json
  def index
    @trade_codes = TradeCode.order(:code)
  end

  # POST /trade_codes/import_t5
  def import_t5
    load Rails.root.join('db/seed_data/t5_trade_codes.rb')
    created = TRADE_CODES.count do |attrs|
      TradeCode.find_or_create_by!(code: attrs[:code]) do |tc|
        tc.definition = attrs[:definition]
      end.previously_new_record?
    end
    redirect_to trade_codes_path,
                notice: created > 0 ? "#{created} trade #{'code'.pluralize(created)} added." : 'All T5 trade codes already present.',
                status: :see_other
  end

  # GET /trade_codes/1 or /trade_codes/1.json
  def show
  end

  # GET /trade_codes/new
  def new
    @trade_code = TradeCode.new
    @return_to = request.referer
  end

  # GET /trade_codes/1/edit
  def edit
  end

  # POST /trade_codes or /trade_codes.json
  def create
    @trade_code = TradeCode.new(trade_code_params)

    respond_to do |format|
      if @trade_code.save
        format.html { redirect_to params[:return_to].presence || @trade_code, notice: 'Trade code was successfully created.' }
        format.json { render :show, status: :created, location: @trade_code }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @trade_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trade_codes/1 or /trade_codes/1.json
  def update
    respond_to do |format|
      if @trade_code.update(trade_code_params)
        format.html { redirect_to @trade_code, notice: 'Trade code was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @trade_code }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @trade_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trade_codes/1 or /trade_codes/1.json
  def destroy
    @trade_code.destroy!

    respond_to do |format|
      format.html { redirect_to trade_codes_path, notice: 'Trade code was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trade_code
      @trade_code = TradeCode.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def trade_code_params
      params.expect(trade_code: [:code, :definition])
    end
end
