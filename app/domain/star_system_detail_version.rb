# frozen_string_literal: true

require 'digest'

# A short digest that changes whenever the star system detail JSON
# (api/_star_system_detail) would change, so a response can be cached under it
# and a caller can be told "unchanged" with a 304.
#
# It rests on the system's updated_at, which the app keeps current by touching:
#
#   its bodies, stars, moons, rings   belongs_to touch: true up to the system
#   cities, planet maps, trade codes  belongs_to touch: true on their body
#   tags                              Tagging touches its owner, and Taggable#tag_names=
#   bases                             StarSystemFacility touches the system
#   shared rows (sophonts, governments, law and tech levels, trade codes,
#   facilities, allegiances, tags, the sector)
#                                     TouchesStarSystems touches the systems that show them
#   generated systems                 the importer touches the system once, at the end
#   survey index raised by a jump     JumpLog sets updated_at as it writes
#
# A change that writes columns directly (update_column, update_all) leaves
# updated_at alone, so those writes must set it or touch the system.
#
# The parsec, shown by GET /parsecs/lookup, is not touched by its system's
# changes, so it is added when given. The campaign is added for its reference
# URL and signing secret.
#
# The digest also depends on who is asking, as `viewer`: :owner (the signed-in
# referee), :referee_token (the API token, which has referee authority) or
# :player. Tags and classified records are shown to both kinds of referee, but
# a sophont's referee notes only to the owner, so each gets its own copy.
class StarSystemDetailVersion
  VIEWERS = %i[owner referee_token player].freeze

  def initialize(star_system, viewer:, parsec: nil)
    raise ArgumentError, "unknown viewer #{viewer.inspect}" unless VIEWERS.include?(viewer)

    @star_system = star_system
    @viewer = viewer
    @parsec = parsec
  end

  def digest
    parts = [@star_system.cache_key_with_version, @parsec&.cache_key_with_version,
             @viewer, Current.campaign&.cache_key_with_version]
    Digest::SHA256.hexdigest(parts.to_json)[0, 32]
  end
end
