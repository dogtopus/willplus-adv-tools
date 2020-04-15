require_relative 'op2rpy_settings_enum'
include O2RSettingsEnum

module O2RSettings
    # Always include disassembly inside the emitted code. Useful for debugging emitter.
    FORCE_INCLUDE_DISASM = true

    RIO_TEXT_ENCODING = 'big5'

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

    FLAG_BANKS = [
        # Double inclusive
        [0, 999, 'will_flagbank'],
        [1000, 2999, 'persistent.will_flagbank'],
    ]

    FLAG_TABLE = {
        2 => ['decided_to_build_dessert_house', Flag::INCLUDE],
        3 => ['gem_37564_first_seen', Flag::INCLUDE],
        4 => ['gem_37564_ask_guillered', Flag::INCLUDE],
        7 => ['is_blue_r0', Flag::INCLUDE],
        43 => ['asked_roddy_for_dinner', Flag::INCLUDE],
        47 => ['met_ioan_r0_d4_am', Flag::INCLUDE],
        48 => ['found_book_r0_d4_noon', Flag::INCLUDE],
        170 => ['aff_roddy', Flag::INCLUDE], # As of Route0
        171 => ['aff_ioan', Flag::INCLUDE], # As of Route0
        174 => ['aff_dag', Flag::INCLUDE],
        180 => ['gem_37564', Flag::INCLUDE], # As of Route0
        181 => ['house', Flag::INCLUDE], # As of Route0
        199 => ['gem_37564_more_people_ded', Flag::INCLUDE],
        200 => ['gem_37564_dad_ded', Flag::INCLUDE],
        201 => ['gem_37564_mom_ded', Flag::INCLUDE],
        202 => ['gem_37564_brother_ded', Flag::INCLUDE],
        203 => ['gem_37564_sister_ded', Flag::INCLUDE],
        204 => ['gem_37564_neighbor_girl_ded', Flag::INCLUDE],
        205 => ['gem_37564_neighbor_boy_ded', Flag::INCLUDE],
        206 => ['gem_37564_classmate_0_ded', Flag::INCLUDE],
        207 => ['gem_37564_classmate_1_ded', Flag::INCLUDE],
        208 => ['gem_37564_classmate_2_ded', Flag::INCLUDE],
        209 => ['gem_37564_classmate_3_ded', Flag::INCLUDE],
        211 => ['disp_list', Flag::INCLUDE], # As of Route0
        700 => ['cgdisp_page_num', Flag::HINT],
        709 => ['has_bgm', Flag::HINT],
        720 => ['current_event_id', Flag::INCLUDE],
        723 => ['has_bg', Flag::HINT],
        762 => ['cutscene_index', Flag::INCLUDE],
        763 => ['cutscene_unskippable', Flag::INCLUDE],
        765 => ['ctr_cg', Flag::HINT], # May not useful since we have len() TODO is it just some temp variable?
        850 => ['has_opt_0', Flag::HINT],
        851 => ['has_opt_1', Flag::HINT],
        852 => ['has_opt_2', Flag::HINT],
        853 => ['has_opt_3', Flag::HINT],
        995 => ['in_event_view_mode', Flag::INCLUDE],
        996 => ['performing_transition', Flag::HINT],
        970 => ['gem_maturity', Flag::INCLUDE], # As of Route0
        990 => ['list_related', Flag::HINT], # Purpose unknown
        1004 => ['seen_ending_cutscene', Flag::INCLUDE],
        1007 => ['first_run', Flag::HINT],
        1008 => ['clear_r0', Flag::INCLUDE],
        1009 => ['clear_r2', Flag::INCLUDE],
        1010 => ['clear_r3', Flag::INCLUDE],
        1014 => ['clear_r0_ioan', Flag::INCLUDE],
        1430 => ['unlock_event_ioan_end_0', Flag::INCLUDE],
        1431 => ['unlock_event_ioan_end_1', Flag::INCLUDE],
        1432 => ['unlock_event_ioan_end_2', Flag::INCLUDE],
        1433 => ['unlock_event_roddy_end_0', Flag::INCLUDE],
        1434 => ['unlock_event_roddy_end_1', Flag::INCLUDE],
        1435 => ['unlock_event_dick_captured_0', Flag::INCLUDE],
        1436 => ['unlock_event_dick_captured_1', Flag::INCLUDE],
        1437 => ['unlock_event_dick_captured_2', Flag::INCLUDE],
        1438 => ['unlock_event_dag_end_0', Flag::INCLUDE],
        1439 => ['unlock_event_dag_end_1', Flag::INCLUDE],
        1440 => ['unlock_event_sergi_end_0', Flag::INCLUDE],
        1441 => ['unlock_event_sergi_end_1', Flag::INCLUDE],
        1442 => ['unlock_event_cornel_dick', Flag::INCLUDE],
        1443 => ['unlock_event_cornel_end_0', Flag::INCLUDE],
        1444 => ['unlock_event_cornel_end_1', Flag::INCLUDE],
        1445 => ['unlock_event_cornel_end_2', Flag::INCLUDE],
        1446 => ['unlock_event_greg_end_0', Flag::INCLUDE],
        1447 => ['unlock_event_greg_end_1', Flag::INCLUDE],
        1448 => ['unlock_event_greg_end_encore', Flag::INCLUDE],
        1449 => ['unlock_event_guillered_0', Flag::INCLUDE],
        1450 => ['unlock_event_guillered_1', Flag::INCLUDE],
        1451 => ['unlock_event_guillered_2', Flag::INCLUDE],
        1452 => ['unlock_event_cornel_oswald', Flag::INCLUDE],
        1453 => ['unlock_event_aby_captured_0', Flag::INCLUDE],
        1454 => ['unlock_event_aby_captured_1', Flag::INCLUDE],
        10007 => ['system_keycode', Flag::HINT],
    }
end
