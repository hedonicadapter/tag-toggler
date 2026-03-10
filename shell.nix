# to use this, simply run `nix-shell`
{
  oldPkgs ?
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/755b915a158c9d588f08e9b08da9f7f3422070cc.tar.gz";
    }) {
      config = {
        allowUnsupportedSystem = true;
        allowUnfree = true;
      };
    },
  pkgs ?
    import <nixpkgs> {
      config = {
        allowUnsupportedSystem = true;
        allowUnfree = true;
      };
    },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    powershell
    vscode
  ];

  shellHook = ''
    echo "⟡ ˚｡ ･ ─── ˗ˏˋ Azure Automation Runbooks Dev Environment ˎˊ˗ ─── ･ ｡ﾟ⟡ "
  '';
}
