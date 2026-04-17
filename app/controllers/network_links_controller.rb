# frozen_string_literal: true

class NetworkLinksController < ApplicationController
  def create
    @network_link = NetworkLink.new(network_link_params)

    if @network_link.save
      @star_system = @network_link.from_star_system_id == params[:star_system_id].to_i ?
                       @network_link.from_star_system :
                       @network_link.to_star_system
      @star_system = StarSystem.find(params[:star_system_id]) if params[:star_system_id].present?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('modal', ''),
            turbo_stream.prepend("network-links-#{params[:star_system_id]}", partial: 'star_systems/network_link_row',
                                                                              locals: { link: @network_link, star_system_id: params[:star_system_id].to_i })
          ]
        end
        format.html { redirect_to star_system_path(params[:star_system_id]) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal',
                                                    partial: 'shared/error_modal',
                                                    locals: { errors: @network_link.errors.full_messages })
        end
        format.html { redirect_to star_system_path(params[:star_system_id]), alert: @network_link.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    @network_link = NetworkLink.find(params[:id])
    star_system_id = params[:star_system_id]
    communication_network_id = @network_link.communication_network_id
    @network_link.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("network_link_#{params[:id]}")
      end
      format.html do
        if star_system_id.present?
          redirect_to star_system_path(star_system_id)
        else
          redirect_to communication_network_path(communication_network_id)
        end
      end
    end
  end

  private

  def network_link_params
    params.expect(network_link: %i[communication_network_id from_star_system_id to_star_system_id])
  end
end
