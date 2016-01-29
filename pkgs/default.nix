{ pkgs, base16Theme ? "default" }:

rec { 
  # TODO:
  #  - py3status configured
  #  - replace offlineimap with isync and add to systemd
  #  - add afew to systemd
  #  - create alot theme

  nixos_slim_theme = pkgs.fetchurl {
    url = "https://github.com/jagajaga/nixos-slim-theme/raw/master/nixos-slim-theme.tar.gz";
    sha256 = "0bn7m3msmwnhlmfz3x3zh29bgb8vs0l4d53m3z5jkgk9ryf03nk2";
  };

  brother-hl2030 = import ./brother-hl2030.nix {
    inherit (pkgs) stdenv fetchurl cups dpkg patchelf bash file coreutils;
    ghostscript = pkgs.ghostscript.override { x11Support = false; cupsSupport = true; };
  };

  chromium = pkgs.chromium.override {
    channel = "beta";
    enableHotwording = false;
    #gnomeSupport = true; 
    #gnomeKeyringSupport = true;
    proprietaryCodecs = true;
    enablePepperFlash = true;
    enableWideVine = true;
    cupsSupport = true;
    pulseSupport = true;
    #hiDPISupport = true;
  };

  rxvt_unicode-with-plugins = pkgs.rxvt_unicode-with-plugins.override {
    plugins = with pkgs; [
      urxvt_perl
      urxvt_perls
      urxvt_tabbedex
      urxvt_font_size
    ];
  };

  inherit (pkgs.callPackages <nixpkgs/pkgs/applications/networking/browsers/firefox> {
    inherit (pkgs.gnome) libIDL;
    inherit (pkgs.pythonPackages) pysqlite;
    libpng = pkgs.libpng_apng;
    #enableGTK3 = true;
    #enableOfficialBranding = true;
  }) firefox-unwrapped firefox-esr-unwrapped;

  firefox = pkgs.wrapFirefox firefox-unwrapped { };
  firefox-esr = pkgs.wrapFirefox firefox-esr-unwrapped { };

  nerdfonts = pkgs.stdenv.mkDerivation rec {
    rev = "6158e08ce0367090e9383a2e795aa03d3550f2b4";
    name = "nerdfonts-2015-${rev}";
    src = pkgs.fetchgit {
      inherit rev;
      url = "https://github.com/ryanoasis/nerd-fonts";
      sha256 = "0d9ddc679e3f47849cd510e7beb6979b5c898118eb8e4127dcddd4682714ec84";
    };
    patchPhase = ''
      sed -i -e 's|/bin/bash|${pkgs.bash}/bin/bash|g' install.sh
      sed -i -e 's|font_dir="$HOME/.fonts"|font_dir="$out/share/fonts"|g' install.sh
      sed -i -e 's|font_dir="$HOME/Library/Fonts"|font_dir="$out/share/fonts"|g' install.sh
      sed -i -e 's|/bin/bash|${pkgs.bash}/bin/bash|g' gotta-patch-em-all-font-patcher!.sh
      sed -i -e 's|/usr/bin/env python2|${pkgs.python2}/bin/python|g' font-patcher
    '';
    buildPhase = ''
      export PYTHONPATH=$PYTHONPATH:${pkgs.fontforge.override { withPython = true; }}/lib/python2.7/site-packages
      #./gotta-patch-em-all-font-patcher!.sh
    '';
    installPhase = ''
      mkdir -p $out/share/fonts
      ./install.sh
    '';
  };

  base16 = pkgs.callPackage ./base16.nix { };

  weechat = pkgs.weechat.override {
    extraBuildInputs = [ pkgs.pythonPackages.websocket_client ];
  };

  ttf_bitstream_vera = pkgs.callPackage ./ttf_bitstream_vera {
    inherit (pkgs) stdenv fetchgit;
  };

  st = pkgs.st.override {
    conf = import ./st_config.nix {
      theme = builtins.readFile "${base16}/st/base16-${base16Theme}.light.c";
    };
  };

  zsh_prezto =
    let
      rev = "f2a826e963f06a204dc0e09c05fc3e5419799f52";
    in pkgs.stdenv.mkDerivation rec {
      name = "zsh-prezto-2015";
      srcs = [
        (pkgs.fetchgit {
          url = "https://github.com/sorin-ionescu/prezto";
          sha256 = "0v8wf722vd7j0p63p6lcvr2s7y91a13s522r0izcay588x9bzslj";
          inherit rev;
          })
        (pkgs.fetchFromGitHub {
          owner = "garbas";
          repo = "nix-zsh-completions";
          rev = "9b7d216ec095ccee541ebfa5f04249aa2964d054";
          sha256 = "1pvmfcqdvdi3nc1jm72f54mwf06yrmlq31pqw6b5fczawcz02jrz";
          })
      ];
      sourceRoot = "prezto-${builtins.substring 0 7 rev}";
      buildPhase = ''
        echo "${import ./zsh_config.nix { inherit pkgs; }}" > zpreztorc
        sed -i -e "s|\''${ZDOTDIR:\-\$HOME}/.zpreztorc|$out/zpreztorc|g" init.zsh
        sed -i -e "s|\''${ZDOTDIR:\-\$HOME}/.zprezto/|$out/|g" init.zsh
        for i in runcoms/*; do
          sed -i -e "s|\''${ZDOTDIR:\-\$HOME}/.zprezto/|$out/|g" $i
        done
        sed -i -e "s|\''${0:h}/cache.zsh|\''${ZDOTDIR:\-\$HOME}/.zfasd_cache|g" modules/fasd/init.zsh
      '';
      installPhase = ''
        mkdir -p $out/modules/nix
        cp ../nix-zsh-completions-*/* $out/modules/nix -R
        cp ./* $out/ -R
      '';
    };

  neovim = pkgs.neovim.override {
    vimAlias = true;
    configure = import ./vim_config.nix { inherit pkgs base16 base16Theme; };
  };
}
