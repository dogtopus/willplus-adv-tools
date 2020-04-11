require_relative 'op2rpy_settings_enum'
include O2RSettingsEnum

module O2RSettings
    CHARACTER_TABLE_LOOKUP = false

    CHARACTER_TABLE = {
        'd' => '迪克',
        'i' => '伊恩',
        'r' => '羅迪',
        't' => '托瑪',
        'p' => '皮耶',
        'c' => '柯奈爾',
        'a' => '艾比',
        'do' => '道格',
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
        7 => ['is_blue_r0', Flag::INCLUDE],
        170 => ['aff_rodd', Flag::INCLUDE], # As of Route0
        171 => ['aff_ioan', Flag::INCLUDE], # As of Route0
        180 => ['gem_37564', Flag::INCLUDE], # As of Route0
        181 => ['house', Flag::INCLUDE], # As of Route0
        211 => ['disp_list', Flag::INCLUDE], # As of Route0
        700 => ['cgdisp_page_num', Flag::HINT],
        709 => ['has_bgm', Flag::HINT],
        723 => ['has_bg', Flag::HINT],
        765 => ['ctr_cg', Flag::HINT], # May not useful since we have len() TODO is it just some temp variable?
        850 => ['has_op_0', Flag::HINT],
        851 => ['has_op_1', Flag::HINT],
        852 => ['has_op_2', Flag::HINT],
        853 => ['has_op_3', Flag::HINT],
        996 => ['performing_transition', Flag::HINT],
        970 => ['pts_gem', Flag::INCLUDE], # As of Route0
        990 => ['list_related', Flag::HINT], # Purpose unknown
        1007 => ['persistent.first_run', Flag::HINT],
        1008 => ['clear_r0', Flag::INCLUDE],
        1009 => ['clear_r2', Flag::INCLUDE],
        1010 => ['clear_r3', Flag::INCLUDE],
        10007 => ['system_keycode', Flag::HINT],
    }
end
