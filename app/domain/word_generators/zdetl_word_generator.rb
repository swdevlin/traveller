# frozen_string_literal: true

# ZdetlWordGenerator produces words in Zdetl — the Zhodani language — using the
# ZHODANI WORD GENERATION lookup tables from the Traveller RPG supplement (zhodani.pdf,
# page 21).
#
# Each phoneme column (initial consonant, vowel, final consonant) is encoded from six
# 6×6 lookup sub-tables (Red Die 1–6 × White Die 1–6 per sub-table), giving 216 cells
# per column. Weights below are the total cell counts across all six sub-tables.
#
# Syllable-type table selection (from the ZHODANI WORD GENERATION rules):
#   BASIC table     — first syllable, or after a vowel-ending syllable (V or CV)
#   ALTERNATE table — after a consonant-ending syllable (VC or CVC)
#
# This is the inverse of Aslan/Arrghoun table selection: consonant codas switch to the
# Alternate table, vowel endings return to Basic.
#
# Word length: 1D syllables per the rules. This implementation uses 1D3 (1–3 syllables)
# as a practical default that produces readable names.
#
class ZdetlWordGenerator
  # Initial consonants — 41 sounds, total weight 216.
  # Encoded from six 6×6 sub-tables (pages 21–22 of the supplement).
  INITIAL_CONSONANTS = [
    # Sub-table 1: B through CHT/D
    ['b',    5], ['bl',   3], ['br',   5],
    ['ch',  12], ['cht',  7],
    # Sub-tables 1–2: D through JD
    ['d',    9], ['dl',   7], ['dr',   5],
    ['f',    5], ['fl',   3], ['fr',   3],
    ['j',    7], ['jd',   5],
    # Sub-table 3: K through PL
    ['k',    5], ['kl',   2], ['kr',   2],
    ['l',    3], ['m',    2], ['n',    8],
    ['p',    7], ['pl',   7],
    # Sub-table 4: PL/PR through SHT
    ['pr',   3], ['q',    2], ['ql',   2], ['qr',   2],
    ['r',    5], ['s',    7], ['sh',   7], ['sht',  7],
    # Sub-table 5: SHT/T through VR
    ['st',   7], ['t',    5], ['tl',  10], ['ts',   3],
    ['v',    5], ['vl',   2], ['vr',   2],
    # Sub-table 6: Y through ZHD
    ['y',    3], ['z',    5], ['zd',  10], ['zh',   7], ['zhd', 10]
  ].freeze

  # Vowels — 7 sounds, total weight 216.
  # Zdetl uses a syllabic R (as a vowel nucleus) alongside standard vowels and diphthongs.
  VOWELS = [
    ['a',   49],
    ['e',   59],
    ['i',   32],
    ['ia',  28],
    ['ie',  28],
    ['o',   14],
    ['r',    6]
  ].freeze

  # Final consonants — 42 sounds, total weight 216.
  # The apostrophe represents a glottal stop, standard in Zdetl romanisation.
  FINAL_CONSONANTS = [
    # Sub-table 1: B through DR
    ['b',    2], ['bl',   7], ['br',   7],
    ['ch',   5], ['d',    4], ['dl',   7], ['dr',   7],
    # Sub-table 2: DR/F through L
    ['f',    5], ['fl',   5], ['fr',   5],
    ['j',    4], ['k',    2], ['kl',   4], ['kr',   2],
    ['l',   12],
    # Sub-table 3: L/M through NT
    ['m',    2], ['n',    2], ['nch',  7], ['nj',   5],
    ['ns',   5], ['nsh',  7], ['nt',   4],
    # Sub-table 4: NT/NTS through Q
    ['nts',  4], ['nz',   5], ['nzh',  7],
    ['p',    2], ['pl',   7], ['pr',   7], ['q',    2],
    # Sub-table 5: QL through TL
    ['ql',   2], ['qr',   2], ['r',    5],
    ['sh',   7], ['t',    4], ['ts',   7], ['tl',   9],
    # Sub-table 6: V through glottal stop
    ['v',    5], ['vl',   4], ['vr',   5],
    ['z',    9], ['zh',   7], ["'",    6]
  ].freeze

  # Basic syllable-type table — first syllable, or after a vowel-ending syllable (V or CV).
  # Allows all four types including pure-vowel (V). Total weight 36.
  SYLLABLE_TYPES_BASIC = [
    [:v,    3],
    [:cv,   3],
    [:vc,   9],
    [:cvc, 21]
  ].freeze

  # Alternate syllable-type table — after a consonant-ending syllable (VC or CVC).
  # More balanced distribution; all four types available. Total weight 36.
  SYLLABLE_TYPES_ALTERNATE = [
    [:v,    6],
    [:cv,   6],
    [:vc,   6],
    [:cvc, 18]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Zdetl syllable count')
    use_basic = true
    syllables = []

    count.times do
      table = use_basic ? SYLLABLE_TYPES_BASIC : SYLLABLE_TYPES_ALTERNATE
      type = pick_from(table, 'Zdetl syllable type')

      syllables << build_syllable(type)
      use_basic = (type == :v || type == :cv)
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
    pick_from(INITIAL_CONSONANTS, 'Zdetl initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Zdetl vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Zdetl final consonant')
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
