# frozen_string_literal: true

# Fixed Trade Goods table (Mongoose Traveller 2e Core Rulebook, p.244-245) — a
# D66 roll table of speculative trade goods. This data is not campaign-overridable
# (see TradeGoodPrices for the one exception, Base Price); only Base Price may be
# tuned per campaign, matching how FreightTrafficTable's dice-code lookup is fixed
# while FreightTrafficDms's values are campaign-overridable.
#
# Purchase/Sale DM keys use this app's 2-letter trade codes (db/seed_data/mgt2_trade_codes.rb)
# plus two synthetic keys, 'ZA'/'ZR', for Amber/Red Travel Zone DMs (zones are not
# TradeCode records — they live on StarSystem#travel_zone).
#
# Exotics (D66 66) has no Tons/Base Price/DM data in the sourcebook — it is pure
# flavour text ("outside the normal trade rules... a matter for roleplaying and
# adventure") — so it carries base_price: nil and empty DM hashes; callers must
# treat a nil base_price as "no price can be computed".
module TradeGoodsTable
  GOODS = [
    { d66: 11, name: 'Common Electronics', category: :common, availability: :all, tons_dice: [2, 10],
      base_price: 20_000, purchase_dms: { 'In' => 2, 'Ht' => 3, 'Ri' => 1 },
      sale_dms: { 'Ni' => 2, 'Lt' => 1, 'Po' => 1 },
      examples: 'Simple electronics including basic computers up to TL10' },
    { d66: 12, name: 'Common Industrial Goods', category: :common, availability: :all, tons_dice: [2, 10],
      base_price: 10_000, purchase_dms: { 'Na' => 2, 'In' => 5 }, sale_dms: { 'Ni' => 3, 'Ag' => 2 },
      examples: 'Machine components and spare parts for common machinery' },
    { d66: 13, name: 'Common Manufactured Goods', category: :common, availability: :all, tons_dice: [2, 10],
      base_price: 20_000, purchase_dms: { 'Na' => 2, 'In' => 5 }, sale_dms: { 'Ni' => 3, 'Hi' => 2 },
      examples: 'Household appliances, clothing and so forth' },
    { d66: 14, name: 'Common Raw Materials', category: :common, availability: :all, tons_dice: [2, 20],
      base_price: 5_000, purchase_dms: { 'Ag' => 3, 'Ga' => 2 }, sale_dms: { 'In' => 2, 'Po' => 2 },
      examples: 'Metal, plastics, chemicals and other basic materials' },
    { d66: 15, name: 'Common Consumables', category: :common, availability: :all, tons_dice: [2, 20],
      base_price: 500, purchase_dms: { 'Ag' => 3, 'Wa' => 2, 'Ga' => 1, 'As' => -4 },
      sale_dms: { 'As' => 1, 'Fl' => 1, 'Ic' => 1, 'Hi' => 1 },
      examples: 'Food, drink and other agricultural products' },
    { d66: 16, name: 'Common Ore', category: :common, availability: :all, tons_dice: [2, 20],
      base_price: 1_000, purchase_dms: { 'As' => 4 }, sale_dms: { 'In' => 3, 'Ni' => 1 },
      examples: 'Ore bearing common metals' },
    { d66: 21, name: 'Advanced Electronics', category: :trade, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 100_000, purchase_dms: { 'In' => 2, 'Ht' => 3 }, sale_dms: { 'Ni' => 1, 'Ri' => 2, 'As' => 3 },
      examples: 'Advanced sensors, computers and other electronics up to TL15' },
    { d66: 22, name: 'Advanced Machine Parts', category: :trade, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 75_000, purchase_dms: { 'In' => 2, 'Ht' => 1 }, sale_dms: { 'As' => 2, 'Ni' => 1 },
      examples: 'Machine components and spare parts, including gravitic components' },
    { d66: 23, name: 'Advanced Manufactured Goods', category: :trade, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 100_000, purchase_dms: { 'In' => 1 }, sale_dms: { 'Hi' => 1, 'Ri' => 2 },
      examples: 'Devices and clothing incorporating advanced technologies' },
    { d66: 24, name: 'Advanced Weapons', category: :trade, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 150_000, purchase_dms: { 'Ht' => 2 }, sale_dms: { 'Po' => 1, 'ZA' => 2, 'ZR' => 4 },
      examples: 'Firearms, explosives, ammunition, artillery and other military-grade weaponry' },
    { d66: 25, name: 'Advanced Vehicles', category: :trade, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 180_000, purchase_dms: { 'Ht' => 2 }, sale_dms: { 'As' => 2, 'Ri' => 2 },
      examples: 'Air/rafts, spacecraft, grav tanks and other vehicles up to TL15' },
    { d66: 26, name: 'Biochemicals', category: :trade, availability: %w[Ag Wa], tons_dice: [1, 5],
      base_price: 50_000, purchase_dms: { 'Ag' => 1, 'Wa' => 2 }, sale_dms: { 'In' => 2 },
      examples: 'Biofuels, organic chemicals, extracts' },
    { d66: 31, name: 'Crystals & Gems', category: :trade, availability: %w[As De Ic], tons_dice: [1, 5],
      base_price: 20_000, purchase_dms: { 'As' => 2, 'De' => 1, 'Ic' => 1 }, sale_dms: { 'In' => 3, 'Ri' => 2 },
      examples: 'Diamonds, synthetic or natural gemstones' },
    { d66: 32, name: 'Cybernetics', category: :trade, availability: %w[Ht], tons_dice: [1, 1],
      base_price: 250_000, purchase_dms: { 'Ht' => 1 }, sale_dms: { 'As' => 1, 'Ic' => 1, 'Ri' => 2 },
      examples: 'Cybernetic components, replacement limbs' },
    { d66: 33, name: 'Live Animals', category: :trade, availability: %w[Ag Ga], tons_dice: [1, 10],
      base_price: 10_000, purchase_dms: { 'Ag' => 2 }, sale_dms: { 'Lo' => 3 },
      examples: 'Riding animals, beasts of burden, exotic pets' },
    { d66: 34, name: 'Luxury Consumables', category: :trade, availability: %w[Ag Ga Wa], tons_dice: [1, 10],
      base_price: 20_000, purchase_dms: { 'Ag' => 2, 'Wa' => 1 }, sale_dms: { 'Ri' => 2, 'Hi' => 2 },
      examples: 'Rare foods, fine liquors' },
    { d66: 35, name: 'Luxury Goods', category: :trade, availability: %w[Hi], tons_dice: [1, 1],
      base_price: 200_000, purchase_dms: { 'Hi' => 1 }, sale_dms: { 'Ri' => 4 },
      examples: 'Rare or extremely high-quality manufactured goods' },
    { d66: 36, name: 'Medical Supplies', category: :trade, availability: %w[Ht Hi], tons_dice: [1, 5],
      base_price: 50_000, purchase_dms: { 'Ht' => 2 }, sale_dms: { 'In' => 2, 'Po' => 1, 'Ri' => 1 },
      examples: 'Diagnostic equipment, basic drugs, cloning technology' },
    { d66: 41, name: 'Petrochemicals', category: :trade, availability: %w[De Fl Ic Wa], tons_dice: [1, 10],
      base_price: 10_000, purchase_dms: { 'De' => 2 }, sale_dms: { 'In' => 2, 'Ag' => 1, 'Lt' => 2 },
      examples: 'Oil, liquid fuels' },
    { d66: 42, name: 'Pharmaceuticals', category: :trade, availability: %w[As De Hi Wa], tons_dice: [1, 1],
      base_price: 100_000, purchase_dms: { 'As' => 2, 'Hi' => 1 }, sale_dms: { 'Ri' => 2, 'Lt' => 1 },
      examples: 'Drugs, medical supplies, anagathics, fast or slow drugs' },
    { d66: 43, name: 'Polymers', category: :trade, availability: %w[In], tons_dice: [1, 10],
      base_price: 7_000, purchase_dms: { 'In' => 1 }, sale_dms: { 'Ri' => 2, 'Ni' => 1 },
      examples: 'Plastics and other synthetics' },
    { d66: 44, name: 'Precious Metals', category: :trade, availability: %w[As De Ic Fl], tons_dice: [1, 1],
      base_price: 50_000, purchase_dms: { 'As' => 3, 'De' => 1, 'Ic' => 2 }, sale_dms: { 'Ri' => 3, 'In' => 2, 'Ht' => 1 },
      examples: 'Gold, silver, platinum, rare elements' },
    { d66: 45, name: 'Radioactives', category: :trade, availability: %w[As De Lo], tons_dice: [1, 1],
      base_price: 1_000_000, purchase_dms: { 'As' => 2, 'Lo' => 2 },
      sale_dms: { 'In' => 3, 'Ht' => 1, 'Ni' => -2, 'Ag' => -3 },
      examples: 'Uranium, plutonium, unobtanium, rare elements' },
    { d66: 46, name: 'Robots', category: :trade, availability: %w[In], tons_dice: [1, 5],
      base_price: 400_000, purchase_dms: { 'In' => 1 }, sale_dms: { 'Ag' => 2, 'Ht' => 1 },
      examples: 'Industrial and personal robots and drones' },
    { d66: 51, name: 'Spices', category: :trade, availability: %w[Ga De Wa], tons_dice: [1, 10],
      base_price: 6_000, purchase_dms: { 'De' => 2 }, sale_dms: { 'Hi' => 2, 'Ri' => 3, 'Po' => 3 },
      examples: 'Preservatives, luxury food additives, natural drugs' },
    { d66: 52, name: 'Textiles', category: :trade, availability: %w[Ag Ni], tons_dice: [1, 20],
      base_price: 3_000, purchase_dms: { 'Ag' => 7 }, sale_dms: { 'Hi' => 3, 'Na' => 2 },
      examples: 'Clothing and fabrics' },
    { d66: 53, name: 'Uncommon Ore', category: :trade, availability: %w[As Ic], tons_dice: [1, 20],
      base_price: 5_000, purchase_dms: { 'As' => 4 }, sale_dms: { 'In' => 3, 'Ni' => 1 },
      examples: 'Ore containing precious or valuable metals' },
    { d66: 54, name: 'Uncommon Raw Materials', category: :trade, availability: %w[Ag De Wa], tons_dice: [1, 10],
      base_price: 20_000, purchase_dms: { 'Ag' => 2, 'Wa' => 1 }, sale_dms: { 'In' => 2, 'Ht' => 1 },
      examples: 'Valuable metals like titanium, rare elements' },
    { d66: 55, name: 'Wood', category: :trade, availability: %w[Ag Ga], tons_dice: [1, 20],
      base_price: 1_000, purchase_dms: { 'Ag' => 6 }, sale_dms: { 'Ri' => 2, 'In' => 1 },
      examples: 'Hard or beautiful woods and plant extracts' },
    { d66: 56, name: 'Vehicles', category: :trade, availability: %w[In Ht], tons_dice: [1, 10],
      base_price: 15_000, purchase_dms: { 'In' => 2, 'Ht' => 1 }, sale_dms: { 'Ni' => 2, 'Hi' => 1 },
      examples: 'Wheeled, tracked and other vehicles from TL10 or lower' },
    { d66: 61, name: 'Illegal Biochemicals', category: :illegal, availability: %w[Ag Wa], tons_dice: [1, 5],
      base_price: 50_000, purchase_dms: { 'Wa' => 2 }, sale_dms: { 'In' => 6 },
      examples: 'Dangerous chemicals, extracts from endangered species' },
    { d66: 62, name: 'Cybernetics, Illegal', category: :illegal, availability: %w[Ht], tons_dice: [1, 1],
      base_price: 250_000, purchase_dms: { 'Ht' => 1 },
      sale_dms: { 'As' => 4, 'Ic' => 4, 'Ri' => 8, 'ZA' => 6, 'ZR' => 6 },
      examples: 'Combat cybernetics, illegal enhancements' },
    { d66: 63, name: 'Drugs, Illegal', category: :illegal, availability: %w[As De Hi Wa], tons_dice: [1, 1],
      base_price: 100_000, purchase_dms: { 'As' => 1, 'De' => 1, 'Ga' => 1, 'Wa' => 1 },
      sale_dms: { 'Ri' => 6, 'Hi' => 6 },
      examples: 'Addictive drugs, combat drugs' },
    { d66: 64, name: 'Luxuries, Illegal', category: :illegal, availability: %w[Ag Ga Wa], tons_dice: [1, 1],
      base_price: 50_000, purchase_dms: { 'Ag' => 2, 'Wa' => 1 }, sale_dms: { 'Ri' => 6, 'Hi' => 4 },
      examples: 'Debauched or addictive luxuries' },
    { d66: 65, name: 'Weapons, Illegal', category: :illegal, availability: %w[In Ht], tons_dice: [1, 5],
      base_price: 150_000, purchase_dms: { 'Ht' => 2 }, sale_dms: { 'Po' => 6, 'ZA' => 8, 'ZR' => 10 },
      examples: 'Weapons of mass destruction, naval weapons' },
    { d66: 66, name: 'Exotics', category: :exotic, availability: [], tons_dice: nil,
      base_price: nil, purchase_dms: {}, sale_dms: {},
      examples: 'Alien relics, prototype technology, unique plant or animal life, priceless treasures ' \
                'and so forth. Buying and selling exotic goods is a matter for roleplaying and adventure.' }
  ].sort_by { |row| row[:d66] }.freeze

  # @param d66 [Integer]
  # @return [Hash, nil]
  def self.for(d66)
    GOODS.find { |row| row[:d66] == d66.to_i }
  end

  def self.all
    GOODS
  end

  # @return [Array<Integer>] every d66 code except Exotics (66), which has no price to override
  def self.priceable_d66_codes
    GOODS.reject { |row| row[:base_price].nil? }.map { |row| row[:d66] }
  end
end
