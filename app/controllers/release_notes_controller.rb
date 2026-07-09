class ReleaseNotesController < ApplicationController
  def index
    @pagy, @releases = pagy(:offset, ReleaseNote.all, limit: 10)
  end
end
