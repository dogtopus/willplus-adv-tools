#!/usr/bin/env ruby
module O2RSettingsEnum
    module Flag
        INCLUDE = 1
        EXCLUDE = 0
        HINT = 2
    end
    module SubstType
        # Ignore this entry
        DISABLED = 0
        # Do nothing. Suitable for "naturally" returning to main menu
        NO_OP = 1
        # Redirect to another call
        REDIR = 2
    end
end # O2RSettingsEnum
