module Appkit
  class FirstRun
    #: (untyped) -> untyped
    def self.create!(user_params)
      Appkit.config.first_run.call(user_params)
    end
  end
end
