require 'test_helper'

class SubsectorTest < ActiveSupport::TestCase
  setup do
    @subsector = subsectors(:subsector_1_1)
  end

  test 'apply_deepnight_defaults! inherits sector-level populated when subsector has none' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      unusualChance: 2
      defaultSI: 3
      populated:
        type: full
        allegiance: 3eIm
        minTechLevel: 5
        maxTechLevel: 12
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
    YAML

    @subsector.apply_deepnight_defaults!(data)

    config = YAML.safe_load(@subsector.build)
    assert_equal 'full', config.dig('populated', 'type')
    assert_equal '3eIm', config.dig('populated', 'allegiance')
  end

  test 'apply_deepnight_defaults! does not overwrite subsector populated with sector populated' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      populated:
        type: full
        allegiance: 3eIm
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 5
            before:
              allegiance: null
            after:
              allegiance: ZhCo
    YAML

    @subsector.apply_deepnight_defaults!(data)

    config = YAML.safe_load(@subsector.build)
    assert_equal 'split-horizontal', config.dig('populated', 'type')
    assert_equal 'ZhCo', config.dig('populated', 'after', 'allegiance')
  end

  test 'apply_deepnight_defaults! creates allegiances from populated allegiance field' do
    Allegiance.where(code: 'GR').delete_all

    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: full
            allegiance: GR
            minTechLevel: 5
            maxTechLevel: 12
    YAML

    @subsector.apply_deepnight_defaults!(data)

    assert Allegiance.exists?(code: 'GR')
  end

  test 'apply_deepnight_defaults! creates allegiances from before and after regions' do
    Allegiance.where(code: %w[AA BB]).delete_all

    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 4
            before:
              allegiance: AA
            after:
              allegiance: BB
    YAML

    @subsector.apply_deepnight_defaults!(data)

    assert Allegiance.exists?(code: 'AA')
    assert Allegiance.exists?(code: 'BB')
  end

  test 'apply_deepnight_defaults! skips null allegiances in before and after regions' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 4
            before:
              allegiance: null
            after:
              allegiance: 3eIm
    YAML

    count_before = Allegiance.count

    @subsector.apply_deepnight_defaults!(data)

    assert_equal count_before, Allegiance.count
  end
end
