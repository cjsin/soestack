{%- if 'images' in args and args.images %}
{%-     for sitename, infos in args.images.iteritems() %}
{%-         if 'pull_from' in infos %}
{%-             set pull_from = infos.pull_from %}
{%-             set tag_into = infos.tag_into if 'tag_into' in infos else sitename ~ '/' %}
{%-             if 'images' in infos and infos.images %}
{%-                 for img, ver in infos.images.iteritems() %}
{%-                     set args = { 'pull_tag': pull_from ~ '/' ~ img ~ ':' ~ ver, 'new_tag': tag_into ~ img ~ ':' ~ ver } %}
{%                      include('templates/docker/pull_and_tag.sls') with context %}
{%-                 endfor %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
