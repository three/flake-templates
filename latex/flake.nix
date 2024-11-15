{
  description = "Tooling for building Latex files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # The full texlive package can be quite large.
        # See https://nixos.wiki/wiki/TexLive for variants.
        texlive = pkgs.texlive.combined.scheme-full;

        document_name = "./document.tex";

        shell_vars = ''
          ${nixpkgs.lib.strings.toShellVar "DOCUMENT_NAME" document_name}
          ${nixpkgs.lib.strings.toShellVar "NIX_SYSTEM_TYPE" system}
        '';

        script_build = pkgs.writeShellScriptBin "document_build" ''
          set -x
          ${shell_vars}
          exec ${texlive}/bin/pdflatex -halt-on-error -synctex=1 "$DOCUMENT_NAME"
        '';
        script_clean = pkgs.writeShellScriptBin "document_clean" ''
          set -x
          ${shell_vars}
          rm -rf build *.pdf *.aux *.out *.log *.synctex.gz
        '';
        script_watch =
          if builtins.match ".*linux.*" system != null then
            pkgs.writeShellScriptBin "document_watch" ''
              set -x
              ${shell_vars}
              ${script_build}/bin/document_build || true
              while ${pkgs.inotify-tools}/bin/inotifywait "$DOCUMENT_NAME"; do
                ${script_build}/bin/document_build || true
              done
            ''
          else
            pkgs.writeShellScriptBin "document_watch" ''
              ${shell_vars}
              printf 'document_watch not supported on %s\n' "$NIX_SYSTEM_TYPE" >&2
              exit 1
              # TODO: Find an alternative to inotify-tools for OSX
            '';

      in {
        packages.default = pkgs.symlinkJoin {
          name = "latex-builder";
          paths = [
            texlive
            script_build
            script_clean
            script_watch
          ];
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/document_watch";
          };
        };
      }
    );
}
