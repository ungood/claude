{
  description = "ungood's Claude plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          treefmt.programs = {
            nixfmt.enable = true;
            prettier = {
              enable = true;
              excludes = [ "*.md" ];
            };
            mdformat = {
              enable = true;
              plugins = pkgs': [ pkgs'.mdformat-frontmatter ];
              settings.number = true;
            };
          };

          pre-commit.settings.hooks.treefmt.enable = true;
          devShells.default = config.pre-commit.devShell;

          checks = {
            validate-schemas =
              pkgs.runCommand "validate-plugin-schemas" { buildInputs = [ pkgs.check-jsonschema ]; }
                ''
                  # Validate marketplace.json
                  check-jsonschema --schemafile ${./schemas/marketplace.schema.json} ${./.claude-plugin/marketplace.json}

                  # Validate all plugin.json files
                  for plugin in ${./plugins}/*/.claude-plugin/plugin.json; do
                    echo "Validating $plugin"
                    check-jsonschema --schemafile ${./schemas/plugin.schema.json} "$plugin"
                  done

                  touch $out
                '';
          };
        };
    };
}
