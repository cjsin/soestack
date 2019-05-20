# The convention used here is that groups should end with the '-group' suffix
# unless they match a role name (and roles generally end in '-node')
package-groups:

    browsers-group:
        purpose: |
            provide the most important web browsers
        package-sets:
            - chromium-browser
            - firefox-browser


    development-tools-group:
        purpose: |
            provide software development tools, libraries, headers
        package-groups:
            - gnu-autotools-toolchain
            - alternative-toolchains
            - gcc
            - python-development

    development-editors-group:
        purpose: |
            provide editors for software developers
        package-sets:
            - oldschool-editors-console
            - oldschool-editors-gui
            - vscode-editor

