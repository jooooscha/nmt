{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nmt;

in {
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

    result = {
      success = mkOption {
        type = types.bool;
        internal = true;
        readOnly = true;
        description = ''
          Whether the test succeeded.
        '';
      };

      report = mkOption {
        type = types.package;
        internal = true;
        readOnly = true;
        description = ''
          The test results.
        '';
      };
    };
  };

  config = {
    nmt.result = {
      success = ''
        OK
      '' == builtins.readFile "${cfg.result.report}/result";

      report = let
        scriptPath =
          makeBinPath (with pkgs; [ coreutils diffutils findutils gnugrep ]);

        testScript = pkgs.writeShellScript "nmt-test-script-${cfg.name}" ''
          set -uo pipefail

          export PATH="${scriptPath}"

          . "${./bash-lib/assertions.sh}"

          TESTED="${cfg.tested}"
          ${cfg.script}
        '';
      in pkgs.runCommandLocal "nmt-report-${cfg.name}" { } ''
        mkdir -p $out
        ln -s ${cfg.tested} $out/tested
        ln -s ${testScript} $out/script
        if ${testScript} 2>&1 > $out/output; then
          echo OK > $out/result
        else
          echo FAILED > $out/result
        fi
      '';
    };
  };
}
