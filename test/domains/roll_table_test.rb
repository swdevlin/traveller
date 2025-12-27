require "test_helper"
require "minitest/spec"

describe RollTable do
  before do
    @roller = DiceRoller.new
    table = {
      2 => "low",
      3 => "medium low",
      4 => "medium",
      5 => "medium high",
      6 => "high"
    }
    @roll_table =  RollTable.new(table: table, dice: 1, size: 6)

    table = {
      2 => "low",
      3 => "medium low",
      4 => ->(the_roll:, **_) { "medium (rolled #{the_roll})" },
      5 => "medium high",
      6 => "high"
    }
    @lambda_table =  RollTable.new(table: table, dice: 1, size: 6)

    table = {
      1..3 => "low",
      4..8 =>  "middle",
      9..10 => "high"
    }
    @range_table =  RollTable.new(table: table, dice: 1, size: 6)
  end

  describe "#roll" do
    it "records a note that defaults to the class name" do
      # When
      @roll_table.roll(dm: 0, roller: @roller)

      # Then
      assert_equal "roll table", @roller.log.last[:note]
    end

    it "roll less than min is min" do
      r = @roll_table.roll(the_roll: 1, dm: 0, roller: @roller)
      _(r).must_equal 'low'
    end

    it "table lookup" do
      r = @roll_table.roll(the_roll: 4, dm: 0, roller: @roller)
      _(r).must_equal 'medium'
    end

    it "roll greater than max is max" do
      r = @roll_table.roll(the_roll: 19, dm: 0, roller: @roller)
      _(r).must_equal 'high'
    end

    it "lambda called" do
      r = @lambda_table.roll(the_roll: 4, dm: 0, roller: @roller)
      _(r).must_equal 'medium (rolled 4)'
    end

    it "ranges supported" do
      r = @range_table.roll(the_roll: 4, dm: 0, roller: @roller)
      _(r).must_equal 'middle'
    end

    it "ranges can be at the edges" do
      r = @range_table.roll(the_roll: -2, dm: 0, roller: @roller)
      _(r).must_equal 'low'

      r = @range_table.roll(the_roll: 22, dm: 0, roller: @roller)
      _(r).must_equal 'high'
    end
  end
end
