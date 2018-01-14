#!/bin/bash

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
      git checkout "${_desired_branch}"
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
    git checkout "${_matching_branch}"
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
	local -a array_unstaged_files
	local -a array_numbers
	local -a array_staged_files
    local -a str_git_status_file
    local -a str_status
    local -a str_file_path
    local -a str_type
    local -a int_i
    local -a int_number

    int_i=0

    output "Delete files from the next commit: "

    # STAGED FILES
	{ while IFS= read -r str_git_status_file;
	do
		[[ -z ${str_git_status_file} ]] && continue

		((int_i--))
		str_status=$(echo ${str_git_status_file} | cut -c1-1)
		str_file_path=$(echo "${str_git_status_file}" | sed -E 's/^.{0,3}//g')

		array_staged_files+=("${str_file_path}")


        case ${str_status} in
            'M')
                type='modified'
                ;;
            'D')
                type='deleted '
                ;;
            'A')
                type='new file'
                ;;
            'R')
                type='renamed '
                ;;
            *)
                type='unknown'
                ;;
        esac

		output "[$int_i] \e[32m${type}: ${str_file_path}\e[0m"

	done } <<< "$(git status -s | grep -E 'M. |D. |A. |R. ')"

    [[ int_i -eq 0 ]] && output "\e[32mNo staged files\e[0m"

	int_i=0

    output
    output "Add files to the next commit: "

    # UNSTAGED FILES
	{ while IFS= read -r str_git_status_file;
	do
        [[ -z "${str_git_status_file}" ]] && continue

        ((int_i++))
        str_status=$(echo "${str_git_status_file}" | cut -c1-2)
        str_file_path=$(echo "${str_git_status_file}" | sed -E 's/^.{0,3}//g')

        array_unstaged_files+=(${str_file_path})

        case "${str_status:1:1}" in
            '?')
                output "[${int_i}] \e[31muntracked:\e[0m ${str_file_path}"
                ;;
            'M')
            	output "[${int_i}] \e[34mmodified:\e[0m  ${str_file_path}"
                ;;
            'D')
                output "[${int_i}] \e[37mdeleted:\e[0m   ${str_file_path}"
                ;;
        esac
	done } <<< "$(git status -s | grep -E '\?\? |.M |.D ')"

    [[ int_i -eq 0 ]] && output "\e[32mNo unstaged files\e[0m"

    output
    output "Enter file numbers separating by spaces: " no

    read array_numbers

    array_numbers=($(echo ${array_numbers}))

    # STAGING FILES
    for int_number in "${array_numbers[@]}"
    do
        if [[ "$(echo ${int_number} | cut -c 1)" == '-' ]];
        then
            if [[ -n "${array_staged_files[$(($(echo ${int_number} | cut -c2-)-1))]}" ]];
            then
                git reset HEAD "${array_staged_files[$(($(echo ${int_number} | cut -c2-)-1))]}"
            fi
        else
            if [[ -n "${array_unstaged_files[$((${int_number}-1))]}" ]];
            then
                git add "${array_unstaged_files[$((${int_number}-1))]}"
            fi
        fi
    done

    commit
}

function _command_git_smart_checkout() {
  local    _desired_branch_index
	local    _desired_branch
	local    _branch_counter=0
	local -a _matching_branches

  # ask the user to input a name of a branch
	_print_input_request_message "Enter a branch name or a part of name: "
	read _desired_branch
  _print_empty_line

  # there is only one branch matching the desired branch
  if `_find_and_switch_desired_branch ${_desired_branch}`
  then
    return 0
  fi

  # there is more than one branch matching the desired branch
  if [[ `_how_many_branches_match ${_desired_branch}` -gt 0 ]]; then
    _print_newline_message "More than one git branch were found."
    _print_newline_message "10 first branches are being shown."
    _print_newline_message "Please choose a desired branch."
    _print_empty_line

    # all the branches that match the desired one
    _matching_branches=(`_get_matching_branches ${_desired_branch}`)

    # printing all the branches that match the desired one
    for branch in "${_matching_branches[@]}";
    do
      _print_newline_message "\033[1;31m[${_branch_counter}] "${branch}"\033[0m"
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
        git checkout "${_matching_branches[${_desired_branch_index}]}"
        return 0
      else
        return 1
      fi
    fi
  fi

  _print_newline_message "There is no such branch."

  _command_git_smart_checkout
}

function output() {
    local -a lb

    if [[ $2 != 'no' ]];
    then
        lb="\n"
    fi

    printf "  $1$lb"
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
