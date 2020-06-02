# Adapted from https://github.com/arialdomartini/oh-my-git

autoload -U colors && colors

PROMPT='$(__print_prompt)'
ZLE_RPROMPT_INDENT=0

function __print_prompt {
    local current_commit_hash

    current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    if [[ -n $current_commit_hash ]]; then
        __print_git_line "${current_commit_hash}"
    fi

    __print_input_line
}

function __print_git_line {
    local -r current_commit_hash=${1}

    local -r s_git_repo=''
    local -r s_additions=''
    local -r s_deletions=''
    local -r s_modifications=''
    local -r s_cached_additions=''
    local -r s_cached_deletions=''
    local -r s_cached_modifications=''
    local -r s_commit=''
    local -r s_tag=''
    local -r s_detached=''
    local -r s_fast_forward=''
    local -r s_diverged=''
    local -r s_local=''
    local -r s_rebase=''
    local -r s_merge=''
    local -r s_push=''
    local -r s_stash=''
    local -r s_action=''

    local -r CLBG="%K{white}" #white
    local -r CL="%F{black}" #black
    local -r CLX="%F{white}" #white
    local -r CLH="%F{124}" #red
    local -r CRBG="%K{30}" #teal
    local -r CRX="%F{30}" #teal
    local -r CR="%F{black}" #black
    local -r CRH="%F{white}" #white
    local -r CLT0="%F{white}" #white
    local -r CLT1="%F{248}" #gray
    local -r CLT2="%F{130}" #yelloy
    local -r C_ROOT="%F{magenta}" #magenta
    local -r C_USER="%F{green}" #green

    local is_detached is_ready_to_commit
    local has_upstream has_modifications has_modifications_cached
    local has_deletions has_deletions_cached has_adds has_untracked_files
    local number_of_files number_of_staged_files number_of_stashes number_of_branch_stashes
    local current_branch upstream git_status git_stash_list tag_at_current_commit action

    upstream=$(git rev-parse --symbolic-full-name --abbrev-ref "@{upstream}" 2> /dev/null)
    git_status="$(git status --porcelain 2> /dev/null)"
    current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    git_stash_list="$(git stash list 2> /dev/null)"
    tag_at_current_commit=$(git describe --exact-match --tags "$current_commit_hash" 2> /dev/null)
    action="$(__git_action)"

    has_untracked_files=false; if [[ $git_status =~ ($'\n'|^)\\?\\? ]]; then has_untracked_files=true; fi
    has_adds=false; if [[ $git_status =~ ($'\n'|^)A ]]; then has_adds=true; fi
    has_deletions=false; if [[ $git_status =~ ($'\n'|^).D ]]; then has_deletions=true; fi
    has_deletions_cached=false; if [[ $git_status =~ ($'\n'|^)D ]]; then has_deletions_cached=true; fi
    has_modifications=false; if [[ $git_status =~ ($'\n'|^).M ]]; then has_modifications=true; fi
    has_modifications_cached=false; if [[ $git_status =~ ($'\n'|^)[MR] ]]; then has_modifications_cached=true; fi
    has_upstream=false; if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi
    is_detached=false; if [[ $current_branch == 'HEAD' ]]; then is_detached=true; fi
    is_ready_to_commit=false; if [[ $git_status =~ ($'\n'|^)[MADR] && ! $git_status =~ ($'\n'|^).[MADR\?] ]]; then is_ready_to_commit=true; fi

    number_of_files=$(\grep -c '[^[:space:]]' <<< "$git_status")
    number_of_staged_files=$(\grep -c '^[MADR]' <<< "$git_status")
    number_of_stashes="$(\grep -c '[^[:space:]]' <<< "$git_stash_list")"
    number_of_branch_stashes="$(\grep -c "n $current_branch:" <<< "$git_stash_list")"
    #number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
    #number_of_branch_stashes="$(git stash list --grep "n $current_branch:" 2> /dev/null | wc -l)"

    echo -n "${CLBG} "

    if [[ $number_of_files -gt 0 ]]; then
        echo -n "${CL}${number_of_staged_files}/${number_of_files}"
    else
        echo -n "${CL}${s_git_repo}"
    fi

    echo -n "  "

    local stash_color="${CLT0}"

    if [[ $number_of_branch_stashes -gt 0 ]]; then
        stash_color="${CLT2}"
    elif [[ $number_of_stashes -gt 0 ]]; then
        stash_color="${CLT1}"
    fi

    echo -n "${stash_color}${s_stash}  "
    echo -n "$(__cond "$has_untracked_files" "$CLH" "$CLX")$s_additions  "
    echo -n "$(__cond "$has_modifications" "$CLH" "$CLX")$s_modifications  "
    echo -n "$(__cond "$has_deletions" "$CLH" "$CLX")$s_deletions  "
    echo -n "$(__cond "$has_adds" "$CL" "$CLX")$s_cached_additions  "
    echo -n "$(__cond "$has_modifications_cached" "$CL" "$CLX")$s_cached_modifications  "
    echo -n "$(__cond "$has_deletions_cached" "$CL" "$CLX")$s_cached_deletions  "
    echo -n "$(__cond "$is_ready_to_commit" "$CLH" "$CLX")$s_commit"

    if [[ -n $action ]]; then
        echo -n "  ${CLH}$s_action $action"
    fi

    echo -n "  $CRBG   "

    if [[ $is_detached == true ]]; then
        echo -n "${CRH}${s_detached}  ${CR}(${current_commit_hash:0:7})"
    elif [[ $has_upstream == false ]]; then
        echo -n "${CR}${current_branch} ${s_local} "
    else
        local will_rebase commits_diff commits_ahead commits_behind

        will_rebase=$(git config --get "branch.${current_branch}.rebase" 2> /dev/null)
        commits_diff="$(git log --pretty=oneline --topo-order --left-right "${current_commit_hash}...${upstream}" 2> /dev/null)"
        commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
        commits_behind=$(\grep -c "^>" <<< "$commits_diff")

        if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then
            echo -n "${CRH}-${commits_behind} ${s_diverged}  +${commits_ahead}  ${CR}("
        elif [[ $commits_behind -gt 0 ]]; then
            echo -n "${CR}-${commits_behind} ${CRH}${s_fast_forward}${CR} --  ${CR}("
        elif [[ $commits_ahead -gt 0 ]]; then
            echo -n "${CR}-- ${CRH}${s_push}${CR}  +${commits_ahead}  ${CR}("
        fi

        echo -n "${CR}${current_branch} $(__cond "$will_rebase" "$s_rebase" "$s_merge") ${upstream//\/$current_branch/}"

        if [[ $commits_behind -gt 0 || $commits_ahead -gt 0 ]]; then
            echo -n "${CR})"
        fi
    fi

    if [[ -n $tag_at_current_commit ]]; then
        echo -n "  ${CR}${s_tag} ${tag_at_current_commit}"
    fi

    echo -n "  %k${CRX}▊▊▋%f"$'\n'
}

function __print_input_line() {
    echo -n "%{$(__iterm2_prompt_mark)%}%~$status_dot%f"
}

function __print_prompt_context() {
    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        if [[ $(print -P "%#") == '#' ]]; then
            echo " ${C_ROOT}${USER}@%m%f"
        else
            echo " ${C_USER}${USER}@%m%f"
        fi
    fi
}

function __input_prefix() {
    if [[ $(print -P "%#") == '#' ]]; then
        echo "#"
    else
        echo "●"
    fi
}

function __cond() {
    if [[ "$1" == false ]]; then echo "$3"; else echo "$2"; fi
}

function __git_action () {
    local info

    info="$(git rev-parse --git-dir 2>/dev/null)"

    if [ -n "$info" ]; then
        local action

        if [ -f "$info/rebase-merge/interactive" ]; then
            action=${is_rebasing_interactively:-"rebase -i"}
        elif [ -d "$info/rebase-merge" ]; then
            action=${is_rebasing_merge:-"rebase -m"}
        else
            if [ -d "$info/rebase-apply" ]; then
                if [ -f "$info/rebase-apply/rebasing" ]; then
                    action=${is_rebasing:-"rebase"}
                elif [ -f "$info/rebase-apply/applying" ]; then
                    action=${is_applying_mailbox_patches:-"am"}
                else
                    action=${is_rebasing_mailbox_patches:-"am/rebase"}
                fi
            elif [ -f "$info/MERGE_HEAD" ]; then
                action=${is_merging:-"merge"}
            elif [ -f "$info/CHERRY_PICK_HEAD" ]; then
                action=${is_cherry_picking:-"cherry-pick"}
            elif [ -f "$info/BISECT_LOG" ]; then
                action=${is_bisecting:-"bisect"}
            fi
        fi

        if [[ -n $action ]]; then printf "%s" "$action"; fi
    fi
}

__iterm2_prompt_mark() {
    printf "\033]133;A\007"
}

function preexec() {
    preexec_called=1
}

function precmd() {
    if [ "$?" != 0 ] && [ "$preexec_called" = 1 ]; then
        status_dot="%F{red} $(__input_prefix) "
        RPROMPT="%F{red}%?%f < %T$(__print_prompt_context)"
        unset preexec_called
    else
        status_dot="%F{green} $(__input_prefix) "
        RPROMPT="%f%T$(__print_prompt_context)"
    fi
}
