ActiveRecord::Schema.define(version: 20170619120400) do
  create_table "books", force: :cascade do |t|
    t.string   "name"
    t.integer  "pages"
    t.datetime "published"
  end

  create_table "companies", force: :cascade do |t|
    t.boolean "dummy"
    t.string  "database"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "birthdate"
    t.string   "sex"
  end
end
