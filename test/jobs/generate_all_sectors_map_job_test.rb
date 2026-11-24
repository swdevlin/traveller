# frozen_string_literal: true

require 'test_helper'

class GenerateAllSectorsMapJobTest < ActiveJob::TestCase
  def run_job(stale:, **kwargs)
    calls = []
    generator = Struct.new(:stale?).new(stale)
    generator.define_singleton_method(:call) { calls << :call }
    stub_new(AllSectorsMapGenerator, generator) do
      GenerateAllSectorsMapJob.perform_now(campaigns(:one).id, **kwargs)
    end
    calls
  end

  test 'builds the map when stale' do
    assert_equal [:call], run_job(stale: true)
  end

  test 'skips the build when the map is already fresh' do
    assert_empty run_job(stale: false)
  end

  test 'force builds even when fresh' do
    assert_equal [:call], run_job(stale: false, force: true)
  end
end
