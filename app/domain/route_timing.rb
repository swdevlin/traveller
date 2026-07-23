# frozen_string_literal: true

class RouteTiming
  include JumpShadowMath

  JUMP_BASE_HOURS = 148.0
  JUMP_DICE       = 6
  JUMP_AVG_HOURS  = JUMP_BASE_HOURS + (JUMP_DICE * 3.5) # 169.0
  JUMP_MIN_HOURS  = JUMP_BASE_HOURS + (JUMP_DICE * 1)   # 154.0
  JUMP_MAX_HOURS  = JUMP_BASE_HOURS + (JUMP_DICE * 6)   # 184.0

  RowTiming = Struct.new(:transit_hours, :elapsed_avg_hours, keyword_init: true)

  def initialize(m_drive:)
    @m_drive = m_drive.to_i.clamp(1, 6)
  end

  def timings_for(systems)
    elapsed = 0.0
    previous_transit = nil

    systems.map do |system|
      transit = transit_hours(system)
      row_elapsed =
        if previous_transit
          elapsed += previous_transit + JUMP_AVG_HOURS + transit
          elapsed
        else
          transit
        end
      previous_transit = transit

      RowTiming.new(transit_hours: transit, elapsed_avg_hours: row_elapsed)
    end
  end

  def total(rows)
    if rows.size < 2
      return {
        jump_avg_hours: 0.0, jump_min_hours: 0.0, jump_max_hours: 0.0, transit_hours: 0.0,
        total_avg_hours: 0.0, total_min_hours: 0.0, total_max_hours: 0.0
      }
    end

    jumps        = rows.size - 1
    intermediate = rows[1..-2] || []
    transit_sum  = rows.first.transit_hours + rows.last.transit_hours + (2 * intermediate.sum(&:transit_hours))
    jump_avg     = jumps * JUMP_AVG_HOURS
    jump_min     = jumps * JUMP_MIN_HOURS
    jump_max     = jumps * JUMP_MAX_HOURS

    {
      jump_avg_hours: jump_avg,
      jump_min_hours: jump_min,
      jump_max_hours: jump_max,
      transit_hours:  transit_sum,
      total_avg_hours: jump_avg + transit_sum,
      total_min_hours: jump_min + transit_sum,
      total_max_hours: jump_max + transit_sum
    }
  end

  private

  def transit_hours(system)
    flip_burn_travel_time_hours(reference_jump_shadow_km(system), @m_drive) || 0.0
  end

  def reference_jump_shadow_km(system)
    world = system.main_world
    return world.effective_jump_shadow_km if world.respond_to?(:effective_jump_shadow_km)

    system.primary_star&.jump_shadow
  end
end
