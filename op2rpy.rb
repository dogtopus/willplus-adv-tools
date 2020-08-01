#!/usr/bin/env ruby
# (partially) converts RIOASM to Ren'Py script 

require_relative 'opcode'
require_relative 'op2rpy_settings_enum'
require_relative 'op2rpy_settings'
require_relative 'bb'
include O2RSettingsEnum
include O2RSettings

module RIOASMTranslator
    WILLPLUS_FPS = 20.0
    class WillPlusStubDisplayable
        def initialize(reference)
            @reference = reference
            @pending_for_removal = false
        end

        def add_key_frame(type, delta_x, delta_y, duration, alpha)
            raise 'Animation for stub object is not supported'
        end

        def flattern_key_frame()
            # no-op
        end

        def replace(name, absxpos=0, absypos=0)
            raise 'Cannot replace stub object'
        end

        def dirty?()
            return false
        end

        def mark_as_drawn()
            # no-op
        end

        def to_renpy_atl()
            return []
        end

        attr_reader :reference
        attr_accessor :pending_for_removal
    end

    class WillPlusDisplayable
        def initialize(name, absxpos=0, absypos=0, relative_to=:screen, force_topleft_anchor=false)
            @name = name
            @pos_init = [absxpos, absypos]
            @pos = [absxpos, absypos]
            @zoom = 100
            @pan = [400, 300]
            @alpha = 1.0
            @total_duration = 0.0
            @key_frames = []
            @force_topleft_anchor = force_topleft_anchor
            @relative_to = relative_to
            @pending_for_removal = false
            @tint = 0
            @tint_reset = false
            @dirty = true
        end

        def tint=(newval)
            @dirty = true if newval != @tint
            @tint_reset = true if newval != @tint
            @tint = newval
        end

        def set_viewport(zoom, xpan, ypan)
            @dirty = true if zoom != @zoom || xpan != @pan[0] || ypan != @pan[1]
            @zoom = zoom
            @pan[0] = xpan
            @pan[1] = ypan
        end

        def add_key_frame(type, delta_x, delta_y, duration, alpha)
            @pos[0] += delta_x
            @pos[1] += delta_y
            # TODO Untested. What's the unit value?
            @alpha += alpha / 255.0
            duration_s = duration / 1000.0
            @total_duration += duration_s
            # Calculate absolute positions on screen
            frame_abs = {}
            frame_abs[:duration] = duration_s
            frame_abs[:xpos] = @pos[0] / 800.0 unless delta_x == 0
            frame_abs[:ypos] = @pos[1] / 600.0 unless delta_y == 0
            frame_abs[:alpha] = @alpha unless alpha == 0
            frame_abs[:type] = type
            @key_frames << frame_abs
            @dirty = true
        end

        def flattern_key_frame()
            @key_frames.clear()
            @pos_init[0] = @pos[0]
            @pos_init[1] = @pos[1]
        end

        def replace(name, absxpos=0, absypos=0)
            @pending_for_removal = false
            if @name == name && absxpos == @pos_init[0] && absypos == @pos_init[1]
                # No modification
                return false
            end
            @key_frames.clear()
            @name = name
            @pos_init[0] = @pos[0] = absxpos
            @pos_init[1] = @pos[1] = absypos
            @dirty = true
            return true
        end

        def dirty?()
            return @dirty
        end

        def mark_as_drawn()
            @dirty = false
            @tint_reset = false
        end

        def to_renpy_atl()
            if @relative_to == :image
                xpos_init_f = -@pos_init[0] / 800.0
                ypos_init_f = -@pos_init[1] / 600.0
            else
                xpos_init_f = @pos_init[0] / 800.0
                ypos_init_f = @pos_init[1] / 600.0
            end
            result = []
            # Write initial position
            result << 'anchor (0, 0)' if @force_topleft_anchor
            if @pos_init[0] == 0 || @pos_init[1] == 0
                result << "xpos #{xpos_init_f}" unless @pos_init[0] == 0
                result << "ypos #{ypos_init_f}" unless @pos_init[1] == 0
            else
                result << "pos (#{xpos_init_f}, #{ypos_init_f})"
            end

            # Write zoom and pan
            result << "zoom #{@zoom / 100.0}" if @zoom != 100
            xpan_f = 180 * ((@pan[0] - 400) / 400.0)
            ypan_f = 180 * ((@pan[1] - 300) / 300.0)
            if @zoom != 100 && @pan[0] == 400 && @pan[1] == 300
                # Ren'Py has default alignment at top left corner so fix it
                result << "xpan 0.0"
                result << "ypan 0.0"
            elsif @zoom == 100
                # skip
            #elsif (@pan[0] == 400 || @pan[1] == 300)
            else
                result << "xpan #{xpan_f}" if @pan[0] != 400
                result << "ypan #{ypan_f}" if @pan[1] != 300
            #else
            #    result << "pan (#{xpan_f}, #{ypan_f})"
            end

            # Write matrixcolor (if applicable)
            if USE_ATL_MATRIXCOLOR && @tint != 0 && @tint_reset
                result << "matrixcolor None"
                result << "matrixcolor WillTintTable(#{@tint})"
            elsif USE_ATL_MATRIXCOLOR && @tint == 0 && @tint_reset
                result << "matrixcolor None"
            end

            # Write key frames
            @key_frames.each do |f|
                # TODO handle shake animation
                # Shake2Driver(duration, xdist=0, ydist=0, frame_unit=0.016)
                if @relative_to == :image
                    xpos = -f[:xpos] rescue nil
                    ypos = -f[:ypos] rescue nil
                else
                    xpos = f[:xpos]
                    ypos = f[:ypos]
                end
                # All nil => pause
                if xpos.nil? && ypos.nil? && f[:alpha].nil?
                    result << "pause #{f[:duration]}"
                # xpos or ypos is nil => split xpos and ypos and add alpha if necessary
                elsif xpos.nil? || ypos.nil?
                    entries = []
                    entries << "linear #{f[:duration]}"
                    entries << "xpos #{xpos}" unless xpos.nil?
                    entries << "ypos #{ypos}" unless ypos.nil?
                    entries << "alpha #{f[:alpha]}" unless f[:alpha].nil?
                    result << entries.join(' ')
                # xpos and ypos are both not nil => squash them as pos and add alpha if necessary
                else
                    entries = []
                    entries << "linear #{f[:duration]} pos (#{xpos}, #{ypos})"
                    entries << "alpha #{f[:alpha]}" unless f[:alpha].nil?
                    result << entries.join(' ')
                end
            end
            return result
        end
        attr_reader :total_duration, :pos_init, :pos, :alpha, :key_frames, :name, :pan, :zoom, :tint
        attr_accessor :pending_for_removal, :zorder_changed
    end


    def translate(scr_name, scr)
        scr_name.upcase!
        @rpy = RpyGenerator.new
        @gfx = {:bg => nil, :bg_redraw => false, :fg => [], :fg_redraw => false, :obj => nil, :obj_redraw => false, :side => nil, :tint => 0, :in_animation_seg => false}
        @say_for_menu = nil
        @index = 0
        @offset = 0
        @code_block_ends_at = []
        @jmp_trigger = []
        @typewriter_effect_duration = 0
        @scr = scr
        @scr_inst_by_offset = {}
        @scr_name = scr_name
        @cps_sleep_consumed = []
        @text_size = 0
        @cfg = RIOControlFlow.new(scr)
        @hentai_lookup = {}
        @next_chara_from_voice = nil
        HENTAI_RANGES.each_with_index do |ent, idx|
            @hentai_lookup[ent[0][0..1]] = {:type => :begin, :index => idx, :insert_transition => ent[0][2], :ends_at => ent[1][0..1]}
            @hentai_lookup[ent[1][0..1]] = {:type => :end, :index => idx, :insert_transition => ent[1][2], :begins_at => ent[0][0..1]}
        end
        @rpy.add_comment("Generated by op2rpy, edit with caution.")
        @rpy.add_cmd("label RIO_#{scr_name}:")
        @rpy.begin_block()
        @scr.each_with_index { |cmd, entry| @scr_inst_by_offset[cmd[0]] = entry }
        @scr.each_with_index do |cmd, entry|
            begin
                # Skip real EOF
                next if cmd[1] == 'EOF'
                @offset = cmd[0]
                _check_hentai_skip() if GEN_HENTAI_SKIP_LOGIC && !HENTAI_RANGES.nil? && HENTAI_RANGES.length > 0
                _check_code_block(cmd[0])
                _check_absjump_tag(cmd[0])
                _queue_say_for_menu_if_necessary(cmd, @scr[entry+1..-1]) if MOVE_PREVIOUS_SAY_INTO_MENU
                if respond_to?("op_#{cmd[1]}")
                    @rpy.add_comment("[cmd] #{_generate_cmd_disasm(cmd)}") if FORCE_INCLUDE_DISASM
                    send("op_#{cmd[1]}", *cmd[2..-1])
                else
                    @rpy.add_comment("[cmd:unhandled] #{_generate_cmd_disasm(cmd)}")
                end
                @index += 1
            rescue Exception => e
                STDERR.puts('PANIC: Unhandled exception while translating script.')
                STDERR.puts("Last position: #{@scr_name} @ 0x#{@offset.to_s(16)} (inst \##{@index})")
                STDERR.puts("Instruction: #{_generate_cmd_disasm(cmd)}")
                @rpy.add_comment('[panic] Translation interrupted. See log.')
                @rpy.add_cmd("$ renpy.error('Incomplete script translation')")
                return e, @rpy.to_s
            end
        end
        @rpy.end_block()
        return nil, @rpy.to_s
    end

    def _frames(frames)
        return frames / WILLPLUS_FPS
    end

    def _generate_cmd_disasm(cmd)
        return "0x#{cmd[0].to_s(16)}:#{cmd[1]}(#{cmd[2..-1].to_s.gsub(/[\[\]]/, '')})"
    end

    def _check_hentai_skip()
        hentai_boundary = @hentai_lookup[[@scr_name, @offset]]
        unless hentai_boundary.nil?
            case hentai_boundary[:type]
            when :begin
                @rpy.add_comment("[hentai] Begin \##{hentai_boundary[:index]}")
                @rpy.add_cmd('if not persistent.hentai:')
                @rpy.begin_block()
                # insert transitions if needed
                if hentai_boundary[:insert_transition]
                    @rpy.add_cmd("scene bg BLACK with dissolve")
                    @rpy.add_cmd("pause 1.0")
                end
                @rpy.add_cmd("jump RIO_#{hentai_boundary[:ends_at][0].upcase}_hentai_#{hentai_boundary[:index]}_end")
                @rpy.end_block()
            when :end
                @rpy.end_block()
                @rpy.add_comment("[hentai] End \##{hentai_boundary[:index]}")
                @rpy.add_cmd("label RIO_#{@scr_name}_hentai_#{hentai_boundary[:index]}_end:")
                @rpy.begin_block()
                # TODO insert transitions (force redraw) if needed
            else
                raise 'BUG: unknown hentai_boundary type'
            end
        end
    end

    def _check_code_block(cur_offset)
        if @code_block_ends_at[-1] == cur_offset
            @rpy.end_block()
            @code_block_ends_at.pop()
            _check_code_block(cur_offset)
        end
    end
    
    def _check_absjump_tag(cur_offset)
        if @jmp_trigger.include?(cur_offset)
            @rpy.end_block()
            @rpy.add_cmd("label RIO_#{@scr_name}_#{cur_offset}:")
            @rpy.begin_block()
            @jmp_trigger.delete(cur_offset)
        end
    end

    def _queue_say_for_menu_if_necessary(cmd, scr_after)
        return unless cmd[1] == 'text_c' || cmd[1] == 'text_n'
        scr_after.each do |cmd_next|
            case cmd_next[1]
            # Follows by a say. Stop looking.
            when 'text_c', 'text_n'
                break
            # Follows by menu. This is what we are looking for.
            when 'option'
                # Save the say instruction for later use.
                @say_for_menu = cmd
            end
        end
    end

    def _get_flag_reference(flag_addr, on_hint)
        bank = nil
        FLAG_BANKS.each do |b|
            if flag_addr.between?(b[0], b[1])
                bank = b[2]
                break
            end
        end
        if bank.nil?
            @rpy.add_comment("[warning:_get_flag_reference] Access to unmapped flag address #{flag_addr}")
            return nil
        end
        v = FLAG_TABLE[flag_addr]
        # Check for excluded or hinted flags
        if v
            # Labeled flag or requires special care
            flag_ref = "#{bank}[#{(v[0].nil?) ? flag_addr : ("'#{v[0]}'")}]"
            if v[1] == Flag::EXCLUDE
                return nil
            elsif v[1] == Flag::HINT
                @rpy.add_comment(on_hint.call(flag_ref))
                return nil
            elsif v[1] == Flag::INCLUDE
                return flag_ref
            else
                raise 'Invalid flag inclusion policy.'
            end
        else
            # Unlabeled flag
            return "#{bank}[#{flag_addr}]"
        end
    end

    def _convert_escape_sequences(text)
        result = []
        offset = 0
        while offset < text.length
            case text[offset]
            # Backslash (\n => \n, \\ => \\, \<other> => \\<other>)
            when '\\'
                case text[offset+1]
                # Newline
                when 'n'
                    result << '\\n'
                    offset += 2
                # Escaped backslash
                when '\\'
                    result << '\\\\'
                    offset += 2
                # Unknown escaping, output with the backslash escaped. The next character will be properly escaped if necessary.
                else
                    result << '\\\\'
                    offset += 1
                end
            # Percent sign
            when '%'
                result << '\\%'
                offset += 1
            # Single/double quote (' " => \' \")
            when '"', "'"
                result << '\\'
                result << text[offset]
                offset += 1
            # TODO: Escape all spaces?
            # Square brackets. Not (?) used in WillPlus engine?
            when '[', ']'
                result << text[offset]
                result << text[offset]
                offset += 1
            # Curly brackets. Used by WillPlus engine as (at least) ruby text.
            when '{'
                # {<rb>:<rt>}
                m = /^{([^:{}]+):([^:{}]+)}/.match(text[offset..-1])
                # Malformed ruby text escaping. Escape the leading bracket and continue.
                if m.nil?
                    result << text[offset]
                    result << text[offset]
                    offset += 1
                else
                    result << '{rb}' if m[1].length > 1
                    result << m[1]
                    result << '{/rb}' if m[1].length > 1
                    result << '{rt}'
                    result << m[2]
                    result << '{/rt}'
                    offset += m[0].length
                end
            # This shouldn't happen when the input is properly formatted. However if it does, escape it.
            when '}'
                result << text[offset]
                result << text[offset]
                offset += 1
            # Regular text
            else
                # Check if it's emoji
                emoji = (RESOLVE_EMOJI_SUBSTITUDE rescue false) ? EMOJI_TABLE[text[offset]] : nil
                if emoji.nil?
                    result << text[offset]
                    offset += 1
                else
                    result << "{font=#{EMOJI_FONT}}" unless EMOJI_FONT.nil?
                    result << emoji
                    result << "{/font}" unless EMOJI_FONT.nil?
                    offset += 1
                end
            end
        end
        return result.join()
    end

    def _is_end_of_animation_segment()
        # TODO make this CFG-aware
        scr_after = @scr[@index+1..-1]
        scr_after.each do |cmd_next|
            case cmd_next[1]
            when 'text_c', 'text_n', 'transition'
                # Say. No need for an explicit segment.
                return true
            when 'play_animation'
                # Animation + Animation
                return false
            end
        end
        return true
    end

    def op_call(label)
        @rpy.add_cmd("call RIO_#{label.upcase()}")
        custom_expr = PROC_EXTRA_EXPR[label.upcase()]
        eval(custom_expr) unless custom_expr.nil?
    end

    def op_return()
        @rpy.add_cmd('return')
    end

    def op_option(*args)
        raise 'Wrong number of parameters' if (args.length % 6) != 0

        @rpy.add_cmd("menu:")
        @rpy.begin_block()
        if MOVE_PREVIOUS_SAY_INTO_MENU && !@say_for_menu.nil?
            raise '@say_for_menu contains instruction other than text_n or text_c' unless @say_for_menu[1] == 'text_c' || @say_for_menu[1] == 'text_n'
            send("op__option_#{@say_for_menu[1]}", *@say_for_menu[2..-1])
            @say_for_menu = nil
        end
        (args.length / 6).times do |i|
            opt = args[(i * 6)..((i + 1) * 6)]
            opt[1].encode!('utf-8', RIO_TEXT_ENCODING)
            visibility_flag = _get_flag_reference(opt[3], ->(ref) { return "[option] visible if #{ref} != 0" })
            if visibility_flag.nil?
                @rpy.add_comment("[warning:option] Flag #{opt[3]} is inaccessible. Option will always be shown.")
                @rpy.add_cmd("\"#{opt[1]}\":")
            else
                @rpy.add_cmd("\"#{opt[1]}\" if #{visibility_flag}:")
            end
            @rpy.begin_block()
            @rpy.add_cmd("jump RIO_#{opt[5].upcase()}")
            @rpy.end_block()
        end
        @rpy.end_block()
    end

    def _build_mega_flagbank()
        result = []
        result << FLAG_BANKS[0][2]
        FLAG_BANKS[1..-1].each do |ent|
            result << ".map_(#{ent[2]})"
        end
        return result.join('')
    end

    # TODO flag operations
    def op_set(operator, lvar, reference_level, rside, try_boolify=false)
        case reference_level
        when 2
            # indirect reference
            rside_ref = _get_flag_reference(rside, ->(ref) { return "[set:reflevel=2] rside = #{rside}" })
            rside = (rside_ref.nil?) ? nil : "#{_build_mega_flagbank()}[#{rside_ref}]"
        when 1
            # flag
            rside = _get_flag_reference(rside, ->(ref) { return "[set:reflevel=1] rside = #{rside}" })
        when 0
            # immediate
            rside = (rside == 0 ? 'False' : 'True') if try_boolify && rside.between?(0, 1)
        end
        flag_ref = _get_flag_reference(lvar, ->(ref) { return "$ #{ref} #{operator} #{(rside.nil?) ? '<NO_RESULT>' : rside}" })
        @rpy.add_cmd("$ #{flag_ref} #{operator} #{rside}") unless flag_ref.nil?
    end

    def op_mov(lvar, is_flag, rside)
        op_set('=', lvar, is_flag != 0, rside, true)
        # typewriter effect
        # TODO make this callback-based?
        if lvar == 993
            @typewriter_effect_duration = rside
        end
    end

    def op_add(lvar, is_flag, rside)
        op_set('+=', lvar, (is_flag != 0) ? 1 : 0, rside)
    end

    def op_sub(lvar, is_flag, rside)
        op_set('-=', lvar, (is_flag != 0) ? 1 : 0, rside)
    end

    def op_movf(lvar, is_flag, rside)
        op_set('=', lvar, ((is_flag != 0) ? 1 : 0) + 1, rside)
    end

    def op_mod(lvar, is_flag, rside)
        op_set('%=', lvar, (is_flag != 0) ? 1 : 0, rside)
    end

    def op_rnd(lvar, is_flag, rside)
        flag_ref = _get_flag_reference(lvar, ->(ref) { return "$ #{ref} = renpy.random.randint(0, #{rside})" })
        @rpy.add_cmd("$ #{flag_ref} = renpy.random.randint(0, #{rside})") unless flag_ref.nil?
    end

    def op_clr(_lvar, _is_flag, _rside)
        FLAG_BANKS.each do |ent|
            # Clear all flagbanks except the one in 
            @rpy.add_cmd("$ #{ent[2]}.clear()") unless ent[2].start_with?('persistent.')
        end
    end

    # TODO Can we translate this to an if...else statement?
    def op_jmp_offset(offset)
        @rpy.add_cmd("jump RIO_#{@scr_name}_#{offset}")
        @jmp_trigger << offset
    end

    def op_jmp(operator, lvar, rside, rel_offset)
        flag_ref = _get_flag_reference(lvar, ->(ref) { return "if #{ref} #{operator} #{rside}: ..." })
        if flag_ref.nil?
            # Evaluate cjmp to always be false in case the flag is inaccessible.
            @rpy.add_comment("[warning:jmp] Attempt to access inaccessible flag #{lvar} in cjmp. Evaluating to false.")
            @rpy.add_cmd("if False:")
        else
            @rpy.add_cmd("if #{flag_ref} #{operator} #{rside}:")
        end
        @rpy.begin_block()
        @code_block_ends_at << (@scr[@index + 1][0] + rel_offset)
    end

    def op_jbe(lvar, rside, rel_offset)
        return op_jmp('>=', lvar, rside, rel_offset)
    end

    def op_jle(lvar, rside, rel_offset)
        return op_jmp('<=', lvar, rside, rel_offset)
    end

    def op_jbt(lvar, rside, rel_offset)
        return op_jmp('>', lvar, rside, rel_offset)
    end

    def op_jlt(lvar, rside, rel_offset)
        return op_jmp('<', lvar, rside, rel_offset)
    end

    def op_jeq(lvar, rside, rel_offset)
        return op_jmp('==', lvar, rside, rel_offset)
    end

    def op_jne(lvar, rside, rel_offset)
        return op_jmp('!=', lvar, rside, rel_offset)
    end

    def op_bg(xabspos, yabspos, arg3, arg4, arg5, bgname)
        if bgname != (@gfx[:bg].name rescue nil)
            @gfx[:bg] = WillPlusDisplayable.new(bgname, xabspos, yabspos, :image)
            @gfx[:bg_redraw] = true
        elsif !@gfx[:bg].nil?
            @gfx[:bg_redraw] = true if @gfx[:bg].replace(bgname, xabspos, yabspos)
        end
    end

    def op_bg_vp(zoom, xpan, ypan)
        @gfx[:bg].set_viewport(zoom, xpan, ypan) unless @gfx[:bg].nil?
        @gfx[:bg_redraw] = true if @gfx[:bg].dirty?
    end

    def op_fg(index, xabspos, yabspos, arg4, arg5, ignore_pos, inhibit_tint, fgname)
        if @gfx[:fg][index].nil?
            @gfx[:fg][index] = WillPlusDisplayable.new(fgname, xabspos, yabspos)
            @gfx[:fg_redraw] = true
        else
            if @gfx[:in_animation_seg]
                @rpy.add_comment('[animation] Image replacement inhibited by in-progress animation segment.')
            else
                @gfx[:fg_redraw] = true if @gfx[:fg][index].replace(fgname, xabspos, yabspos)
            end
        end
        unless @gfx[:fg][index].nil?
            if inhibit_tint == 0 && @gfx[:tint] != 0
                @gfx[:fg][index].tint = @gfx[:tint] 
            elsif inhibit_tint != 0
                @gfx[:fg][index].tint = 0
            end
        end
    end

    def op_tint(index)
        @gfx[:tint] = index
    end

    def op_fg_noarg7(index, xabspos, yabspos, arg4, arg5, ignore_pos, fgname)
        return op_fg(index, xabspos, yabspos, arg4, arg5, ignore_pos, 0, fgname)
    end

    def op_obj(xabspos, yabspos, arg3, arg4, arg5, objname)
        if objname != (@gfx[:obj].name rescue nil)
            @gfx[:obj] = WillPlusDisplayable.new(objname, xabspos, yabspos)
            @gfx[:obj_redraw] = true
        elsif !@gfx[:obj].nil?
            @gfx[:obj_redraw] = true if @gfx[:obj].replace(objname, xabspos, yabspos)
        end
    end

    def op_side_image(siname)
        @gfx[:side] = siname
        @rpy.add_cmd("will_side show side #{@gfx[:side].upcase()}")
    end

    def op_hide_side_image()
        @rpy.add_cmd("will_side hide")
        @gfx[:side] = nil
    end

    #0x21
    def op_bgm(repeat, fadein, arg3, filename)
        ref = AUDIO_SYMBOL_ONLY ? filename : "Bgm/#{filename}.OGG"
        cmd = "play music '#{ref}'"
        cmd << " fadein #{fadein / 1000.0}" if fadein != 0
        # The BGM seems to loop even if repeat is 1?
        #case repeat
        #when 0
        #    cmd << " loop"
        #when 1
        #    cmd << " noloop"
        #else
        #    cmd << " loop \# #{repeat} loops"
        #end
        cmd << ' loop'
        @rpy.add_cmd(cmd)
    end

    def op_bgm_noarg3(repeat, fadein, filename)
        return op_bgm(repeat, fadein, 0, filename)
    end

    def op_bgm_stop(arg1, fadeout)
        cmd = "stop music"
        cmd << " fadeout #{fadeout / 1000.0}" if fadeout != 0
        @rpy.add_cmd(cmd)
    end

    def op_se(channel, repeat, is_blocking, offset, fadein, volume, arg7, filename)
        ref = AUDIO_SYMBOL_ONLY ? filename : "Se/#{filename}"
        if channel < 0
            @rpy.add_comment('[warning:se] Sound channel is < 0')
            return
        end
        cmd = 'play '
        ch_name = 'sound'
        if channel != 0
            ch_name << "#{channel + 1}"
            @rpy.add_comment("[patch:sound_channel.rpy] renpy.music.register_channel('#{ch_name}', 'sfx', False)")
        end
        cmd << ch_name << " '#{ref}'"
        cmd << " fadein #{fadein / 1000.0}" if fadein != 0
        if repeat == 255 # Loop "forever"
            cmd << ' loop'
        elsif repeat != 0
            cmd << " loop \# #{repeat} loops"
        end
        @rpy.add_cmd(cmd)
    end

    def op_se_noarg8(channel, repeat, is_blocking, offset, fadein, volume, arg7, filename)
        return op_se(channel, repeat, is_blocking, offset, fadein, volume, arg7, filename)
    end

    def _se_stop(channel, fadeout=nil)
        if channel < 0
            param = (!fadeout.nil?) ? "fadeout=#{fadeout}" : ''
            @rpy.add_cmd("call stop_all_sounds(#{param})")
            return
        end
        cmd = 'stop '
        ch_name = 'sound'
        if channel != 0
            ch_name << "#{channel + 1}"
            @rpy.add_comment("[patch:sound_channel.rpy] renpy.sound.register_channel('#{ch_name}', 'sfx', False)")
        end
        cmd << ch_name
        cmd << " fadeout #{fadeout / 1000.0}" unless fadeout.nil?
        @rpy.add_cmd(cmd)
    end

    def op_se_stop(channel)
        _se_stop(channel)
    end

    def op_se_fadeout(channel, fadeout)
        _se_stop(channel, fadeout)
    end

    def op_voice(ch,arg2,arg3,type,volume_group,filename)
        ref = AUDIO_SYMBOL_ONLY ? filename : "Voice/#{filename}.OGG"
        @rpy.add_cmd("voice '#{ref}'")
        # Select character object by voice name if applicable
        # TODO bb awareness?
        if CHARACTER_VOICE_MATCH && CHARACTER_VOICE_MATCH
            found = false
            CHARACTER_VOICE_MATCHES.each do |pattern, chara|
                if pattern =~ filename
                    found = true
                    @next_chara_from_voice = chara
                    break
                end
            end
            @next_chara_from_voice = nil unless found
        end
    end

    def op_text_size_modifier(size)
        @text_size = size
    end

    def _add_say(id, text, name=nil)
        text.encode!('utf-8', RIO_TEXT_ENCODING)
        # Escape stuff
        text = _convert_escape_sequences(text)
        # Handle text size
        case @text_size
        when 0
            # Nothing
        when 1 # Huge
            text = "{size=+32}#{text}{/size}"
        when 2 # Small
            text = "{size=-8}#{text}{/size}"
        else
            @rpy.add_comment("[warning:say] Unknown text size modifier #{@text_size}")
        end
        # Handle typewriter effect
        if @typewriter_effect_duration != 0
            inline_sleep = nil
            inline_sleep_decided = false
            # Detect unconditional pauses
            bb_current = @cfg.inside_bb(@offset)
            instr_lower_half = @cfg.instruction_in_bb(bb_current, @offset)
            instr_lower_half[1..-1].each do |inst|
                case inst[1]
                when 'text_c', 'text_n'
                    inline_sleep_decided = true
                    break
                when 'sleep'
                    inline_sleep = "{w=#{inst[2] / 1000.0}}"
                    @cps_sleep_consumed << inst[0]
                    inline_sleep_decided = true
                    break
                end
            end
            # Detect skipping-guarded pause
            if !inline_sleep_decided && bb_current.type == 'cjmp'
                cond = instr_lower_half[-1]
                flag_name = FLAG_TABLE[cond[2]][0] rescue nil
                value = cond[3]
                # Only whitelist `jeq skipping, 0, <else>` for now
                if cond[1] == 'jeq' && flag_name == 'skipping' && value == 0
                    bb_next = @cfg.get_bb_by_offset(bb_current.jump_true)
                    instr_next = @cfg.instruction_in_bb(bb_next)
                    instr_next.each do |inst|
                        if inst[1] == 'sleep'
                            inline_sleep = "{w=#{inst[2] / 1000.0}}"
                            @cps_sleep_consumed << inst[0]
                            inline_sleep_decided = true
                        end
                    end
                end
            end
            text = "{cps=#{text.length / _frames(@typewriter_effect_duration / 100.0)}}#{text}{/cps}#{inline_sleep}{nw}"
        end
        if name.nil?
            # Narration
            @rpy.add_cmd("\"#{text}\"")
            @next_chara_from_voice = nil
        else
            # Character dialogue
            name.encode!('utf-8', RIO_TEXT_ENCODING)
            extra_params = nil
            # Character object name lookup
            chara_sym = CHARACTER_TABLE.key(name)
            is_alias = false
            # Use character object extracted from voice name if there's no direct match.
            if chara_sym.nil? && !@next_chara_from_voice.nil?
                chara_sym = @next_chara_from_voice
                # Check if the say name is an alias. If yes, force the say name later.
                is_alias = true if CHARACTER_TABLE[chara_sym] != name
                # Clear the chara set by op_voice to prevent polluting other say instructions.
                @next_chara_from_voice = nil
            end
            # Add namespace if needed.
            chara_sym = (CHARACTER_TABLE_NS.nil?) ? chara_sym : "#{CHARACTER_TABLE_NS}.#{chara_sym}" unless chara_sym.nil?

            extra_params = " (name='#{name}')" if is_alias
            if CHARACTER_TABLE_LOOKUP && !chara_sym.nil?
                @rpy.add_cmd("#{chara_sym} \"#{text}\"#{extra_params}")
            else
                @rpy.add_cmd("\"#{name}\" \"#{text}\"#{extra_params}")
            end
        end
    end

    #0x41
    def op_text_n(id, text)
        if @say_for_menu.nil? || @say_for_menu[2] != id
            _add_say(id, text)
        else
            @rpy.add_comment("[say] Added under the next menu.")
        end
    end

    def op__option_text_n(id, text)
        _add_say(id, text)
    end

    #0x42
    def op_text_c(id, name, text)
        if @say_for_menu.nil? || @say_for_menu[2] != id
            _add_say(id, text, name)
        else
            @rpy.add_comment("[say] Added under the next menu.")
        end
    end

    def op_text_extend(id, text)
        @rpy.add_cmd("extend \"#{text.encode('utf-8', RIO_TEXT_ENCODING)}\"")
    end

    def op__option_text_c(id, name, text)
        _add_say(id, text, name)
    end

    # TODO weather effect
    # type:
    # - snow (small particles only)
    # - rain
    # - moderate_snow (small and medium particles)
    # - moderate_snow_west_wind
    # - moderate_snow_east_wind
    # - heavy_snow (small, medium and big particles)
    # - snow_west_wind
    # - snow_east_wind
    def op_weather(type, sprite_limit_table_entry, arg3)
        # TODO figure out a way to not get cleared between scenes.
        slte = sprite_limit_table_entry == 0 ? '' : " #{sprite_limit_table_entry}"
        onlayer = (WEATHER_LAYER.nil?) ? nil : " onlayer #{WEATHER_LAYER}"
        case type
        when 0
            @rpy.add_cmd("hide weather#{onlayer}")
        when 2
            @rpy.add_cmd("show weather rain#{slte} as weather#{onlayer}")
        else
            @rpy.add_comment("[weather] Unhandled type #{type}")
        end
    end

    #0x54
    def op_set_trans_mask(filename)
        @gfx[:trans_mask] = filename
        @rpy.add_comment("[gfx] trans_mask = #{filename}")
    end

    def op_transition(type, duration)
        has_change = flush_gfx()
        return if !has_change and REMOVE_ORPHAN_WITH
        # "none" with 0 ms time on willplus engine will at least persist the object 1 frame. Used for strobe effect in some cases.
        duration_s = [duration / 1000.0, 0.016].max
        case type #TODO
        # None. Immediately shows up.
        when 'none'
            @rpy.add_cmd("with Pause(0.016)")
        # Dissolve
        # TODO why there are two types? Is it a labeling issue?
        when 'fade_out'
            @rpy.add_cmd("with WillFadeOut(#{duration_s})")
        when 'fade_in'
            @rpy.add_cmd("with Dissolve(#{duration_s})")
        # Pixel replace (wipe in imagemagick) with mask.
        when 'mask_wipe'
            @rpy.add_cmd("with WillImageDissolveSR('mask #{@gfx[:trans_mask].upcase()}', #{duration_s})")
        when 'mask_wipe_r'
            @rpy.add_cmd("with WillImageDissolveSR('mask #{@gfx[:trans_mask].upcase()}', #{duration_s}, reverse=True)")
        # Dissolve with mask.
        when 'mask_dissolve'
            @rpy.add_cmd("with WillImageDissolve('mask #{@gfx[:trans_mask].upcase()}', #{duration_s})")
        when 'mask_dissolve_r'
            @rpy.add_cmd("with WillImageDissolve('mask #{@gfx[:trans_mask].upcase()}', #{duration_s}, reverse=True)")
        # Pixellate
        when 'pixellate'
            @rpy.add_cmd("with Pixellate(#{duration_s}, 8)")
        # Wipe
        when /^wipe_(?:up|down|left|right)$/
            dir = type.split('_')[-1]
            @rpy.add_cmd("with CropMove(#{duration_s}, mode='wipe#{dir}')")
        # Dissolve to push animation
        when /^dissolve_to_push_(?:up|down|left|right)$/
            dir = type.split('_')[-1]
            @rpy.add_cmd("with WillDissolveToPush(#{duration_s}, 'push#{dir}')")
        # Diagonal strips
        when 'diagonal'
            @rpy.add_cmd("with WillDiagonalStrip(#{duration_s})")
        # Diagonal box fill
        when 'boxes'
            @rpy.add_cmd("with WillBoxes(#{duration_s})")
        # Dissolving to zooming out new image
        when 'dissolve_to_zoom_out'
            @rpy.add_cmd("with WillDissolveToZoomOut(#{duration_s})")
        # Similar to dissolve_to_zoom_out but without dissolve
        when 'zoom_out'
            @rpy.add_cmd("with WillZoomOut(#{duration_s})")
        when /^wipe_(?:up|down|left|right)_strip$/
            dir = type.split('_')[1]
            @rpy.add_cmd("with WillWipeStrip(#{duration_s}, 'wipe#{dir}')")
        when /^wipe_(?:up|down|left|right)_all_strip$/
            dir = type.split('_')[1]
            @rpy.add_cmd("with WillWipeAllStrip(#{duration_s}, 'wipe#{dir}')")
        when 'shutter_open'
            @rpy.add_cmd("with WillShutterOpen(#{duration_s})")
        when 'fade_out_noleadin'
            @rpy.add_cmd("with WillFadeOutNoLeadIn(#{duration_s})")
        when /^xrotate_new_c?cw$/
            cw = type.split('_')[-1] == 'cw' ? ', new_dir_cw=True' : ''
            @rpy.add_cmd("with WillXRotate(#{duration_s}#{cw})")
        when 'vwipe_checkerboard'
            @rpy.add_cmd("with WillWipeCheckboard(#{duration_s})")
        when 'new_dissolve_to_zoom_out_while_image_dissolve_r_to_new'
            @rpy.add_cmd("with WillND2ZOWIDR2N('mask #{@gfx[:trans_mask].upcase()}', #{duration_s})")
        when 'old_dissolve_to_zoom_in_while_image_dissolve_to_new'
            @rpy.add_cmd("with WillOD2ZIWID2N('mask #{@gfx[:trans_mask].upcase()}', #{duration_s})")
        when 'mask_dissolve_white_out'
            @rpy.add_cmd("with WillImageDissolveToWhiteOut('mask #{@gfx[:trans_mask].upcase()}', #{duration_s})")
        when 'mask_dissolve_r_white_out'
            @rpy.add_cmd("with WillImageDissolveToWhiteOut('mask #{@gfx[:trans_mask].upcase()}', #{duration_s}, reverse=True)")
        when /[vh]wave/
            if (USE_GFX_NEXT rescue false)
                horizontal = type.start_with?('h') ? ", mode='horizontal'" : nil
                @rpy.add_cmd("with WillWave(#{duration_s}#{horizontal})")
            else
                @rpy.add_comment("[warning:transition] #{type} requires USE_GFX_NEXT, which is set to false. Substitute with dissolve.")
                @rpy.add_cmd("with Dissolve(#{duration_s})")
            end
        when 'stretch'
            if (USE_GFX_NEXT rescue false)
                @rpy.add_cmd("with WillStretch(#{duration_s})")
            else
                @rpy.add_comment("[warning:transition] #{type} requires USE_GFX_NEXT, which is set to false. Substitute with dissolve.")
                @rpy.add_cmd("with Dissolve(#{duration_s})")
            end
        # Fallback to dissolve when transition is not supported.
        else
            @rpy.add_comment("[warning:transition] unknown method #{type}, time: #{duration_s}. Substitute with dissolve.")
            @rpy.add_cmd("with Dissolve(#{duration_s})")
        end
    end

    def op_add_animation_key_frame(index, delta_x, delta_y, ms, arg5, alpha)
        if HACK_DETECT_ANIMATION_SKIP
            bb = @cfg.inside_bb(@offset)
            if bb.jumped_from.length == 0 && bb.entry == 0
                # Unconditional animation, proceed unconditionally
            elsif bb.jumped_from.length == 0 && bb.entry != 0
                # Something is wrong, log and stop
                @rpy.add_comment("[warning:animation] Potential broken bb: back reference table has no entry and the bb is not a start block.")
                return
            elsif bb.jumped_from.length != 0 && bb.entry == 0
                # Something is wrong, log and stop
                @rpy.add_comment("[warning:animation] Potential broken bb: back reference table has entries but the bb is a start block.")
                return
            elsif bb.jumped_from.length == 1
                # Resolve the predecessor block
                pred = @cfg.get_bb_by_offset(bb.jumped_from[0])
                if pred.type == 'cjmp'
                    cond = @cfg.instruction_in_bb(pred)[-1]
                    if ['jbe', 'jle', 'jeq', 'jne', 'jbt', 'jlt'].include?(cond[1])
                        flag_name = FLAG_TABLE[cond[2]][0] rescue nil
                        value = cond[3]
                        unless flag_name == 'skipping'
                            @rpy.add_comment("[animation] Ignoring unknown conditioned animation")
                            return
                        end
                        unless value == 0
                            @rpy.add_comment("[animation] Ignoring skip-only animation")
                            return
                        end
                    else
                        @rpy.add_comment("[warning:animation] Potential broken bb: CJMP block does not end with a CJMP instruction.")
                        return
                    end
                else
                    @rpy.add_comment("[unimplemented:animation] bb's predecessor is not a CJMP block")
                    return
                end
            else
                # TODO what about unconditional bbs that are behind an if...else? Should we traverse back to the origin?
                @rpy.add_comment("[unimplemented:animation] Multiple predecessor found for this bb.")
                return
            end
        end
        # TODO index=10x? (seen in kani)
        if index == 0
            @gfx[:bg].add_key_frame(:linear, delta_x, delta_y, ms, alpha)
            @gfx[:bg_redraw] = true
        elsif index == 100
            @gfx[:bg].add_key_frame(:shake, delta_x, delta_y, ms, alpha)
            @gfx[:bg_redraw] = true
        else
            ftype = :linear
            if index > 100
                ftype = :shake
                index -= 100
            end
            if @gfx[:fg][index-1].nil?
                @rpy.add_comment("[warning:animation] Attempting to manipulate cleared displayable fg\##{index-1}. Ignored.")
            else
                @gfx[:fg][index-1].add_key_frame(ftype, delta_x, delta_y, ms, alpha)
                @gfx[:fg_redraw] = true
            end
        end
    end

    def op_play_animation(skippable)
        if _is_end_of_animation_segment()
            @gfx[:in_animation_seg] = false
            flush_gfx()
        else
            @rpy.add_comment('[animation] Play inside an detected animation segment. Delaying gfx commit to the last play instruction.')
            @gfx[:in_animation_seg] = true
        end
    end

    def op_play_animation_noskip()
        return op_play_animation(0)
    end

    def op_screen_effect(type, duration, magnitude)
        case type # shake, vwave, hwave, negative_flash
        when 0
            # Clear any layer effects
            @rpy.add_cmd('show layer master')
        when 1 # Shake
            if duration == 0xff
                # Indefinite layer shake
                @rpy.add_cmd('show layer master:')
                @rpy.begin_block()
                @rpy.add_cmd("function WillShakeDriverIndefinite(#{magnitude})")
                @rpy.end_block()
            else
                @rpy.add_cmd("with WillScreenShake(#{duration}, #{magnitude})")
            end
        else
            @rpy.add_comment("[screen_effect] Ignoring unknown type #{type}")
        end
    end

    def op_clear_screen_effect()
        @rpy.add_cmd('show layer master')
    end

    # 0x82
    def op_sleep(ms)
        if @cps_sleep_consumed.include?(@offset)
            @rpy.add_comment('[sleep] Inlined into previous CPS say.')
            @cps_sleep_consumed.delete(@offset)
        else
            @rpy.add_cmd("pause #{ms / 1000.0}")
        end
    end

    def op_goto(scr)
        @rpy.add_cmd("jump RIO_#{scr.upcase()}")
    end

    def op_event_name(name)
        @rpy.add_cmd("$ save_name = _('#{name.encode('utf-8', RIO_TEXT_ENCODING)}')")
    end

    def op_eof()
        # pass
    end

    def op_video(skippable, videofile)
        @rpy.add_cmd("$ renpy.movie_cutscene('Videos/#{videofile}')")
    end

    # TODO Figure out where fg is located (Looks like layer1 and kani.pl says it's layer1 as well but vnvm said it's on layer2. Different version of the bytecode?)
    def op_layer1_cl(index)
        @rpy.add_comment("[layer1] cl #{index}")
        unless @gfx[:fg][index].nil?
            # Flag for hiding
            @gfx[:fg][index].pending_for_removal = true
            @gfx[:fg_redraw] = true
        end
    end

    def op_obj_cl(arg1)
        @rpy.add_comment("[obj] cl")
        unless @gfx[:obj].nil?
            # Flag for hiding
            @gfx[:obj].pending_for_removal = true
            @gfx[:obj_redraw] = true
        end
    end

    def flush_gfx()
        has_change = false
        bg_redrew = @gfx[:bg_redraw]
        if @gfx[:bg_redraw]
            unless @gfx[:bg].nil? || !@gfx[:bg].dirty?
                atl = @gfx[:bg].to_renpy_atl()
                if atl.length != 0
                    @rpy.add_cmd("scene bg #{@gfx[:bg].name.upcase} at reset:")
                    @rpy.begin_block()
                    atl.each { |line| @rpy.add_cmd(line) }
                    @rpy.end_block()
                else
                    @rpy.add_cmd("scene bg #{@gfx[:bg].name.upcase} at reset")
                end
                @gfx[:bg].flattern_key_frame()
                @gfx[:bg].mark_as_drawn()
                has_change = true
            end
            @gfx[:bg_redraw] = false
        end
        
        if @gfx[:fg_redraw]
            @gfx[:fg].each_with_index do |f, i|
                if !f.nil? && !f.pending_for_removal && (bg_redrew || f.dirty?)
                    object = "fg #{f.name.upcase}"
                    object = "expression WillImTint('#{object}', #{f.tint})" if f.tint != 0 && !USE_ATL_MATRIXCOLOR
                    zorder = ACCURATE_ZORDER ? " zorder #{i}" : ''
                    atl = f.to_renpy_atl()
                    if atl.length == 0
                        @rpy.add_cmd("show #{object} at reset#{zorder} as fg_i#{i}")
                    else
                        @rpy.add_cmd("show #{object} at reset#{zorder} as fg_i#{i}:")
                        @rpy.begin_block()
                        atl.each { |line| @rpy.add_cmd(line) }
                        @rpy.end_block()
                    end
                    f.flattern_key_frame()
                    f.mark_as_drawn()
                    has_change = true
                elsif !f.nil? && f.pending_for_removal
                    # If the layer was flagged for hiding, hide and free the object.
                    ref = f.respond_to?(:reference) ? f.reference : "fg_i#{i}"
                    @rpy.add_cmd("hide #{ref}") unless bg_redrew
                    @gfx[:fg][i] = nil
                    has_change = true
                end
            end
            @gfx[:fg_redraw] = false
        end
        if @gfx[:obj_redraw]
            if !@gfx[:obj].nil? && !@gfx[:obj].pending_for_removal && (bg_redrew || @gfx[:obj].dirty?)
                zorder = ACCURATE_ZORDER ? " zorder 256" : ''
                atl = @gfx[:obj].to_renpy_atl()
                if atl.length == 0
                    @rpy.add_cmd("show obj #{@gfx[:obj].name.upcase} at reset#{zorder} as obj_i0")
                else
                    @rpy.add_cmd("show obj #{@gfx[:obj].name.upcase} at reset#{zorder} as obj_i0:")
                    @rpy.begin_block()
                    atl.each { |line| @rpy.add_cmd(line) }
                    @rpy.end_block()
                end
                @gfx[:obj].flattern_key_frame()
                @gfx[:obj].mark_as_drawn()
                has_change = true
            elsif !@gfx[:obj].nil? && @gfx[:obj].pending_for_removal
                # If the layer was flagged for hiding, hide and free the object.
                @rpy.add_cmd("hide obj_i0") unless bg_redrew
                @gfx[:obj] = nil
                has_change = true
            end
            @gfx[:obj_redraw] = false
        end
        return has_change
    end

    def debug(message)
        STDERR.write("#{message}\n")
    end
end

class RpyGenerator
    def initialize(indent_char=nil)
        #@script = ''
        @script = []
        @indent = 0
        @indent_char = (indent_char.nil?) ? '  ' : indent_char
        @empty_block = []
    end

    def add_line(*lines)
        lines.each do |line|
            @script << {:type => :line, :indent => @indent, :payload => line}
        end
    end

    def add_cmd(*lines)
        add_line(*lines)
        # Ignore empty root block
        @empty_block[-1] = false if @indent > 0 && @empty_block.length > 0
    end

    def add_comment(*lines)
        lines.each do |line|
            add_line("\# #{line}")
        end
    end

    def begin_block()
        @indent += 1
        @empty_block << true
    end

    def end_block()
        # TODO broken when there is only empty sub-emitters. Do we need to force a sub-emitter per block?
        add_cmd('pass') if @empty_block.pop() == true
        @indent -= 1
    end

    def insert_sub_generator()
        @script << {:type => :subgen, :indent => @indent, :payload => RpyGenerator.new(indent_char)}
    end

    def each_line()
        @script.each do |entry|
            indent_str = @indent_char * entry[:indent]
            case entry[:type]
            when :subgen
                entry[:payload].each_line { |l| yield "#{indent_str}#{l}" }
            when :line
                yield "#{indent_str}#{entry[:payload]}"
            end
        end
    end

    def empty?()
        return @script.empty?
    end

    def to_s()
        # TODO this is super hacky. Find a better way to do this
        return to_enum(:each_line).to_a.join("\n")
    end
end

include RIOASMTranslator

abort("Usage: #{$PROGRAM_NAME} scr rpy") if ARGV.length < 2
RIOOpCode.set_opcode_version(OPCODE_VERSION) unless OPCODE_VERSION.nil?
File.open(ARGV[1], 'w') do |f|
    e, result = translate(File.basename(ARGV[0]).split('.')[0], RIOOpCode.decode_script(IO.binread(ARGV[0]), true))
    if e.nil?
        f.write(result)
    else
        STDERR.puts('Partial output file created.')
        f.write(result)
        raise e
    end
end
