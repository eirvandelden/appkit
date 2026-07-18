require "test_helper"

module Appkit
  class FlashesTest < ActionView::TestCase
    test "renders a notice with role status and an alert with role alert inside the flashes section" do
      @controller.request.flash[:notice] = "Saved"
      @controller.request.flash[:alert] = "Something went wrong"

      render partial: "appkit/shared/flashes"

      assert_select "section[data-mvpa-flashes]" do
        assert_select "aside[role='status']", text: "Saved"
        assert_select "aside[role='alert']", text: "Something went wrong"
      end
    end

    test "renders nothing when flash is empty" do
      render partial: "appkit/shared/flashes"

      assert_select "section[data-mvpa-flashes]", count: 0
    end
  end
end
