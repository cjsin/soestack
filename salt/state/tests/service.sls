{%- with args = { 'test_type': 'service' } %}
{%      include('tests/specific-type.sls') with context %}
{%- endwith %}
