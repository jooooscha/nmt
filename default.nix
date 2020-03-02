{ modules, testedAttrPath, tests, pkgs, lib ? pkgs.lib }:

with lib;

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

  scriptPath = makeBinPath (with pkgs; [
    # For tput.
    ncurses
  ]);

  runScript = name: script:
    runShellOnlyCommand name ''
      set -uo pipefail

      export PATH="${scriptPath}''${PATH:+:}$PATH"

      . "${./bash-lib/color-echo.sh}"
      . "${./bash-lib/assertions.sh}"

      ${script}

      exit 0
    '';

  runShellOnlyCommand = name: shellHook:
    pkgs.runCommand
      name
      {
        inherit shellHook;
        allowSubstitutes = false;
        preferLocalBuild = true;
      }
      ''
        echo This derivation is only useful when run through nix-shell.
        exit 1
      '';

  runTest = name: test:
    runScript
      "nmt-run-test-${test.config.nmt.name}"
      test.config.nmt.wrappedScript;

  runAllTests =
    runScript "nmt-run-all-tests" (
      concatStringsSep "\n\n"
      (mapAttrsToList (n: test: test.config.nmt.wrappedScript)
      (evaluatedTests))
    );

in

rec {
  run =
    mapAttrs runTest evaluatedTests
    // { all = runAllTests; };

  list =
    runScript
      "nmt-list-tests"
      (
        let
          scripts =
            concatStringsSep "\n"
            (map (n: "echo ${n}") (attrNames tests));
        in
          ''
            echo all
            ${scripts}
          ''
      );
}
