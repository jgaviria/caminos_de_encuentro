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

ActiveRecord::Schema[7.2].define(version: 2025_08_17_220158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "search_profile_id"
    t.string "country", default: "Colombia", null: false
    t.string "state"
    t.string "city"
    t.string "neighborhood"
    t.string "street_address"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_addresses_on_city"
    t.index ["country", "state", "city"], name: "index_addresses_on_location"
    t.index ["country"], name: "index_addresses_on_country"
    t.index ["search_profile_id"], name: "index_addresses_on_search_profile_id"
    t.index ["state"], name: "index_addresses_on_state"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "search_profile_id", null: false
    t.bigint "user_id"
    t.float "similarity_score", default: 0.0
    t.boolean "is_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_matches_on_created_at"
    t.index ["search_profile_id", "similarity_score"], name: "index_matches_on_profile_and_score"
    t.index ["search_profile_id"], name: "index_matches_on_search_profile_id"
    t.index ["search_profile_id"], name: "index_unverified_matches", where: "(is_verified = false)"
    t.index ["similarity_score", "is_verified"], name: "index_matches_on_score_and_verification"
    t.index ["user_id"], name: "index_matches_on_user_id"
  end

  create_table "personal_infos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((first_name)::text), lower((last_name)::text)", name: "index_personal_infos_on_lower_names"
    t.index ["first_name"], name: "index_personal_infos_on_first_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["last_name"], name: "index_personal_infos_on_last_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id"], name: "index_personal_infos_on_user_id"
  end

  create_table "search_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "match_status", default: 0, null: false
    t.integer "match_count", default: 0, null: false
    t.datetime "last_matched_at"
    t.index "lower((first_name)::text), lower((last_name)::text)", name: "index_search_profiles_on_lower_names"
    t.index ["first_name"], name: "index_search_profiles_on_first_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["last_matched_at"], name: "index_search_profiles_on_last_matched_at"
    t.index ["last_name"], name: "index_search_profiles_on_last_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["match_status"], name: "index_search_profiles_on_match_status"
    t.index ["user_id"], name: "index_search_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "addresses", "search_profiles"
  add_foreign_key "addresses", "users"
  add_foreign_key "matches", "search_profiles"
  add_foreign_key "matches", "users"
  add_foreign_key "personal_infos", "users"
  add_foreign_key "search_profiles", "users"
end
