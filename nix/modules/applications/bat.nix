{ lib }:

{
  # Config file path relative to ~/.config/bat/
  configFile = "themes/Vogix16.tmTheme";

  # Generator function to create bat theme from semantic colors
  # Returns bat theme file content in Sublime Text tmTheme XML format
  #
  # Vogix16 Philosophy for bat:
  # - Minimal syntax highlighting (most code uses monochromatic colors)
  # - Semantic colors ONLY for git diffs (added/removed/modified lines)
  # - No decorative syntax colors - code structure shown through subtle variations
  #
  # Why minimal syntax highlighting?
  # - Syntax highlighting is decorative, not semantic
  # - The user doesn't "need" to know that something is a keyword vs variable
  # - Reserve color for information that matters: diff changes, errors, warnings
  generate = colors: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>author</key>
        <string>Vogix16</string>
        <key>name</key>
        <string>Vogix16</string>
        <key>colorSpaceName</key>
        <string>sRGB</string>
        <key>settings</key>
        <array>
            <!-- Global editor settings -->
            <dict>
                <key>settings</key>
                <dict>
                    <key>background</key>
                    <string>${colors.background}</string>
                    <key>foreground</key>
                    <string>${colors.foreground-text}</string>
                    <key>caret</key>
                    <string>${colors.foreground-bright}</string>
                    <key>lineHighlight</key>
                    <string>${colors.background-selection}</string>
                    <key>selection</key>
                    <string>${colors.background-selection}</string>
                    <!-- Gutter (line numbers area) -->
                    <key>gutter</key>
                    <string>${colors.background-surface}</string>
                    <key>gutterForeground</key>
                    <string>${colors.foreground-comment}</string>
                </dict>
            </dict>

            <!-- MONOCHROMATIC SYNTAX (Structure only, no semantic meaning) -->

            <!-- Comments -->
            <dict>
                <key>name</key>
                <string>Comments</string>
                <key>scope</key>
                <string>comment, punctuation.definition.comment</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.foreground-comment}</string>
                    <key>fontStyle</key>
                    <string>italic</string>
                </dict>
            </dict>

            <!-- All code: keywords, variables, functions, strings, numbers -->
            <!-- Use foreground-text for everything - minimal differentiation -->
            <dict>
                <key>name</key>
                <string>Code</string>
                <key>scope</key>
                <string>keyword, storage, variable, constant, string, number, entity, support, meta</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.foreground-text}</string>
                </dict>
            </dict>

            <!-- Operators and punctuation -->
            <dict>
                <key>name</key>
                <string>Operators</string>
                <key>scope</key>
                <string>keyword.operator, punctuation</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.foreground-border}</string>
                </dict>
            </dict>

            <!-- Function/class names slightly emphasized -->
            <dict>
                <key>name</key>
                <string>Definitions</string>
                <key>scope</key>
                <string>entity.name.function, entity.name.class, entity.name.type</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.foreground-heading}</string>
                </dict>
            </dict>

            <!-- SEMANTIC COLORS (Git diff - information user needs) -->

            <!-- Git diff: Added lines -->
            <dict>
                <key>name</key>
                <string>Diff Inserted</string>
                <key>scope</key>
                <string>markup.inserted, markup.inserted.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.success}</string>
                </dict>
            </dict>

            <!-- Git diff: Removed lines -->
            <dict>
                <key>name</key>
                <string>Diff Deleted</string>
                <key>scope</key>
                <string>markup.deleted, markup.deleted.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.danger}</string>
                </dict>
            </dict>

            <!-- Git diff: Modified/changed lines -->
            <dict>
                <key>name</key>
                <string>Diff Changed</string>
                <key>scope</key>
                <string>markup.changed, markup.changed.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.warning}</string>
                </dict>
            </dict>

            <!-- Git diff: Diff header/range -->
            <dict>
                <key>name</key>
                <string>Diff Header</string>
                <key>scope</key>
                <string>meta.diff.header, meta.diff.range</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.notice}</string>
                    <key>fontStyle</key>
                    <string>bold</string>
                </dict>
            </dict>

            <!-- Errors/invalid (semantic: something is wrong) -->
            <dict>
                <key>name</key>
                <string>Invalid</string>
                <key>scope</key>
                <string>invalid, invalid.illegal</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.danger}</string>
                    <key>fontStyle</key>
                    <string>bold</string>
                </dict>
            </dict>
        </array>
    </dict>
    </plist>
  '';
}
