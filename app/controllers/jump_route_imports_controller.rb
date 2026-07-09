# frozen_string_literal: true

class JumpRouteImportsController < ApplicationController
  def create
    @jump_route = JumpRoute.find(params[:jump_route_id])

    unless params[:file].present?
      redirect_to jump_route_path(@jump_route), alert: 'No file selected.' and return
    end

    csv_text = params[:file].read
    results = import_links(csv_text)

    notice = "Imported #{results[:created]} link(s)."
    notice += " #{results[:skipped]} skipped (already exist or system not found)." if results[:skipped] > 0
    notice += " #{results[:errors]} error(s)." if results[:errors] > 0

    redirect_to jump_route_path(@jump_route), notice: notice
  end

  private

  def import_links(csv_text)
    require 'csv'

    created = 0
    skipped = 0
    errors  = 0

    CSV.parse(csv_text, headers: true) do |row|
      from_name = row['from_system']&.strip
      to_name   = row['to_system']&.strip

      unless from_name.present? && to_name.present?
        skipped += 1
        next
      end

      from_sys = StarSystem.find_by(name: from_name)
      to_sys   = StarSystem.find_by(name: to_name)

      unless from_sys && to_sys
        skipped += 1
        next
      end

      link = JumpRouteLink.new(
        jump_route: @jump_route,
        from_star_system: from_sys,
        to_star_system: to_sys
      )

      if link.save
        created += 1
      elsif link.errors[:from_star_system_id].any? { |e| e.include?('already exists') }
        skipped += 1
      else
        errors += 1
      end
    rescue StandardError
      errors += 1
    end

    { created: created, skipped: skipped, errors: errors }
  end
end
