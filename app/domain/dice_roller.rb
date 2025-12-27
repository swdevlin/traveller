# frozen_string_literal: true

# DiceRoller makes rolls of n x-sided dice. It logs all rolls so the results can be audited.
class DiceRoller
  # @return [Array<Hash>] History of all rolls
  attr_reader :log
  # @return [integer] the seed used to start the RNG
  attr_reader :seed

  # Initialize the dice rolle.
  #
  # @param seed [Integer, nil]
  #   Seed for deterministic output. If nil, a random seed is generated.
  def initialize(seed: nil)
    @seed = seed.nil? ? Random.new_seed : seed
    @roller = Random.new(@seed)
    @log = []
    @cache = {}
  end

  # Roll nDd plus an optional die modifier (DM).
  #
  # @param n [Integer] Number of dice to roll (N). Must be positive.
  # @param d [Integer] Sides per die (D). Must be positive.
  # @param dm [Integer] Die modifier added to the sum. Default: 0.
  # @param note [String] Required. Describes why the roll was made.
  #
  # @return [Integer] The total of the dice plus DM.
  #
  # @raise [ArgumentError] If n or d are not positive.
  # @raise [ArgumentError] If note is blank.
  def roll(n:, d:, dm: 0, note:)
    raise ArgumentError, 'n must be positive' unless n.positive?
    raise ArgumentError, 'd must be positive' unless d.positive?
    raise ArgumentError, 'note must be provided' if note.strip.empty?

    l = { rolls: [], note: note, dm: dm, dice: n, sides: d }
    (1..n).each do |i|
      l[:rolls] << @roller.rand(1..d)
    end
    @log << l
    l[:rolls].sum(dm)
  end
end
