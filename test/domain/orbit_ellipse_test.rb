require 'test_helper'

class OrbitEllipseTest < ActiveSupport::TestCase
  class Host
    include OrbitEllipse

    def ellipse(*args, **kwargs) = orbit_ellipse(*args, **kwargs)
    def ranked(*args, **kwargs) = ranked_orbit_ellipse(*args, **kwargs)
  end

  test 'a stored periapsis direction replaces the one recovered from position' do
    host = Host.new
    recovered = host.ellipse(1.0, 1.2, 1.0, 0.3, 100)
    stored = host.ellipse(1.0, 1.2, 1.0, 0.3, 100, stored_direction: -0.5)

    assert_in_delta(-0.5 * 180 / Math::PI, stored[:rotation_deg], 1e-9)
    assert_not_in_delta recovered[:rotation_deg], stored[:rotation_deg], 1
  end

  test 'ranked ellipse puts the body on its orbit using the stored direction' do
    ellipse = Host.new.ranked(1.0, 1.0, 1.0, 0.3, 100, stored_direction: 1.0)

    assert_in_delta 100 * (1 - (0.3**2)) / 1.3, ellipse[:r_px], 1e-9
  end
end
