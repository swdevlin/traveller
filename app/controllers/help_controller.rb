class HelpController < ApplicationController
  allow_unauthenticated_access

  def index
    help_dir = Rails.root.join('app', 'views', 'help')
    @entries = Dir.glob(help_dir.join('*.html.erb'))
                  .map { |f| File.basename(f, '.html.erb') }
                  .reject { |name| name == 'index' || name.start_with?('_') }
                  .sort
  end

  def show
    if lookup_context.template_exists?("help/#{params[:page]}", [], false)
      render params[:page]
    else
      redirect_to help_path
    end
  end
end
