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

ActiveRecord::Schema[8.1].define(version: 2025_12_14_152150) do
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
  add_foreign_key "subsectors", "sectors"
end
