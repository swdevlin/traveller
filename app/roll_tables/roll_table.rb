# frozen_string_literal: true

# RolLTable encapsulates table lookups typically used in roleplaying games.
class RollTable
  # Initialize the roll table.
  #
  # @param table [Hash]
  #   The table is represented as a hash, with the keys being the die rolls. The values can be constants or can be
  #   lambda functions. The roll, dm, note, and roller are passed to the lambda. You can extract what you need and
  #   use **_ for the rest. Eg. ->(the_roll, **_) { "medium (rolled #{the_roll})" }
  # @param dice[Integer]
  #   The number of dice to roll
  # @param size[Integer]
  #   The number of sides on the die
  def initialize(table:, dice: 2, size: 6)
    @dice = dice
    @size = size
    @table = table

    numbers= @table.keys.flat_map do |k|
      k.is_a?(Range) ? [k.begin, k.end] : [k]
    end

    @min = numbers.min
    @max = numbers.max
  end

  # Perform a roll and return the result from the table
  #
  # @param the_roll[Integer]
  #   If the roll happens outside of the instance, you can just pass it in
  # @param dm[Integer]
  #   The die modifier to apply to the roll. If the_roll is passed, the DM is not applied; it is assumed the DM was already
  #   factored into the die rol.
  # @param note[String]
  #   The note associated with the roll. If none is past, the note defaults to the class name
  # @param roller[DiceRoller]
  #   The RNG to use for the roll
  # @return the result of the lookup
  def roll(the_roll: nil, dm: 0, note: nil, roller:)
    note ||= default_note
    the_roll ||= roller.roll(n: @dice, d: @size, dm: dm, note: note)

    key =
      if the_roll <= @min
        @min
      elsif the_roll >= @max
        @max
      else
        the_roll
      end

    value = lookup(key)
    evaluate(value, the_roll:, dm:, note:, roller:)
  end

  private

  def lookup(the_roll)
    return @table[the_roll] if @table.key?(the_roll)

    range_key = @table.keys.find { |k| k.is_a?(Range) && k.cover?(the_roll) }
    @table[range_key]
  end

  def evaluate(value, the_roll:, dm:, note:, roller:)
    return value unless value.respond_to?(:call)

    value.call(the_roll:, dm:, note:, roller:)
  end

  def default_note
    self.class.name.gsub(/([a-z\d])([A-Z])/, '\1 \2').downcase
  end
end
