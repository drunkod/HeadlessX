{
  description = "HeadlessX development environment and quick-start commands";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = pkgs.lib;

        # Change this to your real repository URL if you want a permanent default.
        defaultRepoUrl = "https://github.com/saifyxpro/HeadlessX";
        prismaEngines = pkgs."prisma-engines";
        prismaSchemaEngineBinary = "${prismaEngines}/bin/schema-engine";
        runtimeLibPath = lib.makeLibraryPath (
          commonLibs ++ [
            pkgs.openssl
            pkgs.zlib
            pkgs.stdenv.cc.cc.lib
            pkgs.nss
            pkgs.nspr
            pkgs.libgbm
            pkgs.glib
            pkgs.libxkbcommon
            pkgs.libxau
            pkgs.libxdmcp
          ]
        );
        nixLd = pkgs.stdenv.cc.bintools.dynamicLinker;

        commonLibs = with pkgs; [
          # Runtime libraries commonly needed by Prisma and browser tooling.
          stdenv.cc.cc.lib
          zlib
          nss
          nspr
          libgbm
          libdrm
          dbus
          alsa-lib
          gtk3
          pango
          cairo
          at-spi2-core
          at-spi2-atk
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxcb
          libxshmfence
          libxtst
          libxi
          libxcursor
          libxrender
          libxscrnsaver
          fontconfig
          freetype
        ];

        camoufoxVersion = "135.0.1-beta.24";
        camoufoxEnabled = system == "x86_64-linux";
        camoufoxRuntimeLibs = with pkgs; [
          stdenv.cc.cc.lib
          glib
          gtk3
          pango
          cairo
          gdk-pixbuf
          atk
          at-spi2-atk
          at-spi2-core
          libxkbcommon
          dbus
          alsa-lib
          fontconfig
          freetype
          libglvnd
          libdrm
          nss
          nspr
          libnotify
          cups
          pciutils
          vulkan-loader
          libva
          libgbm
          pipewire
          libpulseaudio
          libcanberra-gtk3
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxrender
          libxtst
          libxcb
          libxcursor
          libxi
          libxinerama
        ];
        camoufoxRuntimeLibPath = lib.makeLibraryPath camoufoxRuntimeLibs;
        camoufoxRuntimeBinPath = lib.makeBinPath [ pkgs.xdg-utils ];
        camoufoxXdgDataPath =
          "${pkgs.adwaita-icon-theme}/share:"
          + "${pkgs.gsettings-desktop-schemas}/share:"
          + "${pkgs.gtk3}/share";

        camoufoxUnwrapped =
          if camoufoxEnabled then
            pkgs.stdenvNoCC.mkDerivation rec {
              pname = "headlessx-camoufox-unwrapped";
              version = camoufoxVersion;

              src = pkgs.fetchzip {
                url = "https://github.com/daijro/camoufox/releases/download/v${version}/camoufox-${version}-lin.x86_64.zip";
                sha256 = "sha256-k5t12L5q0RG8Zun0SAjGthYQXUcf+xVHvk9Mknr97QY=";
                stripRoot = false;
              };

              nativeBuildInputs = [
                pkgs.jq
                pkgs.patchelf
              ];

              dontBuild = true;
              dontStrip = true;
              dontPatchELF = true;

              installPhase = ''
                runHook preInstall

                mkdir -p "$out/lib/camoufox"
                cp -a ./. "$out/lib/camoufox/"

                if [ -f "$out/lib/camoufox/distribution/policies.json" ]; then
                  tmp_policies="$(mktemp)"
                  jq '
                    if .policies then
                      .policies |= (
                        del(.SearchEngines)
                        | if (.Extensions and .Extensions.Uninstall) then
                            .Extensions.Uninstall |= map(select(test("@search\\.mozilla\\.org$") | not))
                          else
                            .
                          end
                      )
                    else
                      .
                    end
                  ' "$out/lib/camoufox/distribution/policies.json" > "$tmp_policies"
                  mv "$tmp_policies" "$out/lib/camoufox/distribution/policies.json"
                fi

                if [ -f "$out/lib/camoufox/camoufox.cfg" ]; then
                  sed -i 's|"browser.newtabpage.activity-stream.asrouter.providers.snippets", ""|"browser.newtabpage.activity-stream.asrouter.providers.snippets", "{}"|' "$out/lib/camoufox/camoufox.cfg"
                fi

                chmod +x "$out/lib/camoufox/camoufox"
                chmod +x "$out/lib/camoufox/camoufox-bin"

                if [ ! -e "$out/lib/camoufox/glxtest" ]; then
                  ln -s ${pkgs.firefox-unwrapped}/lib/firefox/glxtest "$out/lib/camoufox/glxtest"
                fi

                patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} "$out/lib/camoufox/camoufox"
                patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} "$out/lib/camoufox/camoufox-bin"

                runHook postInstall
              '';
            }
          else
            null;

        camoufoxWrapped =
          if camoufoxEnabled then
            pkgs.stdenvNoCC.mkDerivation rec {
              pname = "headlessx-camoufox";
              version = camoufoxVersion;

              nativeBuildInputs = [ pkgs.makeWrapper ];

              dontUnpack = true;
              dontBuild = true;

              buildCommand = ''
                mkdir -p "$out/bin" "$out/lib"
                ln -s ${camoufoxUnwrapped}/lib/camoufox "$out/lib/camoufox"

                makeWrapper ${camoufoxUnwrapped}/lib/camoufox/camoufox "$out/bin/camoufox" \
                  --prefix LD_LIBRARY_PATH : "${camoufoxRuntimeLibPath}:${camoufoxUnwrapped}/lib/camoufox" \
                  --suffix PATH : "${camoufoxRuntimeBinPath}" \
                  --suffix XDG_DATA_DIRS : "${camoufoxXdgDataPath}" \
                  --set MOZ_APP_LAUNCHER camoufox \
                  --set MOZ_LEGACY_PROFILES 1 \
                  --set MOZ_ALLOW_DOWNGRADE 1 \
                  --set-default MOZ_ENABLE_WAYLAND 1 \
                  --set-default LIBGL_ALWAYS_SOFTWARE 1 \
                  --set-default MOZ_WEBRENDER 0 \
                  --set-default MOZ_ACCELERATED 0 \
                  --set-default GDK_DISABLE_GL 1

                makeWrapper ${camoufoxUnwrapped}/lib/camoufox/camoufox-bin "$out/bin/camoufox-bin" \
                  --prefix LD_LIBRARY_PATH : "${camoufoxRuntimeLibPath}:${camoufoxUnwrapped}/lib/camoufox" \
                  --set-default LIBGL_ALWAYS_SOFTWARE 1 \
                  --set-default MOZ_WEBRENDER 0 \
                  --set-default MOZ_ACCELERATED 0 \
                  --set-default GDK_DISABLE_GL 1
              '';
            }
          else
            null;

        camoufoxExecutablePath =
          if camoufoxEnabled then
            "${camoufoxWrapped}/bin/camoufox-bin"
          else
            "";
        camoufoxUserPreferredPath = "/home/alex/Documents/camoufox-browser-nix/result/bin/camoufox-bin";

        mkApp = name: text:
          let
            app = pkgs.writeShellApplication {
              inherit name;
              runtimeInputs =
                (with pkgs; [
                  bash
                  coreutils
                  findutils
                  git
                  gnugrep
                  gnused
                  nodejs_22
                  pnpm
                  postgresql_16
                ])
                ++ lib.optionals camoufoxEnabled [ camoufoxWrapped ];
              text = ''
                export PRISMA_HIDE_UPDATE_MESSAGE=1
                export PRISMA_SCHEMA_ENGINE_BINARY="${prismaSchemaEngineBinary}"
                export NIX_LD="${nixLd}"
                export NIX_LD_LIBRARY_PATH="${runtimeLibPath}:''${NIX_LD_LIBRARY_PATH:-}"
                export LD_LIBRARY_PATH="${runtimeLibPath}:''${LD_LIBRARY_PATH:-}"
                ${lib.optionalString camoufoxEnabled ''
                  export CAMOUFOX_EXECUTABLE_PATH="$HOME/.cache/camoufox/camoufox-bin-nix"
                  mkdir -p "$HOME/.cache/camoufox"
                  if [ -x "''${HEADLESSX_CAMOUFOX_BIN:-${camoufoxUserPreferredPath}}" ]; then
                    ln -sf "''${HEADLESSX_CAMOUFOX_BIN:-${camoufoxUserPreferredPath}}" "$CAMOUFOX_EXECUTABLE_PATH"
                  else
                    ln -sf "${camoufoxExecutablePath}" "$CAMOUFOX_EXECUTABLE_PATH"
                  fi
                ''}
                ${text}
              '';
            };
          in {
            type = "app";
            program = "${app}/bin/${name}";
          };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22
            pnpm
            git
            bashInteractive
            openssl
            pkg-config
            python3
            gnumake
            gcc
            postgresql_16
            prismaEngines
            glib
            libxkbcommon
          ] ++ commonLibs ++ lib.optionals camoufoxEnabled [ camoufoxWrapped ];

          shellHook = ''
            export NODE_ENV=development
            export PRISMA_HIDE_UPDATE_MESSAGE=1
            export PRISMA_SCHEMA_ENGINE_BINARY="${prismaSchemaEngineBinary}"
            export NIX_LD="${nixLd}"
            export NIX_LD_LIBRARY_PATH="${runtimeLibPath}:''${NIX_LD_LIBRARY_PATH:-}"
            export LD_LIBRARY_PATH="${runtimeLibPath}:''${LD_LIBRARY_PATH:-}"
            ${lib.optionalString camoufoxEnabled ''
              export CAMOUFOX_EXECUTABLE_PATH="$HOME/.cache/camoufox/camoufox-bin-nix"
              mkdir -p "$HOME/.cache/camoufox"
              if [ -x "''${HEADLESSX_CAMOUFOX_BIN:-${camoufoxUserPreferredPath}}" ]; then
                ln -sf "''${HEADLESSX_CAMOUFOX_BIN:-${camoufoxUserPreferredPath}}" "$CAMOUFOX_EXECUTABLE_PATH"
              else
                ln -sf "${camoufoxExecutablePath}" "$CAMOUFOX_EXECUTABLE_PATH"
              fi
            ''}

            echo "HeadlessX dev shell ready."
            echo "Quick start with nix apps:"
            echo "  nix run .#clone -- <repo-url> [dir]"
            echo "  nix run .#env"
            echo "  nix run .#deps"
            echo "  nix run .#models"
            echo "  nix run .#db"
            echo "  nix run .#install-db"
            echo "  nix run .#postgres-start"
            echo "  nix run .#postgres-stop"
            echo "  nix run .#setup-install-db"
            echo "  nix run .#dev"
            echo "  nix run .#build"
            echo "  nix run .#start"
            echo "  nix run .#build-client"
            echo "  nix run .#start-client"
            echo "Or run all at once (after DATABASE_URL is set):"
            echo "  nix run .#setup"
          '';
        };

        apps.clone = mkApp "headlessx-clone" ''
          set -euo pipefail

          repo_url="''${1:-${defaultRepoUrl}}"
          target_dir="''${2:-.}"

          if [ "$target_dir" = "." ]; then
            if [ -n "$(find . -mindepth 1 -maxdepth 1 -print -quit)" ]; then
              echo "Current directory is not empty: $(pwd)"
              echo "Use an empty directory, or pass a target folder:"
              echo "  nix run .#clone -- <repo-url> HeadlessX"
              exit 1
            fi
            git clone "$repo_url" .
            echo "Cloned $repo_url -> $(pwd)"
            exit 0
          fi

          if [ -e "$target_dir" ]; then
            echo "Target path already exists: $target_dir"
            echo "Use: nix run .#clone -- <repo-url> <different-dir>"
            exit 1
          fi

          git clone "$repo_url" "$target_dir"
          echo "Cloned $repo_url -> $target_dir"
        '';

        apps.env = mkApp "headlessx-env" ''
          set -euo pipefail

          if [ ! -f ".env.example" ]; then
            echo ".env.example not found in $(pwd)"
            exit 1
          fi

          mkdir -p backend
          if [ -f "backend/.env" ]; then
            echo "backend/.env already exists; leaving it unchanged."
          else
            cp ".env.example" "backend/.env"
            echo "Created backend/.env from .env.example"
          fi

          echo "Edit backend/.env and set DATABASE_URL before db/setup."
        '';

        apps.deps = mkApp "headlessx-deps" ''
          set -euo pipefail
          pnpm install
        '';

        apps.models = mkApp "headlessx-models" ''
          set -euo pipefail

          if [ -f "./install.sh" ]; then
            chmod +x ./install.sh
            ./install.sh
          else
            pnpm run camoufox:fetch
          fi
        '';

        apps.db = mkApp "headlessx-db" ''
          set -euo pipefail

          if [ ! -f "backend/.env" ]; then
            echo "backend/.env not found. Run: nix run .#env"
            exit 1
          fi

          database_url="$(
            sed -n -E 's/^DATABASE_URL=(.*)$/\1/p' backend/.env | tail -n 1 \
              | tr -d '"' | tr -d "'" | tr -d '[:space:]'
          )"
          if [ -z "$database_url" ]; then
            echo "DATABASE_URL is missing or empty in backend/.env"
            exit 1
          fi

          pnpm db:push
        '';

        apps."install-db" = mkApp "headlessx-install-db" ''
          set -euo pipefail

          if [ ! -f "backend/.env" ]; then
            if [ -f ".env.example" ]; then
              mkdir -p backend
              cp ".env.example" "backend/.env"
              echo "Created backend/.env from .env.example"
              echo "Set DATABASE_URL in backend/.env and rerun:"
              echo "  nix run .#install-db"
              exit 2
            fi

            echo "backend/.env not found. Run: nix run .#env"
            exit 1
          fi

          database_url="$(
            sed -n -E 's/^DATABASE_URL=(.*)$/\1/p' backend/.env | tail -n 1 \
              | tr -d '"' | tr -d "'" | tr -d '[:space:]'
          )"
          if [ -z "$database_url" ]; then
            echo "DATABASE_URL is missing or empty in backend/.env"
            exit 1
          fi

          pnpm install
          pnpm db:push
        '';

        apps."postgres-start" = mkApp "headlessx-postgres-start" ''
          set -euo pipefail

          pg_data_dir="''${POSTGRES_DATA_DIR:-.postgres}"
          pg_port="''${POSTGRES_PORT:-5432}"
          pg_user="''${POSTGRES_USER:-postgres}"
          pg_db="''${POSTGRES_DB:-headlessx}"
          pg_socket_dir="$pg_data_dir"
          pg_log_file="$pg_data_dir/postgresql.log"

          mkdir -p "$pg_data_dir"

          if [ ! -f "$pg_data_dir/PG_VERSION" ]; then
            initdb -D "$pg_data_dir" --username="$pg_user" --auth=trust >/dev/null
            {
              echo "listen_addresses = '127.0.0.1'"
              echo "port = $pg_port"
              echo "unix_socket_directories = '$pg_socket_dir'"
            } >> "$pg_data_dir/postgresql.conf"
          fi

          if pg_ctl -D "$pg_data_dir" status >/dev/null 2>&1; then
            echo "PostgreSQL already running."
          else
            pg_ctl -D "$pg_data_dir" -l "$pg_log_file" start
          fi

          createdb -h "$pg_socket_dir" -p "$pg_port" -U "$pg_user" "$pg_db" >/dev/null 2>&1 || true
          echo "PostgreSQL running."
          echo "DATABASE_URL=\"postgresql://$pg_user@127.0.0.1:$pg_port/$pg_db\""
        '';

        apps."postgres-stop" = mkApp "headlessx-postgres-stop" ''
          set -euo pipefail

          pg_data_dir="''${POSTGRES_DATA_DIR:-.postgres}"

          if [ ! -d "$pg_data_dir" ]; then
            echo "PostgreSQL data directory not found: $pg_data_dir"
            exit 1
          fi

          if pg_ctl -D "$pg_data_dir" status >/dev/null 2>&1; then
            pg_ctl -D "$pg_data_dir" stop
            echo "PostgreSQL stopped."
          else
            echo "PostgreSQL is not running."
          fi
        '';

        apps."setup-install-db" = mkApp "headlessx-setup-install-db" ''
          set -euo pipefail

          if [ ! -f ".env.example" ]; then
            echo ".env.example not found in $(pwd)"
            exit 1
          fi

          mkdir -p backend
          if [ ! -f "backend/.env" ]; then
            cp ".env.example" "backend/.env"
            echo "Created backend/.env from .env.example"
          fi

          pg_data_dir="''${POSTGRES_DATA_DIR:-.postgres}"
          pg_port="''${POSTGRES_PORT:-5432}"
          pg_user="''${POSTGRES_USER:-postgres}"
          pg_db="''${POSTGRES_DB:-headlessx}"
          pg_socket_dir="$pg_data_dir"
          pg_log_file="$pg_data_dir/postgresql.log"
          local_db_url="postgresql://$pg_user@127.0.0.1:$pg_port/$pg_db"

          mkdir -p "$pg_data_dir"
          if [ ! -f "$pg_data_dir/PG_VERSION" ]; then
            initdb -D "$pg_data_dir" --username="$pg_user" --auth=trust >/dev/null
            {
              echo "listen_addresses = '127.0.0.1'"
              echo "port = $pg_port"
              echo "unix_socket_directories = '$pg_socket_dir'"
            } >> "$pg_data_dir/postgresql.conf"
          fi

          if ! pg_ctl -D "$pg_data_dir" status >/dev/null 2>&1; then
            pg_ctl -D "$pg_data_dir" -l "$pg_log_file" start
          fi

          createdb -h "$pg_socket_dir" -p "$pg_port" -U "$pg_user" "$pg_db" >/dev/null 2>&1 || true

          current_database_url="$(
            sed -n -E 's/^DATABASE_URL=(.*)$/\1/p' backend/.env | tail -n 1 \
              | tr -d '"' | tr -d "'" | tr -d '[:space:]'
          )"

          if [ -z "$current_database_url" ]; then
            tmp_env="$(mktemp)"
            awk -v db_url="$local_db_url" '
              BEGIN { updated = 0 }
              /^DATABASE_URL=/ {
                print "DATABASE_URL=\"" db_url "\""
                updated = 1
                next
              }
              { print }
              END {
                if (updated == 0) {
                  print "DATABASE_URL=\"" db_url "\""
                }
              }
            ' backend/.env > "$tmp_env"
            mv "$tmp_env" backend/.env
            echo "Set DATABASE_URL in backend/.env to local PostgreSQL."
          else
            echo "Using existing DATABASE_URL from backend/.env"
          fi

          pnpm install
          pnpm db:push
          echo "Install + database setup complete."
          echo "PostgreSQL is running with: $local_db_url"
        '';

        apps.dev = mkApp "headlessx-dev" ''
          set -euo pipefail
          pnpm dev
        '';

        apps.build = mkApp "headlessx-build" ''
          set -euo pipefail
          pnpm build
        '';

        apps.start = mkApp "headlessx-start" ''
          set -euo pipefail

          if [ ! -f "frontend/.next/BUILD_ID" ]; then
            echo "Frontend production build not found. Running client build..."
            pnpm --filter headlessx-frontend run build
          fi

          pnpm start
        '';

        apps."build-client" = mkApp "headlessx-build-client" ''
          set -euo pipefail
          pnpm --filter headlessx-frontend run build
        '';

        apps."start-client" = mkApp "headlessx-start-client" ''
          set -euo pipefail

          if [ ! -f "frontend/.next/BUILD_ID" ]; then
            echo "Frontend production build not found. Running client build..."
            pnpm --filter headlessx-frontend run build
          fi

          pnpm --filter headlessx-frontend run start
        '';

        apps.setup = mkApp "headlessx-setup" ''
          set -euo pipefail

          repo_url="''${1:-}"
          target_dir="''${2:-.}"

          if [ -n "$repo_url" ]; then
            if [ "$target_dir" = "." ]; then
              if [ -d ".git" ] || [ -f "package.json" ]; then
                echo "Using existing repository directory: $(pwd)"
              elif [ -n "$(find . -mindepth 1 -maxdepth 1 -print -quit)" ]; then
                echo "Current directory is not empty and does not look like a repo: $(pwd)"
                echo "Use an empty directory, or pass a target folder."
                exit 1
              else
                git clone "$repo_url" .
              fi
            else
              if [ -d "$target_dir/.git" ] || [ -f "$target_dir/package.json" ]; then
                echo "Using existing repository directory: $target_dir"
              elif [ -e "$target_dir" ]; then
                echo "Target path exists but does not look like a repo: $target_dir"
                exit 1
              else
                git clone "$repo_url" "$target_dir"
              fi
              cd "$target_dir"
            fi
          fi

          if [ ! -f ".env.example" ]; then
            echo ".env.example not found in $(pwd)"
            echo "Run inside the HeadlessX repo, or pass clone args:"
            echo "  nix run .#setup -- <repo-url> <target-dir>"
            exit 1
          fi

          if [ ! -f "backend/.env" ]; then
            mkdir -p backend
            cp ".env.example" "backend/.env"
            echo "Created backend/.env"
            echo "Set DATABASE_URL in backend/.env and rerun:"
            echo "  nix run .#setup"
            exit 2
          fi

          database_url="$(
            sed -n -E 's/^DATABASE_URL=(.*)$/\1/p' backend/.env | tail -n 1 \
              | tr -d '"' | tr -d "'" | tr -d '[:space:]'
          )"
          if [ -z "$database_url" ]; then
            echo "DATABASE_URL is missing or empty in backend/.env"
            echo "Set it and rerun: nix run .#setup"
            exit 2
          fi

          repo_path="$(pwd)"
          pnpm install

          if [ -f "./install.sh" ]; then
            chmod +x ./install.sh
            ./install.sh
          else
            pnpm run camoufox:fetch
          fi

          pnpm db:push
          echo "Setup complete."
          echo "Start services with:"
          echo "  cd $repo_path"
          echo "  pnpm dev"
        '';

        apps.default = self.apps.${system}.setup;
      });
}
