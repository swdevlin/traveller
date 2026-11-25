require 'test_helper'

class GasGiantTest < ActiveSupport::TestCase
  test 'retrograde comes from the generator and defaults to false' do
    giant = GasGiant.new
    giant.assign_data_from_generator({ 'retrograde' => true })

    assert giant.retrograde

    assert_not GasGiant.new.tap(&:valid?).retrograde
  end
end
