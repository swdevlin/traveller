require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  def words(count)
    (1..count).map { |i| "word#{i.to_s.tr('0-9', 'a-j')}" }.join("\n")
  end

  test 'fixture is valid' do
    assert languages(:elvish).valid?
  end

  test 'derives key from name' do
    language = Language.new(name: 'Deep Speech', corpus: words(25))
    assert language.valid?
    assert_equal 'deep_speech', language.key
  end

  test 'rejects a key that clashes with a built-in language' do
    language = Language.new(name: 'Aslan', corpus: words(25))
    assert_not language.valid?
    assert language.errors[:name].any?
  end

  test 'rejects a duplicate key' do
    language = Language.new(name: 'Elvish', corpus: words(25))
    assert_not language.valid?
  end

  test 'requires enough words' do
    language = Language.new(name: 'Tiny', corpus: words(5))
    assert_not language.valid?
    assert language.errors[:corpus].any?
  end

  test 'words ignores blanks and duplicates' do
    language = Language.new(corpus: "alpha\n\nalpha\nbeta, gamma\n")
    assert_equal %w[alpha beta gamma], language.words
  end

  def upload(content, name: 'words.txt')
    file = Tempfile.new(['words', '.txt'], binmode: true)
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/plain', true, original_filename: name)
  end

  def greek_words
    %w[Αθηνά Ἀπόλλων Ἑρμῆς Ἥρα Ζεύς Ποσειδῶν Δήμητρα Ἄρτεμις Διόνυσος Ἥφαιστος Ἀφροδίτη Ἄρης
       Πάν Ἑστία Ἠώς Σελήνη Ἥλιος Γαῖα Οὐρανός Κρόνος Ῥέα Τιτάν].join("\n")
  end

  test 'accepts non-ASCII letters' do
    language = Language.new(name: 'Greek', corpus: greek_words)
    assert language.valid?, language.errors.full_messages.to_sentence
  end

  test 'normalises decomposed characters to composed form' do
    decomposed = "élan\n" + words(25)
    language = Language.new(name: 'Accents', corpus: decomposed)
    assert_includes language.words, 'élan'
  end

  test 'file upload fills the corpus' do
    language = Language.new(name: 'Uploaded', corpus_file: upload("#{Language::BOM}#{greek_words}\r\n"))
    assert language.valid?, language.errors.full_messages.to_sentence
    assert_equal 22, language.words.size
    assert_equal 'Αθηνά', language.words.first
  end

  test 'file upload rejects binary data' do
    language = Language.new(name: 'Binary', corpus_file: upload("PK\x03\x04\x00\x00#{"\xFF\xFE" * 50}".b))
    assert_not language.valid?
    assert_match(/plain UTF-8 text/, language.errors[:corpus].to_sentence)
  end

  test 'file upload rejects text containing NUL bytes' do
    language = Language.new(name: 'Nul', corpus_file: upload("#{words(25)}\n\0abc"))
    assert_not language.valid?
  end

  test 'file upload rejects Latin-1 encoded text' do
    language = Language.new(name: 'Latin', corpus_file: upload("caf\xE9\n#{words(25)}".b))
    assert_not language.valid?
  end

  test 'file upload rejects oversize files' do
    language = Language.new(name: 'Big', corpus_file: upload("abcdef\n" * 200_000))
    assert_not language.valid?
    assert_match(/too large/, language.errors[:corpus].to_sentence)
  end

  test 'rejects entries with digits or markup' do
    language = Language.new(name: 'Dirty', corpus: "#{words(25)}\n<script>")
    assert_not language.valid?
    assert_match(/may only contain letters/, language.errors[:corpus].to_sentence)
  end

  test 'in_use? is true when a sector uses the language' do
    language = languages(:elvish)
    assert_not language.in_use?
    sectors(:one).update!(language: 'elvish')
    assert language.in_use?
  end
end
