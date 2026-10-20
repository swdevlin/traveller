class ReleaseNotesController < ApplicationController
  allow_unauthenticated_access

  def index
    @pagy, @releases = pagy(:offset, ReleaseNote.all, limit: 10)
  end
end
