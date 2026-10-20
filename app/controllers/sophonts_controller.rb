class SophontsController < ApplicationController
  # The picture is shown in the star map, which players view without logging in, so it also
  # accepts a signed URL token (as planet maps do).
  include UrlTokenVerification
  optional_authentication only: :picture
  skip_before_action :verify_url_token, except: :picture

  before_action :set_sophont, only: %i[show edit update destroy picture]

  def index
    @sophonts = Sophont.ordered.includes(home_system: { parsec: :sector })
  end

  def show
    @worlds = @sophont.worlds.order(:name)
  end

  def new
    @sophont = Sophont.new
  end

  def edit
  end

  def create
    @sophont = Sophont.new(sophont_params)

    if @sophont.save
      redirect_to @sophont, notice: 'Sophont was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @sophont.update(sophont_params)
      redirect_to @sophont, notice: 'Sophont was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @sophont.in_use?
      redirect_to sophonts_path, alert: "#{@sophont.name} is still the native sophont of #{@sophont.worlds.count} world(s).", status: :see_other
    else
      @sophont.destroy!
      redirect_to sophonts_path, notice: 'Sophont was successfully destroyed.', status: :see_other
    end
  end

  def picture
    return head :not_found unless @sophont.picture.attached?

    send_data @sophont.picture.download,
              type: @sophont.picture.content_type,
              disposition: 'inline',
              filename: "#{@sophont.name.parameterize.presence || 'sophont'}#{File.extname(@sophont.picture.filename.to_s)}"
  end

  private

  def set_sophont
    @sophont = Sophont.find(params.expect(:id))
  end

  def sophont_params
    permitted = params.expect(sophont: %i[name language home_system_id reference_url referee_notes player_notes picture remove_picture])
    @sophont&.picture&.purge_later if permitted.delete(:remove_picture) == '1' && !permitted[:picture]
    permitted
  end
end
