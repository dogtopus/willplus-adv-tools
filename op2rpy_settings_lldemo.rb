require_relative 'op2rpy_settings_enum'
include O2RSettingsEnum

module O2RSettings
    # Set version of opcode (nil == don't set and keep the default)
    # Supported versions: :default (the default), :ymk (variant used by Yume Miru Kusuri and possibly earlier WillPlus games)
    OPCODE_VERSION = nil

    # Include the exact zorder instead of using the natural order. Some games require this for accurate character image placement.
    ACCURATE_ZORDER = false

    # Use at statement-based positioner instead of the original ATL-based positioner to improve analysis performance.
    USE_AT_POSITIONER = true

    # Use the new ATL matrixcolor API for tint() implementation, etc. Requires Ren'Py 7.4 and GL2 renderer.
    USE_ATL_MATRIXCOLOR = true

    # (Reserved) Use GFX helpers that depends on features that are not yet available in stable Ren'Py.
    USE_GFX_NEXT = false

    # Always include disassembly inside the emitted code. Useful for debugging emitter.
    FORCE_INCLUDE_DISASM = true

    RIO_TEXT_ENCODING = 'shift_jis'

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
    CHARACTER_VOICE_MATCH = false
    # Character namespace. Can be nil or a Python name. Will be added to the character object name as a prefix with a dot between the namespace name and character object name. (#{CHARACTER_TABLE_NS}.#{some_chara})
    CHARACTER_TABLE_NS = 'chara'
    CHARACTER_TABLE = {
        'd' => 'ディック',
        'i' => 'ヨアン',
        'r' => 'ロディ',
        't' => 'トマ',
        'p' => 'ピエール',
        'gu' => 'ギュレッド',
        'x' => '？？？',
    }

    CHARACTER_PROPS = {
        'd' => {'who_color' => '#ff4b4b'},
        'i' => {'who_color' => '#d154cb'},
        'r' => {'who_color' => '#ffae4c'},
        't' => {'who_color' => '#b8864d'},
        'p' => {'who_color' => '#b5003f'},
        'c' => {'who_color' => '#ffff00'},
        'a' => {'who_color' => '#9fff6e'},
        'da' => {'who_color' => '#de9658'},
        'gr' => {'who_color' => '#7578ff'},
        'gu' => {'who_color' => '#8e3eae'},
        's' => {'who_color' => '#a2faff'},
        'n' => {'who_color' => '#49ff55'},
        'l' => {'who_color' => '#ffa5a3'},
        'l2' => {'who_color' => '#ffa5a3'},
        'o' => {'who_color' => '#d8d800'},
        'z' => {'who_color' => '#6e53ff'},
        'x' => {'who_color' => '#7f7f7f'},
    }

    # Expression that are evaluated when specified procedures are called.
    PROC_EXTRA_EXPR = {
        'LIST_VIW' => "@gfx[:fg][3] = WillPlusStubDisplayable.new('screen gem_37564_sacrifice_list')"
    }

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
        [1000, 2999, 'persistent.will_flagbank'],
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
        1 => ['help_biscal', Flag::INCLUDE, FlagCategory::STORY],
        2 => ['dessert_house', Flag::INCLUDE, FlagCategory::STORY],
        3 => ['gem_37564_first_seen', Flag::INCLUDE, FlagCategory::STORY],
        4 => ['gem_37564_seen_again', Flag::INCLUDE, FlagCategory::STORY],
        7 => ['sergi_knew_dick_turned_blue', Flag::INCLUDE, FlagCategory::STORY],
        9 => ['aby_escaped', Flag::INCLUDE, FlagCategory::STORY],
        21 => ['did_target_practice', Flag::INCLUDE, FlagCategory::STORY],
        22 => ['called_guillered', Flag::INCLUDE, FlagCategory::STORY],
        23 => ['rescue_cornel', Flag::INCLUDE, FlagCategory::STORY],
        43 => ['asked_roddy_for_dinner', Flag::INCLUDE, FlagCategory::STORY],
        47 => ['met_ioan_d4_am', Flag::INCLUDE, FlagCategory::STORY],
        48 => ['i_o_a_northbrook', Flag::INCLUDE, FlagCategory::STORY],
        51 => ['spent_night_w_sergi', Flag::INCLUDE, FlagCategory::STORY],
        52 => ['sergi_wants_to_go_back', Flag::INCLUDE, FlagCategory::STORY],
        170 => ['aff_roddy', Flag::INCLUDE, FlagCategory::STORY],
        171 => ['aff_ioan', Flag::INCLUDE, FlagCategory::STORY],
        172 => ['aff_greg', Flag::INCLUDE, FlagCategory::STORY],
        173 => ['aff_sergi', Flag::INCLUDE, FlagCategory::STORY],
        174 => ['aff_dag', Flag::INCLUDE, FlagCategory::STORY],
        175 => ['aff_cornel', Flag::INCLUDE, FlagCategory::STORY],
        176 => ['aff_guillered', Flag::INCLUDE, FlagCategory::STORY],
        180 => ['gem_37564', Flag::INCLUDE, FlagCategory::STORY],
        181 => ['house', Flag::INCLUDE, FlagCategory::STORY],
        199 => ['gem_37564_more_people_ded', Flag::INCLUDE, FlagCategory::STORY],
        200 => ['gem_37564_dad_ded', Flag::INCLUDE, FlagCategory::STORY],
        201 => ['gem_37564_mom_ded', Flag::INCLUDE, FlagCategory::STORY],
        202 => ['gem_37564_brother_ded', Flag::INCLUDE, FlagCategory::STORY],
        203 => ['gem_37564_sister_ded', Flag::INCLUDE, FlagCategory::STORY],
        204 => ['gem_37564_neighbor_girl_ded', Flag::INCLUDE, FlagCategory::STORY],
        205 => ['gem_37564_neighbor_boy_ded', Flag::INCLUDE, FlagCategory::STORY],
        206 => ['gem_37564_classmate_0_ded', Flag::INCLUDE, FlagCategory::STORY],
        207 => ['gem_37564_classmate_1_ded', Flag::INCLUDE, FlagCategory::STORY],
        208 => ['gem_37564_classmate_2_ded', Flag::INCLUDE, FlagCategory::STORY],
        209 => ['gem_37564_classmate_3_ded', Flag::INCLUDE, FlagCategory::STORY],
        211 => ['disp_list', Flag::INCLUDE, FlagCategory::SYSTEM],
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
        970 => ['gem_maturity', Flag::INCLUDE, FlagCategory::STORY],
        990 => ['list_related', Flag::HINT, FlagCategory::SYSTEM], # Purpose unknown
        1004 => ['seen_ending_cutscene', Flag::INCLUDE, FlagCategory::SYSTEM],
        1007 => ['first_run', Flag::INCLUDE, FlagCategory::SYSTEM],
        1008 => ['clear_r0', Flag::INCLUDE, FlagCategory::STORY],
        1009 => ['clear_r2', Flag::INCLUDE, FlagCategory::STORY],
        1010 => ['clear_r3', Flag::INCLUDE, FlagCategory::STORY],
        1011 => ['blickwinkel', Flag::INCLUDE, FlagCategory::STORY],
        1012 => ['unlock_r0_roddy', Flag::INCLUDE, FlagCategory::STORY],
        1013 => ['seen_leesha', Flag::INCLUDE, FlagCategory::STORY],
        1014 => ['clear_r0_ioan', Flag::INCLUDE, FlagCategory::STORY],
        1015 => ['re_welcome_to_laughter_land', Flag::INCLUDE, FlagCategory::STORY],
        1100 => ['unlock_gallery', Flag::INCLUDE, FlagCategory::UNLOCK, 79],
        1200 => ['unlock_image', Flag::INCLUDE, FlagCategory::UNLOCK, 168],
        1400 => ['unlock_replay', Flag::INCLUDE, FlagCategory::UNLOCK, 25],
        1430 => ['replay_bgm_store', Flag::INCLUDE, FlagCategory::SYSTEM, 25],
        10007 => ['system_keycode', Flag::HINT, FlagCategory::SYSTEM],
    }
end
