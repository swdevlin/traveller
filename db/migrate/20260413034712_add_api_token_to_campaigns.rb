# frozen_string_literal: true

class AddApiTokenToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :api_token, :string
  end
end
