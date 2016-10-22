# Prompt
# \e]0;<FOO>\007 sets the terminal title to <FOO>
# \u user name
# \h host
# \w working directory
# \$ '$' or '#'
if [ x"$TERM" = x"xterm" ]; then
  PS1='\e]0;\u@\h:\w\007[ \u@\h:\w ]\n\$ '
else
  PS1='[ \u@\h:\w ]\n\$ '
fi
export PS1

# ls aliases
alias ls='ls -F'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias l='ls'

# Disable pager for "dumb" terminals (e.g. emacs shell)
if [ x"$TERM" = x"dumb" ]; then
  PAGER=cat
  export PAGER
fi

if [ -x "$HOME"/bin/em ]; then
  EDITOR=em
  export EDITOR
fi

if [ -x /usr/bin/chromium-browser ]; then
  BROWSER=/usr/bin/chromium-browser
elif [ -x /usr/bin/google-chrome ]; then
  BROWSER=/usr/bin/google-chrome
elif [ -x /usr/bin/x-www-browser ]; then
  BROWSER=/usr/bin/x-www-browser
fi
export BROWSER
