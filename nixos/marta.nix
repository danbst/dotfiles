{ }:

{ pkgs, config, ... }:
{

  imports = [ ./common.nix ];

  services.nixosManual.showManual = true;
  services.openssh.enable = true;
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brother-hl2030 pkgs.cups_filters ];

  environment.systemPackages = with pkgs; [
    chromium
    firefox
    skype
    libreoffice
    sublime
    shotwell
  ];

  users.users."marta" = {
    hashedPassword = "$6$7dMLWxcLDtuSYeR$JtD.4LVc3SwB2JZzcjHFllyxtg2hZvoXZ.SJ7SHXaEzJAoFr2t8Sjpmbk3/VNmLNMcIxmOpx.icLy.y5lpSom/";
    isNormalUser = true;
    uid = 1001;
    description = "Marta Rychlewski";
    extraGroups = [ "wheel" "vboxusers" "networkmanager" ] ;
    group = "users";
    home = "/home/marta";
  };

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-unstable";
}
