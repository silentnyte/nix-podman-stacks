{
  lib,
  config,
  ...
}: {
  # With HM version 25.11 the construction of the Quadlet file changed.
  # Quotation marks that appear in the Quadlet don't have to be extra escaped anymore
  # https://github.com/nix-community/home-manager/commit/d800d198b8376ffb6d8f34f12242600308b785ee
  escapeOnDemand = str:
    if lib.versionAtLeast config.home.version.release "25.11"
    then str
    else lib.replaceStrings [''"'' ''`''] [''\"'' ''\`''] str;
}
