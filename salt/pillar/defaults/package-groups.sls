# The convention used here is that groups should end with the '-group' suffix
# unless they match a role name (and roles generally end in '-node')
package-groups:

    browsers-group:
        purpose: |
            provide the most important web browsers
        package-sets:
            # chromium-browser is broken/unailable due to broken epel zchunk issue
            # - chromium-browser
            - firefox-browser

    development-tools-group:
        purpose: |
            provide software development tools, libraries, headers
        package-sets:
            - alternative-toolchains
            - gcc
            - python-development
            - gnu-autotools-toolchain

    development-editors-group:
        purpose: |
            provide editors for software developers
        package-sets:
            - oldschool-editors-console
            - oldschool-editors-gui
            - vscode-editor

