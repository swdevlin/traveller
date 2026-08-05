# Minitest 6 removed `minitest/mock` (no `Object#stub`), and this project has no
# Mocha/rspec-mocks dependency. This provides the one small piece needed by job
# tests: temporarily replacing `SomeClass.new` with a fixed double for the
# duration of a block, so a job's internally-constructed collaborator (e.g. a
# `PdfTextExtractor`/`RulebookImporter` the job builds itself) can be swapped
# out without changing the job's public interface.
module StubNewHelper
  def stub_new(klass, replacement)
    singleton = klass.singleton_class
    singleton.send(:alias_method, :__stub_new_original, :new)
    singleton.send(:define_method, :new) { |*_args, **_kwargs| replacement }

    yield
  ensure
    singleton.send(:alias_method, :new, :__stub_new_original)
    singleton.send(:remove_method, :__stub_new_original)
  end
end

ActiveSupport::TestCase.include StubNewHelper
