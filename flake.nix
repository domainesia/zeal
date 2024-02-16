{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }@inputs: utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    lib = pkgs.lib;
    qt6 = pkgs.qt6;
  in {
    packages.default = let
      isQt5 = pkgs.lib.versions.major pkgs.qt6.qtbase.version == "5";
    in pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "zeal";
      version = "0.7.0";

      src = pkgs.fetchFromGitHub {
        owner = "zealdocs";
        repo = "zeal";
        rev = "v${finalAttrs.version}";
        hash = "sha256-s1FaazHVtWE697BO0hIOgZVowdkq68R9x327ZnJRnlo=";
      };

      patches = [
        # fix build with qt 6.6.0
        # treewide: replace deprecated qAsConst with std::as_const()
        # https://github.com/zealdocs/zeal/pull/1565
        (pkgs.fetchpatch2 {
          url = "https://github.com/zealdocs/zeal/commit/d50a0115d58df2b222ede4c3a76b9686f4716465.patch";
          hash = "sha256-Ub6RCZGpLSOjvK17Jrm+meZuZGXcC4kI3QYl5HbsLWU=";
        })
      ];

      postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace 'ZEAL_VERSION_SUFFIX "-dev"' 'ZEAL_VERSION_SUFFIX ""'
      '';

      nativeBuildInputs = with pkgs; [
        cmake
        extra-cmake-modules
        pkg-config
        qt6.wrapQtAppsHook
      ];

      buildInputs = with pkgs; [
        xorg.libXdmcp
        libarchive
        xorg.libpthreadstubs
        qt6.qtbase
        qt6.qtimageformats
        qt6.qtwebengine
        xorg.xcbutilkeysyms
      ]
      ++ pkgs.lib.optionals isQt5 (with pkgs; [ qtx11extras ]);

      meta = {
        description = "A simple offline API documentation browser";
        longDescription = ''
          Zeal is a simple offline API documentation browser inspired by Dash (macOS
          app), available for Linux and Windows.
        '';
        homepage = "https://zealdocs.org/";
        changelog = "https://github.com/zealdocs/zeal/releases";
        license = pkgs.lib.licenses.gpl3Plus;
        maintainers = with pkgs.lib.maintainers; [ peterhoeg AndersonTorres ];
        inherit (pkgs.qt6.qtbase.meta) platforms;
      };
    });
  });
}
