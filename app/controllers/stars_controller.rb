# frozen_string_literal: true

class StarsController < ApplicationController
  before_action :set_star, only: %i[ show edit update destroy ]

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def set_star
    @star = Star.find(params.expect(:id))
  end
end
