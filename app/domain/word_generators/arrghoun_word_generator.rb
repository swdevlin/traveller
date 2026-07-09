# frozen_string_literal: true

# ArrghounWordGenerator produces words in Arrghoun — the Vargr language — using the
# VARGR WORD GENERATION lookup grids from the Traveller RPG rulebook (vargr.jpg).
#
# Frequency tables are encoded from the 6×6 lookup grids (Red Die 1–6, White Die 1–6):
#
#   Initial Consonants (36 cells):
#     RD1: G×6
#     RD2: D×3, DH×3
#     RD3: GZ×1, K×5
#     RD4: KN×2, KS×2, LL×2
#     RD5: R×3, RR×1, S×2
#     RD6: TH×2, TS×1, V×2, Z×1
#
#   Vowels (36 cells):
#     RD1: A×6
#     RD2: A×3, AE×3
#     RD3: AE×3, E×3
#     RD4: O×6
#     RD5: OU×3, U×3
#     RD6: U×3, UE×3
#
#   Final Consonants (36 cells):
#     RD1: G×3, DH×2, DZ×1
#     RD2: GH×3, GZ×3
#     RD3: KH×6
#     RD4: N×3, NG×3
#     RD5: R×2, RR×2, RRGH×2
#     RD6: S×2, TH×1, TS×1, Z×2
#
# Syllable-type table selection (from the VARGR WORD GENERATION rules):
#   BASIC table    — first syllable, or after a consonant-ending syllable (VC or CVC)
#   ALTERNATE table — after a vowel-ending syllable (CV)
#
# This matches the same sense as Aslan. Critically, Arrghoun has NO pure-vowel (V)
# syllable type — every syllable begins or ends with a consonant.
#
# Word length: 1D6 per the rules. This implementation uses 1D3 (1–3 syllables) as
# a practical default that produces readable names; the full rule allows up to six.
#
class ArrghounWordGenerator
  # Initial consonants — 15 sounds, total weight 36.
  INITIAL_CONSONANTS = [
    # Red Die 1 — G dominates
    ['g',  6],
    # Red Die 2 — voiced stops
    ['d',  3], ['dh', 3],
    # Red Die 3 — velars
    ['gz', 1], ['k',  5],
    # Red Die 4 — clusters
    ['kn', 2], ['ks', 2], ['ll', 2],
    # Red Die 5 — liquids and sibilant
    ['r',  3], ['rr', 1], ['s',  2],
    # Red Die 6 — fricatives
    ['th', 2], ['ts', 1], ['v',  2], ['z',  1]
  ].freeze

  # Vowels — 7 sounds, total weight 36.
  VOWELS = [
    ['a',  9],
    ['ae', 6],
    ['e',  3],
    ['o',  6],
    ['ou', 3],
    ['u',  6],
    ['ue', 3]
  ].freeze

  # Final consonants — 16 sounds, total weight 36.
  # RRGH is the standard Vargr romanisation for the trilled-R + voiced velar fricative
  # cluster (as in the name "Rurrgh").
  FINAL_CONSONANTS = [
    # Red Die 1 — voiced stops and affricates
    ['g',    3], ['dh',   2], ['dz',   1],
    # Red Die 2 — voiced fricatives
    ['gh',   3], ['gz',   3],
    # Red Die 3 — voiceless velar fricative (very common coda in Vargr)
    ['kh',   6],
    # Red Die 4 — nasals
    ['n',    3], ['ng',   3],
    # Red Die 5 — liquids
    ['r',    2], ['rr',   2], ['rrgh', 2],
    # Red Die 6 — sibilants and fricatives
    ['s',    2], ['th',   1], ['ts',   1], ['z',    2]
  ].freeze

  # Basic syllable-type table — used for first syllable and after consonant-ending.
  # No V type: every Vargr syllable is anchored by at least one consonant. Total 36.
  SYLLABLE_TYPES_BASIC = [
    [:cv,   4],
    [:vc,   7],
    [:cvc, 25]
  ].freeze

  # Alternate syllable-type table — used after a CV (vowel-ending) syllable, preventing
  # a VV boundary at the syllable join. Only consonant-initial types. Total 36.
  SYLLABLE_TYPES_ALTERNATE = [
    [:cv,  10],
    [:cvc, 26]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Arrghoun syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_ALTERNATE : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Arrghoun syllable type')

      syllables << build_syllable(type)
      previous_ends_with_vowel = type == :cv
    end

    syllables.join
  end

  private

  def build_syllable(type)
    case type
    when :cv  then consonant + vowel
    when :vc  then vowel + final_consonant
    when :cvc then consonant + vowel + final_consonant
    end
  end

  def consonant
    pick_from(INITIAL_CONSONANTS, 'Arrghoun initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Arrghoun vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Arrghoun final consonant')
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
