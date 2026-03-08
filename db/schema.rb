# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_08_013949) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "allegiances", force: :cascade do |t|
    t.string "background_colour"
    t.string "border_colour"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "legacy_code"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_allegiances_on_code", unique: true
  end

  create_table "facilities", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "traveller_map_code"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_facilities_on_code", unique: true
  end

  create_table "governments", force: :cascade do |t|
    t.integer "code"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "government_type"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_governments_on_code", unique: true
  end

  create_table "law_levels", force: :cascade do |t|
    t.string "armour"
    t.integer "code"
    t.datetime "created_at", null: false
    t.string "criminal_law"
    t.string "economic_law"
    t.text "notes"
    t.string "personal_law"
    t.string "private_law"
    t.datetime "updated_at", null: false
    t.string "weapons"
    t.index ["code"], name: "index_law_levels_on_code", unique: true
  end

  create_table "parsecs", force: :cascade do |t|
    t.jsonb "build_log"
    t.datetime "created_at", null: false
    t.string "label"
    t.string "label_colour"
    t.text "note"
    t.boolean "player_visible", default: false
    t.bigint "sector_id", null: false
    t.float "star_chance", default: 50.0
    t.integer "survey_index", default: 0
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["sector_id", "x", "y"], name: "index_parsecs_on_sector_id_and_x_and_y", unique: true
    t.index ["sector_id"], name: "index_parsecs_on_sector_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.string "abbreviation"
    t.text "build"
    t.jsonb "build_log"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.text "notes"
    t.string "source", default: "manual"
    t.float "star_chance", default: 50.0
    t.datetime "updated_at", null: false
    t.integer "x"
    t.integer "y"
    t.index ["discarded_at"], name: "index_sectors_on_discarded_at"
    t.index ["name"], name: "index_sectors_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["x", "y"], name: "index_sectors_on_x_and_y", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "star_system_facilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "facility_id", null: false
    t.bigint "star_system_id", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_star_system_facilities_on_facility_id"
    t.index ["star_system_id", "facility_id"], name: "index_star_system_facilities_on_star_system_id_and_facility_id", unique: true
    t.index ["star_system_id"], name: "index_star_system_facilities_on_star_system_id"
  end

  create_table "star_system_trade_codes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "star_system_id", null: false
    t.bigint "trade_code_id", null: false
    t.datetime "updated_at", null: false
    t.index ["star_system_id", "trade_code_id"], name: "idx_on_star_system_id_trade_code_id_9139c73bd8", unique: true
    t.index ["star_system_id"], name: "index_star_system_trade_codes_on_star_system_id"
    t.index ["trade_code_id"], name: "index_star_system_trade_codes_on_trade_code_id"
  end

  create_table "star_systems", force: :cascade do |t|
    t.bigint "allegiance_id"
    t.integer "belt_count", default: 0, null: false
    t.jsonb "build_log"
    t.datetime "created_at", null: false
    t.integer "gas_giant_count", default: 0, null: false
    t.bigint "main_world_id"
    t.json "meta"
    t.string "name"
    t.text "notes"
    t.bigint "parsec_id", null: false
    t.integer "survey_index", default: 0
    t.integer "terrestrial_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["allegiance_id"], name: "index_star_systems_on_allegiance_id"
    t.index ["main_world_id"], name: "index_star_systems_on_main_world_id"
    t.index ["name"], name: "index_star_systems_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["parsec_id"], name: "index_star_systems_on_parsec_id"
  end

  create_table "stellar_object_trade_codes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stellar_object_id", null: false
    t.bigint "trade_code_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stellar_object_id", "trade_code_id"], name: "idx_on_stellar_object_id_trade_code_id_0e62e9d1bb", unique: true
    t.index ["stellar_object_id"], name: "index_stellar_object_trade_codes_on_stellar_object_id"
    t.index ["trade_code_id"], name: "index_stellar_object_trade_codes_on_trade_code_id"
  end

  create_table "stellar_objects", force: :cascade do |t|
    t.bigint "allegiance_id"
    t.float "au"
    t.jsonb "build_log"
    t.json "characteristics"
    t.bigint "companion_id"
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.integer "detect_si"
    t.float "diameter"
    t.float "eccentricity"
    t.float "effective_hzco_deviation"
    t.float "inclination"
    t.float "mass"
    t.string "name"
    t.text "notes"
    t.float "orbit"
    t.string "orbit_sequence"
    t.float "orbit_x"
    t.float "orbit_y"
    t.bigint "orbiting_id"
    t.bigint "parsec_id"
    t.string "size_code"
    t.bigint "star_system_id"
    t.integer "survey_index"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "uwp"
    t.index ["allegiance_id"], name: "index_stellar_objects_on_allegiance_id"
    t.index ["companion_id"], name: "index_stellar_objects_on_companion_id"
    t.index ["orbiting_id"], name: "index_stellar_objects_on_orbiting_id"
    t.index ["parsec_id"], name: "index_stellar_objects_on_parsec_id"
    t.index ["star_system_id"], name: "index_stellar_objects_native_sophont", where: "((data ->> 'native_sophont'::text) = 'true'::text)"
    t.index ["star_system_id"], name: "index_stellar_objects_on_star_system_id"
    t.check_constraint "type::text = 'Star'::text OR (parsec_id IS NULL) <> (orbiting_id IS NULL)", name: "stellar_objects_parsec_xor_orbiting_present"
  end

  create_table "subsectors", force: :cascade do |t|
    t.string "abbreviation"
    t.text "build"
    t.jsonb "build_log"
    t.datetime "created_at", null: false
    t.string "name"
    t.text "notes"
    t.bigint "sector_id", null: false
    t.float "star_chance", default: 50.0
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["name"], name: "index_subsectors_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["sector_id", "x", "y"], name: "index_subsectors_on_sector_id_and_x_and_y", unique: true
    t.index ["sector_id"], name: "index_subsectors_on_sector_id"
  end

  create_table "tech_levels", force: :cascade do |t|
    t.string "air"
    t.integer "code"
    t.datetime "created_at", null: false
    t.string "electronics"
    t.string "energy"
    t.string "environmental"
    t.string "heavy_military"
    t.string "land"
    t.string "manufacturing"
    t.string "medical"
    t.string "notes"
    t.string "personal_military"
    t.string "sea"
    t.string "space"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tech_levels_on_code", unique: true
  end

  create_table "trade_codes", force: :cascade do |t|
    t.string "code", limit: 2, null: false
    t.datetime "created_at", null: false
    t.string "definition", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_trade_codes_on_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "parsecs", "sectors", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "star_system_facilities", "facilities", on_delete: :cascade
  add_foreign_key "star_system_facilities", "star_systems", on_delete: :cascade
  add_foreign_key "star_system_trade_codes", "star_systems", on_delete: :cascade
  add_foreign_key "star_system_trade_codes", "trade_codes", on_delete: :cascade
  add_foreign_key "star_systems", "allegiances", on_delete: :nullify
  add_foreign_key "star_systems", "parsecs", on_delete: :cascade
  add_foreign_key "star_systems", "stellar_objects", column: "main_world_id", on_delete: :nullify
  add_foreign_key "stellar_object_trade_codes", "stellar_objects", on_delete: :cascade
  add_foreign_key "stellar_object_trade_codes", "trade_codes", on_delete: :cascade
  add_foreign_key "stellar_objects", "allegiances", on_delete: :nullify
  add_foreign_key "stellar_objects", "parsecs", on_delete: :cascade
  add_foreign_key "stellar_objects", "star_systems", on_delete: :cascade
  add_foreign_key "stellar_objects", "stellar_objects", column: "companion_id", on_delete: :nullify
  add_foreign_key "stellar_objects", "stellar_objects", column: "orbiting_id", on_delete: :cascade
  add_foreign_key "subsectors", "sectors", on_delete: :cascade
end
