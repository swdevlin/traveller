class SystemQueriesController < ApplicationController
  before_action :set_system_query, except: %i[index new create]
  rescue_from JSON::ParserError, with: :render_invalid_rule_data

  def index
    @pagy, @system_queries = pagy(SystemQuery.order(:name), limit: 20, params: request.query_parameters)
  end

  def show
    scope = @system_query.matching_star_systems(
      StarSystem.includes({ parsec: { sector: :subsectors } }, :allegiance, :travel_zone, :facilities, main_world: :trade_codes)
    )
    @pagy, @star_systems = pagy(scope, limit: 25, params: request.query_parameters)
  end

  def new
    columns = SystemQuery::COLUMN_KEYS
    columns -= ['survey_index'] unless current_campaign.exploration?
    @system_query = SystemQuery.new(columns: columns)
  end

  def edit
  end

  def create
    @system_query = SystemQuery.new(system_query_params)

    if @system_query.save
      redirect_to @system_query, notice: 'Query created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @system_query.update(system_query_params)
      redirect_to @system_query, notice: 'Query updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @system_query.destroy!
    redirect_to system_queries_path, notice: 'Query deleted.', status: :see_other
  end

  private

  def set_system_query
    @system_query = SystemQuery.find(params.expect(:id))
  end

  # PATCH only ever updates the fields actually present in the request —
  # `rule_data_json` is included only by the full rule editor.
  def system_query_params
    attrs = params.expect(system_query: [:name, columns: []])
    attrs[:columns] = attrs[:columns].to_a.reject(&:blank?) if attrs[:columns]
    attrs[:rule_data] = rule_data_param if rule_data_json_submitted?
    attrs
  end

  def rule_data_json_submitted?
    params[:system_query]&.key?(:rule_data_json)
  end

  def rule_data_param
    JSON.parse(params.dig(:system_query, :rule_data_json).presence || '{}')
  end

  def render_invalid_rule_data
    flash.now[:alert] = 'Rule data was not valid JSON.'
    @system_query ||= SystemQuery.new
    @system_query.errors.add(:rule_data, 'must be valid JSON')
    render(@system_query.persisted? ? :edit : :new, status: :unprocessable_entity)
  end
end
