#!stateconf yaml . jinja

{%- with args = {
        'dotd_path' : '/etc/profile.d',
        'pillar_key': 'bash:profile',
        'contentdir': slspath ~ '/files',
        'extension' : 'sh',
        'mode'      : '0644',
        'user'      : 'root',
        'group'     : 'root' } %}
{%      include('templates/dotd_folder.sls') with context %}
{%- endwith %}
