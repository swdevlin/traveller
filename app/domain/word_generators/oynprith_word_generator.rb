# frozen_string_literal: true

# OynprithWordGenerator produces words in Oynprith — the Droyne language — using the
# DROYNE SOUND FREQUENCY TABLE and DROYNE WORD GENERATION lookup grids from pages 40–41
# of the Traveller RPG rulebook.
#
# Frequency tables are encoded directly from the 6×6 lookup grids on page 41:
#   - Initial Consonants (2D6, 36 cells): P=4, H=4, PR=4, K=3, N=3, D=2, S=2, T=2,
#     B=DR=F=G=KR=L=M=R=ST=TH=TS=Y=1
#   - Vowels (2D6, 36 cells): A=7, E=5, O=5, U=5, AY=4, I=4, OY=4, EE=2
#   - Final Consonants (2D6, 36 cells): N=8, K=4, S=3, T=3, R=2, NK=2,
#     B=CH=D=F=KH=L=LK=M=ND=P=RD=SK=TH=TS=1
#
# Syllable-type table selection (page 40, Syllable Type rule):
#   BASIC table    — first syllable, and any syllable following a V or CV
#                    (i.e. after a vowel-ending syllable)
#   ALTERNATE table — any syllable following a VC or CVC
#                    (i.e. after a consonant-ending syllable)
#
# This is the INVERSE of Aslan: Droyne uses the basic table after vowels and the
# alternate table after consonants.
#
# Word length: 1D6 per rules (most words are three syllables; maximum six). This
# implementation rolls 1D3 + 1 to produce 2–4 syllables — a practical approximation
# that keeps output readable while reflecting the three-syllable norm.
#
# Word generation confirmed against the rulebook example:
#   Syllable 1 (basic table) → VC: vowel OY + final N  → "oyn"
#   Syllable 2 (alternate table, previous ended in consonant) → CVC: PR + I + TH → "prith"
#   Result: Oynprith ✓
#
class OynprithWordGenerator
  # Initial Consonants — 20 sounds, total weight 36.
  # Encoded from the 6×6 Initial Consonant lookup grid (page 41).
  INITIAL_CONSONANTS = [
    ['p',  4], ['h',  4], ['pr', 4],
    ['k',  3], ['n',  3],
    ['d',  2], ['s',  2], ['t',  2],
    ['b',  1], ['dr', 1], ['f',  1], ['g',  1], ['kr', 1],
    ['l',  1], ['m',  1], ['r',  1], ['st', 1],
    ['th', 1], ['ts', 1], ['y',  1]
  ].freeze

  # Vowels — 8 sounds, total weight 36.
  # Encoded from the 6×6 Vowel lookup grid (page 41).
  VOWELS = [
    ['a',  7],
    ['e',  5], ['o',  5], ['u',  5],
    ['ay', 4], ['i',  4], ['oy', 4],
    ['ee', 2]
  ].freeze

  # Final Consonants — 20 sounds, total weight 36.
  # Encoded from the 6×6 Final Consonant lookup grid (page 41).
  FINAL_CONSONANTS = [
    ['n',  8],
    ['k',  4],
    ['s',  3], ['t',  3],
    ['r',  2], ['nk', 2],
    ['b',  1], ['ch', 1], ['d',  1], ['f',  1], ['kh', 1],
    ['l',  1], ['lk', 1], ['m',  1], ['nd', 1], ['p',  1],
    ['rd', 1], ['sk', 1], ['th', 1], ['ts', 1]
  ].freeze

  # Basic syllable-type table — used for the first syllable and after any syllable
  # ending in a vowel (V or CV). CVC dominates; V is least common. Total weight 36.
  SYLLABLE_TYPES_BASIC = [
    [:cvc, 15],
    [:vc,   9],
    [:cv,   8],
    [:v,    4]
  ].freeze

  # Alternate syllable-type table — used after any syllable ending in a consonant
  # (VC or CVC). Shifts heavily toward CVC. Total weight 36.
  SYLLABLE_TYPES_ALTERNATE = [
    [:cvc, 21],
    [:vc,   9],
    [:cv,   4],
    [:v,    2]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  # Generates an Oynprith word of 2–4 syllables using the table-selection rule:
  # basic after vowel-ending (or at start), alternate after consonant-ending.
  def generate
    count = @dice_roller.roll(n: 1, d: 3, dm: 1, note: 'Oynprith syllable count')
    previous_ends_with_consonant = false
    syllables = []

    count.times do
      table = previous_ends_with_consonant ? SYLLABLE_TYPES_ALTERNATE : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Oynprith syllable type')

      syllables << build_syllable(type)
      previous_ends_with_consonant = type == :vc || type == :cvc
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
    pick_from(INITIAL_CONSONANTS, 'Oynprith initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Oynprith vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Oynprith final consonant')
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
