require 'test_helper'

class JumpLogTest < ActiveSupport::TestCase
  test 'misjump defaults to false' do
    assert_not JumpLog.new.misjump?
  end
end
