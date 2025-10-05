#!/bin/bash

function is_number_int()
{
	in_arg=$1
	re='^[0-9]+$'
	if ! [[ $in_arg =~ $re ]] ; then
		echo 0
		return
	fi

	echo 1
}

function is_number()
{
	in_arg=$1
	re='^[0-9]+([.][0-9]+)?$'
	if ! [[ $in_arg =~ $re ]] ; then
		echo 0
		return
	fi

	echo 1
}

function is_number_signed()
{
	in_arg=$1
	re='^[+-]?[0-9]+([.][0-9]+)?$'
	if ! [[ $in_arg =~ $re ]] ; then
		echo 0
		return
	fi

	echo 1
}

function ff()
{
	find . -iname "$1" -exec readlink -f {} + ;
}

function fany()
{
	if [[ ! -z $2 ]]; then
		param="-type ${2#-}"
	fi
	find . $param -iname "*$1*" -exec readlink -f {} + ;
}

function evb
{
	local evb_idx=$1
	local last_nibble=0
	local IP

	case "$evb_idx" in
		master|200)
			last_nibble=200
			;;
		5|6)
			# evb 5 --> ip 50
			# evb 6 --> ip 51
			last_nibble=$((50 + ${evb_idx} - 5))
			;;
		8)
			last_nibble=52
			;;
		12)
			last_nibble=53
			;;
		15)
			last_nibble=54
			;;
		2[0-8])
			last_nibble=${evb_idx}
			;;
		*)
			echo "UNKNOWN EVB" > /dev/tty
			return
			;;
	esac
	
	IP=192.168.175.${last_nibble}
	
	echo ${IP}
}

function sevb
{
	local evb_ip
	
	if [[ $# -eq 1 ]]; then
		evb_ip=$(evb $1)
	elif [[ $# -eq 2 && $1 == "ip" ]]; then
		evb_ip=192.168.175.$2
	else
		echo "Erroneous usage..." > /dev/tty
		echo -e "sevb [evb_id|ip <ip>]\n\tEither use a specific known EVB ID or use prefix 'ip' followed by last nibble of requested evb"
		return
	fi

	ssh root@${evb_ip}
}

function newip
{
	if [[ $# -gt 2 ]]; then
		echo -e "Too many parameters"
	elif [[ $# -eq 2 ]]; then
		src_evb=192.168.175.$2
	else
		src_evb=$(evb master)
	fi
	
	new_addr="192.168.175.${1}"
	echo ssh -t root@${src_evb} "sed -i \"s/Address\=192\.168\.175\.200/Address=${new_addr}/g\" /etc/systemd/network/01-eth0.network ; /sbin/reboot"
}

function arc_license()
{
	local enable_floating=$1

	if [[ ! -z $enable_floating ]] && ([[ ${enable_floating,,} == "floating" ]] || [[ ${enable_floating,,} == "true" ]] || [[ $enable_floating == "1" ]]); then
		echo setting ARC floating license
		export LM_LICENSE_FILE=27020@cad-license.retym.internal
		export SNPSLMD_LICENSE_FILE=27020@cad-license.retym.internal
	else
		echo removing ARC floating license
		unset LM_LICENSE_FILE
		unset SNPSLMD_LICENSE_FILE
	fi
}

function calc_indent
{
    local msg=$@
    local half_lmsg=$((${#msg}/2))
    local half_term=$(($(tput cols)/2))
    local indent=$((half_term - half_lmsg))

    echo $indent
}

# get current row index
function get_row
{
    IFS='[;' read -p $'\e[6n' -d R -rs _ y x _
    printf '%s\n' "$y"
}

# indented  print
function iprint
{
    local indent=$1
    shift
    msg=$@
    if [[ $indent == "0" ]]; then
        printf "${msg}"
    else
        # escape character \e[<n>C would indent the cursor in 'n' places in the row
        printf "\e[${indent}C${msg}"
    fi
}

function gadd
{
    . /home/sw/tools/general/colors.sh
    
    define_colors

	function gadd_internal()
	{
		files=$@
		echo -e "press 'Y' and enter for each file you want to add to git:"
		local flist=""
		for file in $files; do
			local mystr="$(set_color $_CORG $_CNONE 1)${file}${_NC} (y/n)?   "
			local r=$(get_row)
			local c=${#mystr}
			tput cup $((r-1)) 10
			echo -e $mystr
			tput cup $((r-2)) $c
			read -n 1 -r rpl
			tput cup $((r-2)) 0
			if [[ $rpl =~ ^[Qq]$ ]]; then
				return
			elif [[ $rpl =~ ^[Yy]$ ]]; then
				echo -e "$(set_color $_CGRN)ADD${_NC}";
				flist="$flist $file"
			else
				echo -e "$(set_color $_CRED)IGNORE${_NC}";
			fi;
		done
		
		if [[ ! -z $flist ]]; then
			git add $flist
		else
			echo -e "Nothing to add"
		fi
	}

	pushd $(git rev-parse --show-toplevel)

	echo -e "$(set_color $_CCYN $_CNONE 1)Showing modified files first:${_NC}"
	echo -e "$(set_color $_CCYN $_CNONE 1)=============================${_NC}"
	local files=$(git diff --name-only)
	gadd_internal $files

	echo -e "$(set_color $_CCYN $_CNONE 1)Now untracked files:${_NC}"
	echo -e "$(set_color $_CCYN $_CNONE 1)====================${_NC}"
	files=$(git ls-files --others --exclude-standard)
	gadd_internal $files

	popd

    undef_colors
}

function lsh
{
    . /home/sw/tools/general/colors.sh
    
    define_colors

	local first_commit=$1
	local last_commit=$2
	local cmd=$3

	local hlist=$(git log --reverse --pretty=format:'%h' ${1}^..${2})
	for cmh in $hlist
	do
		local commit_message=$(git log $cmh --pretty=format:%s -n1 2>&1)
		echo -e "commit_message:\n$(set_color $_CGRN)$commit_message${_NC}\n"
		echo -e Are you sure you want to "-  $(set_color $_CORG)$cmd${_NC}  -" this commit? [y/n]
		read -n1 -s decision
		decision="${decision^}" # set to uppercase

		if [[ $decision != "Y" ]]; then
			echo Skipping....
		else
			echo performing: $cmd
			git $cmd $cmh
		fi
	done

    undef_colors
}

function parse_version_file()
{
	function parse_it()
	{
		local filename=$1
		local regexp_str=$2
		local is_hex=$3
		local strip=
		local cur_d=

		if [[ -z $is_hex ]]; then
			local stringarray=($(cat $filename | grep -i "define.*$regexp_str"))
			cur_d=${stringarray[2]}
		else
			local old_hex_value=$(cat $filename | grep -i $regexp_str | cut -d "x" -f2)
			local cur_h=$(printf %d 0x$old_hex_value)
    		cur_d=$((16#$old_hex_value))
		fi

		echo $cur_d
	}

	unset is_hex
	local version_file=$1
	case "$2" in
		-h)
			is_hex="1"
			;;
		*)
			# do nothing
			;;
	esac

    # find current version from file
	local major_d=$(parse_it $version_file "MAJOR" $is_hex)
	local minor_d=$(parse_it $version_file "MINOR" $is_hex)
	local build_d=$(parse_it $version_file "BUILD" $is_hex)

	if [[ ! -z $build_d ]]; then
		build_d=$((0x7fff & $build_d))
		build_d=".$build_d"
	fi

    echo "${major_d}.${minor_d}${build_d}"

	unset is_hex
}

function update_hooks()
{
	. /home/sw/tools/general/colors.sh

	define_colors

	htype=$1

	case "$htype" in
		fw)
			repo_name=$(echo $(basename -s .git `git config --get remote.origin.url`) | cut -d ":" -f 2)
			if [[ $repo_name != "sw-dev" ]];
			then
				echo -e "$(set_color $_CRED $_CNONE 0)Cannot update when outside of $(set_color $_CORG $_CNONE 1)sw-dev$(set_color $_CRED $_CNONE 0) repo!!${_NC}"
			else
				if [[ $(pwd) != $(git rev-parse --show-toplevel) ]]; then
					echo -e "$(set_color $_CRED $_CNONE 0)You must run from GIT top-level!!${_NC}"
					echo -e "please type \'cdfw\'' and retry"
				else
					shift
					./tools/scripts/update_fw_hooks.sh "$1"
				fi
			fi
			;;
		*)
			echo -e "$(set_color $_CRED $_CNONE 1)This option is not supported at the momemnt!!${_NC}"
			;;
	esac

	undef_colors
}





























































































































































































































































































































function viavi()
{
	local fwv=$1
	local ip='192.168.175.13'

	if [[ -z $2 ]]; then
		ext=''
	else
		ext=${2}
	fi

	./tools/scripts/fbuild.sh -fv ${fwv} -bv 0.8.900 ${ext}
	scp $(git rev-parse --show-toplevel)/fw/workspace/mide/fw/Release/griffin/fw_v${fwv}.bin ${ip}:/home/sw/app_server/images/test/fw/.
	lfwcp
}

function cpvm()
{
	local main_fw=02.13
	local main_b=0.8
	local fwv=$1
	local dest='192.168.175.'$2
	local cmd='cp'

    if [[ $(is_number_int $2) == 1 ]]; then
		dest='sw@192.168.175.'$2':/home/sw'
		cmd='scp'
	else
		dest='/home/sw'
	fi

	if [[ -z $3 ]]; then
		ext=''
	else
		ext=${3}
	fi

	./tools/scripts/fbuild.sh -fv ${main_fw}.${fwv} -bv ${main_b}.${fwv} ${ext}
	cp $(git rev-parse --show-toplevel)/fw/workspace/mide/fw/Release/griffin/fw_v${main_fw}.${fwv}.bin ${dest}/app_server/images/test/fw/.
	#lfwcp
}

function free_ssh()
{
	function doit()
	{
		local cmd=$@

		echo -e $cmd
		echo -e no perform it $cmd
	}
	
	local parr=()
	local ip
	local parts
	local cmd


	if [[ $# -eq 0 ]]; then
		echo -e "Error. missing IP"
		return
	fi
	
	ip=$1
	user=$2
	# split $ip into an array named parr, with delimiter of a dot
	IFS='.' read -r -a parr <<< $ip; unset IFS
	# check number of parts received
	parts=${#parr[@]}
	if [[ ${parts} < 4 ]]; then
		echo "Invalid IP ($ip)"
		return
	fi


	cmd="chmod 0700 ~/.ssh"
	cmd+="; chmod 0600 ~/.ssh/authorized_keys"
	cmd+="; chmod go-w /home/sw"

	cmd="echo lior > ~/lyb.log"
	cmd+="; echo lior2 >> ~/lyb.log"

	ssh ${user}@${ip} '$cmd'
}

initials() {
	local full_name="$@"
	local name_initials=""

	# Check if a name was provided as an argument
	# if [ -z "$1" ]; then
	# 	echo "Usage: $0 'Full Name'"
	for word in $full_name; do
		name_initials+="${word:0:1}"
	done

	echo "$name_initials"
}

function fgv
{
	local var_name=$1
	local option=
	# use exact match
	if [[ $2 == "e" ]]; then option=-w; fi

	addr=$(cat $(mapfile) | grep $option "\.data\.$var_name" -A 1 | grep -v "\.data\.$var_name" | grep -v "@offset" | sed -e "s/ \+/,/g" | cut -d ',' -f 2 | grep "[0-9|a-f|A-F]")
	if [[ -z ${addr} ]]; then
		addr=$(cat $(mapfile) | grep $option "\.bss\.$var_name" -A 1 | grep -v "\.bss\.$var_name" | grep -v "@offset" | sed -e "s/ \+/,/g" | cut -d ',' -f 2 | grep "[0-9|a-f|A-F]")
		if [[ -z ${addr} ]]; then
			addr=$(cat $(mapfile) | grep $option "\.text\.$var_name" -A 1 | grep -v "\.text\.$var_name" | grep -v "@offset" | sed -e "s/ \+/,/g" | cut -d ',' -f 2 | grep "[0-9|a-f|A-F]")
			if [[ -z ${addr} ]]; then
				echo 'not found'
				return 1
			fi
			echo 'Found in TEXT section'
		fi
		echo 'Found in BSS section'
	fi

	echo "0x${addr}"
}

function dbranch
{
	branch_name=$1

	echo -e "git branch  -D ${branch_name}"
	git branch  -D ${branch_name}
	echo -e "git push origin -d ${branch_name}"
	git push origin -d ${branch_name}
}
