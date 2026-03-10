class HelpController < ApplicationController
  allow_unauthenticated_access
  def index
    help_dir = Rails.root.join('app', 'views', 'help')
    @entries = Dir.glob(help_dir.join('*.html.erb'))
                  .map { |f| File.basename(f, '.html.erb') }
                  .reject { |name| name == 'index' || name.start_with?('_') }
                  .sort
  end

  def subsector_build_specification
  end

  def star_system_build_specification
  end

  def star_system_registration
  end
end
