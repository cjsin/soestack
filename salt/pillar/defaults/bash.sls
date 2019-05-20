
bash:
    profile:
        big-history:     
            enabled:       True
            template:      big-history.sh.jinja
            config:
                histfile:     ~/.bash_history_big
                histsize:     99999
                histfilesize: 99999

        disable-completion:
            enabled:       True   
            contents:      complete -r

        less-custom:  
            enabled:       True
            template:      less.sh.jinja
            config_pillar: less
