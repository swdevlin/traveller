# frozen_string_literal: true

module ClearableParsecs
  def parsec_scope
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def clear
    scope = parsec_scope

    StarSystem.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
    StellarObject.joins(:parsec).where(parsecs: { id: scope.select(:id) }).destroy_all
  rescue ActiveRecord::InvalidForeignKey => e
    fk_rows = ActiveRecord::Base.connection.execute('PRAGMA foreign_key_check').to_a

    Rails.logger.error(
      "Clear failed with FK constraint: #{e.message}\n" \
        "foreign_key_check: #{fk_rows.inspect}"
    )

    raise
  end
end
