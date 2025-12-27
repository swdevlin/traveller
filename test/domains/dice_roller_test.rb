require 'test_helper'
require "minitest/spec"

describe DiceRoller do
  before do
    @roller = DiceRoller.new
  end

  describe "#roll" do
    it "number of dice must be positive" do
      _ { @roller.roll(n: -1, d: 6, notes: 'dice must be positive') }.must_raise(ArgumentError)
    end

    it "number of sides must be positive" do
      _ { @roller.roll(n: 3, d: -1, notes: 'sides must be positive') }.must_raise(ArgumentError)
    end

    it "note is required" do
      _ { @roller.roll(n: 3, d: 6) }.must_raise(ArgumentError)
    end
  end
end
