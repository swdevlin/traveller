require 'test_helper'

class CreateSubsectorJobTest < ActiveJob::TestCase
  def setup
    @job = CreateSubsectorJob.new
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
        'Allegiance' => 'ImDi',
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
        'Allegiance' => 'ImDi',
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
        'Allegiance' => 'ImDi',
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

  test "systems_to_build_plan converts systems to YAML with type STANDARD" do
    result = @job.send(:systems_to_build_plan, @systems)
    parsed = YAML.safe_load(result)

    assert_equal 'STANDARD', parsed['type']
    assert_equal 3, parsed['systems'].length
  end

  test "systems_to_build_plan converts hex to subsector coordinates" do
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal 1, result['x']
    assert_equal 1, result['y']
  end

  test "systems_to_build_plan handles sector hex codes for subsector B (columns 9-16)" do
    @systems.first['Hex'] = '0901'
    # Subsector B would have hex codes like 0901-1610
    # 0901 should become subsector coords 1,1
    result = @job.send(:build_system_definition, @systems.first)

    assert_equal 1, result['x']
    assert_equal 1, result['y']
  end

  test "systems_to_build_plan handles sector hex codes for subsector E (rows 11-20)" do
    @systems.first['Hex'] = '0313'
    # Subsector E would have hex codes like 0111-0820
    # 0313 should become subsector coords 3,3
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal 3, result['x']
    assert_equal 3, result['y']
  end

  test "systems_to_build_plan includes name" do
    result = @job.send(:systems_to_build_plan, @systems)
    parsed = YAML.safe_load(result)

    assert_equal 'Didraga', parsed['systems'].first['name']
  end

  test "systems_to_build_plan handles multiple systems" do
    result = @job.send(:systems_to_build_plan, @systems)
    parsed = YAML.safe_load(result)

    assert_equal 3, parsed['systems'].length
    assert_equal 'Didraga', parsed['systems'][0]['name']
    assert_equal 'Ymirial', parsed['systems'][1]['name']
    assert_equal 'San Nuska Kilna', parsed['systems'][2]['name']
  end

  test "systems_to_build_plan returns valid YAML" do
    result = @job.send(:systems_to_build_plan, @systems)

    assert_nothing_raised do
      YAML.safe_load(result)
    end

    validator = BuildConfigValidator.new(result)

    assert validator.valid?
  end

  test "PBG mapped to counts" do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A' }
    ]
    result = @job.send(:build_system_definition, systems.first)
    assert_equal 6, result['counts']['terrestrialPlanets']
    assert_equal 0, result['counts']['planetoidBelts']
    assert_equal 3, result['counts']['gasGiants']

  end

  test "Mainworld included in counts" do
    systems = [
      { 'Hex' => '0303', 'Name' => "World's End", 'PBG' => '603', 'UWP' => 'B431721-A' }
    ]
    result = @job.send(:build_system_definition, systems.first)
    assert_equal 'B431721-A', result['counts']['mainWorld']['uwp']
    assert_equal 'hzco', result['counts']['mainWorld']['orbit']
  end

  test "No bases is an empty array" do
    @systems.first['Bases'] = nil
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal [], result['bases']
  end

  test "bases added" do
    @systems.first['Bases'] = 'S'
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal ['S'], result['bases']
  end

  test "Multiple bases added" do
    @systems.first['Bases'] = 'SN'
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal ['S', 'N'], result['bases']
  end

  test "No allegiance is nil" do
    @systems.first['Allegiance'] = ''
    result = @job.send(:build_system_definition, @systems.first)
    assert_nil result['allegiance']
  end

  test "allegiance added" do
    result = @job.send(:build_system_definition, @systems.first)
    assert_equal 'ImDi',  result['allegiance']
  end

  test "stars added" do
    result = @job.send(:build_system_definition, @systems.first)
    expected = { 'type' => 'K0', 'class' => 'V'}
    assert_equal expected,  result['primary']

    result = @job.send(:build_system_definition, @systems.second)
    primary = {'type' => 'M3', 'class' => 'V', 'near' => {'type' => 'M5', 'class' => 'V'}}
    assert_equal primary,  result['primary']

  end
end
