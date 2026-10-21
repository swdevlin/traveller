class RingsController < ApplicationController
  before_action :set_stellar_object, only: %i[new create]
  before_action :set_ring, only: %i[edit update destroy]

  # GET /stellar_objects/1/rings/new
  def new
    @ring = build_ring
  end

  # The page is refreshed rather than just the moons table, so everything that depends on the ring
  # (such as the ring icon on the planet's Moons tab) is up to date.
  # POST /stellar_objects/1/rings
  def create
    @ring = build_ring(ring_params)

    if @ring.save
      respond_to { |format| format.turbo_stream }
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /rings/1/edit
  def edit
  end

  # PATCH/PUT /rings/1
  def update
    if @ring.update(ring_params)
      respond_to { |format| format.turbo_stream }
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /rings/1
  def destroy
    @ring.destroy!

    respond_to { |format| format.turbo_stream { render :create } }
  end

  private
    def set_stellar_object
      @stellar_object = StellarObject.find(params[:stellar_object_id])
    end

    def set_ring
      @ring = Ring.find(params[:id])
      @stellar_object = @ring.orbiting
    end

    def build_ring(attributes = {})
      Ring.new(attributes.merge(orbiting: @stellar_object, star_system_id: @stellar_object.star_system_id))
    end

    def ring_params
      params.expect(ring: %i[name orbit span])
    end
end
