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
#--------------- loading general funcs
  if [ -f "$RUNDIR/files/my.general.functions.sh" ] ; then
    source "$RUNDIR/files/my.general.functions.sh"
  fi
#--------------- script vars
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

#--------------- checking argument functions
usage() {
     echo
     echo " Usage: $0 -u <username> [-i] [-g] [-h] [-d] [-m] [-a] [-v] [-s] [-x] [-p]"
     echo "  -u <username>  Specify the username (required)."
     echo "  -i             Install useful packages, if gui is set graphical if not only cmd. "
     echo "  -g             Install GUI Apps for Workstation (optional)."
     echo "  -h             Update Hardware Framework (optional)."
     echo "  -d             Perform a full software update (optional)."
     echo "  -m             Install Multimedia Packages (optional)."
     echo "  -a             Install Admin tools, docker, podman, kubectl, mysql-cli,... (optional)."
     echo "  -v             Install virtualizaiotn tools, KVM, QEMU, ... (optional)."
     echo "  -s             Disable SELINUX (optional) NOT RECOMMANDED."
     echo "  -x             Install extra packages (optional)."
     echo "  -p             Setup Proxy for dnf and docker (optional)."

     echo -e "${BWhite}\nRecommended:"
     echo -e "For Desktop Version:\n   $0 -u user -idgap"
     echo -e "${CLEAR}"

     exit 1
 }
check_args(){
  while getopts "u:xshdigmavp" opt; do
      case "$opt" in
          u) THEUSER="$OPTARG"
              ;;
          i) INSTALL=1
              ;;
          g) GUI=1
              ;;
          h) HARDWAREUP=1
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

          *) usage
              ;;
      esac
  done
  if [ -z "$THEUSER" ]; then
      err "error: \"-u username\" is required."
      usage
  fi
 }
# -------------- using functions
dnf_pkg_func(){
  if [ "$HASDNF5" -eq "1" ];then
    sudo dnf install -y --best --skip-unavailable --skip-broken --allowerasing $@
  else
    sudo dnf install -y --best --allowerasing $@
  fi
 }
dnf_grp_func(){
  if [ "$HASDNF5" -eq "1" ];then
    sudo dnf group install --with-optional -y --skip-unavailable --skip-broken --best --allowerasing $@
  else
    sudo dnf group install --with-optional -y --best --allowerasing $@
  fi
 }
disable_systemdns(){
    sudo resolvectl dns 
    sudo systemctl disable systemd-resolved
    sudo systemctl stop systemd-resolved
    sudo unlink /etc/resolv.conf 
    sudo echo -e "[main]\ndns=none" > /etc/NetworkManager/conf.d/90-dns-none.conf
    sudo echo "options timeout:1 attempts:10 rotate" >  /etc/resolv.conf
    sudo echo "nameserver 8.8.8.8" >>  /etc/resolv.conf
    sudo echo "nameserver 4.2.2.4" >> /etc/resolv.conf
    sudo echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    sudo echo "nameserver 9.9.9.9" >> /etc/resolv.conf
    sudo systemctl reload NetworkManager
  }
# ------------
check_fedora(){
    OS=`cat /etc/os-release 2> /dev/null ;hostnamectl 2> /dev/null`
    if [ `echo "$OS" | grep -ic fedora` -lt 1 ]; then
      err "This script is written to be used for Fedora Linux distribution only."
      exit 1
    fi
    HASDNF4=`sudo which dnf 2> /dev/null | grep -ic dnf`
    HASDNF5=`sudo which dnf5 2> /dev/null | grep -ic dnf5`
    let "FEDORAAAA=HASDNF4+HASDNF5"
    if [ "$FEDORAAAA" -lt "1" ] ; then
      err "This script is written to be used for Fedora Linux distribution only."
      err "no dnf found."
      exit 1
    fi
  }
configure(){
  sudo sed 's/^# %wheel/%wheel/' -i /etc/sudoers

  # config dnf
  if [ -f "$RUNDIR/files/dnf.conf" ] ; then 
      sudo cat "$RUNDIR/files/dnf.conf" > /etc/dnf/dnf.conf
  fi

  # source packages
  if [ -f "$RUNDIR/files/packages" ] ; then
    source "$RUNDIR/files/packages"
  fi

  # config mybash
  if [ -f "$RUNDIR/files/mybash" ] ; then
      sudo mkdir -p /root/.bashrc.d/
      if [ `sudo grep "source /root/.bashrc.d/mybash" -iwc /root/.bashrc 2> /dev/null` -ne "1" ] ;then
        sudo echo 'source /root/.bashrc.d/mybash' >> /root/.bashrc
      fi
      sudo cat "$RUNDIR/files/mybash" > /root/.bashrc.d/mybash

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
      sudo mkdir -p "/root/.ssh/"
      sudo cat "$RUNDIR/files/ssh.sample.config" > /root/.ssh/ssh.sample.config
      sudo mkdir -p /root/.ssh
      sudo touch /root/.ssh/authorized_keys
  fi

  # configure network manager 
  if [ "$GUI" -eq "1" ] ; then
    if [ -f "$RUNDIR/files/nm_connectivity.conf" ] ; then
        sudo cat "$RUNDIR/files/nm_connectivity.conf" > /etc/NetworkManager/conf.d/20-connectivity.conf
    fi
  fi

  # configure gnome templates
  if [ "$GUI" -eq "1" ] ; then
    sudo echo 'sample text' > /home/$THEUSER/Templates/new_text.txt
    sudo echo '#!/usr/bin/env bash' > /home/$THEUSER/Templates/new_bash_script.sh
    sudo echo '#!/usr/bin/env python3' > /home/$THEUSER/Templates/new_python_script.py
    sudo chmod +x /home/$THEUSER/Templates/new_python_script.py /home/$THEUSER/Templates/new_bash_script.sh
    sudo chown "$THEUSER:$THEUSER" -R /home/$THEUSER/
  fi
  }

config_repos(){

    enabled_repos=`sudo dnf repolist --enabled`

    # setting up workstation repositories
    if [ "$GUI" -eq "1" ] ; then

      if [ `sudo dnf list install fedora-workstation-repositories | grep -icw fedora-workstation-repositories ` -lt "1" ] ; then
        sudo dnf install fedora-workstation-repositories -y
      fi

      # setting up google chrome repo
      if [ "`echo "$enabled_repos" | grep -ic google-chrome`" -lt "1" ] ; then
        sudo dnf config-manager --set-enabled google-chrome     # Fedora40 DNF4
        sudo dnf config-manager setopt google-chrome.enabled=1  # Fedora41 DNF5 
      fi

      # setting up vscodium
      if [ "`echo "$enabled_repos" | grep -ic vscodium`" -lt "1" ] ; then
        if [ -f "$RUNDIR/files/vscodium.repo" ] ; then
          sudo rpmkeys --import "https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
          sudo cat "$RUNDIR/files/vscodium.repo" > /etc/yum.repos.d/vscodium.repo
        fi
      fi
    fi

    # setting up rpmfusion-free repo
    if [ "`echo "$enabled_repos" | grep -ic rpmfusion-free`" -lt "2" ] ; then
      sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
    
    # setting up rpmfusion-nonfree repo
    if [ "`echo "$enabled_repos" | grep -ic rpmfusion-nonfree`" -lt "1" ] ; then
      sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi
  }

disable_selinux(){
    if [ "$SELINUX" -eq "1" ]; then
      sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config        
      sudo setenforce 0
    fi
   }
before_install(){
    GIT=`sudo which git 2> /dev/null | grep -ic git`
    SCREEN=`sudo which screen 2> /dev/null | grep -ic screen`
    DELTARPM=`sudo rpm -ql deltarpm | grep -c bin.applydeltarpm`
    let "CHECK1=GIT+SCREEN+DELTARPM"
    if [ "$CHECK1" -lt "3" ] ; then
        dnf_pkg_func deltarpm git screen
    fi
 }
system_update(){
    if [ "$SOFTWAREUP" -eq "1" ]; then
      sudo dnf clean all
      sudo dnf distro-sync -y
      sudo dnf update --best --allowerasing -y --refresh
      if [ "$GUI" -eq "1" ] ; then
        sudo pip install --upgrade pip
      fi
    fi
  } 
hardware_update(){
    if [ "$HARDWAREUP" -eq "1" ]; then
      sudo fwupdmgr refresh --force
      sudo fwupdmgr get-updates
      sudo fwupdmgr update -y
    fi
  }
install_packages(){

  if [ "$INSTALL" -eq "1" ]; then

    # install srv base packages
      dnf_pkg_func "${SRV_BASE[@]}"

    # install srv extra packages
    if [ "$EXTRA" -eq "1" ]; then
      dnf_pkg_func "${SRV_EXTRA[@]}"
    fi

    if [ "$GUI" -eq "1" ] ; then
      # install gui base packages
        dnf_pkg_func "${GUI_BASE[@]}"
        dnf_grp_func "${GUI_GRP_BASE[@]}"

      # install gui extra packages
      if [ "$EXTRA" -eq "1" ]; then
        dnf_pkg_func "${GUI_EXTRA[@]}"
        dnf_grp_func "${GUI_GRP_EXTRA[@]}"
      fi

      # install gui multimedia packages
      if [ "$MMEDIA" -eq "1" ]; then
        dnf_pkg_func "${MMEDIA_BASE[@]}" "$MMEXCLUDES"
        dnf_grp_func "${MMGRPPKG[@]}"
          if [ "$EXTRA" -eq "1" ]; then
            dnf_pkg_func "${MMEDIA_EXTRA[@]}" "$MMEXCLUDES"
          fi
      fi
    fi
  fi
 }

remove_packages(){
  let "CHECKER=INSTALL+SOFTWAREUP+HARDWAREUP+SYSADMIN+VIRT"
  if [ "$CHECKER" -gt "1" ]; then
    sudo dnf remove "${REMOVE[@]}" -y
  fi
 }

system_admin_tools(){
  if [ "$SYSADMIN" -eq "1" ]; then
    # installing dbeaver-ce
    if [ "$GUI" -eq "1" ] ; then
      if [ "`dnf list --installed dbeaver-ce | grep -ic dbeaver-ce `" -lt "1" ] ; then
        sudo dnf install -y "$DBEAVER_URL"
      fi
    fi
    dnf_pkg_func ${ADMIN_TOOLS[@]} ${DOCKER[@]} ${KUBER[@]}
    dnf_grp_func $DOCKER_GRP

    sudo mkdir -p /etc/docker /usr/local/lib/docker/cli-plugins 

    # installing docker-compose
    if [ ! -f /usr/local/lib/docker/cli-plugins/docker-compose ] ; then
        # https://github.com/docker/compose/releases/latest
      GH_DP_COMPOSE=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | jq -r '.assets[] | "\(.name) \(.browser_download_url)"')
      DLND_URL=$(echo "$GH_DP_COMPOSE" | grep "linux-x86_64 " | awk '{print $2}')
      sudo curl -sSL "$DLND_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose
      sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    fi

    # installing docker-buildx
    if [ ! -f /usr/local/lib/docker/cli-plugins/docker-buildx ] ; then
        # https://github.com/docker/buildx/releases/latest
      GH_DP_COMPOSE=$(curl -s "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r '.assets[] | "\(.name) \(.browser_download_url)"')
      DLND_URL=$(echo "$GH_DP_COMPOSE" | grep "linux-amd64 " | awk '{print $2}')
      sudo curl -sSL $DLND_URL -o /usr/local/lib/docker/cli-plugins/docker-buildx
      sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx
    fi

    sudo echo -e "{\n\"bip\" : \"192.168.255.1/24\",\n\"data-root\": \"/data/docker-data/\"\n}\n" > /etc/docker/daemon.json

    # configuring docker kuber for gui user
    if [ "$GUI" -eq "1" ] ; then
      sudo usermod -a -G docker "$THEUSER"
      sudo mkdir -p /home/$THEUSER/.docker
      sudo echo '{"psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"}' > /home/$THEUSER/.docker/config.json
      sudo kubectl completion bash > /etc/bash_completion.d/kubectl 
      sudo mkdir -p "/home/$THEUSER/.kube/"
      sudo touch "/home/$THEUSER/.kube/conf"
    fi

    # configuring docker kuber for root user
    sudo mkdir -p /root/.docker
    sudo echo '{"psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"}' > /root/.docker/config.json
    sudo kubectl completion bash > /etc/bash_completion.d/kubectl 
    sudo mkdir -p "/root/.kube/"
    sudo touch "/root/.kube/conf"
    sudo systemctl enable docker
    sudo systemctl restart docker

  fi

  }
netadmin_tools(){

  if [ "$GUI" -eq "1" ] ; then
    # installing gns3 for gui
    if [ `sudo which pip 2> /dev/null | grep -ic pip` -lt "1" ] ; then 
      if [ "`pip list | grep -ci gns3`" -eq "0" ] ; then
        sudo pip install gns3-gui
      fi
    fi

    # installing winbox for gui
    if [ ! -f /opt/winbox/win/winbox64.exe  ] ; then
      dnf_pkg_func wine
      git clone https://github.com/darrenoshan/winbox_on_linux.git
      cd winbox_on_linux
      sudo bash ./install.sh
    fi
  fi
  cd "$RUNDIR"

 }

vm_virtualization(){
  
  if [ "$VIRT" -eq "1" ] ; then

    dnf_pkg_func "$VIRT_BASE"
    dnf_grp_func "$VIRT_GRP"

    if [ "`grep -icw 'user = "root"' /etc/libvirt/qemu.conf`" -lt "0" ];then
        sudo echo -e 'user = "root"' >> /etc/libvirt/qemu.conf
        sudo echo -e 'group = "root"' >> /etc/libvirt/qemu.conf
    fi

    if [ "$GUI" -eq "1" ] ; then
      NETS=`sudo virsh net-list`
      if [ -f ./files/virt-net-default-isolate.xml ] ; then
        if [ "`echo "$NETS" | grep -ic Default-Isolate`" -lt "1" ] ; then
          sudo virsh net-define --file "$LOGDIR/NET1.xml"
          sudo virsh net-autostart --network Default-Isolate
          sudo virsh net-start --network Default-Isolate
        fi
      fi
      if [ -f ./files/virt-net-default-nat.xml ] ; then
        if [ "`echo "$NETS" | grep -ic Default-NAT`" -lt "1" ] ; then
          sudo virsh net-define --file ./files/virt-net-default-nat.xml
          sudo virsh net-autostart --network Default-NAT
          sudo virsh net-start --network Default-NAT
        fi
      fi

    fi
    sudo systemctl enable libvirtd 
    sudo systemctl restart libvirtd
  fi
  }

post_install(){
    if [ "$GUI" -eq "1" ] ; then
      sudo rm -rf "/home/$THEUSER/.config/autostart/"
      sudo usermod -a -G wireshark "$THEUSER"
      sudo rm -rf  /home/$THEUSER/.local/state/wireplumber/
      sudo chown -R "$THEUSER:$THEUSER" `sudo -i -u $THEUSER printenv HOME`
    fi
    sudo git config --global init.defaultBranch main
    sudo touch /etc/vimrc ; sudo sed -i /etc/vimrc -e "s/set hlsearch/set nohlsearch/g"
    sudo timedatectl set-timezone Asia/Tehran 
    sudo timedatectl set-ntp true
    sudo systemctl daemon-reload
    SERVICES_ENABLE="NetworkManager firewalld sshd sysstat vnstat vmtoolsd chronyd crond docker"
    SERVICES_START="NetworkManager firewalld sshd sysstat vnstat vmtoolsd chronyd crond docker"
    for SRV in $SERVICES_ENABLE ; do sudo systemctl enable --now &> /dev/null  $SRV ; done
    for SRV in $SERVICES_START  ; do sudo systemctl restart      &> /dev/null  $SRV ; done
    sudo resolvectl flush-caches 
    sudo rpm --rebuilddb
 }
proxy(){
    if [ "$PROXY" -eq "1" ] ; then 
      sudo echo -e '\nproxy=http://ir.linuxmirrors.ir:8080\n' >> /etc/dnf/dnf.conf

      sudo mkdir -p /etc/systemd/system/docker.service.d
      echo '
      [Service]
      Environment="HTTP_PROXY=http://ir.linuxmirrors.ir:8080"
      Environment="HTTPS_PROXY=http://ir.linuxmirrors.ir:8080"
      Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp"
      ' > /etc/systemd/system/docker.service.d/00-proxy.conf
      # sduo systemctl daemon-reload   DISABLED BECAUSE THE post_install will restart docker anyway
      # sudo systemctl restart docker  DISABLED BECAUSE THE post_install will restart docker anyway 

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
check_args $@
main(){
  for STEP in $MAIN_STEPS ; do
    log -e " --------> ${BRed} Running : $STEP ${CLEAR}" | tee "$LOGFILE"
    # ($STEP | tee "$LOGFILE") 3>&1 1>&2 2>&3 | tee "$ERRFILE"
    $STEP
  done
}

main
