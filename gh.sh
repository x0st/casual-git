#!/bin/bash

# Returns 1 if the provided string contains at least 1 space, 0 otherwise.
function _string_contains_spaces {
  [[ "$1" != "${1%[[:space:]]*}" ]] && return 0 || return 1
}

# Shows help to the user.
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
  _print_empty_line
}

# Prints the current project's branch.
function _current_branch() {
  git rev-parse --abbrev-ref HEAD
}

# User input is shown.
function _turn_on_user_input() {
  stty echo
}

# User input is not shown.
function _turn_off_user_input() {
  stty -echo
}

# Prints a message with a line break.
function _print_newline_message() {
  printf "  $1\n"
}

# Prints a message with no line break.
function _print_input_request_message() {
  printf "  $1"
}

# Prints a line break.
function _print_empty_line() {
  printf "\n"
}

# Asks the user to enter any character.
function _ask_for_a_char() {
  local _answer;

  read -r -s -n 1 _answer

  echo ${_answer}
}

# Asks the user for input 'y' or 'n'.
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

# Prints all the local and remote branches received with 'git fetch --all'.
function _all_git_branches() {
  git branch -a \
  | sed 's/^[[:space:]][[:space:]][[:alnum:]]*\/[[:alnum:]]*\///g' \
  | sed '/HEAD -> [[:alnum:]/]*/d' \
  | sed '/^* [[:alnum:]]*/d' \
  | sed '/^[[:space:]][[:space:]][[:alnum:]]*/d'
}

# Accepts an approximate or exact name of a branch as first argument.
# Tries to find a branch matching the provided one.
# If only one branch matches the provided one then it is switched.
function _find_and_switch_desired_branch() {
  local _desired_branch=${1}
  local _matching_branches_count=0
  local _matching_branch
  local -a _all_branches=(`_all_git_branches`)

  # the user did not provide a name of a branch
  if [[ -z ${_desired_branch} ]];
  then
    return 1
  fi

  # iterating over all branches and checking if any branch matches the desired one
  for i in "${_all_branches[@]}"
  do
    # the desired branch is found and we can switch the branch instanly
    if [[ "${i}" == "${_desired_branch}" ]]; then
      git checkout "${_desired_branch}" > /dev/null
      return 0
    fi

    # if there is no the exact name then matched names are written
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      ((_matching_branches_count++))
      _matching_branch="${i}"
    fi
  done

  # if only one branche matched than we can switch
  if [[ ${_matching_branches_count} -eq 1 ]]; then
    git checkout "${_matching_branch}" > /dev/null
    return 0
  fi

  return 1
}

# Accepts an approximate or exact name of a branch as first argument.
# Counts the amount of the branches that match the provided one.
function _how_many_branches_match() {
  local _desired_branch=${1}
  local _matching_branches_count=0
  local -a _all_branches=(`_all_git_branches`)

 # iterating over all branches and checking if any branch matches the desired one
  for i in "${_all_branches[@]}"
  do
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      ((_matching_branches_count++))
    fi
  done

  echo ${_matching_branches_count}
}

# Accepts an approximate or exact name of a branch as first argument.
# Finds the branches that match the provided one.
function _get_matching_branches() {
  local _desired_branch="${1}"
  local -a _all_branches=(`_all_git_branches`)
  local -a _matching_branches=()

  # iterating over all branches and checking if any branch matches the desired one
  for i in "${_all_branches[@]}"
  do
    if [[ "${i}" =~ "${_desired_branch}" ]]; then
      _matching_branches=("${_matching_branches[@]}" "${i}")
    fi
  done

  echo "${_matching_branches[@]}"
}

# Prints all staged files.
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

# Prints all staged files.
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

  # printing all staged files
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

  # printing all unstaged files

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

  # asking the user to enter indexes of the files that should be deleted or added
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

  # ask the user to input a name of a branch
  _print_input_request_message "Enter a branch name or a part of name: "
  read _desired_branch
  _print_empty_line

  # there is only one branch matching the desired branch
  if `_find_and_switch_desired_branch "${_desired_branch}"`
  then
    return 0
  fi

  # there is more than one branch matching the desired branch
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
        # if the branch exists with the entered index
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
      # show  the previous page with branches
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
esac

_turn_on_user_input
