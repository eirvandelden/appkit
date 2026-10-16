module Appkit
  module DeleteConfirmationHelper
    # Renders the `Delete…` button that opens the dialog from
    # appkit/shared/_delete_confirmation. Place the dialog outside any form.
    def delete_confirmation_opener(dialog_id)
      button_tag t("appkit.delete_confirmation.open"),
        type: "button",
        class: "button-danger",
        command: "show-modal",
        commandfor: dialog_id,
        data: { controller: "invoker", action: "invoker#invoke" }
    end
  end
end
