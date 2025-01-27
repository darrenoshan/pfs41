#!/usr/bin/env bash
#  PS4='$LINENO: '
#  set -x
#--------------- init vars
  RUNCMD=`realpath $0`
  RUNDIR=`dirname $RUNCMD`
  cd "$RUNDIR"
  LOGDIR="$RUNDIR/temp"
  RUNTIME=`jdate +%Y%m%d%H%M%S 2> /dev/null || date +%Y%m%d%H%M%S`
  LOGFILE="$LOGDIR/$RUNTIME.log"
  ERRFILE="$LOGDIR/$RUNTIME.err"
  mkdir -p "$LOGDIR"
  touch "$LOGFILE"
  exec > >(tee -a "$LOGFILE") 2>&1
#--------------- loading general funcs
  if [ -f "$RUNDIR/files/my.general.functions.sh" ] ; then
    source "$RUNDIR/files/my.general.functions.sh"
  fi
#--------------- script vars
 AGREE=N
 THEUSER=""
 EXTRA=0
 SELINUX=0
 HARDWAREUP=0
 SOFTWAREUP=0
 INSTALL=0
 GUI=0
 MMEDIA=0
 SYSADMIN=0
 VIRT=0
 PROXY=0
 HASDNF4=0
 HASDNF5=0
 DESKENV=0

#--------------- usage and running
usage() {
     echo " Usage: $0 -u <username> [-i] [-g] [-h] [-d] [-m] [-a] [-v] [-s] [-x] [-p]"
     echo "  -u <username>  Specify the username (required) , IF NOT GUI could be skipped. "
     echo "  -i             Install useful packages, if gui is set graphical if not only cmd. "
     echo "  -g             Install GUI Apps for Workstation (optional)."
     echo "  -w             Update Hardware Framework (optional)."
     echo "  -d             Perform a full software update (optional)."
     echo "  -m             Install Multimedia Packages (optional)."
     echo "  -a             Install Admin tools, docker, podman, kubectl, mysql-cli,... (optional)."
     echo "  -v             Install virtualizaiotn tools, KVM, QEMU, ... (optional)."
     echo "  -s             Disable SELINUX (optional) NOT RECOMMANDED."
     echo "  -x             Install extra packages (optional)."
     echo "  -p             Setup Proxy for dnf and docker (optional)."

     echo -e "\nRecommended:"
     echo -e "For Desktop Version:\n   $0 -u user -idgap"
     end
 }
check_args(){
  while getopts "u:igwdmavsxpehWS" opt; do
      case "$opt" in
          u) THEUSER="$OPTARG"
              ;;
          i) INSTALL=1
              ;;
          g) GUI=1
              ;;
          w) HARDWAREUP=1
              ;;
          d) SOFTWAREUP=1
              ;;
          m) MMEDIA=1
              ;;
          a) SYSADMIN=1
              ;;
          v) VIRT=1
              ;;
          s) SELINUX=1
              ;;
          x) EXTRA=1
              ;;
          p) PROXY=1
              ;;
          e) DESKENV=1
              ;;
          h) usage
              ;;
          W) THEUSER="darren";INSTALL=1;GUI=1;DESKENV=1;HARDWAREUP=0;SOFTWAREUP=1;MMEDIA=1;SYSADMIN=1;VIRT=1;SELINUX=1;EXTRA=0;PROXY=1;
          # for Workstation automating silent
              ;;
          S) THEUSER="darren";INSTALL=1;GUI=0;DESKENV=0;HARDWAREUP=0;SOFTWAREUP=1;MMEDIA=0;SYSADMIN=1;VIRT=0;SELINUX=1;EXTRA=0;PROXY=0;
          # for Server automating silent
              ;;
          *) usage
              ;;
      esac
  done
  if [ "$GUI" -eq "1" ]; then
    if [ -z "$THEUSER" ]; then
        echo "error: \"-u username\" is required."
        usage
    fi
  fi
 }
save_run_vars(){
  echo  "AGREE        $AGREE"
  echo  "THEUSER      $THEUSER"
  echo  "EXTRA        $EXTRA"
  echo  "SELINUX      $SELINUX"
  echo  "HARDWAREUP   $HARDWAREUP"
  echo  "SOFTWAREUP   $SOFTWAREUP"
  echo  "INSTALL      $INSTALL"
  echo  "GUI          $GUI"
  echo  "MMEDIA       $MMEDIA"
  echo  "SYSADMIN     $SYSADMIN"
  echo  "VIRT         $VIRT"
  echo  "PROXY        $PROXY"
  echo  "HASDNF4      $HASDNF4"
  echo  "HASDNF5      $HASDNF5"
  echo  "DESKENV      $DESKENV"
 }
# -------------- functions
dnf_pkg_func(){
  if [ "$HASDNF5" -eq "1" ];then
    dnf install -y --best --skip-unavailable --skip-broken --allowerasing $@
  else
    dnf install -y --best --allowerasing $@
  fi
 }
dnf_grp_func(){
  if [ "$HASDNF5" -eq "1" ];then
    dnf group install --with-optional -y --skip-unavailable --skip-broken --best --allowerasing $@
  else
    dnf group install --with-optional -y --best --allowerasing $@
  fi
 }
disable_systemdns(){
    resolvectl dns 
    systemctl disable systemd-resolved
    systemctl stop systemd-resolved
    unlink /etc/resolv.conf 
    echo -e "[main]\ndns=none" > /etc/NetworkManager/conf.d/90-dns-none.conf
    echo "options timeout:1 attempts:10 rotate" >  /etc/resolv.conf
    echo "nameserver 8.8.8.8" >>  /etc/resolv.conf
    echo "nameserver 4.2.2.4" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    echo "nameserver 9.9.9.9" >> /etc/resolv.conf
    systemctl reload NetworkManager
  }
eula_agree(){
  echo -e '   ╔════════════════════════════════════════════════════════════════════════════════════╗'
  echo -e '   ║   THIS SCRIPT IS PROVIDED "AS IS" AND FOR PERSONAL USE ONLY.                       ║'
  echo -e '   ║   IT MAY NOT SUIT ALL USE CASES, AND NO WARRANTY OR SUPPORT IS OFFERED.            ║'
  echo -e '   ║   THIS SCRIPT IS LICENSED UNDER THE MIT LICENSE.                                   ║'
  echo -e '   ║   FOR MORE DETAILS, REFER TO THE LICENSE FILE IN THE REPOSITORY                    ║'
  echo -e '   ║   https://raw.githubusercontent.com/darrenoshan/pfs41/refs/heads/main/LICENSE      ║'
  echo -e '   ║                                                                                    ║'
  echo -e '   ║   THE SCRIPT IS WITTEN FOR FEDORA LINUX https://fedoraproject.org V41 ONLY         ║'
  echo -e '   ║   GET THE LATEST COPY OF THE FROM: https://github.com/darrenoshan/pfs41            ║'
  echo -e '   ╚════════════════════════════════════════════════════════════════════════════════════╝'
  line_pr
  read -p "   DO YO AGREE TO RUN THIS SCRIPT WITH THE ABOVE CONDITIONS ? [y/N] " -N1 AGREE
  echo -e ""
  line_pr
  if [ "`echo $AGREE | grep -icw y `" -ne "1" ]; then
    end 1
    exit 1
  fi
 }
check_fedora(){
    OS=`cat /etc/os-release 2> /dev/null ;hostnamectl 2> /dev/null`
    if [ `echo "$OS" | grep -ic fedora` -lt 1 ]; then
      err "This script is written to be used for Fedora Linux distribution only."
      end 1
    fi
    HASDNF4=`which dnf 2> /dev/null | grep -ic dnf`
    HASDNF5=`which dnf5 2> /dev/null | grep -ic dnf5`
    let "FEDORAAAA=HASDNF4+HASDNF5"
    if [ "$FEDORAAAA" -lt "1" ] ; then
      err "This script is written to be used for Fedora Linux distribution only."
      err "no dnf found."
      end 1
    fi
  }
configure(){
  sed 's/^# %wheel/%wheel/' -i /etc/sudoers

  # config dnf
  if [ -f "$RUNDIR/files/dnf.conf" ] ; then 
      cat "$RUNDIR/files/dnf.conf" > /etc/dnf/dnf.conf
  fi

  # source packages
  if [ -f "$RUNDIR/files/packages" ] ; then
    source "$RUNDIR/files/packages"
  fi

  # config mybash
  if [ -f "$RUNDIR/files/mybash" ] ; then
      mkdir -p /root/.bashrc.d/
      if [ `grep "source /root/.bashrc.d/mybash" -iwc /root/.bashrc 2> /dev/null` -ne "1" ] ;then
        echo 'source /root/.bashrc.d/mybash' >> /root/.bashrc
      fi
      cat "$RUNDIR/files/mybash" > /root/.bashrc.d/mybash

      if [ "$GUI" -eq "1" ] ; then
          mkdir -p /home/$THEUSER/.bashrc.d/
          cat "$RUNDIR/files/mybash" > /home/$THEUSER/.bashrc.d/mybash
      fi

  fi

  # config ssh client sample
  if [ -f "$RUNDIR/files/ssh.sample.config" ] ; then
    if [ "$GUI" -eq "1" ] ; then
      mkdir -p "/home/$THEUSER/.ssh/"
      cat "$RUNDIR/files/ssh.sample.config" > "/home/$THEUSER/.ssh/ssh.sample.config"
    fi
      mkdir -p "/root/.ssh/"
      cat "$RUNDIR/files/ssh.sample.config" > /root/.ssh/ssh.sample.config
      mkdir -p /root/.ssh
      touch /root/.ssh/authorized_keys
  fi

  # configure network manager 
  if [ "$GUI" -eq "1" ] ; then
    if [ -f "$RUNDIR/files/nm_connectivity.conf" ] ; then
        cat "$RUNDIR/files/nm_connectivity.conf" > /etc/NetworkManager/conf.d/20-connectivity.conf
    fi
  fi

  # configure gnome templates
  if [ "$GUI" -eq "1" ] ; then
    echo 'sample text' > /home/$THEUSER/Templates/new_text.txt
    echo '#!/usr/bin/env bash' > /home/$THEUSER/Templates/new_bash_script.sh
    echo '#!/usr/bin/env python3' > /home/$THEUSER/Templates/new_python_script.py
    chmod +x /home/$THEUSER/Templates/new_python_script.py /home/$THEUSER/Templates/new_bash_script.sh
    chown "$THEUSER:$THEUSER" -R /home/$THEUSER/
  fi
  }

config_repos(){

    enabled_repos=`dnf repolist --enabled`

    # setting up workstation repositories
    if [ "$GUI" -eq "1" ] ; then

      if [ `dnf list install fedora-workstation-repositories | grep -icw fedora-workstation-repositories ` -lt "1" ] ; then
        dnf install fedora-workstation-repositories -y
      fi

      # setting up google chrome repo
      if [ "`echo "$enabled_repos" | grep -ic google-chrome`" -lt "1" ] ; then
        dnf config-manager --set-enabled google-chrome     # Fedora40 DNF4
        dnf config-manager setopt google-chrome.enabled=1  # Fedora41 DNF5 
      fi

      # setting up vscodium
      if [ "`echo "$enabled_repos" | grep -ic vscodium`" -lt "1" ] ; then
        if [ -f "$RUNDIR/files/vscodium.repo" ] ; then
          rpmkeys --import "https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
          cat "$RUNDIR/files/vscodium.repo" > /etc/yum.repos.d/vscodium.repo
        fi
      fi
    fi

    # setting up rpmfusion-free repo
    if [ "`echo "$enabled_repos" | grep -ic rpmfusion-free`" -lt "2" ] ; then
      dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
    
    # setting up rpmfusion-nonfree repo
    if [ "`echo "$enabled_repos" | grep -ic rpmfusion-nonfree`" -lt "1" ] ; then
      dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi
  }

disable_selinux(){
    if [ "$SELINUX" -eq "1" ]; then
      sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config        
      setenforce 0
    fi
   }
before_install(){
    GIT=`which git 2> /dev/null | grep -ic git`
    SCREEN=`which screen 2> /dev/null | grep -ic screen`
    DELTARPM=`rpm -ql deltarpm | grep -c bin.applydeltarpm`
    let "CHECK1=GIT+SCREEN+DELTARPM"
    if [ "$CHECK1" -lt "3" ] ; then
        dnf_pkg_func deltarpm git screen
    fi
 }
system_update(){
    if [ "$SOFTWAREUP" -eq "1" ]; then
      dnf clean all
      dnf distro-sync -y
      dnf update --best --allowerasing -y --refresh
      if [ "$GUI" -eq "1" ] ; then
        pip install --upgrade pip
      fi
    fi
  } 
hardware_update(){
    if [ "$HARDWAREUP" -eq "1" ]; then
      fwupdmgr refresh --force
      fwupdmgr get-updates
      fwupdmgr update -y
    fi
  }
install_packages(){

  if [ "$INSTALL" -eq "1" ]; then

    # install srv base packages
      dnf_pkg_func "${SRV_BASE[@]}"
      dnf_grp_func "${SRV_BASE_GRP[@]}"      

    # install srv extra packages
    if [ "$EXTRA" -eq "1" ]; then
      dnf_pkg_func "${SRV_EXTRA[@]}"
    fi

    if [ "$GUI" -eq "1" ] ; then
      # install gui base packages
        dnf_pkg_func "${GUI_BASE[@]}"
        dnf_grp_func "${GUI_GRP_BASE[@]}"

      # install lightweight desktop environment
      if [ "$DESKENV" -eq "1" ]; then
        dnf_grp_func "${DESKTOPS_LIGHT[@]}"
      fi

      # install gui extra packages
      if [ "$EXTRA" -eq "1" ]; then
        dnf_pkg_func "${GUI_EXTRA[@]}"
        dnf_grp_func "${GUI_GRP_EXTRA[@]}"

          # install lightweight desktop environment extra
          if [ "$DESKENV" -eq "1" ]; then
            dnf_grp_func "${DESKTOPS_LIGHT_EXTRA[@]}"
          fi

      fi

    fi

    # install gui multimedia packages
    if [ "$MMEDIA" -eq "1" ]; then
      dnf_pkg_func ${MMEDIA_BASE[@]} $MMEXCLUDES
      dnf_grp_func ${MMGRPPKG[@]}
        if [ "$EXTRA" -eq "1" ]; then
          dnf_pkg_func "${MMEDIA_EXTRA[@]}" "$MMEXCLUDES"
        fi
      dnf swap ffmpeg-free ffmpeg --allowerasing -y
    fi

  fi
 }

remove_packages(){
  let "CHECKER=INSTALL+SOFTWAREUP+HARDWAREUP+SYSADMIN+VIRT"
  if [ "$CHECKER" -gt "1" ]; then
    dnf remove "${REMOVE[@]}" -y
  fi
 }

system_admin_tools(){
  if [ "$SYSADMIN" -eq "1" ]; then
    # installing dbeaver-ce
    if [ "$GUI" -eq "1" ] ; then
      if [ "`dnf list --installed dbeaver-ce | grep -ic dbeaver-ce `" -lt "1" ] ; then
        dnf_pkg_func "$DBEAVER_URL"
      fi
    fi
    dnf_pkg_func ${ADMIN_TOOLS[@]} ${DOCKER[@]} ${KUBER[@]}
    dnf_grp_func ${SYSADMIN_GRP[@]}

    mkdir -p /etc/docker /usr/local/lib/docker/cli-plugins 

    # installing docker-compose
    if [ ! -f /usr/local/lib/docker/cli-plugins/docker-compose ] ; then
        # https://github.com/docker/compose/releases/latest
      GH_DP_COMPOSE=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | jq -r '.assets[] | "\(.name) \(.browser_download_url)"')
      DLND_URL=$(echo "$GH_DP_COMPOSE" | grep "linux-x86_64 " | awk '{print $2}')
      curl -sSL "$DLND_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose
      chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    fi

    # installing docker-buildx
    if [ ! -f /usr/local/lib/docker/cli-plugins/docker-buildx ] ; then
        # https://github.com/docker/buildx/releases/latest
      GH_DP_COMPOSE=$(curl -s "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r '.assets[] | "\(.name) \(.browser_download_url)"')
      DLND_URL=$(echo "$GH_DP_COMPOSE" | grep "linux-amd64 " | awk '{print $2}')
      curl -sSL $DLND_URL -o /usr/local/lib/docker/cli-plugins/docker-buildx
      chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx
    fi

    echo -e "{\n\"bip\" : \"192.168.255.1/24\",\n\"data-root\": \"/data/docker-data/\"\n}\n" > /etc/docker/daemon.json

    # configuring docker kuber for gui user
    if [ "$GUI" -eq "1" ] ; then
      usermod -a -G docker "$THEUSER"
      mkdir -p /home/$THEUSER/.docker
      echo '{"psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"}' > /home/$THEUSER/.docker/config.json
      kubectl completion bash > /etc/bash_completion.d/kubectl 
      mkdir -p "/home/$THEUSER/.kube/"
      touch "/home/$THEUSER/.kube/config"
    fi

    # configuring docker kuber for root user
    mkdir -p /root/.docker
    echo '{"psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"}' > /root/.docker/config.json
    kubectl completion bash > /etc/bash_completion.d/kubectl 
    mkdir -p "/root/.kube/"
    touch "/root/.kube/conf"
    systemctl enable docker
    systemctl restart docker

  fi

  }
netadmin_tools(){

  if [ "$GUI" -eq "1" ] ; then
    # installing gns3 for gui
    if [ `which pip 2> /dev/null | grep -ic pip` -lt "1" ] ; then 
      dnf_pkg_func python3-pip
    fi
    if [ "`pip list | grep -ci gns3-gui`" -ne "1" ] ; then
      pip install gns3-gui==2.2.51
    fi

    # installing winbox for gui
    if [ ! -f /opt/winbox/win/winbox64.exe  ] ; then
      dnf_pkg_func wine
      git clone https://github.com/darrenoshan/winbox_on_linux.git
      cd winbox_on_linux
      bash ./install.sh
    fi
  fi
  cd "$RUNDIR"

 }

vm_virtualization(){
  
  if [ "$VIRT" -eq "1" ] ; then

    dnf_pkg_func "$VIRT_BASE"
    dnf_grp_func "$VIRT_GRP"

    if [ "`grep -icw 'user = "root"' /etc/libvirt/qemu.conf`" -lt "0" ];then
        echo -e 'user = "root"' >> /etc/libvirt/qemu.conf
        echo -e 'group = "root"' >> /etc/libvirt/qemu.conf
    fi

    if [ "$GUI" -eq "1" ] ; then
      NETS=`virsh net-list`
      if [ -f ./files/virt-net-default-isolate.xml ] ; then
      if [ "`echo "$NETS" | grep -ic Default-Isolate`" -lt "1" ] ; then
          virsh net-define --file "./files/virt-net-default-isolate.xml"
      fi ; fi
      if [ -f ./files/virt-net-default-nat.xml ] ; then
      if [ "`echo "$NETS" | grep -ic Default-NAT`" -lt "1" ] ; then
        virsh net-define --file ./files/virt-net-default-nat.xml
      fi ; fi
    virsh net-autostart --network Default-Isolate
    virsh net-start --network Default-Isolate
    virsh net-autostart --network Default-NAT
    virsh net-start --network Default-NAT
    fi
    systemctl enable libvirtd 
    systemctl restart libvirtd
  fi
  }

post_install(){
    if [ "$GUI" -eq "1" ] ; then
      rm -rf "/home/$THEUSER/.config/autostart/"
      usermod -a -G wireshark "$THEUSER"
      rm -rf  /home/$THEUSER/.local/state/wireplumber/
      chown -R "$THEUSER:$THEUSER" `su - $THEUSER -c 'printenv HOME'`
      timedatectl set-timezone Asia/Tehran
      # timedatectl set-timezone UTC
    fi
    git config --global init.defaultBranch main
    touch /etc/vimrc ; sed -i /etc/vimrc -e "s/set hlsearch/set nohlsearch/g"
    timedatectl set-ntp true
    systemctl daemon-reload

    SERVICES="NetworkManager firewalld sshd sysstat vnstat vmtoolsd chronyd crond docker"
    for SRV in $SERVICES  ; do systemctl restart      &> /dev/null  $SRV ; done
    resolvectl flush-caches 
    rpm --rebuilddb
 }
proxy(){
    if [ "$PROXY" -eq "1" ] ; then 
      echo -e '\nproxy=http://ir.linuxmirrors.ir:8080\n' >> /etc/dnf/dnf.conf

      mkdir -p /etc/systemd/system/docker.service.d
      echo '
      [Service]
      Environment="HTTP_PROXY=http://ir.linuxmirrors.ir:8080"
      Environment="HTTPS_PROXY=http://ir.linuxmirrors.ir:8080"
      Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp"
      ' > /etc/systemd/system/docker.service.d/00-proxy.conf
      # systemctl daemon-reload   DISABLED BECAUSE THE post_install will restart docker anyway
      # systemctl restart docker  DISABLED BECAUSE THE post_install will restart docker anyway 

    fi

 }
#
  MAIN_STEPS="
  check_fedora
  configure
  proxy
  disable_selinux
  config_repos
  before_install
  system_update
  hardware_update
  install_packages
  system_admin_tools
  netadmin_tools
  vm_virtualization
  remove_packages
  post_install
 "
#
main(){
  root_run
  set_tui
  check_args $@
  eula_agree
  save_run_vars >> "$LOGFILE"
    for STEP in $MAIN_STEPS ; do
      log " --------> Running : $STEP "
      echo -ne "${NORMAL}${MY_TUI2}"
      $STEP
      echo -ne "${MY_TUI1}"
    done
  line_pr
 }
#
main $@
end 0
