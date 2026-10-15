# frozen_string_literal: true

# CorpusWordGenerator builds words in the style of a user-supplied word list using an
# order-2 character Markov chain. Each corpus word is padded with start and end markers,
# and every pair of characters records how often each character followed it.
#
# Building the chain scans the whole word list, so it is stored in Rails.cache per tenant
# and language. The key includes the language's updated_at, so editing the word list
# produces a fresh chain and the old entry simply ages out.
class CorpusWordGenerator
  START = '^'
  STOP = '$'
  MIN_LENGTH = 3
  MAX_LENGTH = 12
  MAX_ATTEMPTS = 50
  CACHE_TTL = 30.days

  def self.for(language, dice_roller)
    new(cached_model(language), dice_roller)
  end

  def self.cached_model(language)
    key = ['corpus_word_generator', Apartment::Tenant.current, language.key, language.updated_at.utc.iso8601(6)]
    Rails.cache.fetch(key, expires_in: CACHE_TTL) { build_model(language.words) }
  end

  # @return [Hash] { chain: { 'ab' => { 'c' => 3, '$' => 1 } }, known: [words] }
  def self.build_model(words)
    words = words.map(&:downcase).uniq
    chain = {}
    words.each do |word|
      padded = [START, START, *word.chars, STOP]
      padded.each_cons(3) do |a, b, c|
        followers = (chain["#{a}#{b}"] ||= Hash.new(0))
        followers[c] += 1
      end
    end
    { chain: chain, known: words }
  end

  def initialize(model, dice_roller)
    @chain = model[:chain]
    @known = model[:known].to_set
    @dice_roller = dice_roller
  end

  def generate
    candidate = nil
    MAX_ATTEMPTS.times do
      candidate = attempt
      return candidate if candidate.length.between?(MIN_LENGTH, MAX_LENGTH) && @known.exclude?(candidate)
    end
    candidate
  end

  private

  def attempt
    state = "#{START}#{START}"
    word = +''
    while word.length <= MAX_LENGTH
      char = next_char(@chain.fetch(state))
      break if char == STOP

      word << char
      state = "#{state[-1]}#{char}"
    end
    word
  end

  def next_char(followers)
    roll = @dice_roller.roll(n: 1, d: followers.values.sum, note: 'Next character')
    followers.each do |char, count|
      roll -= count
      return char if roll <= 0
    end
  end
end
