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
    runShellOnlyCommand
      "nmt-run-test-${test.config.nmt.name}"
      ''
        ${runScriptHeader}

        ${test.config.nmt.wrappedScript}

        exit 0
      '';

  runAllTests =
    runShellOnlyCommand
      "nmt-run-all-tests"
      (
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
          ''
      );

in

rec {
  run =
    mapAttrs runTest evaluatedTests
    // { all = runAllTests; };

  list =
    runShellOnlyCommand
      "nmt-list-tests"
      (
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
          ''
      );
}
