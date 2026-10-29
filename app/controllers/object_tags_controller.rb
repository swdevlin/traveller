class ObjectTagsController < ApplicationController
  TYPES = {
    'Sector' => Sector, 'Subsector' => Subsector, 'StarSystem' => StarSystem,
    'StellarObject' => StellarObject, 'Region' => Region
  }.freeze

  before_action :set_record

  def show
    if @record.is_a?(StarSystem)
      @tagged_bodies = StellarObject.where(star_system_id: @record.id).where(id: Tagging.where(taggable_type: 'StellarObject').select(:taggable_id)).order(:id)
      render partial: 'application/starmap_system_tags', locals: { record: @record, bodies: @tagged_bodies }
    else
      render_sidebar
    end
  end

  def create
    names = params.fetch(:tag_list, '').to_s.split(',').map(&:strip).reject(&:blank?)
    if names.empty?
      return render_sidebar('Enter a tag to add.', :unprocessable_entity)
    end

    @record.with_lock { @record.tag_names = @record.tag_names + names }
    respond_with_tags
  rescue ActiveRecord::RecordInvalid => error
    render_sidebar(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  def destroy
    name = params.expect(:tag)
    @record.with_lock { @record.taggings.joins(:tag).where(tags: { name: name }).destroy_all; @record.tags.reset }
    respond_with_tags
  rescue ActiveRecord::RecordInvalid => error
    render_sidebar(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  private

  def set_record
    type = TYPES[params[:record_type]]
    raise ActiveRecord::RecordNotFound unless type

    @record = type.find(params.expect(:record_id))
  end

  def respond_with_tags
    if turbo_frame_request?
      render_sidebar
    elsif (path = local_return_path)
      redirect_to path, status: :see_other
    else
      path = case @record
      when Star then star_path(@record)
      when StellarObject then stellar_object_path(@record)
      else polymorphic_path(@record)
      end
      redirect_to path, status: :see_other
    end
  end

  # Grids pass their own URL so adding a tag returns to the grid; only local paths are honoured.
  def local_return_path
    path = params[:return_to].to_s
    path if path.start_with?('/') && !path.start_with?('//') && !path.include?("\n")
  end

  def render_sidebar(error = nil, status = :ok)
    render partial: 'application/tags_sidebar', locals: { record: @record, error: error }, status: status
  end
end
