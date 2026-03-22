{ lib }:
let
  expand = registry: visited: tagName:
    if builtins.elem tagName visited
    then throw "Circular tag dependency detected: ${tagName} already visited in [${builtins.concatStringsSep ", " visited}]"
    else
      let
        tag =
          if builtins.hasAttr tagName registry
          then registry.${tagName}
          else throw "Unknown tag: ${tagName}";
        newVisited = visited ++ [ tagName ];
        depNames = lib.concatMap (expand registry newVisited) tag.deps;
      in
        [ tagName ] ++ depNames;
in
{
  resolveTags = registry: tagNames:
    let
      allTagNames = lib.unique (lib.concatMap (expand registry []) tagNames);
      allTags = map (n: registry.${n}) allTagNames;
    in
    {
      packages = lib.unique (lib.concatLists (map (t: t.packages) allTags));
      casks = lib.unique (lib.concatLists (map (t: t.casks) allTags));
    };
}
