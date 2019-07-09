{{ salt.loadtracker.load_pillar(sls) }}

object-data: {}
    # test-obj < fs-items:
    #     children:
    #         - /tmp/test-obj/dir < dir:
    #         - /tmp/test-obj/dir/subdir < dir:
    #         - /tmp/test-obj/dir/subdir/date.txt < file:
    #             template: {%raw%}datetime|strftime("%Y-%m-%d"){%endraw%}
    #         - /tmp/test-obj/dir/subdir/symlink.txt < link:
    #             target: date.txt
