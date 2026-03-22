{ lib, ... }:

{
  options.myConfig = {
    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tag names to install on this host.";
    };
  };
}
