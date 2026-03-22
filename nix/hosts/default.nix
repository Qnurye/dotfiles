{ lib, ... }:

{
  options.myConfig = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name.";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tag names to install on this host.";
    };
  };
}
