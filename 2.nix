with builtins;
let
  lib = (import <nixpkgs> { }).lib;
  extract = str: filter (item: typeOf item == "list") (split "([[:digit:]]+)-([[:digit:]]+)" str);
  expand = all: concatMap (list: lib.range (elemAt list 0) (elemAt list 1)) (map (map lib.toInt) all);
  test =
    id:
    let
      string = toString id;
      length = stringLength string;
    in
  if length % 2 == 0 then false else true;

  example = readfile ./examples/2.txt;
in
{
  example2 = filter test (expand (extract example));
}
