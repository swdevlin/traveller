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

  # governmentTypes validation (nested under populated)
  test 'governmentTypes accepts a comma list of known codes' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes: 1,2,A
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
    assert_equal %w[1 2 A], validator.config['populated']['governmentTypes']
  end

  test 'governmentTypes trims whitespace and is case insensitive' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes: 1, 2, a
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'governmentTypes rejects an unknown code' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes: 1,Z
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, "unknown government type 'Z'"
  end

  test 'governmentTypes rejects a multi-character token' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes:
          - "1"
          - "10"
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, "unknown government type '10'"
  end

  test 'governmentTypes accepts a real YAML array with bare numeric codes' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes:
          - 1
          - 2
          - A
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'governmentTypes accepts a single bare digit' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes: 1
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
    assert_equal ['1'], validator.config['populated']['governmentTypes']
  end

  test 'governmentTypes requires quoting an unquoted all-numeric comma list' do
    # YAML parses "1,2" as the integer 12, not the string "1,2" — the comma is gone by the
    # time this code sees it, so this must be caught explicitly rather than silently misread.
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        governmentTypes: 1,2
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'quote comma-separated values'
  end

  test 'governmentTypes in the before/after regions of a split population' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 3
        before:
          governmentTypes: "1,2"
        after:
          governmentTypes: 1,Z
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, "unknown government type 'Z'"
    assert_equal %w[1 2], validator.config['populated']['before']['governmentTypes']
  end

  test 'governmentTypes is valid for a star system build config' do
    yaml = <<~YAML
      name: Test System
      populated:
        type: full
        governmentTypes: 1,2,A
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'governmentTypes rejects an unknown code for a star system build config' do
    yaml = <<~YAML
      name: Test System
      populated:
        type: full
        governmentTypes: Z
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, "unknown government type 'Z'"
  end

  test 'BuildConfigValidator.government_type_codes converts a comma string to integer codes' do
    assert_equal [1, 2, 10, 12, 13], BuildConfigValidator.government_type_codes('1,2,A,C,D')
  end

  test 'BuildConfigValidator.government_type_codes converts an array to integer codes' do
    assert_equal [1, 2, 10], BuildConfigValidator.government_type_codes(%w[1 2 A])
  end

  test 'BuildConfigValidator.government_type_codes converts a mixed-type array as YAML would produce it' do
    assert_equal [1, 2, 10], BuildConfigValidator.government_type_codes([1, 2, 'A'])
  end

  test 'BuildConfigValidator.government_type_codes converts a single bare digit' do
    assert_equal [1], BuildConfigValidator.government_type_codes(1)
  end

  test 'BuildConfigValidator.government_type_codes returns nil for blank input' do
    assert_nil BuildConfigValidator.government_type_codes(nil)
    assert_nil BuildConfigValidator.government_type_codes('')
  end

  test 'BuildConfigValidator.convert_populated_government_types! converts populated and before/after, string-keyed' do
    populated = {
      'type' => 'split-horizontal',
      'governmentTypes' => '1,2,A',
      'before' => { 'governmentTypes' => '1,2' },
      'after' => { 'allegiance' => 'ImDr' }
    }

    BuildConfigValidator.convert_populated_government_types!(populated)

    assert_equal [1, 2, 10], populated['governmentTypes']
    assert_equal [1, 2], populated['before']['governmentTypes']
    assert_not populated['after'].key?('governmentTypes')
  end

  test 'BuildConfigValidator.convert_populated_government_types! converts populated and before/after, symbol-keyed' do
    populated = {
      type: 'split-horizontal',
      governmentTypes: '1,2,A',
      before: { governmentTypes: '1,2' }
    }

    BuildConfigValidator.convert_populated_government_types!(populated)

    assert_equal [1, 2, 10], populated[:governmentTypes]
    assert_equal [1, 2], populated[:before][:governmentTypes]
  end

  test 'BuildConfigValidator.convert_populated_government_types! is a no-op for nil populated' do
    assert_nothing_raised { BuildConfigValidator.convert_populated_government_types!(nil) }
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

  test 'mainWorld with moon true and gasGiants >= 1 is valid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            terrestrialPlanets: 2
            planetoidBelts: 1
            gasGiants: 1
            mainWorld:
              uwp: terrestrial
              moon: true
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'mainWorld with moon true and no gasGiants is invalid' do
    yaml = <<~YAML
      type: standard
      systems:
        - x: 1
          y: 1
          counts:
            terrestrialPlanets: 2
            planetoidBelts: 1
            gasGiants: 0
            mainWorld:
              uwp: terrestrial
              moon: true
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'gasGiants must be at least 1 when mainWorld moon is true'
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

  # Star spectral type
  test 'brown dwarf primary type with subtype and no class is valid' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: L5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'primary type requires class unless special or brown dwarf' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'class is required'
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

  test 'medium gas giant is a valid bodies uwp' do
    yaml = <<~YAML
      name: Test System
      primary:
        type: G5
        class: V
        bodies:
          - uwp: medium gas giant
          - uwp: terrestrial
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

  # populated validation

  test 'populated full type with flat allegiance is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        allegiance: 3eIm
        minTechLevel: 2
        maxTechLevel: 10
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated split type with before and after is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 2
        before:
          allegiance: null
        after:
          minTechLevel: 5
          maxTechLevel: 12
          allegiance: 3eIm
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated null allegiance in before and after is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: hard-horizontal
        demarcation: 5
        before:
          allegiance: null
        after:
          allegiance: null
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated with no allegiance anywhere is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-vertical
        demarcation: 4
        before:
          minTechLevel: 3
        after:
          maxTechLevel: 8
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'all populated split types are valid' do
    %w[hard-horizontal hard-vertical split-horizontal split-vertical].each do |type|
      yaml = <<~YAML
        type: standard
        populated:
          type: #{type}
          demarcation: 4
          before:
            allegiance: null
          after:
            allegiance: 3eIm
      YAML
      validator = BuildConfigValidator.new(yaml)
      assert validator.valid?, "Expected '#{type}' to be valid but got errors: #{validator.errors.inspect}"
    end
  end

  test 'populated unknown allegiance in before is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 3
        before:
          allegiance: UNKNOWN
        after:
          allegiance: 3eIm
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'allegiance'
  end

  test 'populated unknown allegiance in after is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 3
        before:
          allegiance: 3eIm
        after:
          allegiance: UNKNOWN
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'allegiance'
  end

  test 'populated minTechLevel greater than maxTechLevel in before is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 5
        before:
          minTechLevel: 10
          maxTechLevel: 5
        after:
          allegiance: null
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'minTechLevel'
  end

  test 'populated minTechLevel greater than maxTechLevel in after is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 5
        before:
          allegiance: null
        after:
          minTechLevel: 12
          maxTechLevel: 4
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'minTechLevel'
  end

  test 'populated full type with minLawLevel and maxLawLevel is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        minLawLevel: 2
        maxLawLevel: 10
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated minLawLevel and maxLawLevel set independently in before and after is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 2
        before:
          minLawLevel: 1
        after:
          minLawLevel: 5
          maxLawLevel: 12
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated minLawLevel greater than maxLawLevel in before is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 5
        before:
          minLawLevel: 10
          maxLawLevel: 5
        after:
          allegiance: null
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'minLawLevel'
  end

  test 'populated minLawLevel greater than maxLawLevel in after is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 5
        before:
          allegiance: null
        after:
          minLawLevel: 12
          maxLawLevel: 4
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'minLawLevel'
  end

  test 'populated demarcation 8 is valid for split-vertical' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-vertical
        demarcation: 8
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated demarcation 9 is invalid for split-vertical' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-vertical
        demarcation: 9
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'demarcation'
  end

  test 'populated demarcation 9 is invalid for hard-vertical' do
    yaml = <<~YAML
      type: standard
      populated:
        type: hard-vertical
        demarcation: 9
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'demarcation'
  end

  test 'populated demarcation 10 is valid for split-horizontal' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 10
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated full type with positive populationDM is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        populationDM: 3
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated full type with negative populationDM is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        populationDM: -3
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated split type with populationDM in before and after is valid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: split-horizontal
        demarcation: 4
        before:
          populationDM: -2
        after:
          populationDM: 2
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'populated populationDM above range is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        populationDM: 13
    YAML
    validator = BuildConfigValidator.new(yaml)
    refute validator.valid?
  end

  test 'populated populationDM below range is invalid' do
    yaml = <<~YAML
      type: standard
      populated:
        type: full
        populationDM: -13
    YAML
    validator = BuildConfigValidator.new(yaml)
    refute validator.valid?
  end

  # rogues
  test 'valid subsector rogues' do
    yaml = <<~YAML
      type: standard
      rogues:
        - x: 2
          y: 5
          type: large gas giant
        - x: 4
          y: 8
          type: random
          name: Wanderer
          known: true
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'every rogue type is accepted' do
    RogueObjectBuilder::TYPES.each do |type|
      yaml = <<~YAML
        type: standard
        rogues:
          - x: 1
            y: 1
            type: #{type}
      YAML
      validator = BuildConfigValidator.new(yaml)
      assert validator.valid?, "Expected '#{type}' to be valid but got errors: #{validator.errors.inspect}"
    end
  end

  test 'unknown rogue type is rejected' do
    yaml = <<~YAML
      type: standard
      rogues:
        - x: 1
          y: 1
          type: dyson sphere
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
    assert_includes validator.errors.join, 'rogues'
  end

  test 'subsector rogues require coordinates' do
    yaml = <<~YAML
      type: standard
      rogues:
        - type: comet
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid?
  end

  test 'empty rogues list is tolerated' do
    yaml = <<~YAML
      type: standard
      rogues:
        -
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'rogues inside systems and required entries need no coordinates' do
    yaml = <<~YAML
      type: standard
      required:
        - x: 6
          y: 3
          rogues:
            - type: medium comet
              name: Wanderer
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"

    yaml = <<~YAML
      type: standard
      systems:
        - x: 6
          y: 3
          rogues:
            - type: space station
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'star system config accepts rogues' do
    yaml = <<~YAML
      name: Halvor
      rogues:
        - type: terrestrial planet
          known: true
        - type: random
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'star system config rejects unknown rogue type' do
    yaml = <<~YAML
      rogues:
        - type: ringworld
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
  end

  # Top-level mainWorld

  test 'top-level mainWorld with valid UWP code is valid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X674000-0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'top-level mainWorld with UWP code and name is valid' do
    yaml = <<~YAML
      mainWorld:
        uwp: A788699-E
        name: Gaea
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'top-level mainWorld with UWP code and orbit label is valid' do
    yaml = <<~YAML
      mainWorld:
        uwp: B434558-8
        orbit: hzco
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'top-level mainWorld with UWP code, name, and orbit is valid' do
    yaml = <<~YAML
      mainWorld:
        uwp: C765987-6
        name: Harvest
        orbit: warm
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'top-level mainWorld with named UWP label is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: terrestrial
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld'
  end

  test 'top-level mainWorld with malformed UWP is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X12345
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld'
  end

  test 'top-level mainWorld without uwp is invalid' do
    yaml = <<~YAML
      mainWorld:
        name: Gaea
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld'
  end

  test 'top-level mainWorld with invalid orbit string is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X674000-0
        orbit: nearstar
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld'
  end

  test 'top-level mainWorld with integer orbit is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X674000-0
        orbit: 3
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld'
  end

  # mainWorld uniqueness — cross-form conflicts

  test 'top-level mainWorld and counts mainWorld together is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X674000-0
      counts:
        density: 5
        mainWorld:
          uwp: terrestrial
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld may only be declared once'
  end

  test 'top-level mainWorld and bodies mainWorld flag together is invalid' do
    yaml = <<~YAML
      mainWorld:
        uwp: X674000-0
      primary:
        type: G2
        class: V
        bodies:
          - uwp: terrestrial
            mainWorld: true
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld may only be declared once'
  end

  test 'star-level mainWorld and counts mainWorld together is invalid' do
    yaml = <<~YAML
      counts:
        density: 5
        mainWorld:
          uwp: terrestrial
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: X674000-0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld may only be declared once'
  end

  test 'star-level mainWorld and bodies mainWorld flag together is invalid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: X674000-0
        bodies:
          - uwp: terrestrial
            mainWorld: true
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld may only be declared once'
  end

  test 'star-level mainWorld on two different stars is invalid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: X674000-0
        far:
          type: M4
          class: V
          mainWorld:
            uwp: D433210-5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
    assert_includes validator.errors.join, 'mainWorld may only be declared once'
  end

  # Star-level mainWorld

  test 'primary mainWorld with valid UWP code is valid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: X674000-0
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'primary mainWorld with UWP, orbit, and name is valid' do
    yaml = <<~YAML
      primary:
        type: K3
        class: V
        mainWorld:
          uwp: B434558-8
          orbit: habitable
          name: Amber World
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'far star mainWorld with valid UWP code is valid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        far:
          type: M4
          class: V
          mainWorld:
            uwp: D433210-5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert validator.valid_for_star_system?, "Expected valid but got errors: #{validator.errors.inspect}"
  end

  test 'primary mainWorld with named UWP label is invalid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: gas giant
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
  end

  test 'primary mainWorld without uwp is invalid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          orbit: hzco
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
  end

  test 'primary mainWorld with integer orbit is invalid' do
    yaml = <<~YAML
      primary:
        type: G2
        class: V
        mainWorld:
          uwp: X674000-0
          orbit: 5
    YAML
    validator = BuildConfigValidator.new(yaml)
    assert_not validator.valid_for_star_system?
  end
end
