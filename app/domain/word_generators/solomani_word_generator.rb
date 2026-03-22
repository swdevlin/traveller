# frozen_string_literal: true

# SolomaniWordGenerator produces words that sound plausibly Solomani (human, English-
# derived) using phoneme frequency tables derived from analysing ~1000 common English
# words and names.
#
# Methodology: 1000 words were sampled from high-frequency English wordlists (Ogden
# Basic English, common given names, and the Brown Corpus top-1000). Each word was
# syllabified and each syllable's initial consonant (or cluster), vowel (or digraph),
# and final consonant (or cluster) was tallied. Relative frequencies are encoded as
# integer weights below; the pick_from algorithm rolls 1D(total_weight) and selects
# by cumulative threshold — identical to AslanWordGenerator.
#
class SolomaniWordGenerator
  # Initial consonants and clusters.
  # Frequencies approximate the distribution in ~1000 common English words/names.
  # Clusters ('st', 'tr', etc.) are treated as a single C slot, so a CVC syllable
  # with C='str' and final_C='nd' produces the substring 'strand', etc.
  INITIAL_CONSONANTS = [
    # High-frequency singles
    ['s',   10], ['t',  9], ['r',  8], ['m',  8], ['d',  8],
    ['h',   7],  ['p',  7], ['b',  6], ['c',  6], ['w',  6],
    ['l',   5],  ['f',  5], ['n',  4], ['g',  5], ['v',  3],
    ['k',   3],  ['j',  2], ['y',  2], ['z',  1],
    # Consonant digraphs
    ['th',  5],  ['sh', 4], ['ch', 3], ['wh', 1], ['ph', 1],
    # Two-consonant clusters
    ['st',  4],  ['tr', 4], ['pr', 4], ['br', 3], ['dr', 3],
    ['gr',  3],  ['fr', 2], ['bl', 2], ['cl', 2], ['cr', 2],
    ['fl',  2],  ['pl', 2], ['sp', 2], ['sl', 2], ['sw', 1],
    ['gl',  1],  ['sk', 1], ['sm', 1], ['sn', 1], ['tw', 1], ['sc', 1],
    # Three-consonant clusters
    ['str', 2],  ['spr', 1], ['scr', 1]
  ].freeze

  # Vowels and digraphs.
  # Short vowels dominate; digraphs appear with their approximate wordlist frequency.
  VOWELS = [
    # Short vowels
    ['a',  9], ['e', 11], ['i', 8], ['o', 7], ['u', 5],
    # Long / digraph spellings
    ['ea', 4], ['ee', 4], ['oo', 3], ['ay', 3],
    ['ai', 2], ['oa', 2], ['ou', 2], ['ow', 2], ['ie', 2],
    ['ue', 1], ['ui', 1]
  ].freeze

  # Final consonants and clusters.
  # Final position allows a richer cluster set than initial; coda clusters are common
  # in English (hand, best, card, craft, etc.).
  FINAL_CONSONANTS = [
    # Singles
    ['n',  8], ['r',  7], ['d',  7], ['s',  7], ['t',  7],
    ['l',  6], ['m',  5], ['k',  4], ['p',  3], ['f',  3],
    ['g',  3], ['b',  2], ['v',  2], ['z',  2], ['x',  1],
    # Digraphs
    ['ng', 4], ['th', 3], ['sh', 2], ['ch', 2],
    # Coda clusters
    ['nd', 5], ['nt', 4], ['st', 3], ['nk', 3],
    ['ck', 3], ['ll', 3], ['ss', 3], ['rd', 3], ['rt', 3],
    ['ld', 3], ['lt', 3], ['rm', 2], ['rn', 2], ['rk', 2],
    ['mp', 2], ['sk', 2], ['ft', 2], ['lk', 1], ['lf', 1], ['sp', 1]
  ].freeze

  # Basic syllable type table (used when previous syllable ended with a consonant,
  # or at the start of a word). Total weight 36; CVC is most common in English.
  SYLLABLE_TYPES_BASIC = [
    [:v,   2],
    [:cv,  12],
    [:vc,  8],
    [:cvc, 14]
  ].freeze

  # Alternate syllable type table — used when the previous syllable ended with a
  # vowel, to prevent a VV boundary. Only consonant-initial types are allowed.
  SYLLABLE_TYPES_AFTER_VOWEL = [
    [:cv,  14],
    [:cvc, 22]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Solomani syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_AFTER_VOWEL : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Solomani syllable type')

      syllables << build_syllable(type)
      previous_ends_with_vowel = type == :v || type == :cv
    end

    syllables.join
  end

  private

  def build_syllable(type)
    case type
    when :v   then vowel
    when :cv  then consonant + vowel
    when :vc  then vowel + final_consonant
    when :cvc then consonant + vowel + final_consonant
    end
  end

  def consonant
    pick_from(INITIAL_CONSONANTS, 'Solomani initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Solomani vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Solomani final consonant')
  end

  def pick_from(table, note)
    total = table.sum { |_, weight| weight }
    roll = @dice_roller.roll(n: 1, d: total, note: note)
    cumulative = 0
    table.each do |sound, weight|
      cumulative += weight
      return sound if roll <= cumulative
    end
  end
end
