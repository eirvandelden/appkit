class ApplicationController < ActionController::Base
  include Appkit::Authentication
  include Appkit::VersionHeaders

  around_action :switch_locale

  helper_method :menu

  private
    def switch_locale(&action)
      I18n.with_locale(params[:locale] || I18n.default_locale, &action)
    end

    def menu_hubs
      [
        Appkit::Menu::Hub.new(key: :overview, label: "Overview", emoji: "🏠", path: root_path,
          landing: { "controller" => "home" }),
        Appkit::Menu::Hub.new(key: :work, label: "Work", emoji: "🗄️", path: hub_path("work"),
          landing: { "controller" => "hubs", "id" => "work" }, pages: work_pages),
        Appkit::Menu::Hub.new(key: :review, label: "Review", emoji: "📥", path: hub_path("review"),
          landing: { "controller" => "hubs", "id" => "review" }, pages: review_pages)
      ]
    end

    def work_pages
      [
        Appkit::Menu::Page.new(key: :admin, label: "Admin", path: admin_path, controllers: [ "admin" ],
          count: -> { User.where(active: true).count }),
        Appkit::Menu::Page.new(key: :reports, label: "Reports", path: "/reports", controllers: [ "reports" ],
          count: -> { User.where(active: false).count })
      ]
    end

    def review_pages
      [
        Appkit::Menu::Page.new(key: :open_admin, label: "Open admin", path: admin_path(filter: "open"),
          controllers: [ "admin" ], filter: { "filter" => "open" })
      ]
    end

    def menu
      @menu ||= Appkit::Menu.new(hubs: menu_hubs, account: menu_account,
        controller_path: controller_path, params: request.parameters)
    end

    def menu_account
      [ Appkit::Menu::Link.new(label: t("appkit.navigation.preferences"), path: edit_preferences_path) ]
    end
end
