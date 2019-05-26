#!stateconf yaml . jinja 

.module-config:
    file.managed:
        - name: /etc/modprobe.d/99-wireless-emulation.conf
        - contents: |
            options mac80211_hwsim radios=1

.module-loaded:
    kmod.present:
        - mods: 
            - mac80211_hwsim
        - persist: True

#.autoload:
#    file.managed:
#        - name:     /etc/modules-load.d/99-wireless-emulation.conf
#        - contents: |
#            mac80211_hwsim

.hostapd-installed:
    pkg.installed:
        - pkgs:
            - hostapd

