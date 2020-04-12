#!/usr/bin/env ruby
# RIO bytecode disassembler

module RIOOpCode
# {op => [param, name, post_processor]}
    RIO_OPCODE = {
        0x00 => ['C'], # TODO not in vnvm. Does it even exist?
        0x01 => ['CS<s<i<x', '_jmp', :read_subcmd_01],
        # option num_options
        0x02 => ['S<', 'option', :read_options_02],
        # set operator, lhs_var_index, is_flag, rhs_imm
        0x03 => ['CS<CS<x', '_set', :read_subcmd_03],
        0x04 => ['', 'exit'],
        0x05 => ['C', 'apply_timer'],
        0x06 => ['i<C', 'jmp_offset'],
        0x07 => ['Z*', 'goto'],
        0x09 => ['Z*', 'call'],
        0x0a => ['C', 'return'],
        0x0b => ['s<', 'set_timer'],
        0x21 => ['Cs<CZ*', 'bgm'],
        0x22 => ['Cs<C', 'bgm_stop'],
        0x23 => ['Cs<C2s<Z*', 'voice'],
        0x25 => ['C4s<2xZ*', 'se'],
        0x26 => ['s<', 'se_stop'],
        0x29 => ['s<2'], #TODO
        0x41 => ['s<xZ*', 'text_n'],
        0x42 => ['s<x2Z*Z*', 'text_c'],
        0x43 => ['i<s<Z*', 'load_anm'],
        0x45 => ['Cs<C', 'show_anm'],
        0x46 => ['s<4CZ*', 'bg'],
        0x47 => ['C2'], # TODO not in vnvm
        0x48 => ['Cs<4CCZ*', 'fg'], #TODO
        0x49 => ['s<x', 'layer1_cl'],
        0x4a => ['Cs<C', 'transition', :read_subcmd_4a],
        0x4b => ['Cs<5C', 'add_anm'],
        0x4c => ['Cx', 'play_anm'],
        0x4d => ['C2s<C', 'graphic_fx'],
        0x4e => ['i<'], #TODO
        0x4f => ['Cs<C', 'hide_anm'],
        0x50 => ['Z*', 'load_table'],
        0x51 => ['S<2C', 'read_mouse_cursor'], # TODO not in vnvm. Variable related?
        0x52 => ['s<', 'se_wait'],
        0x54 => ['Z*', 'set_trans_mask'],
        0x55 => ['C'], #TODO
        0x61 => ['CZ*', 'video'],
        0x64 => ['Cs<2C', 'fg_transform'],
        0x68 => ['s<3C', 'bg_vp'],
        0x71 => ['Z*', 'em'], #TODO
        0x72 => ['C', 'hide_em'], #TODO
        0x73 => ['s<4CZ*', 'obj'],
        0x74 => ['s<', 'obj_cl'],
        0x82 => ['s<C', 'sleep'],
        0x83 => ['C'], # TODO not in vnvm
        0x85 => ['s<'], #TODO vnvm: Maybe related with being able to save?
        0x86 => ['C2', 'unk_86_delay'], #TODO name from vnvm
        0x89 => ['C'], #TODO
        0x8b => ['C'], # TODO not in vnvm
        0x8c => ['s<C', 'event_id'], #TODO
        0x8e => ['C'], #TODO
        0xb8 => ['s<x', 'layer2_cl'],
        0xb9 => ['C2'],
        0xbd => ['s<'], # TODO
        0xe2 => ['C', 'quick_load'], # TODO not in vnvm
        0xff => ['', 'eof']
    }

    RIO_SUBCMD_01 = [
        'jmp_00',
        'jbe',
        'jle',
        'jeq',
        'jne',
        'jbt',
        'jlt'
    ]

    RIO_SUBCMD_03 = [
        'set_00',
        'mov',
        'inc',
        'dec',
        'mul',
        'div',
        'rnd'
    ]

    RIO_SUBCMD_4a = {
         0 => 'none',
         5 => 'zoom_in',
         6 => 'boxes',
         9 => 'diagonal',
        11 => 'wipe_down',
        12 => 'wipe_up',
        13 => 'wipe_right',
        14 => 'wipe_left',
        21 => 'pixelate',
        22 => 'zoom_in',
        23 => 'mask',
        24 => 'mask_r',
        25 => 'fade_in',
        26 => 'fade_out',
        27 => nil,
        28 => 'effect_up',
        29 => 'effect_down',
        30 => 'effect_left',
        31 => 'effect_right',
        34 => 'zoom_in',
        35 => 'zoom_out',
        36 => 'distort',
        39 => nil,
        40 => nil,
        42 => 'mask_blend',
        43 => nil,
        44 => 'mask_blend_r',
        45 => nil
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
            opt = pool[offset..-1].unpack('s<Z*C4Z*')
            param.push(*opt)
            offset += opt.pack('s<Z*C4Z*').length #TODO
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

    def self.decode_script(scr, resolve_opcode_name = false)
        @resolve_opcode_name = resolve_opcode_name
        base_offset = 0
        op_str = []
        # scr = IO.binread(filename) # load script
        while scr[base_offset] # repeatly interpret script till eof
            op = scr[base_offset].ord # read opcode
            if RIO_OPCODE[op] # if the opcode is known...
                op_offset = base_offset
                base_offset += 1
                format = RIO_OPCODE[op] # load format string and command name
                if format[2] # check if a special processing method is need
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
                op_str << ([op_offset, op_disp].push(*param)) # save commands
                op_disp = nil
            else # the opcode is unknown
                raise "Unknown parameter format for opcode 0x#{op.to_s(16)} at offset 0x#{base_offset.to_s(16)}" # raise execption and exit
                break
            end
        end
        return op_str
    end
end
