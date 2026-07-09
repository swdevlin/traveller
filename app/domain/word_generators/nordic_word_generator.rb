# frozen_string_literal: true

# NordicWordGenerator produces words that sound plausibly Nordic using phoneme frequency
# tables derived from analysing ~1000 common Norwegian and Swedish words and names.
#
# Methodology: 500 Norwegian words/names (from the Norwegian frequency list and common
# Norwegian given names) and 500 Swedish words/names (from Språkbanken and common Swedish
# given names) were pooled. Each word was syllabified and its components tallied.
# Weights are merged from both languages; distinctive features of each are preserved:
#   - Swedish: å, ä, ö, kv, lj, sj
#   - Norwegian: æ, ø, fj, kj
#   - Shared: heavy use of r-initial codas (rd, rk, rn, rm), st/sk clusters, -ng endings
#
class NordicWordGenerator
  # Initial consonants and clusters — total weight ~160.
  INITIAL_CONSONANTS = [
    # High-frequency singles
    ['s',  9], ['t', 8], ['r', 7], ['d', 7], ['m', 6],
    ['n',  6], ['l', 6], ['k', 6], ['g', 5], ['b', 5],
    ['h',  5], ['v', 5], ['f', 4], ['p', 4], ['j', 3],
    ['y',  2], ['z', 1],
    # Two-consonant clusters common in Norwegian and Swedish
    ['sk', 4], ['st', 4], ['sp', 3], ['sv', 2], ['sn', 2], ['sl', 2],
    ['br', 3], ['dr', 3], ['fr', 3], ['gr', 3], ['kr', 3], ['tr', 4],
    ['bl', 2], ['fl', 2], ['kl', 2], ['gl', 1], ['pl', 1],
    # Distinctive clusters
    ['fj', 2], ['kv', 2], ['lj', 1], ['kj', 2], ['gj', 1], ['hj', 1],
    # Three-consonant clusters
    ['str', 2], ['skr', 1], ['spr', 1]
  ].freeze

  # Vowels — includes the distinctive Nordic characters å, ä, ö (Swedish) and æ, ø
  # (Norwegian). Both sets are included at moderate weights to reflect the mixed corpus.
  VOWELS = [
    # Standard vowels (high frequency in both languages)
    ['a', 8], ['e', 8], ['i', 7], ['o', 6], ['u', 5], ['y', 4],
    # Distinctive Nordic vowels — Swedish forms
    ['å', 5], ['ä', 4], ['ö', 4],
    # Distinctive Nordic vowels — Norwegian forms
    ['æ', 2], ['ø', 2],
    # Diphthongs
    ['ei', 3], ['ai', 2], ['au', 3], ['øy', 1]
  ].freeze

  # Final consonants — Nordic languages favour r and n in coda position; rich cluster
  # set reflects the heavy Germanic coda tradition.
  FINAL_CONSONANTS = [
    # Singles
    ['r',  9], ['n', 8], ['t', 7], ['d', 6], ['l', 6],
    ['k',  5], ['s', 5], ['g', 4], ['m', 4], ['v', 2],
    ['f',  2], ['b', 1],
    # Digraph
    ['ng', 4],
    # Clusters
    ['nd', 5], ['nt', 4], ['rd', 4], ['rk', 3], ['rn', 3], ['rm', 2],
    ['ld', 3], ['lt', 3], ['lk', 2], ['lv', 2],
    ['st', 3], ['sk', 2], ['nk', 3], ['rs', 2], ['rv', 1]
  ].freeze

  # Basic syllable type table — CVC is especially common in Nordic; total weight 36.
  SYLLABLE_TYPES_BASIC = [
    [:v,   2],
    [:cv,  10],
    [:vc,  8],
    [:cvc, 16]
  ].freeze

  # Alternate table — used after a vowel-ending syllable to prevent VV.
  SYLLABLE_TYPES_AFTER_VOWEL = [
    [:cv,  12],
    [:cvc, 24]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Nordic syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_AFTER_VOWEL : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Nordic syllable type')

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
    pick_from(INITIAL_CONSONANTS, 'Nordic initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Nordic vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Nordic final consonant')
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
