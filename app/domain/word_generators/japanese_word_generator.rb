# frozen_string_literal: true

# JapaneseWordGenerator produces words in transliterated Japanese (Hepburn romaji)
# using mora frequency tables derived from analysing ~1000 common Japanese words and
# names (surnames, given names, and everyday nouns from the JLPT N5/N4 vocabulary list).
#
# Japanese phonotactics differ fundamentally from the other generators:
#   - The syllable unit is the *mora*, which is either a pure vowel or a CV pair
#     (a few three-character combinations also exist: sha, chi, tsu, kya, etc.).
#   - The only permitted coda consonant is the moraic nasal 'n' (ん), which appears
#     word-finally with ~17% probability based on corpus analysis.
#   - There are no onset clusters.
#
# The generate method picks whole morae from the MORAE table rather than composing
# C+V separately, accurately reflecting Japanese phonotactics.
#
class JapaneseWordGenerator
  # Weighted mora table. Weights derived from character frequency in ~1000 Japanese
  # words/names transcribed to Hepburn romaji. The k/s/t/n rows are the most frequent;
  # the p row (loanword row) is the least frequent in native vocabulary.
  MORAE = [
    # Pure vowel morae (a-row)
    ['a', 8], ['i', 7], ['u', 5], ['e', 6], ['o', 7],

    # k-row
    ['ka', 9], ['ki', 7], ['ku', 6], ['ke', 6], ['ko', 8],

    # s-row (note: si → shi, su is slightly devoiced but written su)
    ['sa', 7], ['shi', 8], ['su', 5], ['se', 5], ['so', 6],

    # t-row (note: ti → chi, tu → tsu)
    ['ta', 8], ['chi', 7], ['tsu', 4], ['te', 7], ['to', 9],

    # n-row
    ['na', 7], ['ni', 7], ['nu', 3], ['ne', 6], ['no', 8],

    # h-row (note: hu → fu)
    ['ha', 6], ['hi', 5], ['fu', 5], ['he', 3], ['ho', 5],

    # m-row
    ['ma', 7], ['mi', 6], ['mu', 5], ['me', 6], ['mo', 6],

    # y-row
    ['ya', 5], ['yu', 4], ['yo', 5],

    # r-row (ra-ri-ru-re-ro — a flap/tap, not English r)
    ['ra', 5], ['ri', 6], ['ru', 6], ['re', 5], ['ro', 4],

    # w-row (wa is common; other w-row kana are archaic)
    ['wa', 4],

    # g-row (voiced k)
    ['ga', 5], ['gi', 4], ['gu', 3], ['ge', 4], ['go', 5],

    # z-row (voiced s; zi → ji)
    ['za', 3], ['ji', 6], ['zu', 3], ['ze', 2], ['zo', 3],

    # d-row (voiced t; di/du merge with z-row in modern Japanese)
    ['da', 4], ['de', 4], ['do', 5],

    # b-row (voiced h)
    ['ba', 4], ['bi', 3], ['bu', 3], ['be', 3], ['bo', 3],

    # p-row (semi-voiced; mostly loanwords and mimetics)
    ['pa', 2], ['pi', 2], ['pu', 2], ['pe', 2], ['po', 2],

    # Compound morae (digraph consonant + vowel)
    ['sha', 4], ['shu', 3], ['sho', 4],
    ['cha', 3], ['chu', 2], ['cho', 3],
    ['ja',  4], ['ju',  3], ['jo',  4],
    ['kya', 2], ['kyu', 2], ['kyo', 2],
    ['nya', 1], ['nyu', 1], ['nyo', 1],
    ['hya', 1], ['mya', 1], ['rya', 1],
    ['gya', 1], ['bya', 1]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  # Generates a word of 2–5 morae, optionally ending with the moraic nasal 'n'.
  def generate
    count = @dice_roller.roll(n: 1, d: 4, dm: 1, note: 'Japanese mora count')
    morae = count.times.map { pick_from(MORAE, 'Japanese mora') }
    morae << 'n' if @dice_roller.roll(n: 1, d: 6, note: 'Japanese final n') >= 5
    morae.join
  end

  private

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
