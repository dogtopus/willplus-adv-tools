require_relative 'op2rpy_settings_enum'
include O2RSettingsEnum

module O2RSettings
    # Set version of opcode (nil == don't set and keep the default)
    # Supported versions: :default (the default), :ymk (variant used by Yume Miru Kusuri and possibly earlier WillPlus games)
    OPCODE_VERSION = nil

    # Include the exact zorder instead of using the natural order. Some games require this for accurate character image placement.
    ACCURATE_ZORDER = true

    # Use at statement-based positioner instead of the original ATL-based positioner to improve analysis performance.
    USE_AT_POSITIONER = true

    # Use the new ATL matrixcolor API for tint() implementation, etc. Requires Ren'Py 7.4 and GL2 renderer.
    USE_ATL_MATRIXCOLOR = true

    # (Reserved) Use GFX helpers that depends on features that are not yet available in stable Ren'Py.
    USE_GFX_NEXT = false

    # Always include disassembly inside the emitted code. Useful for debugging emitter.
    FORCE_INCLUDE_DISASM = true

    RIO_TEXT_ENCODING = 'big5'

    # Replace certain magic symbol substitution characters with standard emoji.
    # NOTE: Disabled by default at this moment since Ren'Py does not correctly handle emojis.
    RESOLVE_EMOJI_SUBSTITUDE = false
    # Select which emoji font to use.
    EMOJI_FONT = 'NotoEmoji-Regular.ttf'
    # Mapping table for emoji substitution.
    EMOJI_TABLE = {
        '＠' => '❤️',
        '＄' => '💧',
        '＃' => '💢',
        '”' => '💦',
        '︼' => '💡',
        '＊' => '💀',
    }

    MOVE_PREVIOUS_SAY_INTO_MENU = true

    # Enable character table lookup
    CHARACTER_TABLE_LOOKUP = true

    # Enable selecting character object by voice name patterns
    CHARACTER_VOICE_MATCH = true

    # Character namespace. Can be nil or a Python name. Will be added to the character object name as a prefix with a dot between the namespace name and character object name. (#{CHARACTER_TABLE_NS}.#{some_chara})
    CHARACTER_TABLE_NS = 'chara'
    CHARACTER_TABLE = {
        'p' => '司',
        'l' => '莉妲',
        'a' => '曉',
        'y' => '邑那',
        'my' => '雅',
        's' => '栖香',
        't' => '殿子',
        'm' => '美綺',
        # 32
        'sn' => '梓乃',
        'ky' => '鏡花',
        'kn' => '奏',
        'yr' => '燕玲',
        'w' => '涉',

    }

    CHARACTER_PROPS = {
        'l' => {'who_color' => '#559b00'},
        'a' => {'who_color' => '#cf7000'},
        'y' => {'who_color' => '#fff52c'},
        'my' => {'who_color' => '#cbc59f'},
        's' => {'who_color' => '#ff4651'},
        't' => {'who_color' => '#9fbcff'},
        'm' => {'who_color' => '#ff3d86'},
        'sn' => {'who_color' => '#ff682f'},
        'ky' => {'who_color' => '#cccccc'},
        'kn' => {'who_color' => '#ffaabf'},
        'yr' => {'who_color' => '#a6003e'},
        'w' => {'who_color' => '#a6cfdc'},
    }

    # Voice name pattern to character mapping. Considered when no CHARACTER_TABLE entry matches the current character.
    CHARACTER_VOICE_MATCHES = {
        /^led_/i => 'l',
        /^aka_/i => 'a',
        /^yun_/i => 'y',
        /^miy_/i => 'my',
        /^sum_/i => 's',
        /^ton_/i => 't',
        /^mis_/i => 'm',
        /^sin_/i => 'sn',
        /^kyu_/i => 'ky',
        /^kan_/i => 'kn',
        /^yen_/i => 'yr',
        /^wat_/i => 'w',
    }

    # Expression that are evaluated when specified procedures are called.
    PROC_EXTRA_EXPR = {}

    # Detect if the animation is wrapped inside a CJMP block that checks if a flag named 'skipping' is 0 or 1. If so only draw the case when the flag is 0.
    # Note that this is a workaround and will likely disappear when proper optimization is implemented in place.
    HACK_DETECT_ANIMATION_SKIP = true

    # Remove orphan with statements (not paired with any show/hide/scene statement)
    REMOVE_ORPHAN_WITH = true

    # Generate code for hentai skip
    # Compatible with https://renpy.org/wiki/renpy/doc/cookbook/Making_adult_scenes_optional
    GEN_HENTAI_SKIP_LOGIC = false

    # Ranges for hentai scenes
    # [[start_label, start_offset, insert_transition], [end_label, end_offset, insert_transition]]
    # WARNING: Replay behavior on hentai scenes are undefined when hentai skip is enabled. So make sure to block replay when hentai skip is enabled by the user. 
    HENTAI_RANGES = []

    # Override explicit images that are not a part of the hentai scene (e.g. flashbacks) to something safe.
    # Note that this does not skip explicit dialogues. Use HENTAI_RANGES without transitions for those.
    # (Maybe add a dedicated entry for those if they are really needed.)
    HENTAI_IMAGE_OVERRIDE = {}

    # Show weather on specified layer, or default if there's no layer specified.
    WEATHER_LAYER = 'weather'

    # Whether or not to only use symbols to reference audio. Set to false makes the generated rpy scripts more portable. Set to true results in less boilerplate but requires change to the default audio file prefixes/suffixes.
    AUDIO_SYMBOL_ONLY = true

    # Respect the volume parameter of audio-related instructions (requires Ren'Py 7.4.0-g1923a40 or later)
    AUDIO_INLINE_VOLUME = true

    # Flagbanks mappings. WARNING: change this after release will cause save incompatibilities.
    FLAG_BANKS = [
        # Double inclusive
        [0, 999, 'will_flagbank'],
        [1000, 3999, 'persistent.will_flagbank'],
    ]

    # Flag table. Change names will not cause save incompatibilities as long as the flag addresses are kept intact.
    # addr => [name, inclusion_policy, category]
    # addr: 16-bit address of the flag.
    # name: The name of the variable. Setting to nil will allow other fields (e.g. inclusion policy) to be specified but keep the flag anonymous.
    # inclusion_policy:
    #   Flag::INCLUDE: Include the flag in the emitted .rpy files with full read/write access.
    #   Flag::EXCLUDE: Exclude the flag in the emitted .rpy files. CJMPs that use it will always be evaluated to false.
    #   Flag::HINT: Similar to Flag::EXCLUDE but inserts a comment instead of completely omitting it.
    # category:
    #   FlagCategory::UNCATEGORIZED: Uncategorized.
    #   FlagCategory::STORY: Story related (i.e. used as a branching condition during the story-telling)
    #   FlagCategory::UNLOCK: Unlocks gallery/event entries
    #   FlagCategory::SYSTEM: Flags used by the infrastructure (non-story) code as temporary or persistent variables.
    FLAG_TABLE = {
        690 => ['tmp_clear_count', Flag::INCLUDE, FlagCategory::SYSTEM],
        691 => ['tmp_epilogue_state', Flag::INCLUDE, FlagCategory::SYSTEM],
        692 => ['skip_to_route_selection', Flag::INCLUDE, FlagCategory::SYSTEM],
        700 => ['cgdisp_page_num', Flag::HINT, FlagCategory::SYSTEM],
        709 => ['has_bgm', Flag::HINT, FlagCategory::SYSTEM],
        720 => ['current_event_id', Flag::INCLUDE, FlagCategory::SYSTEM],
        723 => ['has_bg', Flag::HINT, FlagCategory::SYSTEM],
        756 => ['option_group', Flag::INCLUDE, FlagCategory::SYSTEM],
        762 => ['cutscene_index', Flag::INCLUDE, FlagCategory::SYSTEM],
        763 => ['cutscene_unskippable', Flag::INCLUDE, FlagCategory::SYSTEM],
        765 => ['ctr_cg', Flag::HINT, FlagCategory::SYSTEM], # May not useful since we have len() TODO is it just some temp variable?
        850 => ['has_opt_0', Flag::INCLUDE, FlagCategory::SYSTEM],
        851 => ['has_opt_1', Flag::INCLUDE, FlagCategory::SYSTEM],
        852 => ['has_opt_2', Flag::INCLUDE, FlagCategory::SYSTEM],
        853 => ['has_opt_3', Flag::INCLUDE, FlagCategory::SYSTEM],
        993 => ['typewriter_effect_duration', Flag::HINT, FlagCategory::SYSTEM],
        995 => ['in_event_view_mode', Flag::INCLUDE, FlagCategory::SYSTEM],
        996 => ['performing_transition', Flag::HINT, FlagCategory::SYSTEM],
        998 => ['skipping', Flag::INCLUDE, FlagCategory::SYSTEM],
        1007 => ['first_run', Flag::INCLUDE, FlagCategory::SYSTEM],
        1008 => ['skip_prologue', Flag::INCLUDE, FlagCategory::STORY],
        1010 => ['clear_miyabi', Flag::INCLUDE, FlagCategory::STORY],
        1011 => ['clear_tonoko', Flag::INCLUDE, FlagCategory::STORY],
        1012 => ['clear_shino', Flag::INCLUDE, FlagCategory::STORY],
        1013 => ['clear_sumika', Flag::INCLUDE, FlagCategory::STORY],
        1014 => ['clear_misaki', Flag::INCLUDE, FlagCategory::STORY],
        1015 => ['clear_yuuna', Flag::INCLUDE, FlagCategory::STORY],
        1016 => ['seen_epilogue', Flag::INCLUDE, FlagCategory::STORY],
        1017 => ['seen_epilogue_transition', Flag::INCLUDE, FlagCategory::STORY],
        10007 => ['system_keycode', Flag::HINT, FlagCategory::SYSTEM],
    }
end
