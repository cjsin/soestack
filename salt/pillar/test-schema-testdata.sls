{{ salt.loadtracker.load_pillar(sls) }}

good-data:
    basic-data:
        a-number: 1
        a-string: blah
        a-list: [ 'x','y','z' ]
        a-mapping:
            m: 1
            n: 2
            o: 3
    complex-data:
        deployment:
            filesystem:
                files:
                    /a/b/c/d.txt:
                dirs:
                    /a/b/c:
            config:
                testdata: something

bad-data:
    basic-data:
        a-number: not-a-number
        a-string: blah
        a-list: [ 'x','y','z' ]
        a-mapping:
            m: 1
            n: 2
            o: 3
    complex-data:
        deployment:
            filesystem:
                files:
                    /a/b/c/d.txt:
                dirs:
                    /a/b/c:
            config:
                testdata: something

# test-schema: {}
