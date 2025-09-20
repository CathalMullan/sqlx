{
  description = "sqlx";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
  };

  # nix flake show
  outputs =
    {
      nixpkgs,
      ...
    }:

    let
      perSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      systemPkgs = perSystem (
        system:

        import nixpkgs {
          inherit system;
        }
      );

      perSystemPkgs = f: perSystem (system: f (systemPkgs.${system}));
    in
    {
      devShells = perSystemPkgs (pkgs: {
        # nix develop
        default = pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
          name = "sqlx-shell";

          env = {
            # Nix
            NIX_PATH = "nixpkgs=${nixpkgs.outPath}";

            # Rust
            RUSTC_WRAPPER = "sccache";
            RUSTFLAGS = "-C target-cpu=native -C link-arg=-fuse-ld=mold";
            CARGO_INCREMENTAL = "0";

            # System
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.openssl ];
            LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.libclang ];

            # AWS LC
            AWS_LC_SYS_CC = "sccache clang";
            AWS_LC_SYS_CXX = "sccache clang++";
          };

          buildInputs = with pkgs; [
            # Rust
            rustc
            cargo
            clippy
            rust-analyzer
            rustfmt
            sccache
            mold
            taplo

            # System
            pkg-config
            openssl

            # AWS LC
            cmake
            perl
            go

            # Spellchecking
            typos
            typos-lsp

            # Nix
            nixfmt
            nixd
            nil
          ];
        };
      });
    };
}
