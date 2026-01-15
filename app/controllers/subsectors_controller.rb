class SubsectorsController < ApplicationController
  before_action :set_subsector, only: %i[ show edit update clear populate generate]
  before_action :set_counts, only: %i[show populate]
  # GET /subsectors or /subsectors.json
  def index
    @subsectors = Subsector.all
  end

  # GET /subsectors/1 or /subsectors/1.json
  def show
  end

  # GET /subsectors/1/edit
  def edit
  end

  def populate
    unless @subsector.build.present?
      populate_build_from_template!
    end
  end

  def generate
    build_yaml = subsector_generate_params[:build]
    validator = BuildConfigValidator.new(build_yaml)

    unless validator.valid?
      flash[:alert] = "Invalid build configuration: #{validator.errors.join(', ')}"
      redirect_to populate_subsector_path(@subsector) and return
    end
    @subsector.build = build_yaml
    @subsector.save!
    GenerateSubsectorJob.perform_later(@subsector, build_yaml)
    redirect_to subsector_path(@subsector), notice: 'Subsector population task created.'
  end

  def clear
    Subsector.transaction do
      @subsector.clear
    end
    redirect_to subsector_path(@subsector), notice: 'Subsector cleared.'
  end


  # PATCH/PUT /subsectors/1 or /subsectors/1.json
  def update
    respond_to do |format|
      if @subsector.update(subsector_params)
        format.html { redirect_to @subsector, notice: 'Subsector was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @subsector }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subsector.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_counts
    @star_system_count = @subsector.star_systems.count
    @rogue_count = @subsector.rogues.count
  end

  # Use callbacks to share common setup or constraints between actions.
    def set_subsector
      @subsector = Subsector.find(params.expect(:id))
    end

    def subsector_params
      params.expect(subsector: [:name, :x, :y, :notes, :build])
    end

    def subsector_generate_params
      params.expect(subsector: [:build])
    end

    def populate_build_from_template!
      path = Rails.root.join('app', 'templates', 'subsectors', 'build_template.yml.erb')
      erb  = ERB.new(path.read)

      @subsector.build = erb.result_with_hash({})
    end
end
