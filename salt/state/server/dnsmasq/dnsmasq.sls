#!stateconf yaml . jinja

{%- with args = { 'nugget_name': 'dnsmasq', 'required_by': slspath } %}
{%      include('templates/nugget/install.sls') with context %}
{%- endwith %}

