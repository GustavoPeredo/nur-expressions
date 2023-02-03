{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.flatpak;
  repo = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        description = lib.mdDoc "Whether the repository should be enabled.";
        default = true;
      };
      system = mkOption {
        type = types.bool;
        description = lib.mdDoc "Whether the repository should be installed to all users.";
        default = false;
      };
      name = mkOption {
        type = types.str;
        description = libmdDoc "The name of the repository.";
      };
      url = mkOption {
        type = types.str;
        description = libmdDoc "The url of the repository.";
      };
      apps = mkOption {
        type = types.listOf types.str;
        description = libmdDoc "List of app schemas (org.gnome.Calculator).";
      };
    };
  };
  recursiveMergeAttrs = listOfAttrsets: lib.fold (attrset: acc: lib.recursiveUpdate attrset acc) {} listOfAttrsets;
  getAppsSh = pkgs.writeShellScript "flatpak-get-apps.sh" ''
              shopt -s lastpipe
              repo_name="$1"
              location="$2"
              
              apps=''${3:-""}

              results=""
              ${pkgs.flatpak}/bin/flatpak $location list $apps --columns ref,origin | while read p
              do 
                repo="$(${pkgs.coreutils}/bin/echo $p | ${pkgs.gawk}/bin/awk '{ print $2 }')"
                app="$(${pkgs.coreutils}/bin/echo $p | ${pkgs.gawk}/bin/awk '{ print $1 }')"
                if [[ "$repo" == "$repo_name" ]]
                then
                  results="$results $app"
                fi
              done
              ${pkgs.coreutils}/bin/echo $results
            '';
  managerSh = pkgs.writeShellScript "flatpak-manager.sh" ''
              repo_name="$2"
              location="$3"


              to_install_apps="$1"
              to_remove_apps=""
              installed_apps="$(${pkgs.bash}/bin/bash ${getAppsSh} $repo_name $location "--app")"
              ${pkgs.coreutils}/bin/sleep 5
              for installed_app in $installed_apps
              do
                found=0
                for to_install_app in $to_install_apps
                do
                  if [[ "$installed_app" == *"$to_install_app"* ]]
                  then
                    found=1
                  fi
                done
                if [[ $found == 0 ]]
                then
                  to_remove_apps="$to_remove_apps $installed_app"
                fi
              done
              if [ ! -z "$to_remove_apps" ]
              then
                ${pkgs.flatpak}/bin/flatpak $location uninstall --noninteractive --assumeyes $to_remove_apps
              fi
              if [ ! -z "$to_install_apps" ]
              then
                ${pkgs.flatpak}/bin/flatpak $location install --or-update --noninteractive --assumeyes $repo_name $to_install_apps
              fi
            '';
  removeAllSh = pkgs.writeShellScript "flatpak-delete.sh" ''
                repo_name="$1"
                location="$2"

                to_remove_apps="$(${pkgs.bash}/bin/bash ${getAppsSh} $repo_name $location)"
                if [ ! -z "$to_remove_apps" ]
                then
                  ${pkgs.flatpak}/bin/flatpak $location uninstall --noninteractive --assumeyes $to_remove_apps
                fi
                ${pkgs.flatpak}/bin/flatpak $location remote-delete $repo_name
             '';
                
in {
  options.services.flatpak = {
    enable = mkEnableOption "flatpak repo manager";
    repos = mkOption {
      type = types.listOf repo;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    systemd.user.startServices = "sd-switch";
    systemd.user.services = recursiveMergeAttrs (lib.forEach cfg.repos (repo: (
      if repo.enable then {
        "flatpak-add-${repo.name}" = {
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add ${if repo.system then "--system" else "--user"} --if-not-exists ${repo.name} ${repo.url}";
            ExecStartPost = "${pkgs.coreutils}/bin/touch ${config.home.homeDirectory}/.local/share/flatpak/.${repo.name}-initialized";
	    RemainAfterExit = "yes";
            Type = "simple";
          };
          Unit = {
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
            ConditionPathExists = "!${config.home.homeDirectory}/.local/share/flatpak/.${repo.name}-initialized";
            Description = "Add the ${repo.name} flatpak repository";
          };
        };
	"flatpak-install-${repo.name}-apps" = {
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            ExecStart = "${pkgs.bash}/bin/bash ${managerSh} \"${concatMapStrings (i: " " + i) repo.apps}\" \"${repo.name}\" \"${if repo.system then "--system" else "--user"}\"";
	    RemainAfterExit = "yes";
            Type = "simple";
          };
          Unit = {
            After = [ "flatpak-add-${repo.name}.service" ];
            PartOf = [ "graphical-session.target" ];
            Description = "Install apps from the ${repo.name} flatpak repository";
          };
        };
      }
      else {
        "flatpak-remove-${repo.name}" = {
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            ExecStart = "${pkgs.bash}/bin/bash ${removeAllSh} ${repo.name} ${if repo.system then "--system" else "--user"}";
            ExecStartPost = "${pkgs.coreutils}/bin/rm \"${config.home.homeDirectory}/.local/share/flatpak/.${repo.name}-initialized\"";
            RemainAfterExit = "yes";
            Type = "simple";
          };
          Unit = {
            After = [ "graphical-session-pre.target" "flatpak-remove-${repo.name}-apps.service" ];
            PartOf = [ "graphical-session.target" ];
            ConditionPathExists = "${config.home.homeDirectory}/.local/share/flatpak/.${repo.name}-initialized";
            Description = "Remove the ${repo.name} flatpak repository";
          };
        };
      }
    )));
  };
}