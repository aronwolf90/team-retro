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

ActiveRecord::Schema[8.1].define(version: 2026_10_07_220846) do
  create_table "boards", force: :cascade do |t|
    t.string "name", null: false
    t.integer "max_votes", default: 6, null: false
    t.boolean "hide_votes", default: false, null: false
    t.string "sort_by", default: "order", null: false
    t.datetime "timer_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "hidden_lanes", default: "[]", null: false
    t.boolean "icebreaker", default: false, null: false
    t.boolean "how_is_everyone", default: true, null: false
  end

  create_table "cards", force: :cascade do |t|
    t.integer "board_id", null: false
    t.integer "lane", default: 0, null: false
    t.text "content", null: false
    t.string "author_name"
    t.string "author_token"
    t.integer "position", default: 0, null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "lane", "position"], name: "index_cards_on_board_id_and_lane_and_position"
    t.index ["board_id"], name: "index_cards_on_board_id"
    t.index ["parent_id"], name: "index_cards_on_parent_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.integer "card_id", null: false
    t.string "emoji", null: false
    t.string "user_name"
    t.string "user_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "emoji", "user_token"], name: "index_reactions_on_card_id_and_emoji_and_user_token", unique: true
    t.index ["card_id"], name: "index_reactions_on_card_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "card_id", null: false
    t.string "voter_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "voter_token"], name: "index_votes_on_card_id_and_voter_token"
    t.index ["card_id"], name: "index_votes_on_card_id"
  end

  add_foreign_key "cards", "boards"
  add_foreign_key "cards", "cards", column: "parent_id"
  add_foreign_key "reactions", "cards"
  add_foreign_key "votes", "cards"
end
