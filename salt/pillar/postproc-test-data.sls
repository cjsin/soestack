{{ salt.loadtracker.load_pillar(sls) }}

a:
    b: '!!a.d'
    c: 'blah'
    d: '!!a.z'
    z: '!!a.c'
m:
    n: 1
    o: '!!m.n'
