# Adapted from https://github.com/arialdomartini/oh-my-git

autoload -U colors && colors

ZLE_RPROMPT_INDENT=0
PROMPT='$(pzsh_prompt_print)'

function pzsh_prompt_print {
    local current_commit_hash

    current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    if [[ -n $current_commit_hash ]]; then
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

        local git_status git_stash_list git_dir
        local current_branch upstream tag_at_current_commit action
        local is_detached is_ready_to_commit
        local has_upstream
        local has_modifications has_modifications_cached
        local has_deletions has_deletions_cached
        local has_untracked_files has_untracked_files_cached
        local number_of_files number_of_staged_files
        local number_of_stashes number_of_branch_stashes

        upstream=$(git rev-parse --symbolic-full-name --abbrev-ref "@{upstream}" 2> /dev/null)
        git_status="$(git status --porcelain 2> /dev/null)"
        current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
        git_stash_list="$(git stash list 2> /dev/null)"
        tag_at_current_commit=$(git describe --exact-match --tags "$current_commit_hash" 2> /dev/null)
        git_dir="$(git rev-parse --git-dir 2>/dev/null)"

        has_untracked_files=false; if [[ $git_status =~ ($'\n'|^)\\?\\? ]]; then has_untracked_files=true; fi
        has_untracked_files_cached=false; if [[ $git_status =~ ($'\n'|^)A ]]; then has_untracked_files_cached=true; fi
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

        echo -n "${CLBG} "

        if [[ $number_of_files -gt 0 ]]; then
            echo -n "${CL}${number_of_staged_files}/${number_of_files}"
        else
            echo -n "${CL}${s_git_repo}"
        fi

        echo -n "  "

        local stash_color="${CLT0}" symbol_color

        if [[ $number_of_branch_stashes -gt 0 ]]; then
            stash_color="${CLT2}"
        elif [[ $number_of_stashes -gt 0 ]]; then
            stash_color="${CLT1}"
        fi

        echo -n "${stash_color}${s_stash}  "

        if [[ "${has_untracked_files}" == true ]]; then symbol_color="${CLH}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_additions  "

        if [[ "${has_modifications}" == true ]]; then symbol_color="${CLH}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_modifications  "

        if [[ "${has_deletions}" == true ]]; then symbol_color="${CLH}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_deletions  "

        if [[ "${has_untracked_files_cached}" == true ]]; then symbol_color="${CL}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_cached_additions  "

        if [[ "${has_modifications_cached}" == true ]]; then symbol_color="${CL}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_cached_modifications  "

        if [[ "${has_deletions_cached}" == true ]]; then symbol_color="${CL}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_cached_deletions  "

        if [[ "${is_ready_to_commit}" == true ]]; then symbol_color="${CLH}"; else symbol_color="${CLX}"; fi
        echo -n "${symbol_color}$s_commit"

        if [ -n "${git_dir}" ]; then
            if [ -f "${git_dir}/rebase-merge/interactive" ]; then
                action=${is_rebasing_interactively:-"rebase -i"}
            elif [ -d "${git_dir}/rebase-merge" ]; then
                action=${is_rebasing_merge:-"rebase -m"}
            else
                if [ -d "${git_dir}/rebase-apply" ]; then
                    if [ -f "${git_dir}/rebase-apply/rebasing" ]; then
                        action=${is_rebasing:-"rebase"}
                    elif [ -f "${git_dir}/rebase-apply/applying" ]; then
                        action=${is_applying_mailbox_patches:-"am"}
                    else
                        action=${is_rebasing_mailbox_patches:-"am/rebase"}
                    fi
                elif [ -f "${git_dir}/MERGE_HEAD" ]; then
                    action=${is_merging:-"merge"}
                elif [ -f "${git_dir}/CHERRY_PICK_HEAD" ]; then
                    action=${is_cherry_picking:-"cherry-pick"}
                elif [ -f "${git_dir}/BISECT_LOG" ]; then
                    action=${is_bisecting:-"bisect"}
                fi
            fi
        fi

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

            local s_rebase_or_merge="${s_merge}"
            if [[ "${will_rebase}" == true ]]; then s_rebase_or_merge="${s_rebase}"; fi
            echo -n "${CR}${current_branch} ${s_rebase_or_merge} ${upstream//\/$current_branch/}"

            if [[ $commits_behind -gt 0 || $commits_ahead -gt 0 ]]; then
                echo -n "${CR})"
            fi
        fi

        if [[ -n $tag_at_current_commit ]]; then
            echo -n "  ${CR}${s_tag} ${tag_at_current_commit}"
        fi

        echo -n "  %k${CRX}▊▊▋%f"$'\n'
    fi

    local iterm2_prompt_mark="\033]133;A\007"

    echo -n "%{${iterm2_prompt_mark}%}%~${pzsh_status}%f"
}

function preexec() {
    preexec_called=1
}

function precmd() {
    local status_number="$?"
    local status_sign_color status_return input_prefix prompt_context

    if [ "${status_number}" != 0 ] && [ "${preexec_called}" = 1 ]; then
        status_sign_color="%F{red}"
        status_return="%F{red}%?%f < "
        unset preexec_called
    else
        status_sign_color="%F{green}"
        status_return=""
    fi

    if [[ $(print -P "%#") == '#' ]]; then
        input_prefix="#"
    else
        input_prefix="●"
    fi

    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        if [[ $(print -P "%#") == '#' ]]; then
            prompt_context=" %F{magenta}${USER}@%m%f"
        else
            prompt_context=" $F{green}${USER}@%m%f"
        fi
    fi

    pzsh_status="${status_sign_color} ${input_prefix} "
    RPROMPT="${status_return}%T${prompt_context}"
}
