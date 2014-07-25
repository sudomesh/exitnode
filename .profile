# ~/.profile: executed by Bourne-compatible login shells.
# @@TODO: Check that ~/ is actually where we intend to unpack .nvm into
export NVM_DIR="~/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

