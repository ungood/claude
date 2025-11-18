# Nix Development Best Practices

## Best Practices

- **Always use flakes**: All Nix projects should use flake support for reproducible, composable configurations with locked dependencies
- **Use flake-parts, NOT flake-utils**: flake-parts provides better composability through the module system, type-safe configuration, and improved code organization
- **Assume direnv integration**: User is using direnv with `.envrc` containing `use flake` to automatically activate Nix development environments
- **Use git-hooks-nix**: Manage pre-commit hooks in development shells using git-hooks-nix
- **Use treefmt-nix**: Use treefmt for code formatting and treefmt-nix for Nix integration
- **Use nixfmt**: nixfmt-rfc-style is now the default style for nixfmt.
- **Lock dependencies**: Always commit `flake.lock` to version control
- **Follow nixpkgs**: Use `inputs.nixpkgs.follows` to ensure consistency across inputs
- **Multi-system support**: Include common systems in the `systems` list (x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin)
- **Modular structure**: For complex projects, split configuration into separate modules and import them

## Complete Example

```nix
{
  description = "Example Nix project with best practices";

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
          ...
        }:
        {
          treefmt.programs = {
            nixfmt.enable = true;
            prettier.enable = true;
          };

          pre-commit.settings.hooks.treefmt.enable = true;
          devShells.default = config.pre-commit.devShell;
        };
    };
}
```
