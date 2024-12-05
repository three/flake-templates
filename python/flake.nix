{
  description = "Simple Python Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Could also use python2Packages, python310Packages, etc.
        python = pkgs.python3Packages.python.withPackages (ps: [
          ps.requests
          ps.numpy
        ]);

        # Example of including script inline
        example_script = pkgs.writeTextFile {
          name = "example-python-script";
          text = ''
            #!${python}/bin/python
            print("Hello World!")
          '';
          executable = true;
          destination = "/bin/example_script";
        };
      in {
        packages.default = pkgs.symlinkJoin {
          name = "example-python-project";
          paths = [
            python
            example_script
          ];
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/python";
          };
        };
      }
    );
}
