require_relative 'op2rpy_settings_enum'
include O2RSettingsEnum

module O2RSettings
    # Always include disassembly inside the emitted code. Useful for debugging emitter.
    FORCE_INCLUDE_DISASM = true

    RIO_TEXT_ENCODING = 'big5'

    MOVE_PREVIOUS_SAY_INTO_MENU = true

    CHARACTER_TABLE_LOOKUP = false
    CHARACTER_TABLE = {
        'd' => '迪克',
        'i' => '伊恩',
        'r' => '羅迪',
        't' => '托瑪',
        'p' => '皮耶',
        'c' => '柯奈爾',
        'a' => '艾比',
        'da' => '道格',
        'gr' => '葛列格',
        'gu' => '奇瑞德',
        'gm' => '老奶奶',
        's' => '瑟爾基',
        'm' => '母親',
        'n' => '諾思布魯克',
        'l' => '莉夏',
        'o' => '奧茲華',
        'z' => '札迦萊亞',
        'b0' => '少年Ａ',
        'b1' => '少年Ｂ'
    }

    # Detect if the animation is wrapped inside a CJMP block that checks if a flag named 'skipping' is 0 or 1. If so only draw the case when the flag is 0.
    # Note that this is a workaround and will likely disappear when proper optimization is implemented in place.
    HACK_DETECT_ANIMATION_SKIP = true

    # Remove orphan with statements (not paired with any show/hide/scene statement)
    REMOVE_ORPHAN_WITH = true

    # Generate code for hentai skip
    # Compatible with https://renpy.org/wiki/renpy/doc/cookbook/Making_adult_scenes_optional
    GEN_HENTAI_SKIP_LOGIC = true

    # Hentai ranges
    # [[start_label, start_offset, insert_transition], [end_label, end_offset, insert_transition]]
    HENTAI_RANGES = [
        [['08_2900', 0x0, true], ['08_3000', 0x0, false]],
        [['09_1600', 0x0, true], ['09_1600', 0x22c9, false]],
    ]

    FLAG_BANKS = [
        # Double inclusive
        [0, 999, 'will_flagbank'],
        [1000, 2999, 'persistent.will_flagbank'],
    ]

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
        1 => ['help_pisca', Flag::INCLUDE, FlagCategory::STORY],
        2 => ['decided_to_build_dessert_house', Flag::INCLUDE, FlagCategory::STORY],
        3 => ['gem_37564_first_seen', Flag::INCLUDE, FlagCategory::STORY],
        4 => ['gem_37564_ask_guillered', Flag::INCLUDE, FlagCategory::STORY],
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
        1012 => ['unlock_r0_roddy', Flag::INCLUDE, FlagCategory::STORY],
        1014 => ['clear_r0_ioan', Flag::INCLUDE, FlagCategory::STORY],
        1430 => ['unlock_event_ioan_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1431 => ['unlock_event_ioan_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1432 => ['unlock_event_ioan_end_2', Flag::INCLUDE, FlagCategory::UNLOCK],
        1433 => ['unlock_event_roddy_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1434 => ['unlock_event_roddy_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1435 => ['unlock_event_dick_captured_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1436 => ['unlock_event_dick_captured_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1437 => ['unlock_event_dick_captured_2', Flag::INCLUDE, FlagCategory::UNLOCK],
        1438 => ['unlock_event_dag_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1439 => ['unlock_event_dag_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1440 => ['unlock_event_sergi_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1441 => ['unlock_event_sergi_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1442 => ['unlock_event_cornel_dick', Flag::INCLUDE, FlagCategory::UNLOCK],
        1443 => ['unlock_event_cornel_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1444 => ['unlock_event_cornel_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1445 => ['unlock_event_cornel_end_2', Flag::INCLUDE, FlagCategory::UNLOCK],
        1446 => ['unlock_event_greg_end_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1447 => ['unlock_event_greg_end_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1448 => ['unlock_event_greg_end_encore', Flag::INCLUDE, FlagCategory::UNLOCK],
        1449 => ['unlock_event_guillered_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1450 => ['unlock_event_guillered_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        1451 => ['unlock_event_guillered_2', Flag::INCLUDE, FlagCategory::UNLOCK],
        1452 => ['unlock_event_cornel_oswald', Flag::INCLUDE, FlagCategory::UNLOCK],
        1453 => ['unlock_event_aby_captured_0', Flag::INCLUDE, FlagCategory::UNLOCK],
        1454 => ['unlock_event_aby_captured_1', Flag::INCLUDE, FlagCategory::UNLOCK],
        10007 => ['system_keycode', Flag::HINT, FlagCategory::SYSTEM],
    }
end
