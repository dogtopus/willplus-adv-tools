# willplus-tools

Tools for work with WillPlus ADV games.

Based on some ancient code found inside my code dumpster and fixed up using layers of layers of duct tape. Don't expect quality here...

## Usage

### Deobfuscate scripts

```bash
for f in path/to/Rio/*.WSC; do python wsc2scr.py "${f}" "${f%%.WSC}.SCR"; done
```

### Flowchart plotting

See `path_finder2.rb`.

```bash
ruby path_finder2.rb *.SCR
```

### Porting to Ren'Py

Below only lists some critical steps for porting. Actual steps may vary and may require extra programming or use of extra tools.

1. Create an initial op2rpy config file from template or use an existing config file.
2. Checkout the template.
3. Unpack all the original game's ARC files. Place unpacked `Bgm`, `Se` and `Voice` directly under `game/`.
4. Deobfuscate all `*.WSC` scripts under `Rio`.
5. Use `op2rpy.rb` to generate Ren'Py scripts from deobfuscated RIO scripts (excluding all system scripts) and place them under `game/Riopy/events`.
6. Run lint on the project and feed `lint.log` to `extract_image_symbols.py`.
7. Run `prepare_assets.py` on the JSON file generated on the previous step to convert assets. Place them under `game/`.
8. Change title screen, splash screen, entry points, etc. according to the system scripts.
9. Manually tie any loose ends. Selectively convert/rewrite system scripts and change `option.rpy` and `gui.rpy` to make the game completely functional (lint is your friend). Iteratively modify op2rpy config file to enable features or label necessary flags and regenerate scripts if necessary.
10. Re-encode assets to lossy/even-more-lossy for size control if needed.

## Files

### bb.rb

Basic block library. Cannot be executed directly.

### export_*_list.rb

Export list files for renpy-willplus-template.

### extract_image_symbols.py

Extract image symbols from Ren'Py lint report and generate a JSON file which can be used later by `prepare_assets.py`.

### op2csv.rb

Disassemble RIO scripts and print as csv. (Deprecated)

### op2rpy.rb

Disassemble a RIO script and attempt to convert it to Ren'Py script.

### op2rpy_settings_enum.rb

"Enums" for settings file.

### op2rpy_settings_*.rb

Per-game settings. (flag names, converter options, etc.)

### opcode.rb

Really bad RIO script disassembler engine. Cannot be executed directly.

### path_finder.rb

Plot all in-game choice menus to a DOT file.

### path_finder2.rb

Analyze RIO scripts and plot a low-level flowchart. A better vrsion of `path_finder`.

### prepare_assets.py

Prepare assets for renpy-willplus-template.

### will_arc.py

WillPlus ARC unpack/repack tool.

### will_arc.rb

Old WillPlus ARC tool. (Deprecated)

### wipf.py

WIPF image rip tool.

### wsc2scr.pas, wsc2scr.rb

Decrypt WSC files. (Deprecated)

### wsc2scr.py

Deobfuscate/re-obfuscate WSC files.

