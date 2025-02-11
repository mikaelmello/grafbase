{
  # Nix: https://nixos.org/download.html
  # How to activate flakes: https://nixos.wiki/wiki/Flakes
  # For seamless integration, consider using:
  # - direnv: https://github.com/direnv/direnv
  # - nix-direnv: https://github.com/nix-community/nix-direnv
  #
  # # .envrc
  # use flake
  # dotenv .env
  #
  description = "Grafbase CLI development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dynein-nixpkgs.url = "github:pimeys/nixpkgs/dynein-0.2.1";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    dynein-nixpkgs,
    ...
  }: let
    inherit
      (nixpkgs.lib)
      optional
      ;
    systems = flake-utils.lib.system;
    
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };

      dyneinPkgs = import dynein-nixpkgs {
        inherit system;
      };

      x86_64LinuxPkgs = import nixpkgs {
        inherit system;
        crossSystem = {
          config = "x86_64-unknown-linux-musl";
        };
      };

      x86_64LinuxBuildPkgs = x86_64LinuxPkgs.buildPackages;
      rustToolChain = pkgs.rust-bin.fromRustupToolchainFile ./cli/rust-toolchain.toml;
      defaultShellConf = {
        nativeBuildInputs = with pkgs;
          [
            # I gave up, it's just too cumbersome over time with rust-analyzer because of:
            # https://github.com/rust-lang/cargo/issues/10096
            # So I ended up using rustup
            # rustToolChain
            rustup
            sccache
            pkg-config
            openssl.dev
            # for sqlx-macros
            libiconv

            cargo-nextest
            # Used for resolver tests
            nodePackages.pnpm
            nodePackages.yarn

            # Miniflare
            nodejs

            # Formatting
            nodePackages.prettier

            # Versioning
            nodePackages.semver

            # Local DynamoDB handling
            dyneinPkgs.dynein
          ]
          ++ optional (system == systems.aarch64-darwin) [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
          ];

        RUSTC_WRAPPER = "${pkgs.sccache.out}/bin/sccache";

        shellHook = ''
          export CARGO_INSTALL_ROOT="$(git rev-parse --show-toplevel)/cli/.cargo"
          export PATH="$CARGO_INSTALL_ROOT/bin:$PATH"
        '';
      };
    in {
      devShells.default = pkgs.mkShell defaultShellConf;
      devShells.full = pkgs.mkShell (defaultShellConf
        // {
          buildInputs = with pkgs; [
            rustToolChain
            x86_64LinuxBuildPkgs.gcc
          ];

          CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = "${x86_64LinuxBuildPkgs.gcc.out}/bin/x86_64-unknown-linux-gnu-gcc";
          CC_x86_64_unknown_linux_musl = "${x86_64LinuxBuildPkgs.gcc.out}/bin/x86_64-unknown-linux-gnu-gcc";
        });
      # Nightly Rust
      #
      # Clippy:
      #   nix develop .#nightly --command bash -c 'cd cli && cargo clippy --all-targets'
      #
      # Check Rust version:
      #   nix develop .#nightly --command bash -c 'echo "$PATH" | tr ":" "\n" | grep nightly'
      devShells.nightly = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          (rust-bin.selectLatestNightlyWith
            (toolchain:
              toolchain.minimal.override {
                extensions = ["clippy"];
              }))
        ];
      };
    });
}

