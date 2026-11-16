# frozen_string_literal: true

# For a row that many star systems show, and that is edited on its own: when it
# changes or goes away, touch the star systems that show it. Anything cached
# against a system's updated_at (the subsector maps, the star system detail
# JSON) is then refreshed. A system's own tree is covered by belongs_to
# touch: true instead; this is for the shared rows that touch cannot reach.
#
# Override `affected_star_systems` to narrow it. By default every system is
# touched, which is one UPDATE and fine for rows that are rarely edited.
#
# A touch counts as an update here, so a model that other records touch must
# override `touch_star_systems_after_update?`, or each touch would cascade to
# every system it affects.
module TouchesStarSystems
  extend ActiveSupport::Concern

  included do
    # Before destroy, since dependent: :nullify would otherwise clear the association first.
    before_destroy { affected_star_systems.touch_all }
    after_commit(on: :update, if: :touch_star_systems_after_update?) { affected_star_systems.touch_all }
  end

  private

  def touch_star_systems_after_update? = true

  def affected_star_systems
    StarSystem.all
  end
end
