# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160201230826) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "deeds", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "category"
    t.text     "description"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "avatar_fingerprint"
    t.integer  "tx_id"
    t.string   "tx_hash"
    t.string   "issuer"
    t.string   "avatar_url"
    t.string   "extension"
    t.string   "tx_raw"
    t.string   "upload"
    t.integer  "issuer_id"
  end

  create_table "issuers", force: :cascade do |t|
    t.string   "name"
    t.string   "batch"
    t.string   "mpk"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "email"
    t.integer  "category"
    t.integer  "credit"
  end

  create_table "viewers", force: :cascade do |t|
    t.string   "email"
    t.integer  "deed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "access_key"
  end

end
