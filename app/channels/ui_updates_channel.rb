# frozen_string_literal: true

class UiUpdatesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'ui_updates'
  end
end