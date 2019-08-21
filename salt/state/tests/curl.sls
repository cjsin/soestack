{%- with args = { 'test_type': 'curl' } %}
{%      include('tests/specific-type.sls') with context %}
{%- endwith %}
