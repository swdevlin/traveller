class TradeCodesController < ApplicationController
  before_action :set_trade_code, only: %i[ show edit update destroy ]

  # GET /trade_codes or /trade_codes.json
  def index
    @trade_codes = TradeCode.all
  end

  # GET /trade_codes/1 or /trade_codes/1.json
  def show
  end

  # GET /trade_codes/new
  def new
    @trade_code = TradeCode.new
  end

  # GET /trade_codes/1/edit
  def edit
  end

  # POST /trade_codes or /trade_codes.json
  def create
    @trade_code = TradeCode.new(trade_code_params)

    respond_to do |format|
      if @trade_code.save
        format.html { redirect_to @trade_code, notice: "Trade code was successfully created." }
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
        format.html { redirect_to @trade_code, notice: "Trade code was successfully updated.", status: :see_other }
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
      format.html { redirect_to trade_codes_path, notice: "Trade code was successfully destroyed.", status: :see_other }
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
      params.expect(trade_code: [ :code, :definition ])
    end
end
