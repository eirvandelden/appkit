# Steep checks this file as a host app would use appkit (the :host target in the Steepfile).
# It is never loaded at runtime.

ApplicationController.allow_unauthenticated_access only: :show
ApplicationController.require_unauthenticated_access
Session.start!(user_agent: nil, ip_address: nil)
Session.expire_stale!
User.find_by_transfer_id("transfer-id")

Appkit.configure do |config|
  config.app_name = "My App"
  config.app_name = -> { "My App" }
  config.app_name = -> { nil }
  config.app_name = -> { :MyApp }
  config.locale_attribute = nil
  config.timezone_attribute = :time_zone
end

link = Appkit::Menu::Link.new(label: "Preferences", path: "/preferences/edit")
page = Appkit::Menu::Page.new(key: :records, label: "Records", path: "/records", controllers: [ "records" ],
  count: -> { 1 })
hub = Appkit::Menu::Hub.new(key: :work, label: "Work", emoji: "🗄️", path: "/hubs/work",
  landing: { "controller" => "hubs", "id" => "work" }, pages: [ page ], action: link)
menu = Appkit::Menu.new(hubs: [ hub ], account: [ link ], controller_path: "records", params: {})
menu.carry("/records")
menu.back("/records")
menu.exit_path("/")
