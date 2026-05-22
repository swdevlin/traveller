# frozen_string_literal: true

class JumpRouteLinksController < ApplicationController
  include LinkModalSetup

  def create
    @jump_route_link = JumpRouteLink.new(jump_route_link_params)

    if @jump_route_link.save
      @star_system = StarSystem.find(params[:star_system_id]) if params[:star_system_id].present?
      respond_to do |format|
        format.turbo_stream do
          streams = [
            turbo_stream.prepend("jump-route-links-#{params[:star_system_id]}", partial: 'star_systems/jump_route_link_row',
                                                                                locals: { link: @jump_route_link, star_system_id: params[:star_system_id].to_i })
          ]

          if @star_system
            params[:jump_route_id] = @jump_route_link.jump_route_id.to_s
            setup_link_modal_ivars
            modal_html = render_to_string('star_systems/link_modal', layout: false)
            streams.unshift(turbo_stream.replace('modal', html: modal_html.html_safe))

            parsec = @star_system.parsec
            subsector = parsec&.subsector
            if subsector
              embed_url = map_subsector_path(subsector, highlight: parsec.id, compact: true, t: Time.current.to_i)
              map_html = %(<object id="subsector-map" type="image/svg+xml" data="#{embed_url}" class="block h-full w-full" data-subsector-refresh-target="map">Subsector map</object>)
              streams << turbo_stream.replace('subsector-map', html: map_html.html_safe)
            end
          end

          render turbo_stream: streams
        end
        format.html { redirect_to star_system_path(params[:star_system_id]) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal',
                                                    partial: 'shared/error_modal',
                                                    locals: { errors: @jump_route_link.errors.full_messages })
        end
        format.html { redirect_to star_system_path(params[:star_system_id]), alert: @jump_route_link.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    @jump_route_link = JumpRouteLink.find(params[:id])
    star_system_id = params[:star_system_id]
    jump_route_id = @jump_route_link.jump_route_id
    @jump_route_link.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove("jump_route_link_#{params[:id]}")]

        if star_system_id.present?
          @star_system = StarSystem.includes(:parsec).find(star_system_id)
          parsec = @star_system.parsec
          subsector = parsec&.subsector

          if params[:jump_route_id].present?
            setup_link_modal_ivars
            modal_html = render_to_string('star_systems/link_modal', layout: false)
            streams.unshift(turbo_stream.replace('modal', html: modal_html.html_safe))
          end

          if subsector
            embed_url = map_subsector_path(subsector, highlight: parsec.id, compact: true, t: Time.current.to_i)
            map_html = %(<object id="subsector-map" type="image/svg+xml" data="#{embed_url}" class="block h-full w-full" data-subsector-refresh-target="map">Subsector map</object>)
            streams << turbo_stream.replace('subsector-map', html: map_html.html_safe)
          end
        end

        render turbo_stream: streams
      end
      format.html do
        if star_system_id.present?
          redirect_to star_system_path(star_system_id)
        else
          redirect_to jump_route_path(jump_route_id)
        end
      end
    end
  end

  private

  def jump_route_link_params
    params.expect(jump_route_link: %i[jump_route_id from_star_system_id to_star_system_id])
  end
end
