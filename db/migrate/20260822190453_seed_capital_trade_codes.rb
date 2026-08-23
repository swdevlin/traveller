class SeedCapitalTradeCodes < ActiveRecord::Migration[8.1]
  def up
    TradeCode.find_or_create_by!(code: 'Cs') { |tc| tc.definition = 'Sector Capital' }
    TradeCode.find_or_create_by!(code: 'Cp') { |tc| tc.definition = 'Subsector Capital' }
  end

  def down
    # no-op — don't destroy a tenant's trade-code assignments on rollback
  end
end
