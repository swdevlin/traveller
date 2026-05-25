class LanguagesController < ApplicationController
  def index
    @languages = WordGenerator.languages
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
    @selected  = params[:language]&.to_sym
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
end
