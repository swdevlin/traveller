class Admin::RulebookPagesController < AdminController
  before_action :set_rulebook
  before_action :set_page, only: %i[show update]

  def mapping
    @pagy, @pages = pagy(@rulebook.rulebook_pages.order(:pdf_page_number), limit: 50, params: request.query_parameters)
  end

  def index
    redirect_to mapping_admin_rulebook_rulebook_pages_path(@rulebook)
  end

  def show
  end

  def update
    if @page.update(page_params)
      redirect_to admin_rulebook_rulebook_page_path(@rulebook, @page), notice: 'Page updated.', status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_rulebook
    @rulebook = Rulebook.find(params[:rulebook_id])
  end

  def set_page
    @page = @rulebook.rulebook_pages.find(params[:id])
  end

  def page_params
    params.expect(rulebook_page: [:printed_page_number_override, :printed_page_unnumbered, :heading])
  end
end
