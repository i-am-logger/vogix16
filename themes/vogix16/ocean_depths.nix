{
  name = "ocean_depths";

  variants = {
    dark = {
      polarity = "dark";
      colors = {
        base00 = "#0c1a26";
        base01 = "#152736";
        base02 = "#1e3549";
        base03 = "#2d4c69";
        base04 = "#43678a";
        base05 = "#5d839c";
        base06 = "#a5c8dc";
        base07 = "#eef9ff";
        base08 = "#ff475e";
        base09 = "#ff9c5e";
        base0A = "#ffd373";
        base0B = "#60dfff";
        base0C = "#44ffd2";
        base0D = "#72c2d1";
        base0E = "#c39fff";
        base0F = "#b8865f";
      };
    };

    light = {
      polarity = "light";
      colors = {
        base00 = "#eef9ff";
        base01 = "#cce7f5";
        base02 = "#a5c8dc";
        base03 = "#5d839c";
        base04 = "#43678a";
        base05 = "#2d4c69";
        base06 = "#1e3549";
        base07 = "#0c1a26";
        base08 = "#e03553";
        base09 = "#e67e42";
        base0A = "#d9b44a";
        base0B = "#39b8df";
        base0C = "#1cd6ae";
        base0D = "#4aa5b5";
        base0E = "#9c7fdb";
        base0F = "#9a6f4a";
      };
    };
  };

  defaults = {
    dark = "dark";
    light = "light";
  };
}
