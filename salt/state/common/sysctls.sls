#!stateconf yaml . jinja 

.ip-forwarding:
    file.managed:
        - name:     /etc/sysctl.d/90-ip-forwarding.conf
        - user:     root 
        - group:    root
        - mode:     '0644'
        - contents: net.ipv4.ip_forward = 1

.sysrq:
    file.managed:
        - name:     /etc/sysctl.d/99-sysrq.conf
        - user:     root 
        - group:    root
        - mode:     '0644'
        - contents: kernel.sysrq = 1



