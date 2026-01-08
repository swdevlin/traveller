# frozen_string_literal: true

module ParentHex
  extend ActiveSupport::Concern

  included do
    before_action :load_parent!
    before_action :load_parsecs!
    before_action :set_context_label!
  end

  private

  def set_context_label!
    @context_label =
      if @parsec
        "#{@parsec.sector.name} #{@parsec.hex_code}"
      elsif @subsector
        "#{@subsector.name}, #{@subsector.sector.name}"
      else
        @sector.name
      end
  end

  def load_parent!
    @parsec = Parsec.find(params[:parsec_id]) if params[:parsec_id].present?
    @subsector = Subsector.find(params[:subsector_id]) if params[:subsector_id].present?
    @sector = Sector.find(params[:sector_id]) if params[:sector_id].present?

    @sector ||= @parsec&.sector
    @sector ||= @subsector&.sector
  end

  def load_parsecs!
    scope =
      if @parsec
        [@parsec]
      elsif @subsector
        @subsector.parsecs.includes(:sector)
      else
        @sector.parsecs.includes(:sector)
      end

    @parsecs = scope.sort_by(&:hex_code)

    label_method = @subsector ? :subsector_hex_code : :hex_code
    @parsec_options = @parsecs.map { |p| [p.public_send(label_method), p.id] }
  end


end

