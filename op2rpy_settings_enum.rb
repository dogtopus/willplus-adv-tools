#!/usr/bin/env ruby
module O2RSettingsEnum
    module Flag
        # Include the flag in the emitted .rpy files with full read/write access.
        INCLUDE = 1
        # Exclude the flag in the emitted .rpy files. CJMPs that use it will always be evaluated to false.
        EXCLUDE = 0
        # Similar to Flag::EXCLUDE but inserts a comment instead of completely omitting it.
        HINT = 2
    end
    module FlagCategory
        # Uncategorized.
        UNCATEGORIZED = 0
        # Story related (i.e. used as a branching condition during the story-telling)
        STORY = 1
        # Unlocks gallery/event entries
        UNLOCK = 2
        # Flags used by the infrastructure (non-story) code as temporary or persistent variables.
        SYSTEM = 3
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
