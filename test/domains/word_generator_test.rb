# frozen_string_literal: true

require 'test_helper'

class WordGeneratorTest < ActiveSupport::TestCase
  ASLAN_CHARS    = /\A[aefhiklorstuw y]+\z/
  SOLOMANI_CHARS = /\A[a-z]+\z/
  FRENCH_CHARS   = /\A[a-zéèêâîôû]+\z/
  JAPANESE_CHARS = /\A[a-z]+\z/
  KOREAN_CHARS   = /\A[a-z]+\z/
  HINDI_CHARS    = /\A[a-z]+\z/
  NORDIC_CHARS   = /\A[a-zåäöæø]+\z/
  OYNPRITH_CHARS  = /\A[a-z]+\z/
  ARRGHOUN_CHARS  = /\A[a-z]+\z/

  test 'raises ArgumentError for unknown language' do
    assert_raises(ArgumentError) do
      WordGenerator.new(language: :klingon).generate
    end
  end

  # --- Aslan ---

  test 'aslan: generates a non-empty string' do
    word = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'aslan: generated word contains only Aslan phoneme characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match ASLAN_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'aslan: log is populated after generation' do
    roller = DiceRoller.new(seed: 42)
    WordGenerator.new(language: :aslan, dice_roller: roller).generate
    assert roller.log.length > 0
  end

  test 'aslan: log is accessible via the generator' do
    gen = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42))
    gen.generate
    assert gen.log.length > 0
  end

  test 'aslan: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'aslan: snapshot seed 42 produces raosoltia' do
    word = WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'raosoltia', word
  end

  # --- Solomani ---

  test 'solomani: generates a non-empty string' do
    word = WordGenerator.new(language: :solomani, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'solomani: generated word contains only lowercase ASCII letters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :solomani, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match SOLOMANI_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'solomani: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :solomani, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :solomani, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'solomani: snapshot seed 42 produces towdipo' do
    word = WordGenerator.new(language: :solomani, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'towdipo', word
  end

  # --- French ---

  test 'french: generates a non-empty string' do
    word = WordGenerator.new(language: :french, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'french: generated word contains only French phoneme characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :french, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match FRENCH_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'french: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :french, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :french, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'french: snapshot seed 42 produces mêrsôrnir' do
    word = WordGenerator.new(language: :french, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'mêrsôrnir', word
  end

  # --- Japanese ---

  test 'japanese: generates a non-empty string' do
    word = WordGenerator.new(language: :japanese, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'japanese: generated word contains only romaji characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :japanese, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match JAPANESE_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'japanese: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :japanese, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :japanese, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'japanese: snapshot seed 42 produces shogitasan' do
    word = WordGenerator.new(language: :japanese, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'shogitasan', word
  end

  # --- Nordic ---

  test 'nordic: generates a non-empty string' do
    word = WordGenerator.new(language: :nordic, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'nordic: generated word contains only Nordic phoneme characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :nordic, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match NORDIC_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'nordic: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :nordic, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :nordic, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'nordic: snapshot seed 42 produces tåntsneirmvelt' do
    word = WordGenerator.new(language: :nordic, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'tåntsneirmvelt', word
  end

  # --- Korean ---

  test 'korean: generates a non-empty string' do
    word = WordGenerator.new(language: :korean, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'korean: generated word contains only Revised Romanization characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :korean, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match KOREAN_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'korean: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :korean, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :korean, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'korean: snapshot seed 42 produces juiltteoge' do
    word = WordGenerator.new(language: :korean, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'juiltteoge', word
  end

  # --- Hindi ---

  test 'hindi: generates a non-empty string' do
    word = WordGenerator.new(language: :hindi, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'hindi: generated word contains only ASCII transliteration characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :hindi, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match HINDI_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'hindi: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :hindi, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :hindi, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'hindi: snapshot seed 42 produces ruunkhauja' do
    word = WordGenerator.new(language: :hindi, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'ruunkhauja', word
  end

  # --- Oynprith (Droyne) ---

  test 'oynprith: generates a non-empty string' do
    word = WordGenerator.new(language: :oynprith, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'oynprith: generated word contains only Oynprith phoneme characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :oynprith, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match OYNPRITH_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'oynprith: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :oynprith, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :oynprith, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'oynprith: snapshot seed 42 produces keubpraytsank' do
    word = WordGenerator.new(language: :oynprith, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'keubpraytsank', word
  end

  # --- Arrghoun (Vargr) ---

  test 'arrghoun: generates a non-empty string' do
    word = WordGenerator.new(language: :arrghoun, dice_roller: DiceRoller.new(seed: 42)).generate
    assert word.is_a?(String)
    assert word.length > 0
  end

  test 'arrghoun: generated word contains only Arrghoun phoneme characters' do
    [42, 1, 99, 1337, 0].each do |seed|
      word = WordGenerator.new(language: :arrghoun, dice_roller: DiceRoller.new(seed: seed)).generate
      assert_match ARRGHOUN_CHARS, word, "Unexpected characters in #{word.inspect} (seed #{seed})"
    end
  end

  test 'arrghoun: seeded generation is deterministic' do
    word_a = WordGenerator.new(language: :arrghoun, dice_roller: DiceRoller.new(seed: 42)).generate
    word_b = WordGenerator.new(language: :arrghoun, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal word_a, word_b
  end

  test 'arrghoun: snapshot seed 42 produces kanllaegzzog' do
    word = WordGenerator.new(language: :arrghoun, dice_roller: DiceRoller.new(seed: 42)).generate
    assert_equal 'kanllaegzzog', word
  end
end
