#!stateconf yaml . jinja

{%- if 'selinux' in pillar  and 'mode' in pillar.selinux %}
{%-     set diagnostics = False %}
{#      # The selinux modules always reports it has changed even if it hasn't #}
{#      # so we take steps here to check first: #}
{#      # Additionally, the selinux module does not seem to update the /etc/sysconfig/selinux file at all #}
{#      # so we do that ourselves #}
{%-     set mode = pillar.selinux.mode %}
{%-     set completely_disable =   mode.lower() == 'disabled' %}
{%-     set enabled = not completely_disable %}
{%-     set permissive = enabled and (mode == '0' or mode == 0 or mode.lower() == 'permissive') %}
{%-     set enforcing  = enabled and not permissive %}
{%-     set cfgfile_status = salt['cmd.run'](['bash','-c','egrep ^SELINUX= /etc/sysconfig/selinux | cut -d= -f2 | tail -n1']).lower() %}
{%-     set getenforce_status = salt['cmd.run']('getenforce').lower() %}

            
{%-     set any_mismatch = 
            (completely_disable and (cfgfile_status != 'disabled' or getenforce_status == 'enforcing')) 
            or (enforcing and (cfgfile_status != 'enforcing' or getenforce_status != 'enforcing' ))
            or (permissive and (cfgfile_status != 'permissive' or getenforce_status != 'permissive')) %}

{%-     if diagnostics or any_mismatch %}
.status-selinux:
    cmd.run:
        - name: |
            echo "mode = {{mode}}"
            echo "completely disable = {{completely_disable}}"
            echo "should be enabled = {{enabled }}"
            echo "should be permissive = {{permissive}}"
            echo "should be enforcing {{enforcing}}"
            echo "cfgfile status= {{cfgfile_status}}"
            echo "getenforce status = {{getenforce_status}}"
            echo "mismatch = {{any_mismatch}}"
{%-     endif %}

{%-     if any_mismatch %}

.enable-or-disable:
    selinux.mode:
        - name: {{mode}}

{%-     endif %}

{%-     if cfgfile_status != mode %}

.sysconfig-patch-entry:
    cmd.run:
        - name:   sed -i '/^SELINUX=/ s/=.*/={{mode}}/' /etc/sysconfig/selinux
        - onlyif: bash -c 'egrep "^SELINUX=" /etc/sysconfig/selinux | egrep -vi -- "={{mode}}"'

.sysconfig-add-entry:
    cmd.run:
        - name:   echo "SELINUX={{mode}}" >> /etc/sysconfig/selinux
        - unless: bash -c 'egrep "^SELINUX=" /etc/sysconfig/selinux'

{%-     endif %}

{%- endif %}
