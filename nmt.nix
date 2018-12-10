{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nmt;

in

{
  options.nmt = {
    name = mkOption {
      type = types.str;
      internal = true;
      readOnly = true;
      description = "Name of test case.";
    };

    description = mkOption {
      type = types.str;
      default = "";
      description = "Optional description of this test case.";
    };

    script = mkOption {
      type = types.str;
      example = ''
        assertFileExists home-files/.Xresources
      '';
      description = "Test script.";
    };

    tested = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The tested module result package.
      '';
    };

    wrappedScript = mkOption {
      type = types.str;
      internal = true;
      readOnly = true;
      description = ''
        The package containing the wrapped test script.
      '';
    };
  };

  config = {
    nmt.wrappedScript = ''
      output=$(
      TESTED="${cfg.tested}"
      ${cfg.script}
      )

      if [[ $? != 0 ]]; then
         errorEcho "${cfg.name}: FAILED"
         echo "$output"
         exit 1
      else
         noteEcho "${cfg.name}: OK"
      fi
    '';
  };
}
