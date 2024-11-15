# Flake Template Latex Builder

The intended usage is to use `nix shell .` to enter into a shell whereby you
will have access to latex tools and `document_build` `document_clean` and
`document_watch` commands which are defined in the nix file.

You can also use `nix build .` and run those commands from the `result` folder.

The flake *does not build your latex document* but provides *tooling for
building your latex document*.
