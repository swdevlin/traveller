# frozen_string_literal: true

require 'test_helper'

class BuildConfigValidatorTest < ActiveSupport::TestCase
  test 'valid minimal config' do
    yaml = <<~YAML
      unusualChance: 1
      defaultSI: 3
      type: standard
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'valid config with empty arrays' do
    yaml = <<~YAML
      unusualChance: 1
      defaultSI: 3
      type: standard
      exclude:
        -
      required:
        -
      systems:
        -
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'valid config with coordinates' do
    yaml = <<~YAML
      unusualChance: 50
      defaultSI: 6
      type: dense
      exclude:
        - x: 1
          y: 1
        - x: 8
          y: 10
      required:
        - x: 5
          y: 5
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  # unusualChance validation
  test 'unusualChance must be between 0 and 100' do
    yaml = "unusualChance: 150\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'unusualChance'
  end

  test 'unusualChance accepts 0' do
    yaml = "unusualChance: 0\ndefaultSI: 3\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'unusualChance accepts 100' do
    yaml = "unusualChance: 100\ndefaultSI: 3\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'unusualChance rejects negative values' do
    yaml = "unusualChance: -1\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'unusualChance'
  end

  # defaultSI validation
  test 'defaultSI must be between 0 and 12' do
    yaml = "defaultSI: 15\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'defaultSI'
  end

  test 'defaultSI accepts 0' do
    yaml = "unusualChance: 1\ndefaultSI: 0\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'defaultSI accepts 12' do
    yaml = "unusualChance: 1\ndefaultSI: 12\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'defaultSI rejects negative values' do
    yaml = "defaultSI: -1\ntype: standard"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'defaultSI'
  end

  # chance validation
  test 'type accepts all valid values' do
    valid_types = %w[dense standard moderate low sparse minimal rift rift_fade deep_rift empty]

    valid_types.each do |type|
      yaml = "type: #{type}"
      validator = BuildConfigValidator.new(yaml)
      assert validator.valid?, "Expected '#{type}' to be valid but got errors: #{validator.errors.inspect}"
    end
  end

  test 'type is case insensitive' do
    %w[STANDARD Standard sTaNdArD].each do |type|
      yaml = "type: #{type}"
      validator = BuildConfigValidator.new(yaml)
      assert validator.valid?, "Expected '#{type}' to be valid but got errors: #{validator.errors.inspect}"
      assert_equal 'STANDARD', validator.config['type']
    end
  end

  test 'type rejects invalid values' do
    yaml = 'type: invalid_chance'
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'type'
  end

  test 'type is required' do
    yaml = "unusualChance: 1\ndefaultSI: 3"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'type'
  end

  # Coordinate validation - x range (1-8)
  test 'coordinate x must be at least 1' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 0
          y: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'x'
  end

  test 'coordinate x must be at most 8' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 9
          y: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'x'
  end

  test 'coordinate x accepts boundary values 1 and 8' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
          y: 1
        - x: 8
          y: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  # Coordinate validation - y range (1-10)
  test 'coordinate y must be at least 1' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
          y: 0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'y'
  end

  test 'coordinate y must be at most 10' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
          y: 11
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'y'
  end

  test 'coordinate y accepts boundary values 1 and 10' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
          y: 1
        - x: 1
          y: 10
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  # Coordinate validation in different arrays
  test 'coordinates work in required array' do
    yaml = <<~YAML
      type: standard
      required:
        - x: 1
          y: 1
        - x: 8
          y: 10
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'coordinates work in systems array' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
        - x: 5
          y: 5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'coordinate requires both x and y' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'y'
  end

  # Systems exclusivity rule
  test 'systems cannot coexist with exclude' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
      exclude:
        - x: 2
          y: 2
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'systems is specified'
  end

  test 'systems cannot coexist with required' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
      required:
        - x: 3
          y: 3
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'systems is specified'
  end

  test 'systems can coexist with empty exclude and required' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
      exclude:
        -
      required:
        -
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'exclude and required can coexist when systems is empty' do
    yaml = <<~YAML
      type: standard
      exclude:
        - x: 1
          y: 1
      required:
        - x: 2
          y: 2
      systems:
        -
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  # YAML parsing errors
  test 'invalid YAML syntax returns error' do
    yaml = 'unusualChance: [invalid'
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'Invalid YAML syntax'
  end

  test 'non-hash YAML returns error' do
    yaml = '- item1\n- item2'
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'must be a YAML hash'
  end

  # Security tests
  test 'malicious YAML with object instantiation is blocked' do
    yaml = "--- !ruby/object:Gem::Installer\ni: x"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
  end

  test 'YAML with ERB tags is not executed' do
    yaml = "unusualChance: <%= system('whoami') %>"
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    # The ERB is treated as a string, not executed
    assert_equal "<%= system('whoami') %>", validator.config['unusualChance']
  end

  test 'YAML aliases are disabled' do
    yaml = <<~YAML
      anchor: &anchor
        key: value
      alias: *anchor
    YAML

    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
  end

  # Counts validation
  test 'counts with density only is valid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            density: 5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'counts with all three explicit counts is valid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            terrestrialPlanets: 3
            planetoidBelts: 2
            gasGiants: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'counts with density and mainWorld is valid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            density: 5
            mainWorld:
              uwp: X674000-0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'counts with explicit counts and mainWorld is valid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            terrestrialPlanets: 3
            planetoidBelts: 2
            gasGiants: 1
            mainWorld:
              uwp: terrestrial
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'counts with only partial explicit counts is invalid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            terrestrialPlanets: 3
            planetoidBelts: 2
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'must specify either density or all of'
  end

  test 'counts with only one explicit count is invalid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            gasGiants: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'must specify either density or all of'
  end

  test 'empty counts is invalid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts: {}
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'must specify either density or all of'
  end

  test 'counts density must be between 0 and 30' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            density: 31
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'density'
  end

  # Config accessor
  # Body orbit validation
  test 'bodies with one orbit label is valid' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: terrestrial
            orbit: hzco
          - uwp: gas giant
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'bodies with no orbit labels is valid' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: terrestrial
          - uwp: gas giant
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'bodies with two different orbit labels is invalid' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: terrestrial
            orbit: warm
          - uwp: terrestrial
            orbit: cold
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'only one body may specify an orbit label'
  end

  test 'bodies with duplicate orbit labels is invalid' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: terrestrial
            orbit: hzco
          - uwp: terrestrial
            orbit: hzco
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'only one body may specify an orbit label'
  end

  test 'bodies orbit rejects integers' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: terrestrial
            orbit: 3
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
  end

  # Nested star validation (companion inside far, etc.)
  test 'star with companion inside far is valid' do
    yaml = <<~YAML
      type: sparse
      systems:
        - x: 2
          y: 6
          name: Test System
          primary:
            type: G1
            class: V
            far:
              type: K3
              class: V
              companion:
                type: K3
                class: V
          counts:
            gasGiants: 1
            planetoidBelts: 0
            terrestrialPlanets: 0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'star with companion inside near is valid' do
    yaml = <<~YAML
      type: sparse
      systems:
        - x: 1
          y: 1
          primary:
            type: F6
            class: V
            near:
              type: K3
              class: V
              companion:
                type: M2
                class: V
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'nested star without required class is invalid' do
    yaml = <<~YAML
      type: sparse
      systems:
        - x: 2
          y: 6
          primary:
            type: G1
            class: V
            far:
              type: K3
              class: V
              companion:
                type: K3
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'class'
  end

  test 'config returns parsed and normalized hash' do
    yaml = <<~YAML
      unusualChance: 10
      defaultSI: 5
      type: MODERATE
    YAML

    validator = BuildConfigValidator.new(yaml)
    validator.valid?

    assert_equal 10, validator.config['unusualChance']
    assert_equal 5, validator.config['defaultSI']
    assert_equal 'MODERATE', validator.config['type']
  end
end
