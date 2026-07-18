ActiveRecord::Schema.define(version: 3) do
  create_table :users do |t|
    t.string :name
    t.string :email, null: false
    t.string :password_digest
    t.boolean :active, default: true
    t.integer :role, default: 0, null: false
    t.string :locale, default: "en", null: false
    t.integer :color_scheme, default: 0, null: false
    t.integer :light_theme, default: 1, null: false
    t.integer :dark_theme, default: 1, null: false
    t.string :tz

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

  # Minimal Solid Queue / Solid Cache tables: only what the health checks
  # under test actually query, not the full gem schema (e.g. jobs, executions).
  create_table :solid_queue_processes do |t|
    t.string :kind, null: false
    t.datetime :last_heartbeat_at, null: false
    t.bigint :supervisor_id
    t.integer :pid, null: false
    t.string :hostname
    t.text :metadata
    t.datetime :created_at, null: false
    t.string :name, null: false
  end
  add_index :solid_queue_processes, :last_heartbeat_at

  create_table :solid_cache_entries do |t|
    t.binary :key, limit: 1024, null: false
    t.binary :value, limit: 536870912, null: false
    t.datetime :created_at, null: false
    t.integer :key_hash, limit: 8, null: false
    t.integer :byte_size, limit: 4, null: false
  end
  add_index :solid_cache_entries, :key_hash, unique: true
end
