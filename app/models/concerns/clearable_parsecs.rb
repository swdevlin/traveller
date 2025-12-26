# frozen_string_literal: true

module ClearableParsecs
  extend ActiveSupport::Concern

  def parsec_scope
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def clear
    scope = parsec_scope

    StarSystem.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
    StellarObject.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
  end
end
