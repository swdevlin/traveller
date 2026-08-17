class Admin::RulebooksController < AdminController
  before_action :set_rulebook, except: %i[index new create]

  def index
    scope = Rulebook.order(:title)
    if params[:q].present?
      q = "%#{params[:q].to_s.strip.downcase}%"
      scope = scope.where('LOWER(title) LIKE ? OR LOWER(short_title) LIKE ?', q, q)
    end
    scope = scope.where(category: params[:category]) if params[:category].present?
    @pagy, @rulebooks = pagy(scope, limit: 20, params: request.query_parameters)
  end

  def show
  end

  def new
    @rulebook = Rulebook.new
  end

  def edit
  end

  def create
    pdf_file = rulebook_params[:pdf_file]
    @rulebook = Rulebook.new(rulebook_attributes)
    @rulebook.errors.add(:base, 'A PDF file is required to create a rulebook.') unless valid_pdf_upload?(pdf_file)

    if @rulebook.errors.empty? && @rulebook.save
      enqueue_import(@rulebook, pdf_file)
      BackfillCampaignRulebookJob.perform_later(@rulebook.id)
      redirect_to admin_rulebook_path(@rulebook), notice: 'Rulebook created — import queued.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @rulebook.update(rulebook_attributes)
      redirect_to admin_rulebook_path(@rulebook), notice: 'Rulebook updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rulebook.destroy!
    redirect_to admin_rulebooks_path, notice: 'Rulebook removed.', status: :see_other
  end

  def import
    pdf_file = params[:pdf_file]
    return redirect_to admin_rulebook_path(@rulebook), alert: 'Please upload a PDF file.' unless valid_pdf_upload?(pdf_file)

    enqueue_import(@rulebook, pdf_file)
    redirect_to admin_rulebook_path(@rulebook), notice: 'Import queued.'
  end

  def rebuild_search_vectors
    RebuildRulebookSearchVectorsJob.perform_later(@rulebook.id)
    redirect_to admin_rulebook_path(@rulebook), notice: 'Rebuilding search vectors.'
  end

  def toggle_searchable
    @rulebook.update!(searchable: !@rulebook.searchable?)
    redirect_to admin_rulebook_path(@rulebook), status: :see_other
  end

  private

  def set_rulebook
    @rulebook = Rulebook.find(params[:id])
  end

  def rulebook_params
    params.expect(rulebook: [:title, :short_title, :edition, :publication_year, :category,
                              :page_number_offset, :searchable, :rank_modifier, :header_footer_patterns_raw, :pdf_file])
  end

  # The form submits header/footer patterns as one textarea, one pattern per line, rather
  # than as an array of inputs — translate that into the jsonb array the model expects.
  # pdf_file is a transient upload, not a Rulebook column — stripped before mass-assignment.
  def rulebook_attributes
    attrs = rulebook_params.to_h
    attrs.delete(:pdf_file)
    raw = attrs.delete(:header_footer_patterns_raw)
    attrs[:header_footer_patterns] = raw.to_s.split("\n").map(&:strip).reject(&:blank?) if raw
    attrs
  end

  def valid_pdf_upload?(file)
    file.respond_to?(:original_filename) && file.original_filename.to_s.downcase.end_with?('.pdf')
  end

  # Always force: true — an uploaded PDF is always reprocessed, even if it's byte-identical to
  # what's already imported (e.g. after an extractor/pipeline change, or edited header/footer
  # patterns), rather than silently no-opping on a matching checksum.
  def enqueue_import(rulebook, pdf_file)
    staged_path = stage_upload(rulebook, pdf_file)
    ImportRulebookJob.perform_later(rulebook.id, staged_path.to_s, force: true, cleanup_after: true)
  end

  def stage_upload(rulebook, pdf_file)
    dir = Rails.root.join('tmp', 'rulebook_uploads')
    FileUtils.mkdir_p(dir)
    destination = dir.join("#{rulebook.id}-#{SecureRandom.hex(8)}.pdf")
    IO.copy_stream(pdf_file, destination)
    destination
  end
end
