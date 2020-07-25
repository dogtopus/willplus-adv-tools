module O2RSettings
    VAR_INCLUDE = 1
    VAR_EXCLUDE = 0
    VAR_HINT = 2

    CHARACTER_TABLE_LOOKUP = true

    CHARACTER_TABLE = {
        'dick' => '迪克',
        'ioan' => '伊恩',
        'rodd' => '羅迪',
        'toma' => '托瑪',
        'pyeh' => '皮耶',
        'corn' => '柯奈爾',
        'abby' => '艾比',
        'doge' => '道格',
        'greg' => '葛列格',
        'guil' => '奇瑞德',
        'grma' => '老奶奶',
        'serg' => '瑟爾基',
        'mama' => '母親',
        'nbrk' => '諾思布魯克',
        'lisa' => '莉夏',
        'oswa' => '奧茲華',
        'zack' => '札迦萊亞',
        'boy0' => '少年Ａ',
        'boy1' => '少年Ｂ'
    }

    VAR_TABLE = {
        7 => ['is_blue_r0', VAR_INCLUDE],
        170 => ['pts_rodd', VAR_INCLUDE], # As of Route0
        171 => ['pts_ioan', VAR_INCLUDE], # As of Route0
        180 => ['gem_37564', VAR_INCLUDE], # As of Route0
        181 => ['house', VAR_INCLUDE], # As of Route0
        211 => ['disp_list', VAR_INCLUDE], # As of Route0
        700 => ['cgdisp_page_num', VAR_EXCLUDE],
        709 => ['has_bgm', VAR_EXCLUDE],
        723 => ['has_bg', VAR_EXCLUDE],
        765 => ['persistent.ctr_cg', VAR_EXCLUDE], # May not useful since we have len()
        850 => ['has_op_0', VAR_EXCLUDE],
        851 => ['has_op_1', VAR_EXCLUDE],
        852 => ['has_op_2', VAR_EXCLUDE],
        853 => ['has_op_3', VAR_EXCLUDE],
        996 => ['performing_transition', VAR_EXCLUDE],
        970 => ['pts_gem', VAR_INCLUDE], # As of Route0
        990 => ['list_related', VAR_EXCLUDE] # Purpose unknown
    }
end
