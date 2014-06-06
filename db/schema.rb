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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130218155109) do

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.string   "redirect_uri"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "entity_id"
  end

  add_index "applications", ["name"], :name => "index_applications_on_name", :unique => true

  create_table "connection_context_protocols", :force => true do |t|
    t.string   "name"
    t.text     "attribute_constraints"
    t.text     "context_constraints"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "connection_context_protocols", ["name"], :name => "index_connection_context_protocols_on_name", :unique => true

  create_table "connection_context_protocols_connection_contexts", :id => false, :force => true do |t|
    t.integer "connection_context_protocol_id"
    t.integer "connection_context_id"
  end

  add_index "connection_context_protocols_connection_contexts", ["connection_context_protocol_id", "connection_context_id"], :name => "conntextion_context_protocol_implementors", :unique => true

  create_table "connection_contexts", :force => true do |t|
    t.string   "name"
    t.boolean  "async"
    t.string   "cardinality"
    t.string   "connection_type"
    t.text     "properties"
    t.integer  "application_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "connection_contexts", ["name"], :name => "index_connection_contexts_on_name"

  create_table "connections", :force => true do |t|
    t.integer  "from_id"
    t.string   "from_type"
    t.integer  "to_id"
    t.string   "to_type"
    t.integer  "context_id"
    t.text     "properties"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "connections", ["context_id"], :name => "index_connections_on_context_id"
  add_index "connections", ["from_type", "from_id"], :name => "index_connections_on_from_type_and_from_id"
  add_index "connections", ["to_type", "to_id"], :name => "index_connections_on_to_type_and_to_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "education_attributes", :force => true do |t|
    t.string   "classyear"
    t.string   "station"
    t.text     "majors"
    t.integer  "school_id"
    t.integer  "user_id"
    t.boolean  "visible",    :default => true
    t.integer  "added_by"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "education_attributes", ["station", "school_id", "user_id"], :name => "index_education_attributes_on_station_and_school_id_and_user_id"
  add_index "education_attributes", ["user_id"], :name => "index_education_attributes_on_user_id"

  create_table "emails", :force => true do |t|
    t.string   "email"
    t.string   "md5_hash"
    t.string   "verification_code"
    t.integer  "user_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "emails", ["email"], :name => "index_emails_on_email", :unique => true
  add_index "emails", ["md5_hash"], :name => "index_emails_on_md5_hash"
  add_index "emails", ["user_id"], :name => "index_emails_on_user_id"
  add_index "emails", ["verification_code"], :name => "index_emails_on_verification_code"

  create_table "entities", :force => true do |t|
    t.string   "uid"
    t.string   "url"
    t.string   "image"
    t.text     "credentials"
    t.text     "properties"
    t.integer  "context_id"
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "entities", ["uid", "context_id"], :name => "index_entities_on_uid_and_context_id", :unique => true

  create_table "entity_contexts", :force => true do |t|
    t.string   "name"
    t.text     "properties"
    t.integer  "application_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "title"
  end

  add_index "entity_contexts", ["name"], :name => "index_entity_contexts_on_name", :unique => true

  create_table "identities", :force => true do |t|
    t.string   "uid"
    t.string   "url"
    t.string   "image"
    t.string   "name"
    t.string   "subtitle"
    t.text     "credentials"
    t.text     "properties"
    t.integer  "user_id"
    t.integer  "context_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "identities", ["uid", "context_id"], :name => "index_identities_on_uid_and_context_id", :unique => true

  create_table "identity_contexts", :force => true do |t|
    t.string   "name"
    t.text     "properties"
    t.integer  "application_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "title"
  end

  add_index "identity_contexts", ["name"], :name => "index_identity_contexts_on_name", :unique => true

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.string   "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",           :null => false
    t.string   "uid",            :null => false
    t.string   "secret",         :null => false
    t.string   "redirect_uri",   :null => false
    t.integer  "application_id", :null => false
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "phones", :force => true do |t|
    t.string   "phone"
    t.integer  "user_id"
    t.string   "verification_code"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "phones", ["phone"], :name => "index_phones_on_phone", :unique => true
  add_index "phones", ["user_id"], :name => "index_phones_on_user_id"
  add_index "phones", ["verification_code"], :name => "index_phones_on_verification_code"

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.text     "body"
    t.string   "title"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.text     "summary",    :default => ""
  end

  create_table "profile_pictures", :force => true do |t|
    t.string   "url"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "profile_pictures", ["url", "user_id"], :name => "index_profile_pictures_on_url_and_user_id", :unique => true
  add_index "profile_pictures", ["user_id"], :name => "index_profile_pictures_on_user_id"

  create_table "recommendations", :force => true do |t|
    t.string   "role"
    t.text     "text"
    t.integer  "connection_in_db_id"
    t.integer  "recommender_id"
    t.integer  "recommended_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "recommendations", ["connection_in_db_id"], :name => "index_recommendations_on_connection_in_db_id", :unique => true
  add_index "recommendations", ["recommender_id", "recommended_id"], :name => "index_recommendations_on_recommender_id_and_recommended_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "password_salt"
    t.string   "password_hash"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.string   "name",               :default => "Anonymous User"
    t.string   "background_picture"
    t.text     "tagline",            :default => ""
  end

  create_table "websites", :force => true do |t|
    t.string   "url"
    t.string   "image"
    t.string   "title"
    t.integer  "user_id"
    t.string   "verification_code"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "websites", ["url"], :name => "index_websites_on_url", :unique => true
  add_index "websites", ["user_id"], :name => "index_websites_on_user_id"
  add_index "websites", ["verification_code"], :name => "index_websites_on_verification_code"

  create_table "work_attributes", :force => true do |t|
    t.string   "title"
    t.text     "summary"
    t.text     "to"
    t.text     "from"
    t.boolean  "current"
    t.integer  "workplace_id"
    t.integer  "user_id"
    t.integer  "added_by"
    t.boolean  "visible",      :default => true
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "work_attributes", ["user_id", "workplace_id", "title"], :name => "index_work_attributes_on_user_id_and_workplace_id_and_title"
  add_index "work_attributes", ["user_id"], :name => "index_work_attributes_on_user_id"

end
