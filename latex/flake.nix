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

        script_build = pkgs.writeShellScriptBin "document_build" ''
          set -x
          exec ${texlive}/bin/pdflatex -halt-on-error -synctex=1 '${document_name}'
        '';
        script_clean = pkgs.writeShellScriptBin "document_clean" ''
          set -x
          rm -rf build *.pdf *.aux *.out *.log *.synctex.gz
        '';
        script_watch =
          if builtins.match ".*linux.*" system != null then
            pkgs.writeShellScriptBin "document_watch" ''
              set -x
              ${script_build}/bin/document_build || true
              while ${pkgs.inotify-tools}/bin/inotifywait '${document_name}'; do
                ${script_build}/bin/document_build || true
              done
            ''
          else
            pkgs.writeShellScriptBin "document_watch" ''
              printf 'document_watch not supported on %s\n' '${system}' >&2
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
            program = "${self.packages.${system}.default}/bin/resume_watch";
          };
        };
      }
    );
}
