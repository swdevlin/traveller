# frozen_string_literal: true

module ClearableParsecs
  def parsec_scope
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def clear(exclude_locked: false)
    scope = parsec_scope

    star_system_scope = StarSystem.joins(:parsec).where(parsecs: { id: scope.select(:id) })
    stellar_object_scope = StellarObject.joins(:parsec).where(parsecs: { id: scope.select(:id) })

    if exclude_locked
      locked_parsec_ids = star_system_scope.where(locked: true).select(:parsec_id)
      star_system_scope = star_system_scope.where.not(parsec_id: locked_parsec_ids)
      stellar_object_scope = stellar_object_scope.where.not(parsec_id: locked_parsec_ids)
    end

    star_system_ids = star_system_scope.select(:id)
    NetworkLink.where(from_star_system_id: star_system_ids).delete_all
    NetworkLink.where(to_star_system_id: star_system_ids).delete_all
    star_system_scope.delete_all
    stellar_object_scope.delete_all
  end
end
