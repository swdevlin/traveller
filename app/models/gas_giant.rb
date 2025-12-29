class GasGiant < StellarObject
  store_accessor :data, :code, :has_ring

  def self.allowed_data_keys
    [:code, :has_ring]
  end
end
