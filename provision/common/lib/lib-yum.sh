
function yum_vars()
{
    if command -v dnf
    then
        python -c 'import dnf, pprint; db = dnf.dnf.Base(); pprint.pprint(db.conf.substitutions,width=1)'
    else
        python -c 'import yum, pprint; yb = yum.YumBase(); pprint.pprint(yb.conf.yumvar, width=1)'
    fi
}
