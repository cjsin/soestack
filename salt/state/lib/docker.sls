{% macro image_present(image,image_prefix='') -%}

{%-     set prefix, suffix  = salt.uuids.ids() %}

{%-     if not image %}

{{prefix}}docker-image-no-image-specified{{suffix}}:
    noop.notice

{%-     else %}

{{prefix}}docker-image-{{image}}-present{{suffix}}:
    # This doesn't work because the python modules for the docker support
    # aren't yet installed at the time we want to run this.
    # docker_image.present:
    #     - name: {{image_prefix}}{{image}}
    cmd.run:
        - name:   docker pull '{{image_prefix}}{{image}}'
        - unless: docker images --format '{%raw%}{{.Repository}}:{{.Tag}}{%endraw%}' | grep '{{image_prefix}}{{image}}'

{%-     endif %}

{%- endmacro %}
