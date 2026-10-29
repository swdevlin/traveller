class TagsController < ApplicationController
  PAGE_SIZE = 10

  before_action :set_tag, only: %i[show edit update destroy]

  def index
    @pagy, @tags = pagy(:offset, Tag.alphabetical.includes(:taggings), limit: PAGE_SIZE, params: request.query_parameters)
  end

  def show
    @counts = @tag.counts
    @total = @counts.values.sum
  end

  def edit; end

  def update
    @tag.transaction do
      tag = params[:replacement].to_s.strip == @tag.name ? @tag : @tag.rename!(params[:replacement])
      tag.update!(params.permit(:description))
    end
    redirect_to registry_path, notice: 'Tag updated.', status: :see_other
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : error.message
    @replacement = params.fetch(:replacement, '').to_s
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @tag.destroy!
    redirect_to registry_path, notice: 'Tag deleted and removed from all campaign objects.', status: :see_other
  end

  private

  def set_tag
    @tag = Tag.find_by!(name: params.expect(:name))
    @name = @tag.name
    @replacement ||= @name
  end

  def registry_path
    return tags_path if params[:page].blank?

    last_page = [(Tag.count.to_f / PAGE_SIZE).ceil, 1].max
    tags_path(page: params[:page].to_i.clamp(1, last_page))
  end
end
