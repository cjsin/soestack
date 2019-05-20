{%- set pull_tag = args.pull_tag %}
{%- set new_tag  = args.new_tag %}

pull-image-{{pull_tag}}:
    cmd.run:
        - name:   docker pull '{{pull_tag}}'
        - unless: docker images --format '{%raw%}{{.Repository}}:{{.Tag}}{%endraw%}' | grep '{{pull_tag}}'

tag-image-{{pull_tag}}-as-{{new_tag}}:
    cmd.run:
        - name:   docker tag '{{pull_tag}}' '{{new_tag}}'
        - onlyif: docker images --format '{%raw%}{{.Repository}}:{{.Tag}}{%endraw%}' | grep '{{pull_tag}}'
        - unless: docker images --format '{%raw%}{{.Repository}}:{{.Tag}}{%endraw%}' | grep '{{new_tag}}'
        