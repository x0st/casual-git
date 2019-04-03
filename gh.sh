#!/bin/bash

# return 1 if the given string contains at least 1 space, 0 otherwise.
function _string_contains_spaces {
  [[ "$1" != "${1%[[:space:]]*}" ]] && return 0 || return 1
}

# show help to the user
function _show_usage() {
  _print_empty_line
  _print_newline_message "\033[1;31md \033[0m - push"
  _print_newline_message "\033[1;31mf \033[0m - push --force"
  _print_newline_message "\033[1;31mp \033[0m - pull"
  _print_newline_message "\033[1;31mo \033[0m - pull --force"
  _print_newline_message "\033[1;31mc \033[0m - commit"
  _print_newline_message "\033[1;31ma \033[0m - commit --amend"
  _print_newline_message "\033[1;31ms \033[0m - commit --smart"
  _print_newline_message "\033[1;31ml \033[0m - log --pretty"
  _print_newline_message "\033[1;31mh \033[0m - checkout --smart"
  _print_newline_message "\033[1;31mm \033[0m - modify commit"
  _print_empty_line
}

# print the current project's branch.
function _current_branch() {
  git rev-parse --abbrev-ref HEAD
}

# make user input visible
function _turn_on_user_input() {
  stty echo
}

# make user input unvisible
function _turn_off_user_input() {
  stty -echo
}

# print a message with a line break
function _print_newline_message() {
  printf "  $1\n"
}

# print a message with no line break
function _print_input_request_message() {
  printf "  $1"
}

# print a line break
function _print_empty_line() {
  printf "\n"
}

# ask the user to input a character
function _ask_for_a_char() {
  local _answer;

  read -r -s -n 1 _answer

  echo ${_answer}
}

# ask the user to input 'y' or 'n'.
function _ask_yes_or_no() {
  local _message=${1}
  local _reply

  read -p "  ${_message} " -n 1 -r _reply

  _print_empty_line
  _print_empty_line

  if [[ ${_reply} =~ ^[Yy]$ ]]
  then
    return 0
  fi

  return 1
}

# return 1 in case the given remote exists, 0 otherwise
function _remote_exists() {
  local -a _all_remotes=(`git remote`)
  local _given_remote=${1}

  # iterating over all the existing remotes
  for remote in "${_all_remotes[@]}"
  do
    if [[ "${remote}" == "${_given_remote}" ]]; then
      return 0
    fi
  done

  return 1
}

# retrieve a remote out of the name of a branch
function _retrieve_remote() {
  local _given_branch=${1}
  local -a _slash_breakdown=(`echo ${_given_branch} | awk -F / '{for (i = 1; i < NF; i++) { print $i; }}'`)
  local _possible_remote;

  # no slashes have been found
  if [[ ${#_slash_breakdown[@]} -eq 0 ]]; then
    return 1
  fi

  for i in "${_slash_breakdown[@]}"
  do
    _possible_remote="${_possible_remote}${i}"

    if `_remote_exists "${_possible_remote}"`
    then
      echo "${_possible_remote}"
      return 0
    fi

    _possible_remote="${_possible_remote}/"
  done

  return 1
}

# print all the local and remote branches
function _all_git_branches() {
  git branch -a --format="%(refname)" \
  | sed 's/refs\/heads\///g' \
  | sed 's/refs\/remotes\///g' \
  | sed '/HEAD detached at/d'
}

# Accepts an approximate or the exact name of a branch as first argument.
# Tries to find a branch that match the given one.
# If only one branch matches the given one then it is switched.
function _find_and_switch_desired_branch() {
  local _desired_branch=${1}
  local _matching_branches_count=0
  local _matching_branch
  local _remote
  local -a _all_branches=(`_all_git_branches`)

  # the user did not provide the name of a branch
  if [[ -z ${_desired_branch} ]];
  then
    return 1
  fi

  # iterating over all the branches and checking if any branch matches the desired one
  for i in "${_all_branches[@]}"
  do
    # the desired branch has been found, so we can switch to it instantly
    if [[ "${i}" == "${_desired_branch}" ]]; then
      git checkout "${_desired_branch}" > /dev/null
      return 0
    fi

    # if there is no exact name then the matched names are written
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      ((_matching_branches_count++))
      _matching_branch="${i}"
    fi
  done

  # if only one branch matched, then switch to it
  if [[ ${_matching_branches_count} -eq 1 ]]; then
    _remote="`_retrieve_remote "${_matching_branch}"`"

    # if the matched branch contains a remote
    if [[ $? -eq 0 ]]; then
      git checkout "${_matching_branch:${#_remote}+1}" > /dev/null
    else
      git checkout "${_matching_branch}" > /dev/null
    fi
    return 0
  fi

  return 1
}

# Accepts an approximate or the exact name of a branch as first argument.
# Counts the amount of the branches that match the given one.
function _how_many_branches_match() {
  local _desired_branch=${1}
  local _matching_branches_count=0
  local -a _all_branches=(`_all_git_branches`)

 # iterating over all the branches and checking if any branch matches the given one
  for i in "${_all_branches[@]}"
  do
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      ((_matching_branches_count++))
    fi
  done

  echo ${_matching_branches_count}
}

# Accepts an approximate or the exact name of a branch as first argument.
# Finds the branches that match the given one.
function _get_matching_branches() {
  local _desired_branch="${1}"
  local -a _all_branches=(`_all_git_branches`)
  local -a _matching_branches=()

  # iterating over all then branches and checking if any branch matches the given one
  for i in "${_all_branches[@]}"
  do
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      _matching_branches=("${_matching_branches[@]}" "${i}")
    fi
  done

  echo "${_matching_branches[@]}"
}

# Print all staged files
# Approximate output:
#
# file1.txt:new_file
# file2.txt:deleted
# folder/:modified
function _all_staged_files() {
  local    _file_with_status
  local    _git_file_status
  local    _file_status
  local -a _files
  local -a _one_file

  while IFS= read -r _file_with_status;
  do
    `_string_contains_spaces "$(echo "${_file_with_status}" | sed -E 's/^.{0,3}//g')"` && continue
    [[ -z "${_file_with_status}" ]] && continue

    _git_file_status="$(echo "${_file_with_status}" | cut -c1-1)"

    case "${_git_file_status}" in
      "M")
        _file_status="modified"
        ;;
      "D")
        _file_status="deleted"
        ;;
      "A")
        _file_status="new_file"
        ;;
      "R")
        _file_status="renamed"
        ;;
      *)
        _file_status="unknown"
        ;;
    esac

    _one_file="$(echo "${_file_with_status}" | sed -E 's/^.{0,3}//g'):${_file_status}"

    _files=("${_files[@]}" "${_one_file}")
  done <<< "$(git status -s | grep -E 'M. |D. |A. |R. ')"

  echo "${_files[@]}"
}

# Print all staged files
# Approximate output:
#
# file1.txt:untracked
# file2.txt:modified
# folder/:deleted
function _all_unstaged_files() {
  local    _file_with_status
  local    _git_file_status
  local    _file_status
  local    _one_file
  local -a _files

  while IFS= read -r _file_with_status;
  do
    `_string_contains_spaces "$(echo "${_file_with_status}" | sed -E 's/^.{0,3}//g')"` && continue
    [[ -z "${_file_with_status}" ]] && continue

    _git_file_status=$(echo "${_file_with_status}" | cut -c1-2)

    case "${_git_file_status:1:1}" in
      '?')
        _file_status="untracked"
        ;;
      'M')
        _file_status="modified"
        ;;
      'D')
        _file_status="deleted"
        ;;
    esac

    _one_file="$(echo "${_file_with_status}" | sed -E 's/^.{0,3}//g'):${_file_status}"

    _files=("${_files[@]}" "${_one_file}")
  done <<< "$(git status -s | grep -E '\?\? |.M |.D ')"

  echo "${_files[@]}"
}

function _all_git_commits() {
  git --no-pager log --pretty='%h:%s'
}

function _command_git_push() {
  _print_newline_message "Pushing..."
  git push origin "`_current_branch`"
}

function _command_git_force_push() {
  if `_ask_yes_or_no "This will replace the remote history with yours! Are you sure?"`
  then
    git push --force origin "`_current_branch`"
  fi
}

function _command_git_force_pull() {
  if `_ask_yes_or_no "This will replace your local history with remote one! Are you sure?"`
  then
    _print_newline_message "Pulling..."
    git pull origin "`_current_branch`"
    git reset --hard "origin/`_current_branch`"
  fi
}

function _command_git_pull() {
  _print_newline_message "Pulling..."
  git pull origin "`_current_branch`"
}

function _command_git_pretty_log() {
  git log \
  --color \
  --graph \
  --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
  --abbrev-commit
}

function _command_git_commit() {
  local -a _comment

  _print_empty_line
  _print_input_request_message "Enter a comment: "

  read _comment

  git commit -m "${_comment}"
}

function _command_git_amend_commit() {
  git commit --amend --no-edit
}

function _command_git_smart_commit() {
  local -ax _all_staged_files=(`_all_staged_files`)
  local -ax _all_unstaged_files=(`_all_unstaged_files`)
  local -ax _all_staged_and_unstaged_files=("${_all_staged_files[@]}" "${_all_unstaged_files[@]}")
  local -x  _file_counter=0
  local -ax _file_indexes=()
  local     _file_indexes_user_input
  local     _file_name
  local     _file_status

  # printing all the staged files
  _print_newline_message "Delete files from the next commit: "

  for file in "${_all_staged_files[@]}";
  do
    ((_file_counter--))

    _file_name="$(echo "${file}" | awk -F: '{OFS=":";$NF="";print $0;}')"
    _file_name="${_file_name%?}"

    _file_status="$(echo "${file}" | awk -F: '{print $NF}')"

    _print_newline_message "[${_file_counter}] \e[32m${_file_status}:   ${_file_name}\e[0m"
  done

  if [[ _file_counter -eq 0 ]];
  then
    _print_newline_message "\e[32mNo staged files\e[0m"
  fi

  # printing all the unstaged files

  _file_counter=0

  _print_empty_line
  _print_newline_message "Add files to the next commit: "

  for file in "${_all_unstaged_files[@]}";
  do
    _file_name="$(echo "${file}" | sed -E 's/\[\[:space:\]\]/ /g' | awk -F: '{OFS=":";$NF="";print $0;}')"
    _file_name="${_file_name%?}"

    _file_status="$(echo "${file}" | awk -F: '{print $NF}')"

    case "${_file_status}" in
      "modified")
        _print_newline_message "[${_file_counter}]  \e[34m${_file_status}\e[0m:   ${_file_name}"
        ;;
      "untracked")
        _print_newline_message "[${_file_counter}] \e[31m${_file_status}\e[0m:   ${_file_name}"
        ;;
      "deleted")
        _print_newline_message "[${_file_counter}]   \e[37m${_file_status}\e[0m:   ${_file_name}"
        ;;
    esac

    ((_file_counter++))
  done

  if [[ _file_counter -eq 0 ]];
  then
    _print_newline_message "\e[32mNo unstaged files\e[0m"
  fi

  # asking the user to input indexes of the files that should be deleted or added
  _print_empty_line
  _print_input_request_message "Enter file numbers separating by a space: "
  read _file_indexes_user_input

  _file_indexes=(`echo "${_file_indexes_user_input}"`)

  for index in "${_file_indexes[@]}";
  do
    # delete a staged file from the next commit
    if [[ "$(echo ${index} | cut -c 1)" == '-' ]];
    then
      if [[ -n "${_all_staged_files[$(($(echo ${index} | cut -c2-)-1))]}" ]];
      then
        _file_name="$(echo "${_all_staged_files[$(($(echo ${index} | cut -c2-)-1))]}" | awk -F: '{OFS=":";$NF="";print $0;}')"
        _file_name="${_file_name%?}"

        git reset HEAD "${_file_name}"
      fi
    else
      if [[ -n "${_all_unstaged_files[${index}]}" ]];
      then
        _file_name="$(echo "${_all_unstaged_files[${index}]}" | awk -F: '{OFS=":";$NF="";print $0;}')"
        _file_name="${_file_name%?}"

        git add "${_file_name}"
      fi
    fi
  done

  _command_git_commit
}

function _command_git_smart_checkout() {
  local    _user_choice_branch_counter=0
  local    _top_branch_index
  local    _bottom_branch_index
  local    _desired_branch_index
  local    _desired_branch
  local    _branch_counter=0
  local -x _branches_per_page=10
  local -x _page=1
  local -a _matching_branches

  # ask the user to input the name of a branch
  _print_input_request_message "Enter a branch name or a part of name: "
  read _desired_branch
  _print_empty_line

  # there is only one branch that match the desired one
  if `_find_and_switch_desired_branch "${_desired_branch}"`
  then
    return 0
  fi

  # there is more than one branch that match the desired one
  if [[ `_how_many_branches_match "${_desired_branch}"` -gt 0 ]]; then
    _print_newline_message "More than one git branch were found."
    _print_newline_message "Use the s|S and w|W keys on your keyboard for pagination."
    _print_newline_message "10 first branches are being shown."
    _print_newline_message "Please choose a desired branch."
    _print_empty_line

    # all the branches that match the desired one
    _matching_branches=(`_get_matching_branches "${_desired_branch}"`)

    while [[ 1 -eq 1 ]];
    do
      _branch_counter=0
      _user_choice_branch_counter=0

      # printing all the branches that match the desired one
      for branch in "${_matching_branches[@]}";
      do
        _bottom_branch_index=$(( ((${_page} - 1)) * ${_branches_per_page} ))
        _top_branch_index=$(( ${_bottom_branch_index} + ${_branches_per_page} ))

        # if the current branch index is between the range of the page
        if [[ ${_branch_counter} -ge ${_bottom_branch_index} && ${_branch_counter} -lt ${_top_branch_index} ]];
        then
          _print_newline_message "\033[1;31m[${_user_choice_branch_counter}] "${branch}"\033[0m"
          ((_user_choice_branch_counter++))
        fi

        ((_branch_counter++))
      done

      _print_empty_line

      # ask the user to input a branch index
      _desired_branch_index=`_ask_for_a_char`

      # if the user entered a correct index
      if [[ ${_desired_branch_index} =~ [0-9] ]];
      then
        # if the branch with the entered index exists
        if [[ -n "${_matching_branches[${_desired_branch_index}]}" ]];
        then
          git checkout "${_matching_branches[$(( $(( ${_page} - 1 )) * ${_branches_per_page} + ${_desired_branch_index} ))]}"
          return 0
        else
          return 1
        fi
      elif
      # show the next page with branches
      [[ ${_desired_branch_index} == "s" || ${_desired_branch_index} == "S" ]];
      then
        # incrementing the page's value
        [[ $(( ${_page} * ${_branches_per_page} )) -lt ${#_matching_branches[@]} ]] && ((_page++))

        if [[ ${#_matching_branches[@]} -gt ${_branches_per_page} ]];
        then
          tput cup $(($(tput lines) - 12)) 0
          tput il 12
        else
          tput cup $(( $(tput lines) - $(( ${#_matching_branches[@]} + 2 )) )) 0
          tput il $(( ${#_matching_branches[@]} + 2 ))
        fi
      elif
      # show the previous page with branches
      [[ ${_desired_branch_index} == "w" || ${_desired_branch_index} == "W" ]];
      then
        # decrementing the page's value
        [[ ${_page} -ne 1 ]] && ((_page--))

        if [[ ${#_matching_branches[@]} -gt ${_branches_per_page} ]];
        then
          tput cup $(($(tput lines) - 12)) 0
          tput il 12
        else
          tput cup $(( $(tput lines) - $(( ${#_matching_branches[@]} + 2 )) )) 0
          tput il $(( ${#_matching_branches[@]} + 2 ))
        fi
      else
        break
      fi
    done
  fi

  _print_newline_message "There is no such branch."

  _command_git_smart_checkout
}

function _command_git_modify_commit() {
  IFS=$'\n'
  local -ax _all_commits=(`_all_git_commits`)
  local     _top_commit_index
  local     _bottom_commit_index
  local     _desired_commit_index
  local -x  _user_choice_commit_counter=0
  local -x  _commit_counter=0
  local -x  _commits_per_page=10
  local -x  _page=1
  local     _commit_hash
  local     _commit_message
  local     _commit_index_in_array
  local     _old_git_sequence_editor

  while [[ 1 -eq 1 ]];
  do
    _user_choice_commit_counter=0
    _commit_counter=0

    _bottom_commit_index=$(( ((${_page} - 1)) * ${_commits_per_page} ))
    _top_commit_index=$(( ${_bottom_commit_index} + ${_commits_per_page} ))

    for commit in "${_all_commits[@]}";
    do
      # if the current commit index is between the range
      if [[ ${_commit_counter} -ge ${_bottom_commit_index} && ${_commit_counter} -lt ${_top_commit_index} ]];
      then
        _commit_hash="$(echo ${commit} | awk -F ':' '{print $1}')"
        _commit_message="$(echo ${commit} | awk -F ':' '{$1="";print $0}')"

        _print_newline_message "[${_user_choice_commit_counter}] \033[31m"${_commit_hash}"\033[0m -"${_commit_message}""
        ((_user_choice_commit_counter++))
      else
        [[ ${_commit_counter} -gt ${_top_commit_index} ]] && break
      fi

      ((_commit_counter++))
    done

    _print_empty_line

    # ask the user to input a commit index
    _turn_on_user_input
    _desired_commit_index=`_ask_for_a_char`
    _turn_off_user_input

    # if the user entered a correct index
    if [[ ${_desired_commit_index} =~ [0-9] ]];
    then
      _commit_index_in_array="$(( $(( ${_page} - 1 )) * ${_commits_per_page} + ${_desired_commit_index} ))"
      # if the commit with the entered index exists
      if [[ -n "${_all_commits[${_commit_index_in_array}]}" ]];
      then
        _commit_hash=$(echo ${_all_commits[${_commit_index_in_array}]} | awk -F ':' '{print $1}')

        if [[ -z ${GIT_SEQUENCE_EDITOR} ]];
        then
          export GIT_SEQUENCE_EDITOR="casual-git-dummy-rebase-editor"
          git rebase --interactive "${_commit_hash}^"
          unset GIT_SEQUENCE_EDITOR
        else
          _old_git_sequence_editor=${GIT_SEQUENCE_EDITOR}
          export GIT_SEQUENCE_EDITOR="casual-git-dummy-rebase-editor"
          git rebase --interactive "${_commit_hash}^"
          export GIT_SEQUENCE_EDITOR=${_old_git_sequence_editor}
        fi

        return 0
      else
        return 1
      fi
    elif
    # show the next page
    [[ ${_desired_commit_index} == "s" || ${_desired_commit_index} == "S" ]];
    then
      # incrementing the page's value
      [[ $(( ${_page} * ${_commits_per_page} )) -lt ${#_all_commits[@]} ]] && ((_page++))

      if [[ ${#_all_commits[@]} -gt ${_commits_per_page} ]];
      then
        tput cup $(($(tput lines) - 12)) 0
        tput il 12
      else
        tput cup $(( $(tput lines) - $(( ${#_all_commits[@]} + 2 )) )) 0
        tput il $(( ${#_all_commits[@]} + 2 ))
      fi
    elif
    # show the previous page
    [[ ${_desired_commit_index} == "w" || ${_desired_commit_index} == "W" ]];
    then
      # decrementing the page's value
      [[ ${_page} -ne 1 ]] && ((_page--))

      if [[ ${#_all_commits[@]} -gt ${_commits_per_page} ]];
      then
        tput cup $(($(tput lines) - 12)) 0
        tput il 12
      else
        tput cup $(( $(tput lines) - $(( ${#_all_commits[@]} + 2 )) )) 0
        tput il $(( ${#_all_commits[@]} + 2 ))
      fi
    else
      break
    fi
  done
}

_show_usage
_turn_off_user_input

case `_ask_for_a_char` in
  s|S)
    _turn_on_user_input
    _command_git_smart_commit
    ;;
  l|L)
    _command_git_pretty_log
    ;;
  d|D)
    _command_git_push
    ;;
  f|F)
    _command_git_force_push
    ;;
  p|P)
    _command_git_pull
    ;;
  o|O)
    _command_git_force_pull
    ;;
  c|C)
    _turn_on_user_input
    _command_git_commit
    ;;
  a|A)
    _command_git_amend_commit
    ;;
  h|H)
    _turn_on_user_input
    _command_git_smart_checkout
    ;;
  m|M)
    _command_git_modify_commit
esac

_turn_on_user_input
