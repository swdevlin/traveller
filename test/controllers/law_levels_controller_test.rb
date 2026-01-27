require 'test_helper'

class LawLevelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @law_level = law_levels(:one)
  end

  test 'should get index' do
    get law_levels_url
    assert_response :success
  end

  test 'should get new' do
    get new_law_level_url
    assert_response :success
  end

  test 'should create law_level' do
    assert_difference('LawLevel.count') do
      post law_levels_url, params: { law_level: { armour: @law_level.armour, code: 3, criminal_law: @law_level.criminal_law, economic_law: @law_level.economic_law, notes: @law_level.notes, personal_law: @law_level.personal_law, private_law: @law_level.private_law, weapons: @law_level.weapons } }
    end

    assert_redirected_to law_level_url(LawLevel.last)
  end

  test 'should show law_level' do
    get law_level_url(@law_level)
    assert_response :success
  end

  test 'should get edit' do
    get edit_law_level_url(@law_level)
    assert_response :success
  end

  test 'should update law_level' do
    patch law_level_url(@law_level), params: { law_level: { armour: @law_level.armour, code: @law_level.code, criminal_law: @law_level.criminal_law, economic_law: @law_level.economic_law, notes: @law_level.notes, personal_law: @law_level.personal_law, private_law: @law_level.private_law, weapons: @law_level.weapons } }
    assert_redirected_to law_level_url(@law_level)
  end

  test 'should destroy law_level' do
    assert_difference('LawLevel.count', -1) do
      delete law_level_url(@law_level)
    end

    assert_redirected_to law_levels_url
  end
end
