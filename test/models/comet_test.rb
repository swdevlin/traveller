# test/models/comet_test.rb
require "test_helper"

class CometTest < ActiveSupport::TestCase
  test ".allowed_data_keys permits only the data keys Comet expects" do
    assert_equal [ :comet_type ], Comet.allowed_data_keys
  end

  test "comet_type_is_valid: blank comet_type adds no errors" do
    comet = Comet.new(data: { "comet_type" => "" })

    comet.validate
    assert_empty comet.errors[:data]
  end

  test "comet_type_is_valid: valid comet_type adds no errors" do
    comet = Comet.new(data: { "comet_type" => "tiny" })

    comet.validate
    assert_empty comet.errors[:data]
  end

  test "comet_type_is_valid: invalid comet_type adds errors" do
    comet = Comet.new(data: { "comet_type" => "mundo" })

    comet.validate
    assert_not_empty comet.errors[:data]
  end
end
