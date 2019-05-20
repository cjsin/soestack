{% macro image_present(image,image_prefix='') -%}

{%- set prefix, suffix  = salt.uuid.ids() %}

{{prefix}}docker-image-{{image}}-present{{suffix}}:
    # This doesn't work because the python modules for the docker support
    # aren't yet installed at the time we want to run this.
    # docker_image.present:
    #     - name: {{image_prefix}}{{image}}
    cmd.run:
        - name:   docker pull '{{image_prefix}}{{image}}'
        - unless: docker images --format '{%raw%}{{.Repository}}:{{.Tag}}{%endraw%}' | grep '{{image_prefix}}{{image}}'

# This line is required to fix a salt bug which appends stray 'f' characters to macros

{%- endmacro %}
