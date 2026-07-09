class HelpController < ApplicationController
  allow_unauthenticated_access

  def index
    @entries = available_pages.sort
  end

  def show
    matched = available_pages.find { |p| p == params[:page] }
    matched ? render(template: "help/#{matched}") : redirect_to(help_path)
  end

  private

  def available_pages
    Dir.glob(Rails.root.join('app', 'views', 'help', '*.html.erb'))
       .map { |f| File.basename(f, '.html.erb') }
       .reject { |name| name == 'index' || name.start_with?('_') }
  end
end
