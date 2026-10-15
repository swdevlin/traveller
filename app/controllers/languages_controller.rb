class LanguagesController < ApplicationController
  before_action :set_language, only: %i[edit update destroy download]

  def index
    @languages = WordGenerator.languages
    @custom_languages = Language.order(:name)
  end

  def new
    @language = Language.new
  end

  def edit
  end

  def create
    @language = Language.new(language_params)

    if @language.save
      redirect_to languages_path, notice: 'Language was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @language.update(language_params)
      redirect_to languages_path, notice: 'Language was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @language.in_use?
      redirect_to languages_path, alert: "#{@language.name} is still in use by #{@language.usages.to_sentence}.", status: :see_other
    elsif current_campaign.default_language == @language.key
      redirect_to languages_path, alert: "#{@language.name} is the campaign default language.", status: :see_other
    else
      @language.destroy!
      redirect_to languages_path, notice: 'Language was successfully destroyed.', status: :see_other
    end
  end

  def download
    send_data @language.words.join("\n") + "\n",
              filename: "#{@language.key}.txt",
              type: 'text/plain; charset=utf-8'
  end

  def word
    lang = params[:language]&.to_sym
    if lang.in?(WordGenerator.languages)
      render json: { word: WordGenerator.new(language: lang).generate }
    else
      render json: { error: 'Unknown language' }, status: :unprocessable_entity
    end
  end

  def generate
    @languages = WordGenerator.languages
    @custom_languages = Language.order(:name)
    @selected = params[:language]&.to_sym
    @count     = params[:count].to_i.clamp(1, 100)

    if @selected.in?(@languages)
      generator = WordGenerator.new(language: @selected)
      @words    = Array.new(@count) { generator.generate }
    else
      @words = []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { render :index }
    end
  end

  private

  def set_language
    @language = Language.find(params.expect(:id))
  end

  def language_params
    params.expect(language: %i[name corpus corpus_file])
  end
end
