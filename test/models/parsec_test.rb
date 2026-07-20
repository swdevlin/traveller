require 'test_helper'

class ParsecTest < ActiveSupport::TestCase
  test 'known defaults to false and visible defaults to true' do
    parsec = parsecs(:one)

    assert_not parsec.known?
    assert parsec.visible?
  end

  test 'label supports multiple lines' do
    parsec = parsecs(:one)
    parsec.update!(label: "Line one\nLine two")

    assert_equal "Line one\nLine two", parsec.reload.label
  end

  test 'labeled scope only includes parsecs with a present label' do
    labeled = parsecs(:one)
    labeled.update!(label: 'A label')
    unlabeled = parsecs(:two)
    unlabeled.update!(label: nil)

    assert_includes Parsec.labeled, labeled
    assert_not_includes Parsec.labeled, unlabeled
  end

  test 'icon_class must match the fa-style fa-name format' do
    parsec = parsecs(:one)
    parsec.icon_class = 'not-a-valid-icon'

    assert_not parsec.valid?
    assert_includes parsec.errors[:icon_class], 'must be in the format fa-solid fa-star'
  end

  test 'blank icon_class is valid' do
    parsec = parsecs(:one)
    parsec.icon_class = ''

    assert parsec.valid?
  end

  test 'icon_class resolves to a cached FontAwesomeIcon' do
    FontAwesomeIcon.create!(name: 'fa-star', style: 'solid', view_box: '0 0 640 640', svg_content: '<path d="M1 1z"/>')
    parsec = parsecs(:one)
    parsec.update!(icon_class: 'fa-solid fa-star')

    icon = parsec.icon
    assert_equal 'fa-star', icon.name
    assert_equal 'solid', icon.style
  end
end
