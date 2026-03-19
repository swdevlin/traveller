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

    star_system_scope.delete_all
    stellar_object_scope.delete_all
    # StarSystem.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
    # StellarObject.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
  rescue ActiveRecord::InvalidForeignKey => e
    fk_rows = ActiveRecord::Base.connection.execute('PRAGMA foreign_key_check').to_a

    Rails.logger.error(
      "Clear failed with FK constraint: #{e.message}\n" \
        "foreign_key_check: #{fk_rows.inspect}"
    )

    raise
  end
end
