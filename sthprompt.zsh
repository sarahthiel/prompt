#
# STH Prompt
#
# Author: Sebastian Thiel
# License: MIT
# https://github.com/sebastianthiel/prompt

#-- CONFIGURATION -------------------------------------------------------------
# The default configuration that can be overridden in .zshrc

#-- PROMPT --------------------------------------------------------------------
STH_PROMPT_SYMBOL="${STH_PROMPT_SYMBOL:="❯"}"
STH_PROMPT_COLOR="${STH_PROMPT_COLOR:="green"}"
STH_PROMPT_ERR_COLOR="${STH_PROMPT_ERR_COLOR:="red"}"
STH_META_COLOR="${STH_META_COLOR:="black"}"

#-- USER & HOST ---------------------------------------------------------------
STH_USER_SHOW_ALWAYS="${STH_USER_SHOW_ALWAYS:=false}"
STH_USER_MIN_UID="${STH_USER_MIN_UID:=500}"
STH_USER_COLOR="${STH_USER_COLOR:="cyan"}"
STH_USER_COLOR_SYS_USER="${STH_USER_COLOR_SYS_USER:="magenta"}"
STH_HOST_COLOR="${STH_HOST_COLOR:="cyan"}"

#-- DIRECTORY -----------------------------------------------------------------
STH_DIR_TRUNCATE="${STH_DIR_TRUNCATE:=5}"
STH_DIR_COLOR="${STH_DIR_COLOR:="blue"}"

#-- GIT -----------------------------------------------------------------------
STH_GIT_BRANCH_COLOR="${STH_GIT_BRANCH_COLOR:="cyan"}"
STH_GIT_DIRTY_SYMBOL="${STH_GIT_DIRTY_SYMBOL:="*"}"

#-- VI MODE -------------------------------------------------------------------
STH_VI_PROMPT_SYMBOL="${STH_VI_PROMPT_SYMBOL:="❮"}"
STH_VI_META_COLOR="${STH_VI_META_COLOR:="black"}"
STH_VI_USER_COLOR="${STH_VI_USER_COLOR:="black"}"
STH_VI_USER_COLOR_SYS_USER="${STH_VI_USER_COLOR_SYS_USER:="black"}"
STH_VI_HOST_COLOR="${STH_VI_HOST_COLOR:="black"}"
STH_VI_DIR_COLOR="${STH_VI_DIR_COLOR:="black"}"
STH_VI_GIT_BRANCH_COLOR="${STH_VI_GIT_BRANCH_COLOR:="black"}"

#-- 8< ------------------------------------------------------------------------
STH_CUR_PROMPT_SYMBOL=$STH_PROMPT_SYMBOL
STH_CUR_PROMPT_COLOR=$STH_PROMPT_COLOR
STH_CUR_PROMPT_ERR_COLOR=$STH_PROMPT_ERR_COLOR
STH_CUR_META_COLOR=$STH_META_COLOR
STH_CUR_USER_COLOR=$STH_USER_COLOR
STH_CUR_USER_COLOR_SYS_USER=$STH_USER_COLOR_SYS_USER
STH_CUR_HOST_COLOR=$STH_HOST_COLOR
STH_CUR_DIR_COLOR=$STH_DIR_COLOR
STH_CUR_GIT_BRANCH_COLOR=$STH_GIT_BRANCH_COLOR

#-- HELPER FUNCTIONS ----------------------------------------------------------
sth_prompt_set_title() {
  print -n '\e]0;'
  # show hostname if connected through ssh
  [[ -n $SSH_CONNECTION ]] && print -Pn '(%m) '
  case $1 in
    expand-prompt)
      print -Pn $2;;
    ignore-escape)
      print -rn $2;;
  esac
  # end set title
  print -n '\a'
}

#-- VI MODE -------------------------------------------------------------------
sth_setvi(){
  local map
  map=$1
  [[ -z $1 ]] && map=${KEYMAP}
  case "$map" in
    main|viins)
      # Insert mode
      STH_CUR_PROMPT_SYMBOL=$STH_PROMPT_SYMBOL
      STH_CUR_META_COLOR=$STH_META_COLOR
      STH_CUR_USER_COLOR=$STH_USER_COLOR
      STH_CUR_USER_COLOR_SYS_USER=$STH_USER_COLOR_SYS_USER
      STH_CUR_HOST_COLOR=$STH_HOST_COLOR
      STH_CUR_DIR_COLOR=$STH_DIR_COLOR
      STH_CUR_GIT_BRANCH_COLOR=$STH_GIT_BRANCH_COLOR
    ;;
    vicmd)
      # Command mode
      STH_CUR_PROMPT_SYMBOL=$STH_VI_PROMPT_SYMBOL
      STH_CUR_META_COLOR=$STH_VI_META_COLOR
      STH_CUR_USER_COLOR=$STH_VI_USER_COLOR
      STH_CUR_USER_COLOR_SYS_USER=$STH_VI_USER_COLOR_SYS_USER
      STH_CUR_HOST_COLOR=$STH_VI_HOST_COLOR
      STH_CUR_DIR_COLOR=$STH_VI_DIR_COLOR
      STH_CUR_GIT_BRANCH_COLOR=$STH_VI_GIT_BRANCH_COLOR
    ;;
  esac 
}

function zle-keymap-select {
  sth_setvi
  zle reset-prompt
}

function zle-line-finish {
  sth_setvi "main"
}

# http://pawelgoscicki.com/archives/2012/09/vi-mode-indicator-in-zsh-prompt/
function TRAPINT() {
  sth_setvi "main"
  return $(( 128 + $1 ))
} 

#-- GIT -----------------------------------------------------------------------
sth_is_git() {
  #check if we're in a git repository
  command git rev-parse --is-inside-work-tree &>/dev/null
}

sth_git_branch() { 
  sth_is_git || return
  # get branch name
  local branch="$(git symbolic-ref HEAD 2>/dev/null)"
  branch="${branch##refs/heads/}"
  
  #if no branch was found, we may be on a tag
  [[ -z "$branch" ]] && branch=$(echo -n "$(git describe --exact-match --tags $(git log -n1 --pretty='%h') 2> /dev/null)")
  echo $branch
}

sth_git_dirty(){
  sth_is_git || return
  local dirty=
  # Modified files
  git diff --no-ext-diff --quiet --exit-code --ignore-submodules 2>/dev/null || dirty=1
  # Untracked files
  [ -z "$dirty" ] && test -n "$(git status --porcelain)" && dirty=1

  # output
  [ -n "$dirty" ] && echo "$STH_GIT_DIRTY_SYMBOL"
}

sth_prompt_precmd() {
  # print the preprompt
  sth_prompt_render "precmd"
}

sth_prompt_render() {
  setopt localoptions noshwordsplit

  # Initialize the preprompt array.
  local -a sth_prompt_parts
  local sth_user sth_host sth_dir sth_branch

  # User at Host
  sth_user=
  sth_host=

  if [[ $STH_USER_SHOW_ALWAYS == true ]] || [[ $LOGNAME != $USER ]] || [[ $UID < $STH_USER_MIN_UID ]] || [[ -n $SSH_CONNECTION ]]; then
    
    if [[ $UID -le $STH_USER_MIN_UID ]]; then
      sth_user='%F{$STH_CUR_USER_COLOR_SYS_USER}'
    else
      sth_user='%F{$STH_CUR_USER_COLOR}'
    fi
    sth_user+='%n%f'
    sth_host='%F{$STH_CUR_HOST_COLOR}%m%f'
  fi

  # Directory
  sth_dir='%F{$STH_CUR_DIR_COLOR}%${STH_DIR_TRUNCATE}~%f'

  # Git
  sth_branch="$(sth_git_branch)"
  
  # construct prompt
  if [[ ! -z "$sth_user" ]]; then
    sth_prompt_parts+=($sth_user)
    sth_prompt_parts+=('%f%F{$STH_CUR_META_COLOR}at%f')
    sth_prompt_parts+=($sth_host)
    sth_prompt_parts+=('%f%F{$STH_CUR_META_COLOR}in%f')
  fi

  sth_prompt_parts+=($sth_dir)

  if [[ ! -z "$sth_branch" ]]; then
    sth_prompt_parts+=('%f%F{$STH_CUR_META_COLOR}on%f')
    sth_prompt_parts+=('%F{$STH_CUR_GIT_BRANCH_COLOR}$(sth_git_branch)$(sth_git_dirty)')
  fi

  # https://github.com/sindresorhus/pure
  local cleaned_ps1=$PROMPT
  local -H MATCH
  if [[ $PROMPT = *$prompt_newline* ]]; then
    # When the prompt contains newlines, we keep everything before the first
    # and after the last newline, leaving us with everything except the
    # preprompt. This is needed because some software prefixes the prompt
    # (e.g. virtualenv).
    cleaned_ps1=${PROMPT%%${prompt_newline}*}${PROMPT##*${prompt_newline}}
  fi

  # Construct the new prompt with a clean preprompt.
  local -ah ps1
  ps1=(
    $prompt_newline              # Initial newline, for spaciousness.
    ${(j. .)sth_prompt_parts}  # Join parts, space separated.
    $prompt_newline              # Separate preprompt and prompt.
    $cleaned_ps1
  )

  PROMPT="${(j..)ps1}"

  # Expand the prompt for future comparision.
  local expanded_prompt
  expanded_prompt="${(S%%)PROMPT}"

  if [[ $1 != precmd ]] && [[ $sth_prompt_last_prompt != $expanded_prompt ]]; then
    # Redraw the prompt.
    zle && zle .reset-prompt
  fi

  sth_prompt_last_prompt=$expanded_prompt
}

sth_prompt_setup() {
  prompt_opts=(subst percent)
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  # Prevent percentage showing up if output doesn't end with a newline.
  export PROMPT_EOL_MARK=''

  # disallow python virtualenvs from updating the prompt
  export VIRTUAL_ENV_DISABLE_PROMPT=1

  #restore old behavior for coreutils
  export QUOTING_STYLE=literal

  if [[ -z $prompt_newline ]]; then
    typeset -g prompt_newline=$'\n%{\r%}'
  fi

  zmodload zsh/zle
  
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd sth_prompt_precmd
  
  bindkey -v
  zle -N zle-keymap-select
  zle -N zle-line-finish

  # LSCOLORS
  LSCOLORS="Exfxcxdxbxegedabagacad"
  export LSCOLORS="Exfxcxdxbxegedabagacad"

  LS_COLORS='no=0:di=34;4:ln=target:mh=0:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=31;1:*VERSION.0.0.1=0:*.php=34;1:*.php3=34;1;40:*.php4=34;1;40:*.php5=34;1;40:*.php7=34;1;40:*Controller.php=38;5;45:*Model.php=38;5;33:*Interface.php=38;5;75:*Exception.php=38;5;63:*.phtml=94:*.twig=94:*.tpl=94:*.xml=94;2:*.html=34;2:*.htm=34;2;40:*.js=31;1:*.js.map=31;2:*.min.js=38;5;94:*.json=91;1:*.css=35;2:*.min.css=38;5;90:*.sass=95;1:*.less=95;1:*.lock=30;2:*.log=30;106:*error.log=30;101:*.err=30;101:*.error=30;101:*access.log=30;102:*php.log=30;104:*.pub=32:*known_hosts=38;5;214:*authorized_keys=38;5;184:*.bak=30;2:*.dump=30;2:*lockfile=30;2:*.orig=30;2:*.pid=30;2:*.swp=30;2:*.tmp=30;2:*.CFUserTextEncoding=30;2:*.DS_Store=30;2:*.localized=30;2:*cfg=33;1:*conf=33;1:*config=33;1:*.env=33;1:*.ini=33;1:*rc=33;1:*.jpg=33;2:*.JPG=33;2;40:*.jpeg=33;2;40:*.CR2=95;2;40:*.cr2=95;2:*.dng=35;2:*.DNG=35;2;40:*.xmp=94;2:*.tif=32;2:*.tiff=32;2;40:*.pxm=31;2:*.psd=31;2:*.png=33;1:*.PNG=33;1;40:*.svg=33:*.ico=93;2:*.ICO=93;2;40:*.mp3=36;1:*.m4a=36:*.ogg=36;2;:*.oga=36;2;:*.opus=36;2;:*.flac=36;2;:*.mp4=32;1:*.ogv=32:*.webm=32;2:*.mkv=92;2:*.m3u=90:*.srt=90:*.odt=94:*.doc=94;40:*.docm=94:*.docx=94:*.pages=94:*.gdoc=94:*.rtf=94;1;40:*.md=96:*.nfo=96;2;40:*.txt=96;2:*.ods=92:*.xls=92;40:*.xlsm=92:*.xlsx=92:*.numbers=92:*.gsheet=92:*.csv=32;2:*.odp=91:*.ppt=91;40:*.pptm=91:*.pptx=91:*.key=91:*.gslides=91:*.odg=93:*.vsd=93;40:*.vsdx=93:*.gdraw=93:*.odf=95;2:*.odb=95:*.accdb=95:*.mdb=95;40:*.gtable=95:*.gform=95:*.eml=96;2:*.msg=96;2:*.pdf=97:*.bz2=32;107:*.gz=34;107:*.rar=30;1;107:*.tar=30;107:*.tgz=34;47:*.xz=36;107:*.zip=33;107:*.r00=30;2:*.r01=30;2:*.r02=30;2:*.r03=30;2:*.r04=30;2:*.r05=30;2:*.r06=30;2:*.r07=30;2:*.r08=30;2:*.r09=30;2:*.r10=30;2:*.r11=30;2:*.r12=30;2:*.r13=30;2:*.r14=30;2:*.r15=30;2:*.r16=30;2:*.r17=30;2:*.r18=30;2:*.r19=30;2:*.r20=30;2:*.r21=30;2:*.r22=30;2:*.r23=30;2:*.r24=30;2:*.r25=30;2:*.r26=30;2:*.r27=30;2:*.r28=30;2:*.r29=30;2:*.r30=30;2:*.r31=30;2:*.r32=30;2:*.r33=30;2:*.r34=30;2:*.r35=30;2:*.r36=30;2:*.r37=30;2:*.r38=30;2:*.r39=30;2:*.r40=30;2:*.r41=30;2:*.r42=30;2:*.r43=30;2:*.r44=30;2:*.r45=30;2:*.r46=30;2:*.r47=30;2:*.r48=30;2:*.r49=30;2:*.r50=30;2:*.r51=30;2:*.r52=30;2:*.r53=30;2:*.r54=30;2:*.r55=30;2:*.r56=30;2:*.r57=30;2:*.r58=30;2:*.r59=30;2:*.r60=30;2:*.r61=30;2:*.r62=30;2:*.r63=30;2:*.r64=30;2:*.r65=30;2:*.r66=30;2:*.r67=30;2:*.r68=30;2:*.r69=30;2:*.r69=30;2:*.r70=30;2:*.r71=30;2:*.r72=30;2:*.r73=30;2:*.r74=30;2:*.r75=30;2:*.r76=30;2:*.r77=30;2:*.r78=30;2:*.r79=30;2:*.r80=30;2:*.r81=30;2:*.r82=30;2:*.r83=30;2:*.r84=30;2:*.r85=30;2:*.r86=30;2:*.r87=30;2:*.r88=30;2:*.r89=30;2:*.r90=30;2:*.r91=30;2:*.r92=30;2:*.r93=30;2:*.r94=30;2:*.r95=30;2:*.r96=30;2:*.r97=30;2:*.r98=30;2:*.r99=30;2:*.z00=30;2:*.z01=30;2:*.z02=30;2:*.z03=30;2:*.z04=30;2:*.z05=30;2:*.z06=30;2:*.z07=30;2:*.z08=30;2:*.z09=30;2:*.z10=30;2:*.z11=30;2:*.z12=30;2:*.z13=30;2:*.z14=30;2:*.z15=30;2:*.z16=30;2:*.z17=30;2:*.z18=30;2:*.z19=30;2:*.z20=30;2:*.z21=30;2:*.z22=30;2:*.z25=30;2:*.z26=30;2:*.z27=30;2:*.z28=30;2:*.z29=30;2:*.z30=30;2:*.z31=30;2:*.z32=30;2:*.z33=30;2:*.z34=30;2:*.z35=30;2:*.z36=30;2:*.z37=30;2:*.z38=30;2:*.z39=30;2:*.z40=30;2:*.z41=30;2:*.z42=30;2:*.z43=30;2:*.z44=30;2:*.z45=30;2:*.z46=30;2:*.z47=30;2:*.z48=30;2:*.z49=30;2:*.z50=30;2:*.z51=30;2:*.z52=30;2:*.z53=30;2:*.z54=30;2:*.z55=30;2:*.z56=30;2:*.z57=30;2:*.z58=30;2:*.z59=30;2:*.z60=30;2:*.z61=30;2:*.z62=30;2:*.z63=30;2:*.z64=30;2:*.z65=30;2:*.z66=30;2:*.z67=30;2:*.z68=30;2:*.z69=30;2:*.z69=30;2:*.z70=30;2:*.z71=30;2:*.z72=30;2:*.z73=30;2:*.z74=30;2:*.z75=30;2:*.z76=30;2:*.z77=30;2:*.z78=30;2:*.z79=30;2:*.z80=30;2:*.z81=30;2:*.z82=30;2:*.z83=30;2:*.z84=30;2:*.z85=30;2:*.z86=30;2:*.z87=30;2:*.z88=30;2:*.z89=30;2:*.z90=30;2:*.z91=30;2:*.z92=30;2:*.z93=30;2:*.z94=30;2:*.z95=30;2:*.z96=30;2:*.z97=30;2:*.z98=30;2:*.z99=30;2:*.part=30;2:';
  export LS_COLORS
  
  # Link: http://superuser.com/a/707567
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  
  # prompt turns red if the previous command didn't exit with 0
  PROMPT='%(?.%F{$STH_CUR_PROMPT_COLOR}.%F{$STH_CUR_PROMPT_ERR_COLOR})$STH_CUR_PROMPT_SYMBOL%f '
}

PROMPT_COMMAND=sth_prompt_render

sth_prompt_setup "$@"