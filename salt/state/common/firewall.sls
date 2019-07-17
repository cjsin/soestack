#!stateconf yaml . jinja 

# Generic firewall setup to log rejected packets

.log-reject-chain-present:
    iptables.chain_present:
        - name:        LOG_REJECT
        - table:       filter
        - family:      ipv4


.log-rule:
    iptables.insert:
        - position:    1
        - table:       filter
        - chain:       LOG_REJECT
        - jump:        LOG
        - log-prefix:  'iptables-REJECT '

.reject-rule:
    iptables.insert:
        - table:       filter
        - chain:       LOG_REJECT
        - position:    2
        - jump:        REJECT 
        - reject-with: icmp-host-prohibited

{%- set last_rule_number = salt['cmd.shell']("iptables -L INPUT --line-numbers 2> /dev/null| tail -n1 | egrep '^[0-9].*[[:space:]]REJECT[[:space:]].*icmp-host' | cut -d' ' -f1") %}
{%- if last_rule_number != '' %}

.delete-default-reject:
    iptables.delete:
        - table:       filter
        - chain:       INPUT
        - jump:        REJECT
        - reject-with: icmp-host-prohibited 
        - position:    {{last_rule_number|json}}

{%- endif %}
