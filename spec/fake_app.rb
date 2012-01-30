require 'active_record'
require 'action_controller'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_view/context'

require "cancan"
require "cancan/ability"
require "cancan/controller_resource"
require "cancan/controller_additions"

require 'devise'
require 'devise/orm/active_record'

# database
ActiveRecord::Base.configurations = {'test' => {:adapter => 'postgresql', :database => 'polemic_test', :username => "postgres"}}
# ActiveRecord::Base.configurations = {'test' => {:adapter => 'sqlite3', :database => ':memory:'}}
ActiveRecord::Base.establish_connection('test')

require 'devise_config'

# config
app = Class.new(Rails::Application)
app.config.secret_token = "3b7cd727ee24e8444053437c36cc66c4"
app.config.session_store :cookie_store, :key => "_myapp_session"
app.config.active_support.deprecation = :log
app.initialize!

# models
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name
  validates :name, :presence => true
end

class Post < ActiveRecord::Base
  validates :title, :user, :body, :presence => true
  has_polemic
  belongs_to :user
end

# routes
app.routes.draw do
  devise_for :users
end

#migrations
ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define :version => 0 do
    create_table "users", :force => true do |t|
      t.string   "email",                                 :default => "", :null => false
      t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                         :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name"
    end
    
    create_table "comments", :force => true do |t|
      t.integer  "commentable_id"
      t.string   "commentable_type"
      t.text     "body"
      t.integer  "user_id"
      t.string   "ancestry"
      t.boolean  "deleted",          :default => false
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
    end
    
    create_table "posts", :force => true do |t|
      t.string   "title"
      t.text     "body"
      t.integer  "user_id"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
    end
  end
end

# controllers
class ApplicationController < ActionController::Base
  before_filter :assign_unread_discussions
  
  private
  
  def assign_unread_discussions
    @unread_discussions_count = Discussion.unread_for(current_user).count if user_signed_in?
  end
end

# helpers
Object.const_set(:ApplicationHelper, Module.new)