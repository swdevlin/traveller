# A campaign-specific name-generation language built from a user-supplied word list.
# Tenant schemas are per campaign, so these are scoped to the campaign by construction.
class Language < ApplicationRecord
  MIN_WORDS = 20
  MAX_WORDS = 50_000
  MAX_WORD_LENGTH = 40
  MAX_BYTES = 1.megabyte
  BOM = [0xFEFF].pack('U').freeze
  WORD_FORMAT =/\A[\p{L}\p{M}][\p{L}\p{M}'’\- ]*\z/

  before_validation :derive_key

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :key,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9_]+\z/, allow_blank: true }
  validate :key_not_built_in
  validate :corpus_is_clean_text
  validate :corpus_has_enough_words

  # Replaces the corpus with the contents of an uploaded text file. Problems with the
  # file are reported by validation rather than raised.
  def corpus_file=(upload)
    return if upload.blank?

    if upload.size > MAX_BYTES
      @upload_error = "File is too large (limit #{MAX_BYTES / 1.megabyte} MB)"
      return
    end

    self.corpus = upload.read.force_encoding(Encoding::UTF_8).delete_prefix(BOM)
  end

  # Words from the corpus, one per line (commas also accepted), without blanks or duplicates.
  def words
    corpus.to_s.scrub('').unicode_normalize(:nfc).split(/[\n,]+/).map(&:strip).reject(&:blank?).uniq
  end

  # Where this language is currently selected, as human readable labels.
  def usages
    [Sector, Subsector, StarSystem, StellarObject].filter_map do |model|
      count = model.where(language: key).count
      "#{count} #{model.model_name.human.pluralize(count).downcase}" if count.positive?
    end
  end

  def in_use?
    usages.any?
  end

  private

  def derive_key
    self.key = name.to_s.parameterize(separator: '_') if key.blank?
    self.key = key.to_s.downcase
  end

  def key_not_built_in
    errors.add(:name, 'clashes with a built-in language') if WordGenerator::BUILT_IN.include?(key.to_s.to_sym)
  end

  def corpus_is_clean_text
    return errors.add(:corpus, @upload_error) if @upload_error

    text = corpus.to_s
    if !text.valid_encoding? || text.include?("\0")
      return errors.add(:corpus, 'must be plain UTF-8 text (is this a binary file, or saved in another encoding?)')
    end

    if text.match?(/[\p{Cc}&&[^\n\r\t]]/)
      return errors.add(:corpus, 'contains control characters')
    end

    check_word_shapes
  end

  def check_word_shapes
    text = corpus.to_s
    text.split(/[\n,]+/).each_with_index do |entry, index|
      word = entry.strip
      next if word.blank?

      if word.length > MAX_WORD_LENGTH
        return errors.add(:corpus, "entry #{index + 1} is longer than #{MAX_WORD_LENGTH} characters")
      elsif !word.match?(WORD_FORMAT)
        return errors.add(:corpus, "entry #{index + 1} (#{word.truncate(20).inspect}) may only contain letters, apostrophes, hyphens and spaces")
      end
    end

    errors.add(:corpus, "has too many words (limit #{MAX_WORDS})") if words.size > MAX_WORDS
  end

  def corpus_has_enough_words
    return if errors.include?(:corpus)
    return if words.size >= MIN_WORDS

    errors.add(:corpus, "needs at least #{MIN_WORDS} distinct words (found #{words.size})")
  end
end
