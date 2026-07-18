ActiveRecord::Schema.define(version: 1) do
  create_table :users do |t|
    t.string :name
    t.string :email, null: false
    t.string :password_digest
    t.boolean :active, default: true
    t.integer :role, default: 0, null: false

    t.timestamps
  end
  add_index :users, :email, unique: true

  create_table :sessions do |t|
    t.references :user, null: false, foreign_key: true
    t.string :token, null: false
    t.datetime :last_active_at
    t.string :user_agent
    t.string :ip_address

    t.timestamps
  end
  add_index :sessions, :token, unique: true

  create_table :appkit_push_subscriptions do |t|
    t.references :user, null: false, foreign_key: true
    t.string :endpoint, null: false
    t.string :p256dh_key
    t.string :auth_key
    t.string :user_agent

    t.timestamps
  end
  add_index :appkit_push_subscriptions, :endpoint, unique: true
end
