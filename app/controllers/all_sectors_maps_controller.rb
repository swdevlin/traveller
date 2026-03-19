# frozen_string_literal: true

class AllSectorsMapsController < ApplicationController
  def show
    path = AllSectorsMapGenerator.new(current_campaign).output_path
    return head :not_found unless path.exist?

    send_file path, type: 'image/webp', disposition: 'inline'
  end
end
