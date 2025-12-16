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

ActiveRecord::Schema[8.1].define(version: 2025_12_15_231748) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "parsecs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sector_id", null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["sector_id", "x", "y"], name: "index_parsecs_on_sector_id_and_x_and_y", unique: true
    t.index ["sector_id"], name: "index_parsecs_on_sector_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "x"
    t.integer "y"
    t.index ["x", "y"], name: "index_sectors_on_x_and_y", unique: true
  end

  create_table "solar_systems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "meta"
    t.string "name"
    t.integer "parsec_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parsec_id"], name: "index_solar_systems_on_parsec_id"
  end

  create_table "stellar_objects", force: :cascade do |t|
    t.json "characteristics"
    t.datetime "created_at", null: false
    t.float "diameter"
    t.float "eccentricity"
    t.float "effective_hzco_deviation"
    t.float "inclination"
    t.float "mass"
    t.string "name"
    t.text "notes"
    t.float "orbit"
    t.integer "orbit_x"
    t.integer "orbit_y"
    t.bigint "orbiting_id"
    t.bigint "parsec_id"
    t.bigint "solar_system_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["orbiting_id"], name: "index_stellar_objects_on_orbiting_id"
    t.index ["parsec_id"], name: "index_stellar_objects_on_parsec_id"
    t.index ["solar_system_id"], name: "index_stellar_objects_on_solar_system_id"
    t.check_constraint "parsec_id IS NOT NULL OR solar_system_id IS NOT NULL", name: "stellar_objects_parsec_or_solar_system_present"
  end

  create_table "subsectors", force: :cascade do |t|
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "sector_id", null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["sector_id", "x", "y"], name: "index_subsectors_on_sector_id_and_x_and_y", unique: true
    t.index ["sector_id"], name: "index_subsectors_on_sector_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "parsecs", "sectors"
  add_foreign_key "solar_systems", "parsecs"
  add_foreign_key "stellar_objects", "parsecs"
  add_foreign_key "stellar_objects", "solar_systems"
  add_foreign_key "stellar_objects", "stellar_objects", column: "orbiting_id"
  add_foreign_key "subsectors", "sectors"
end
