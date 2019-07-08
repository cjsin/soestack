{{ salt.loadtracker.load_pillar(sls) }}

pillar-schema:
    template:
        $schema: 'http://json-schema.org/draft-07/schema#'
        definitions: {}

{# Include all the selected schema data into (as child data of) the toplevel 'pillar-schema' key #}
include:
    - schema-selection:
        key: pillar-schema
