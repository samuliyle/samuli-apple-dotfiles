# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

codeDir=/Users/samuli/Projects
appleDir=$codeDir/AppleConfig
colorizeLocation=$appleDir/shell/colorize/colorize.py

# Use colors for 'ls'
export CLICOLOR=1

# Specify which 'ls' colors to use
export LS_COLORS="$(vivid generate snazzy)"
# export LSCOLORS=ExFxBxDxCxegedabagacad

# Set default editors
# export EDITOR=vim
export VISUAL="/opt/homebrew/bin/code"

if [ "$OSTYPE" != linux-gnu ]; then  # Is this the macOS system?
    # BSD version of ls does not use LS_COLORS, use the GNU version of ls instead: brew install coreutils
    alias ls="gls --color -h --group-directories-first"
fi

# Typos
alias Cd='cd'
alias cD='cd'
alias CD='cd'
alias dir='ls'
alias copy='cp'

# Shortcuts
alias s='$VISUAL'

# Misc. aliases
alias editzsh='editbash'
alias sourcezsh='sourcebash'

# Verbosity and settings that you pretty much just always are going to want.
alias \
	cp="cp -iv" \
	mv="mv -iv" \
	rm="rm -vI" \
	mkd="mkdir -pv" \
	yt="yt-dlp --embed-metadata -i" \
	yta="yt -x -f bestaudio/best"

# Colorize commands when possible.
alias \
	grep="grep --color=auto" \
	diff="diff --color=auto"

####################
# Helper functions #
####################

# mkdir and cd into it in one command
function mkdircd() {
    mkdir $1 && cd $1
}

# Simple shortcut to edit this file.
function editbash() {
    colorize "^gEditing ~/.zshrc"
    s ~/.zshrc
}

# Simple shortcut to source this file.
function sourcebash() {
    colorize "Doing ^gsource ~/.zshrc"
    source ~/.zshrc
}

# Thin wrapper around Colorize.
function colorize() {
    python3 $colorizeLocation "$@"
}

# Print time in UTC
function utc() {
    colorize "LOCAL: ^y$(date)"
    colorize "UTC  : ^g$(date -u)"
}

# "Find file" - searches recursively for a file whose name you pass.
# Examples:
# ff "*Phone*"
# ff "something with spaces.txt"
function ff() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: ff <file to find>"
        colorize "Does a case-sensitive recursive search for <file to find>."
        return
    fi

    ffCommon "$1" false
}

# Thin wrapper around `ff` to search for particular file types since zsh would
# otherwise require quotation marks, which are annoying to type.
function fftype() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: fftype <file type to find>, e.g. fftype py"
        return
    fi

    ff "*.$1"
}

# Same as 'ff' but case-insensitive.
function ffi() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: ffi <file to find>"
        colorize "Does a case-insensitive recursive search for <file to find>."

        return
    fi

    ffCommon "$1" true
}

# [private function] - do not call this directly
# Used by ff and ffi.
function ffCommon() {
    local fileName=$1
    local caseInsensitive=$2
    local nameArg=-name

    if [[ "$fileName" == "" ]]; then
        colorize "^rYou should not call this function directly."
        return
    fi

    if [[ $caseInsensitive == true ]]; then
        nameArg=-iname
    fi

    colorize "Finding file(s): find . $nameArg \"^g$1^w\""
    find . $nameArg "$fileName"
}

# "Find string in file" - searches all files recursively for the string that
# you've passed in.
#
# Arg1: the string to search for. The user can choose to provide quotes if they want.
# Arg2: the file types to include in the search.
#
# E.g.
# fs "string with spaces"
# fs foo *.txt
# fs "a single backslash \\\\ looks like that"   (you need to escape the backslash once for Bash and once for regex)
function fs() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: fs <string to find in files> [files to match]"
        colorize "Does a case-sensitive recursive search for <string> in files."
        return
    fi

    fsCommon "$1" "" "$2"
}

# [private function] - do not call this directly
# Implementation for fs and fsi.
#
# Arg1: the string to find
# Arg2: any additional arguments to "find", e.g. -i. Pass " " if you don't want to specify this argument.
# Arg3 (optional): if present, only files of this type will be searched.
function fsCommon() {
    local searchString=$1
    local addlArgs=$2
    local include=$3

    if [[ "$searchString" == "" ]]; then
        colorize "^rYou should not call this function directly."
        return
    fi

    local addlArgsStr=
    if [[ -n $addlArgs ]]; then
        addlArgsStr="^w(additional args: ^g$addlArgs^w)"
    fi

    if [[ -n "$include" ]]; then
        colorize "Searching for ^g$searchString^w in files matching ^g$include $addlArgsStr"
        if [[ -f $include || -d $include ]]; then
            colorize "^yWarning: ^r\"$include\"^y exists in the current directory, which likely means you passed something like *.txt to this function, and bash automatically converted it into an existing path. To fix this, surround the argument in double quotes."
        fi
        grep $addlArgs -r -n "$searchString" ./ --include=$include
    else
        colorize "Searching for the string ^g$searchString^w in files $addlArgsStr"
        grep $addlArgs -r -n "$searchString" ./
    fi
}

# Same as 'fs' ("find string") but fsi is case-insensitive.
function fsi() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: fsi <string to find in files> [files to match]"
        colorize "Does a case-insensitive recursive search for <string> in files."
        return
    fi

    fsCommon "$1" -i "$2"
}

# Find directory recursively
function fd() {
    if [[ "$1" == "" ]]; then
        colorize "^rUsage: fd <directory name>"
        colorize "This function finds directories recursively."
        return
    fi

    colorize "Searching for the directory ^g$1 ^w(case-insensitive)"
    find ./ -iname "$1" -type d
}

# macOS "find" but excludes directories.
function findf() {
    local searchPath=$1

    if [[ "$1" == "" ]]; then
        searchPath=.
    fi

    find $searchPath -type f
}

# Copies the current directory to the clipboard.
function getcd() {
    pwd | tr -d '\n' | pbcopy
    colorize "^wCopied ^g${PWD} ^wto the clipboard"
}

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias config='/usr/bin/git --git-dir=/Users/samuli/.cfg/ --work-tree=/Users/samuli'
