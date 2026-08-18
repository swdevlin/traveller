class BackfillStarportCosts < ActiveRecord::Migration[8.1]
  BACKFILLED_TYPES = %w[TerrestrialPlanet Moon Planetoid PlanetoidBelt].freeze
  BATCH_SIZE = 1000

  # `upsert_all` validates NOT NULL/CHECK constraints against the full candidate
  # insert row before it discovers a conflict and falls back to `update_only`, so
  # every row must carry enough of its own identity (type, parent) to satisfy the
  # `stellar_objects_parsec_xor_orbiting_present` check even though the eventual
  # UPDATE only ever touches `data`.
  def up
    StellarObject.where(type: BACKFILLED_TYPES).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      updates = batch.filter_map do |stellar_object|
        next if stellar_object.data.is_a?(Hash) && stellar_object.data.key?('berthing_cost')

        stellar_object.assign_starport_costs
        { id: stellar_object.id, type: stellar_object.type, orbiting_id: stellar_object.orbiting_id,
          parsec_id: stellar_object.parsec_id, data: stellar_object.data }
      end

      StellarObject.upsert_all(updates, unique_by: :id, update_only: [:data]) if updates.any?
    end
  end

  def down
    StellarObject.where(type: BACKFILLED_TYPES).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      updates = batch.filter_map do |stellar_object|
        next unless stellar_object.data.is_a?(Hash)

        { id: stellar_object.id, type: stellar_object.type, orbiting_id: stellar_object.orbiting_id,
          parsec_id: stellar_object.parsec_id,
          data: stellar_object.data.except('berthing_cost', 'refined_fuel_cost', 'unrefined_fuel_cost') }
      end

      StellarObject.upsert_all(updates, unique_by: :id, update_only: [:data]) if updates.any?
    end
  end
end
