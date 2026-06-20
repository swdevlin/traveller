# frozen_string_literal: true

require 'test_helper'

class RogueObjectsTableTest < ActiveSupport::TestCase
  def setup
    @roller = DiceRoller.new(seed: 42)
  end

  test 'comet results carry a comet type' do
    tiny = RogueObjectsTable.new.roll(the_roll: 5, roller: @roller)
    assert_equal :comet, tiny[:id]
    assert_equal 'tiny', tiny[:comet_type]

    medium = RogueObjectsTable.new.roll(the_roll: 10, roller: @roller)
    assert_equal :comet, medium[:id]
    assert_equal 'medium', medium[:comet_type]

    large = Primary12Table.new.roll(the_roll: 1, roller: @roller)
    assert_equal :comet, large[:id]
    assert_equal 'large', large[:comet_type]
  end

  test 'boxcars rolls on the primary 2 table' do
    result = RogueObjectsTable.new.roll(the_roll: 2, roller: @roller)
    assert_includes %i[unusual_object interstellar_wreck historic_habitation gas_cloud], result[:id]
  end
end
