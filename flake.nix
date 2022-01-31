{

  description = "odroid";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
  };

  outputs = { self, nixpkgs, }@inp:

  let
    l = nixpkgs.lib // builtins;
  in

  {

    # To build, use:
    # nix-build nixos -I nixos-config=nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix -A config.system.build.sdImage
    nixosConfigurations.odroid = l.nixosSystem {
      system = "x86_64-linux";
      specialArgs.pkgs = import nixpkgs { system = "x86_64-linux"; crossSystem = "armv7l-linux"; };
      modules = [
        (
          { config, lib, pkgs, modulesPath, ... }: {
            imports = [
              "${modulesPath}/profiles/base.nix"
              "${modulesPath}/installer/sd-card/sd-image.nix"
            ];

            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;

            boot.consoleLogLevel = lib.mkDefault 7;
            boot.kernelPackages = pkgs.linuxPackages_hardkernel_4_14;
            # The serial ports listed here are:
            # - ttyS0: for Tegra (Jetson TK1)
            # - ttymxc0: for i.MX6 (Wandboard)
            # - ttyAMA0: for Allwinner (pcDuino3 Nano) and QEMU's -machine virt
            # - ttyO0: for OMAP (BeagleBone Black)
            # - ttySAC2: for Exynos (ODROID-XU3)
            boot.kernelParams = ["console=ttyS0,115200n8" "console=ttymxc0,115200n8" "console=ttyAMA0,115200n8" "console=ttyO0,115200n8" "console=ttySAC2,115200n8" "console=tty0"];

            sdImage = {
              populateFirmwareCommands = let
                configTxt = pkgs.writeText "config.txt" ''
                  #a config file which is empty
                '';
                in ''
                  #(cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)

                  # Add the config
                  #cp ${configTxt} firmware/config.txt

                  # Add xu4 specific files which are the same like xu3
                  cp ${pkgs.ubootOdroidXU3}/u-boot.bin firmware/u-boot-xu4.bin
                '';
              populateRootCommands = ''
                mkdir -p ./files/boot
                ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
              '';
            };
          }
        )
      ];
    };


  };

}
