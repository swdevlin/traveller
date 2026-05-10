class NetworksController < ApplicationController
  before_action :set_network, only: %i[show edit update destroy export_links]

  def index
    @networks = Network.ordered
  end

  def show
  end

  def new
    @network = Network.new
  end

  def edit
  end

  def create
    @network = Network.new(network_params)

    if @network.save
      redirect_to @network, notice: 'Network committed.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @network.update(network_params)
      redirect_to @network, notice: 'Network updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @network.destroy!
    redirect_to networks_path, notice: 'Network deleted.', status: :see_other
  end

  def export_links
    require 'csv'

    links = @network.network_links
      .includes(from_star_system: :parsec, to_star_system: :parsec)
      .order(:id)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[from_system from_hex to_system to_hex]
      links.each do |link|
        csv << [
          link.from_star_system.name,
          link.from_star_system.parsec.hex_code,
          link.to_star_system.name,
          link.to_star_system.parsec.hex_code
        ]
      end
    end

    send_data csv_data,
              type: 'text/csv',
              disposition: "attachment; filename=\"#{@network.name.parameterize}-links.csv\""
  end

  private

  def set_network
    @network = Network.find(params.expect(:id))
  end

  def network_params
    params.expect(network: [:name, :colour, :max_jump, :known, :notes])
  end
end
