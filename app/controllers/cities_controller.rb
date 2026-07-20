class CitiesController < ApplicationController
  before_action :set_stellar_object, only: %i[new create]
  before_action :set_city, only: %i[edit update destroy]

  # GET /stellar_objects/1/cities/new
  def new
    @city = @stellar_object.cities.new
  end

  # POST /stellar_objects/1/cities
  def create
    @city = @stellar_object.cities.new(city_params)

    if @city.save
      respond_to { |format| format.turbo_stream }
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /cities/1/edit
  def edit
  end

  # PATCH/PUT /cities/1
  def update
    @stellar_object = @city.stellar_object

    if @city.update(city_params)
      respond_to { |format| format.turbo_stream }
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /cities/1
  def destroy
    @stellar_object = @city.stellar_object
    @city.destroy!

    respond_to { |format| format.turbo_stream }
  end

  private
    def set_stellar_object
      @stellar_object = StellarObject.find(params[:stellar_object_id])
    end

    def set_city
      @city = City.find(params[:id])
    end

    def city_params
      params.expect(city: [:name, :population, :city_type, :capital_designation])
    end
end
