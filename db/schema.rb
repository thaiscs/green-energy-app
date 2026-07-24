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

ActiveRecord::Schema[8.1].define(version: 2026_07_24_183752) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "buildings", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "owner"
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id"
    t.string "type"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_locations_on_external_id", unique: true
    t.index ["type"], name: "index_locations_on_type"
    t.index ["unit_id", "type"], name: "index_locations_on_unit_id_and_type", unique: true
    t.index ["unit_id"], name: "index_locations_on_unit_id"
  end

  create_table "measurements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.bigint "location_id", null: false
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.decimal "value_kwh", precision: 15, scale: 6
    t.index ["location_id", "starts_at"], name: "index_measurements_on_location_id_and_starts_at", unique: true
    t.index ["location_id"], name: "index_measurements_on_location_id"
    t.index ["starts_at"], name: "index_measurements_on_starts_at", using: :brin
  end

  create_table "units", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.datetime "created_at", null: false
    t.string "label"
    t.string "resident_name"
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_units_on_building_id"
  end

  add_foreign_key "locations", "units"
  add_foreign_key "measurements", "locations"
  add_foreign_key "units", "buildings"
end
