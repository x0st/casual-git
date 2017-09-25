#!/bin/bash

function git_push() {
    output "Pushing..."
	git push origin $1
}

function force_push() {
	git push origin $1 --force
}

function pull() {
    output "Pulling..."
	git pull origin $1
}

function pretty_log() {
	git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

function commit() {
    local -a comment

    output
	output "Enter a comment: " no

	read comment

	git commit -m "${comment}"
}

function amend_commit() {
	git commit --amend --no-edit
}

function smart_commit() {
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

function smart_checkout() {
	local -a str_desired_branch_name
	local -a int_branch_num
	local -a array_branch_list
	local -a int_i

	output "Enter a branch name or a part of name: " no

	read str_desired_branch_name

    output ""

	if [[ -z ${str_desired_branch_name} ]];
	then
	    return 1
	fi

	if [[ -n "$(git show-ref refs/heads/${str_desired_branch_name})" ]];
	then
		git checkout ${str_desired_branch_name}

	elif [[ $(git branch | sed -E 's/^.{0,2}//g' | grep ${str_desired_branch_name} --color=no -c) -gt 0 ]];
	then
	    output "More than one git branch were found. \n  10 first branches are shown. \n  Please choose a desired branch. \n"

	    array_branch_list=($(git branch | sed -E 's/^.{0,2}//g' | grep ${str_desired_branch_name} --color=no))
        int_i=0

	    for branch in "${array_branch_list[@]:0:9}";
	    do
	        output "\033[1;31m[${int_i}] "${branch}"\033[0m"
	        ((int_i++))
	    done

	    output ""

	    read -r -s -n 1 int_branch_num

        if [[ ${int_branch_num} =~ [0-9] ]];
        then
            if [[ -n "${array_branch_list[${int_branch_num}]}" ]];
            then
                git checkout "${array_branch_list[$int_branch_num]}"
            else
                return 1
            fi
        fi

	elif [ -z "$(git show-ref refs/heads/${str_desired_branch_name})" ];
	then
		output "There is no such a branch"
		smart_checkout
	fi
}

function get_current_branch() {
    echo $(git rev-parse --abbrev-ref HEAD)
}

function output() {
    local -a lb

    if [[ $2 != 'no' ]];
    then
        lb="\n"
    fi

    printf "  $1$lb"
}

function show_usage() {
    output
    output "\033[1;31md \033[0m - push"
    output "\033[1;31mf \033[0m - force push"
    output "\033[1;31mp \033[0m - pull"
    output "\033[1;31mc \033[0m - commit"
    output "\033[1;31ma \033[0m - amend commit"
    output "\033[1;31ms \033[0m - smart commit"
    output "\033[1;31ml \033[0m - pretty log"
    output "\033[1;31mh \033[0m - smart checkout"
    output
}

show_usage

# waiting for a char and suppressing output
read -r -s -n 1 answer

# turn off any user input
stty -echo

case ${answer} in
    # SMART COMMIT
	s|S)
		stty echo
		smart_commit
		;;
	l|L)
		pretty_log
		;;
	d|D)
		git_push $(get_current_branch)
		;;
	f|F)
		force_push $(get_current_branch)
		;;
	p|P)
		pull $(get_current_branch)
		;;
	c|C)
		# turn on user input
		stty echo
		commit
		;;
	a|A)
		amend_commit
		;;
	h|H)
		# turn on user input
		stty echo
		smart_checkout
		;;
esac

# turn on user input
stty echo
