# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
# Add more stuff to PATH
if [ -d "$HOME/go/bin" ] ; then
    PATH="$HOME/go/bin:$PATH"
fi
if [ -d /usr/local/go/bin ] ; then
    PATH="/usr/local/go/bin:$PATH"
fi

# set PYTHONPATH so it includes user's private 
# lib/python if it exists
if [ -d "$HOME/lib/python" ] ; then
    PYTHONPATH="$HOME/lib/python:$PYTHONPATH"
    export PYTHONPATH
fi

# set GOPATH
if [ -d "$HOME/go/src" ] ; then
    GOPATH="$HOME/go"
    export GOPATH
elif [ -d "$HOME/src" ]; then
    GOPATH="$HOME"
    export GOPATH
fi

export LANGUAGE="en_US:en"
export LC_MESSAGES="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"

