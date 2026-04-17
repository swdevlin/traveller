class CommunicationNetworksController < ApplicationController
  before_action :set_communication_network, only: %i[show edit update destroy export_links]

  def index
    @communication_networks = CommunicationNetwork.ordered
  end

  def show
  end

  def new
    @communication_network = CommunicationNetwork.new
  end

  def edit
  end

  def create
    @communication_network = CommunicationNetwork.new(communication_network_params)

    if @communication_network.save
      redirect_to @communication_network, notice: 'Communication network committed.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @communication_network.update(communication_network_params)
      redirect_to @communication_network, notice: 'Communication network updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @communication_network.destroy!
    redirect_to communication_networks_path, notice: 'Communication network deleted.', status: :see_other
  end

  def export_links
    require 'csv'

    links = @communication_network.network_links
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
              disposition: "attachment; filename=\"#{@communication_network.name.parameterize}-links.csv\""
  end

  private

  def set_communication_network
    @communication_network = CommunicationNetwork.find(params.expect(:id))
  end

  def communication_network_params
    params.expect(communication_network: [:name, :colour, :max_jump, :known, :notes])
  end
end
