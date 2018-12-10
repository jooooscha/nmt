{ modules, testedAttrPath, tests, pkgs }:

with pkgs.lib;

let

  evalTest = name: test: evalModules {
    modules =
      let
        initModule = { config, ... }: {
          nmt.name = name;
          nmt.tested = getAttrFromPath testedAttrPath config;
        };
      in
        [ initModule ./nmt.nix test ] ++ modules;
  };

  evaluatedTests = mapAttrs evalTest tests;

  runScriptHeader = ''
    set -uo pipefail

    . "${./bash-lib/color-echo.sh}"
    . "${./bash-lib/assertions.sh}"
  '';

  runTest = name: test:
    pkgs.runCommand
      "nmt-run-test-${test.config.nmt.name}"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        shellHook = ''
          ${runScriptHeader}

          ${test.config.nmt.wrappedScript}

          exit 0
        '';
      }
      "";

  runAllTests =
    pkgs.runCommand
      "nmt-run-all-tests"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        shellHook =
          let
            scripts =
              concatStringsSep "\n\n"
              (mapAttrsToList (n: test: test.config.nmt.wrappedScript)
              (evaluatedTests));
          in
            ''
              ${runScriptHeader}

              ${scripts}

              exit 0
            '';
      }
      "";

in

rec {
  run =
    mapAttrs runTest evaluatedTests
    // { all = runAllTests; };

  list =
    pkgs.runCommand
      "nmt-list-tests"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        shellHook =
          let
            scripts =
              concatStringsSep "\n"
              (map (n: "echo ${n}") (attrNames tests));
          in
            ''
              ${runScriptHeader}

              echo all
              ${scripts}

              exit 0
            '';
      }
      "";
}
