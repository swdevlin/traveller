require 'test_helper'

class T5TabDelimitedParserTest < ActiveSupport::TestCase
  def setup
    @systems = [
      {
        'Sector' => 'Zaru',
        'SS' => 'A',
        'Hex' => '0101',
        'Name' => 'Didraga',
        'UWP' => 'C1008BC-8',
        'Bases' => 'S',
        'Remarks' => 'Na Va Ph Pi Pz',
        'Zone' => 'A',
        'PBG' => '603',
        'Allegiance' => '3eIm',
        'Stars' => 'K0 V',
        '{Ix}' => '{ -1 }',
        '(Ex)' => '(D77+2)',
        '[Cx]' => '[B78B]',
        'Nobility' => 'BDe',
        'W' => '10',
        'RU' => '1274'
      },
      {
        'Sector' => 'Zaru',
        'SS' => 'A',
        'Hex' => '0106',
        'Name' => 'Ymirial',
        'UWP' => 'B200102-A',
        'Bases' => nil,
        'Remarks' => 'Lo Va',
        'Zone' => nil,
        'PBG' => '303',
        'Allegiance' => '3eIm',
        'Stars' => 'M3 V M5 V',
        '{Ix}' => '{ 1 }',
        '(Ex)' => '(601-3)',
        '[Cx]' => '[1216]',
        'Nobility' => 'B',
        'W' => '10',
        'RU' => '-18'
      },
      {
        'Sector' => 'Zaru',
        'SS' => 'A',
        'Hex' => '0108',
        'Name' => 'San Nuska Kilna',
        'UWP' => 'B5547BD-A',
        'Bases' => nil,
        'Remarks' => 'Ag Pz',
        'Zone' => 'A',
        'PBG' => '202',
        'Allegiance' => '3eIm',
        'Stars' => 'A2 V',
        '{Ix}' => '{ 3 }',
        '(Ex)' => '(B6C+5)',
        '[Cx]' => '[BA9E]',
        'Nobility' => 'BC',
        'W' => '11',
        'RU' => '3960'
      }
    ]
  end

  def build_system_definition(system)
    T5TabDelimitedParser.new([system]).send(:build_system_definition, system)
  end

  test 'parse_rows splits header and tab-delimited rows into hashes' do
    text = "Hex\tName\tUWP\n0101\tDidraga\tC1008BC-8\n0106\tYmirial\tB200102-A"
    result = T5TabDelimitedParser.parse(text).systems

    assert_equal 2, result.length
    assert_equal 'Didraga', result.first['Name']
    assert_equal 'C1008BC-8', result.first['UWP']
  end

  test 'parse_rows returns empty array for blank text' do
    assert_equal [], T5TabDelimitedParser.parse('').systems
  end

  test 'build_plan converts systems to YAML with type STANDARD' do
    result = T5TabDelimitedParser.new(@systems).build_plan
    parsed = YAML.safe_load(result)

    assert_equal 'STANDARD', parsed['type']
    assert_equal 3, parsed['systems'].length
  end

  test 'build_plan converts hex to subsector coordinates' do
    result = build_system_definition(@systems.first)
    assert_equal 1, result['x']
    assert_equal 1, result['y']
  end

  test 'build_plan handles sector hex codes for subsector B (columns 9-16)' do
    @systems.first['Hex'] = '0901'
    # Subsector B would have hex codes like 0901-1610
    # 0901 should become subsector coords 1,1
    result = build_system_definition(@systems.first)

    assert_equal 1, result['x']
    assert_equal 1, result['y']
  end

  test 'build_plan handles sector hex codes for subsector E (rows 11-20)' do
    @systems.first['Hex'] = '0313'
    # Subsector E would have hex codes like 0111-0820
    # 0313 should become subsector coords 3,3
    result = build_system_definition(@systems.first)
    assert_equal 3, result['x']
    assert_equal 3, result['y']
  end

  test 'build_plan includes name' do
    result = T5TabDelimitedParser.new(@systems).build_plan
    parsed = YAML.safe_load(result)

    assert_equal 'Didraga', parsed['systems'].first['name']
  end

  test 'build_plan handles multiple systems' do
    result = T5TabDelimitedParser.new(@systems).build_plan
    parsed = YAML.safe_load(result)

    assert_equal 3, parsed['systems'].length
    assert_equal 'Didraga', parsed['systems'][0]['name']
    assert_equal 'Ymirial', parsed['systems'][1]['name']
    assert_equal 'San Nuska Kilna', parsed['systems'][2]['name']
  end

  test 'build_plan omits surveyIndex when not given' do
    result = T5TabDelimitedParser.new(@systems).build_plan
    parsed = YAML.safe_load(result)

    assert_not parsed.key?('surveyIndex')
  end

  test 'build_plan includes surveyIndex when given' do
    result = T5TabDelimitedParser.new(@systems).build_plan(survey_index: 10)
    parsed = YAML.safe_load(result)

    assert_equal 10, parsed['surveyIndex']
  end

  test 'build_plans_by_subsector threads survey_index into every subsector plan' do
    systems = [
      { 'Hex' => '0101', 'Name' => 'Alpha' },
      { 'Hex' => '0901', 'Name' => 'Gamma' }
    ]
    plans = T5TabDelimitedParser.new(systems).build_plans_by_subsector(survey_index: 3)

    plans.each_value do |yaml|
      assert_equal 3, YAML.safe_load(yaml)['surveyIndex']
    end
  end

  test 'build_plan returns valid YAML' do
    result = T5TabDelimitedParser.new(@systems).build_plan

    assert_nothing_raised do
      YAML.safe_load(result)
    end

    validator = BuildConfigValidator.new(result)

    assert validator.valid?
  end

  test 'PBG belts and gas giants mapped to counts' do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A', 'W' => '10' }
    ]
    result = build_system_definition(systems.first)
    assert_equal 0, result['counts']['planetoidBelts']
    assert_equal 3, result['counts']['gasGiants']
  end

  test 'terrestrialPlanets derived from Worlds total minus mainworld, belts, and gas giants' do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A', 'W' => '10' }
    ]
    result = build_system_definition(systems.first)
    # 10 worlds - 1 mainworld - 0 belts - 3 gas giants = 6
    assert_equal 6, result['counts']['terrestrialPlanets']
  end

  test 'terrestrialPlanets falls back to PBG population digit when Worlds is blank' do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A', 'W' => nil }
    ]
    result = build_system_definition(systems.first)
    assert_equal 6, result['counts']['terrestrialPlanets']
  end

  test 'terrestrialPlanets is clamped to 20' do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '600', 'UWP' => 'B431721-A', 'W' => '99' }
    ]
    result = build_system_definition(systems.first)
    assert_equal 20, result['counts']['terrestrialPlanets']
  end

  test 'Mainworld included in counts' do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A' }
    ]
    result = build_system_definition(systems.first)
    assert_equal 'B431721-A', result['counts']['mainWorld']['uwp']
    assert_equal 'hzco', result['counts']['mainWorld']['orbit']
  end

  test 'No bases is an empty array' do
    @systems.first['Bases'] = nil
    result = build_system_definition(@systems.first)
    assert_equal [], result['bases']
  end

  test 'bases added' do
    @systems.first['Bases'] = 'S'
    result = build_system_definition(@systems.first)
    assert_equal ['S'], result['bases']
  end

  test 'Multiple bases added' do
    @systems.first['Bases'] = 'SN'
    result = build_system_definition(@systems.first)
    assert_equal ['S', 'N'], result['bases']
  end

  test 'No allegiance is nil' do
    @systems.first['Allegiance'] = ''
    result = build_system_definition(@systems.first)
    assert_nil result['allegiance']
  end

  test 'allegiance added' do
    result = build_system_definition(@systems.first)
    assert_equal '3eIm', result['allegiance']
  end

  test 'stars added' do
    result = build_system_definition(@systems.first)
    expected = { 'type' => 'K0', 'class' => 'V' }
    assert_equal expected, result['primary']

    result = build_system_definition(@systems.second)
    primary = { 'type' => 'M3', 'class' => 'V', 'near' => { 'type' => 'M5', 'class' => 'V' } }
    assert_equal primary, result['primary']
  end

  test 'subsector_letter_for_hex maps full-sector hex to subsector letter' do
    parser = T5TabDelimitedParser.new([])

    assert_equal 'A', parser.subsector_letter_for_hex('0101')
    assert_equal 'A', parser.subsector_letter_for_hex('0810')
    assert_equal 'B', parser.subsector_letter_for_hex('0901')
    assert_equal 'D', parser.subsector_letter_for_hex('3201')
    assert_equal 'E', parser.subsector_letter_for_hex('0111')
    assert_equal 'P', parser.subsector_letter_for_hex('3240')
    assert_nil parser.subsector_letter_for_hex(nil)
    assert_nil parser.subsector_letter_for_hex('3341')
  end

  test 'build_plans_by_subsector groups systems by subsector letter' do
    systems = [
      { 'Hex' => '0101', 'Name' => 'Alpha' },
      { 'Hex' => '0810', 'Name' => 'Beta' },
      { 'Hex' => '0901', 'Name' => 'Gamma' }
    ]
    plans = T5TabDelimitedParser.new(systems).build_plans_by_subsector

    assert_equal %w[A B], plans.keys.sort
    a_plan = YAML.safe_load(plans['A'])
    assert_equal 2, a_plan['systems'].length
    b_plan = YAML.safe_load(plans['B'])
    assert_equal 1, b_plan['systems'].length
    assert_equal 'Gamma', b_plan['systems'].first['name']
  end
end
