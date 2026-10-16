require "test_helper"

module Appkit
  class DeleteConfirmationHelperTest < ActionView::TestCase
    include Appkit::DeleteConfirmationHelper

    test "delete_confirmation_opener renders a red type=button naming its dialog" do
      opener = Nokogiri::HTML.fragment(delete_confirmation_opener("delete-dialog")).at_css("button")

      assert_equal "button", opener["type"]
      assert_equal "button-danger", opener["class"]
      assert_equal "show-modal", opener["command"]
      assert_equal "delete-dialog", opener["commandfor"]
      assert_equal "invoker", opener["data-controller"]
      assert_equal "invoker#invoke", opener["data-action"]
    end

    test "opener label is translated with an ellipsis" do
      assert_equal I18n.t("appkit.delete_confirmation.open"),
        Nokogiri::HTML.fragment(delete_confirmation_opener("x")).at_css("button").text
      assert_equal "Delete…", I18n.t("appkit.delete_confirmation.open", locale: :en)
      assert_equal "Verwijderen…", I18n.t("appkit.delete_confirmation.open", locale: :nl)
      assert_equal "Elimina…", I18n.t("appkit.delete_confirmation.open", locale: :it)
    end

    test "dialog footer holds Cancel then a DELETE form" do
      render_dialog

      assert_select "dialog#delete-dialog footer" do
        assert_select "form[method='dialog'] + form[action='/things/1']"
        assert_select "form[action='/things/1'] input[name='_method'][value='delete']"
        assert_select "form[action='/things/1'][data-turbo-frame='_top'] button",
          text: I18n.t("appkit.delete_confirmation.confirm")
      end
      assert_select "dialog p", text: I18n.t("appkit.delete_confirmation.irreversible")
    end

    test "Cancel carries autofocus in a method=dialog form" do
      render_dialog

      assert_select "footer form[method='dialog'] button[autofocus]", text: I18n.t("appkit.delete_confirmation.cancel")
    end

    test "title labels the dialog" do
      render_dialog

      assert_select "dialog#delete-dialog[aria-labelledby='delete-dialog-title']"
      assert_select "dialog h2#delete-dialog-title", text: "Delete Thing?"
    end

    test "confirm dialog keeps its ids inside a footer" do
      render partial: "appkit/shared/confirm_dialog"

      assert_select "dialog#confirm-dialog p#confirm-dialog-message"
      assert_select "dialog#confirm-dialog footer" do
        assert_select "form[method='dialog'] button#confirm-dialog-cancel[autofocus]"
        assert_select "button#confirm-dialog-accept.button-danger"
      end
      assert_select "dialog#confirm-dialog nav", count: 0
    end

    private

    def render_dialog
      render partial: "appkit/shared/delete_confirmation",
        locals: { id: "delete-dialog", url: "/things/1", title: "Delete Thing?" }
    end
  end
end
