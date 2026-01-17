{
  name = "matrix";

  variants = {
    dark = {
      polarity = "dark";
      colors = {
        base00 = "#0a0f00";
        base01 = "#143214";
        base02 = "#1e4b1e";
        base03 = "#206420";
        base04 = "#37c837";
        base05 = "#00ff00";
        base06 = "#92ff92";
        base07 = "#f0fff0";
        base08 = "#ff0000";
        base09 = "#ffcc00";
        base0A = "#aaff00";
        base0B = "#00ff00";
        base0C = "#97ffbd";
        base0D = "#00ffff";
        base0E = "#ff00ff";
        base0F = "#cc9900";
      };
    };

    light = {
      polarity = "light";
      colors = {
        base00 = "#f0fff0";
        base01 = "#d2ffd2";
        base02 = "#92ff92";
        base03 = "#70e070";
        base04 = "#37c837";
        base05 = "#00ff00";
        base06 = "#1e4b1e";
        base07 = "#0a0f00";
        base08 = "#cc0000";
        base09 = "#cc9900";
        base0A = "#88cc00";
        base0B = "#00cc00";
        base0C = "#66cc99";
        base0D = "#00cccc";
        base0E = "#cc00cc";
        base0F = "#997700";
      };
    };
  };

  defaults = {
    dark = "dark";
    light = "light";
  };
}
