#!/usr/bin/env ruby
# RIO bytecode disassembler

module RIOOpCode
# {op => [param, name, post_processor]}
    RIO_OPCODE = {
        0x00 => [''], # TODO not in vnvm. Does it even exist?
        0x01 => ['CS<s<i<', '_jmp', :read_subcmd_01],
        # option num_options
        0x02 => ['S<', 'option', :read_options_02],
        # set operator, lhs_var_index, is_flag, rhs_imm
        0x03 => ['CS<Cs<', '_set', :read_subcmd_03],
        0x04 => [nil, 'exit'],
        0x05 => ['', 'apply_timer'],
        0x06 => ['i<', 'jmp_offset'],
        0x07 => ['Z*', 'goto'],
        0x08 => ['C', 'text_size_modifier'],
        0x09 => ['Z*', 'call'],
        0x0a => ['', 'return'],
        0x0b => ['C', 'set_timer'],
        0x21 => ['Cs<CZ*', 'bgm'],
        0x22 => ['Cs<', 'bgm_stop'],
        0x23 => ['Cs<C2s<Z*', 'voice'],
        0x25 => ['cC3s<c2xZ*', 'se'],
        0x26 => ['c', 'se_stop'],
        0x28 => ['C2s<'], #TODO seems to be something and a duration. Some sort of effects?
        0x29 => ['cs<', 'se_fadeout'],
        0x30 => ['Cs<', 'wait_30'], # kani.pl/nsc.pl TODO verify
        0x41 => ['s<xZ*', 'text_n'],
        0x42 => ['s<x2Z*Z*', 'text_c'],
        0x43 => ['i<s<Z*', 'ui_load_anm'],
        0x45 => ['Cs<', 'ui_show_anm'],
        0x46 => ['s<4CZ*', 'bg'],
        0x47 => ['C', 'bg_color'], # 0=black
        0x48 => ['Cs<4CCZ*', 'fg'], #TODO
        0x49 => ['s<', 'layer1_cl'],
        0x4a => ['Cs<', 'transition', :read_subcmd_4a],
        0x4b => ['Cs<5', 'add_animation_key_frame'],
        0x4c => ['C', 'play_animation'],
        0x4d => ['C2s<', 'screen_effect'],
        0x4e => ['C3', 'weather'], #TODO this was i<
        0x4f => ['Cs<', 'ui_hide_anm'],
        0x50 => ['Z*', 'ui_load_table'],
        0x51 => ['S<2', 'ui_read_click'],
        0x52 => ['C', 'se_wait'],
        0x54 => ['Z*', 'set_trans_mask'],
        0x55 => [''], #TODO
        0x61 => ['CZ*', 'video'],
        0x62 => ['', 'clear_screen_effect'],
        0x64 => ['Cs<2', 'fg_transform'],
        0x68 => ['s<3', 'bg_vp'],
        0x71 => ['Z*', 'side_image'],
        0x72 => ['', 'hide_side_image'],
        0x73 => ['s<4CZ*', 'obj'],
        0x74 => ['C', 'obj_cl'], # NOTE: this was s<
        0x78 => ['C7'], # seen in io
        0x82 => ['s<', 'sleep'],
        0x83 => ['', 'open_load_menu'],
        0x84 => ['', 'open_save_menu'],
        0x85 => ['C', 'block_savegame_access'], #TODO vnvm: Maybe related with being able to save? NOTE: this was s<
        0x86 => ['C', 'unk_86_delay'], #TODO name from vnvm
        0x88 => ['C2', 'initiate_battle'],
        0x89 => [''], #TODO
        0x8b => ['', 'open_prefereces_menu'],
        0x8c => ['s<', 'event_id'], #TODO
        0x8e => ['', 'highlight_visited_options'],
        0xa9 => [''], # seen in io
        0xae => [''], # seen in io
        0xb3 => ['C'], # seen in io
        0xb6 => ['s<Z*', 'text_extend'],
        0xb8 => ['s<', 'layer2_cl'],
        0xb9 => ['C', 'tint'], # TODO decode the lookup table
        0xbd => ['C'], # TODO this was s<
        0xe0 => ['Z*', 'event_name'],
        0xe2 => ['', 'quick_load'], # TODO not in vnvm
        0xe4 => ['C'], # seen in io
        0xe6 => ['C'], # seen in io
        0xe7 => ['C2'], # seen in io
        0xff => [nil, 'eof'],
    }

    RIO_OPCODE_PATCHES = {
        :_ => RIO_OPCODE.clone(),
        :ymk => {
            0x21 => ['Cs<Z*', 'bgm_noarg3'],
            0x28 => ['C2', '0x28_2arg'],
            0x25 => ['cC3s<c2Z*', 'se_noarg8'],
            0x48 => ['Cs<4CZ*', 'fg_noarg7'],
            0x4c => ['', 'play_animation_noskip'],
            0x64 => ['C3', 'fg_transform_all8'],
        },
        :io => {
            0x05 => ['C', 'apply_timer_io'],
            0x21 => ['Cs<Cs<3Z*', 'bgm_io'],
            0x25 => ['cC3s<c2xs<Z*', 'se_io'],
            0x41 => ['s<xCZ*', 'text_n_io'],
            0x4a => ['Cs<2', 'transition_io', :read_subcmd_4a],
            0xb9 => ['C2', 'tint_io'],
            0xff => ['C11', 'eof_io'],
        },
    }

    RIO_SUBCMD_01 = [
        '_cjmp',
        'jbe',
        'jle',
        'jeq',
        'jne',
        'jbt',
        'jlt'
    ]

    RIO_SUBCMD_03 = [
        'clr',
        'mov',
        'add',
        'sub',
        'movf',
        'mod',
        'rnd'
    ]

    RIO_SUBCMD_4a = {
         0 => 'none',
         1 => 'wipe_down_all_strip',
         2 => 'wipe_up_all_strip',
         3 => 'wipe_right_all_strip',
         4 => 'wipe_left_all_strip',
         5 => 'zoom_out',
         6 => 'boxes',
         7 => 'vwipe_interlace',
         8 => 'dithered_dissolve',
         9 => 'diagonal',
        10 => 'shutter_open',
        11 => 'wipe_down_strip',
        12 => 'wipe_up_strip',
        13 => 'wipe_right_strip',
        14 => 'wipe_left_strip',
        15 => 'vwipe_checkerboard',
        16 => 'hwipe_interlace',
        17 => 'wipe_down',
        18 => 'wipe_up',
        19 => 'wipe_right',
        20 => 'wipe_left',
        21 => 'pixellate',
        22 => 'dissolve_to_zoom_out',
        23 => 'mask_wipe',
        24 => 'mask_wipe_r',
        25 => 'fade_in',
        26 => 'fade_out',
        27 => 'mask_dissolve_white_out',
        28 => 'dissolve_to_push_up',
        29 => 'dissolve_to_push_down',
        30 => 'dissolve_to_push_left',
        31 => 'dissolve_to_push_right',
        32 => 'rotate_90_ccw',
        33 => 'rotate_90_cw',
        34 => 'new_dissolve_to_zoom_out_while_image_dissolve_r_to_new',
        35 => 'old_dissolve_to_zoom_in_while_image_dissolve_to_new',
        36 => 'vwave',
        37 => 'hwave',
        38 => 'xrotate_new_ccw_with_vwave',
        39 => 'xrotate_new_cw_with_vwave',
        40 => 'xrotate_new_ccw',
        41 => 'xrotate_new_cw',
        42 => 'mask_dissolve',
        43 => 'stretch',
        44 => 'mask_dissolve_r',
        45 => 'mask_dissolve_r_white_out',
    }

    def self.read_subcmd_01(pool, base_offset)
        format = RIO_OPCODE[0x01]
        param = pool.unpack(format[0]) # read params
        base_offset += param.pack(format[0]).length # calculate offset of the next command (TODO)
        if @resolve_opcode_name
            op_disp = RIO_SUBCMD_01[param.shift()]
        else
            op_disp = nil
        end
        return param, base_offset, op_disp
    end

    def self.read_options_02(pool, base_offset)
        offset = 2
        param = []
        count = pool[0..1].unpack('S<')[0]
        count.times do
            # text_id, text, unk (always 1?), has_opt_n_flag_addr, len_jump_to?, jump_to
            opt = pool[offset..-1].unpack('s<Z*CS<CZ*')
            param.push(*opt)
            offset += opt.pack('s<Z*CS<CZ*').length #TODO
        end
        base_offset += offset
        return param, base_offset, nil
    end

    def self.read_subcmd_03(pool, base_offset)
        format = RIO_OPCODE[0x03]
        param = pool.unpack(format[0]) # read params
        base_offset += param.pack(format[0]).length # calculate offset of the next command (TODO)
        if @resolve_opcode_name
            op_disp = RIO_SUBCMD_03[param.shift()]
        else
            op_disp = nil
        end
        return param, base_offset, op_disp
    end

    def self.read_subcmd_4a(pool, base_offset)
        format = RIO_OPCODE[0x4a]
        param = pool.unpack(format[0]) # read params
        base_offset += param.pack(format[0]).length # calculate offset of the next command (TODO)
        if @resolve_opcode_name
            op_disp = format[1]
            param[0] = RIO_SUBCMD_4a[param[0]] if RIO_SUBCMD_4a[param[0]]
        else
            op_disp = nil
        end
        return param, base_offset, op_disp
    end

    def self.patch_fmt(fmt)
        RIO_OPCODE.merge!(fmt)
    end

    def self.revert_patches()
        RIO_OPCODE.clear()
        patch_fmt(RIO_OPCODE_PATCHES[:_])
    end

    def self.set_opcode_version(version)
        patch = nil
        if version != :default
            patch = RIO_OPCODE_PATCHES[version]
            raise "Unknown opcode version #{version}." if patch.nil?
        end
        revert_patches()
        patch_fmt(patch)
    end

    def self.decode_script(scr, resolve_opcode_name = false)
        @resolve_opcode_name = resolve_opcode_name
        base_offset = 0
        op_str = []
        # scr = IO.binread(filename) # load script
        while scr[base_offset] # repeatly interpret script till eof
            op = scr[base_offset].ord # read opcode
            op_offset = base_offset
            if RIO_OPCODE[op] # if the opcode is known...
                base_offset += 1
                format = RIO_OPCODE[op] # load format string and command name

                if format[0].nil? # check if the opcode is noterm type (i.e. exit or eof)
                    param = []
                elsif format[2] # check if a special processing method is need
                    (param, base_offset, op_disp) = send(format[2], scr[base_offset..-1], base_offset)
                else
                    param = scr[base_offset..-1].unpack(format[0]) # read params
                    base_offset += param.pack(format[0]).length # calculate offset of the next command (TODO)
                end
                if resolve_opcode_name
                    if (format[1] && !op_disp)
                        op_disp = format[1]
                    elsif !op_disp
                        op_disp = "0x#{op.to_s(16)}"
                    end
                else
                    op_disp = op
                end
                not_terminated = false
                if not ((format[0].nil? or format[0].end_with?('Z*') or op == 0x02))
                    # Explicit non-noterms (does not end with a NTS and the op is not `option`) but no termination found
                    if scr[base_offset].ord != 0
                        not_terminated = true
                    else
                        base_offset += 1
                    end
                end
                # No-op for implicit non-noterms or noterms
                op_str << ([op_offset, op_disp].push(*param)) # save commands
                op_str << ([base_offset, 'NOT_TERMINATED']) if not_terminated
                op_disp = nil
            else # the opcode is unknown
                # self recover
                zero_offset = scr[base_offset..-1].index("\x00")
                op_str << ([op_offset, 'INVALID'].push(*scr[base_offset..base_offset+zero_offset].unpack('C*')))
                base_offset += zero_offset + 1
            end
        end
        op_str << [base_offset, 'EOF']
        return op_str
    end
end
