# Backward compatibility for non-flake users
# Usage: nix-build
(import (
  fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "0x2jn3vrawwv9xp15674wjz9pixwjyj3j771izayl962zziivbx2";
  }
) {
  src = ./.;
}).defaultNix
