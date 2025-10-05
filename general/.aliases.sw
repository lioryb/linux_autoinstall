##############################
# source aliases and functions
###############################
alias rlda='. /home/${USER}/tools/general/.aliases.${USER}' # reload aliases
alias rlf='. /home/${USER}/tools/general/.funcs.${USER}' # reload functions

##############################
# general
##############################
alias rl='readlink -f '
alias h='history'
alias hg='history | grep $1'

##############################
# directory switch
##############################
alias ptop='pushd $(git rev-parse --show-toplevel)'

# if [[ -z $(git rev-parse --show-superproject-working-tree) ]] --> is true if in superproject
alias cdtop='if [[ ! -z $(git rev-parse --show-superproject-working-tree) ]]; then cd $(git rev-parse --show-superproject-working-tree); fi; cd $(git rev-parse --show-toplevel)'
alias cdapp='if [[ ! -z $(git rev-parse --show-superproject-working-tree) ]]; then cd $(git rev-parse --show-superproject-working-tree); fi; cd $(git rev-parse --show-toplevel)/src/app_server/griffin_ctrl'
alias cdhost='cd $(git rev-parse --show-toplevel); if [[ -z $(git rev-parse --show-superproject-working-tree) ]]; then cd src/sw-dev/; fi; cd sdk/projects/host/'
alias cdibld='cd $(git rev-parse --show-toplevel); if [[ -z $(git rev-parse --show-superproject-working-tree) ]]; then cd src/sw-dev/; fi; cd tools/image_builder'
alias cdfw='cd $(git rev-parse --show-toplevel); if [[ -z $(git rev-parse --show-superproject-working-tree) ]]; then cd src/sw-dev; fi'

##############################
# copy files to evb
##############################
# copy last bin file to requested evb
#alias lfwcp='if [[ -z $EVB ]]; then echo -e "\033[0;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At $(git rev-parse --show-toplevel)/fw/workspace/mide/fw/Release/griffin/fw_v*.bin)); if [[ $EVB == "rf" ]]; then scp ${flist[0]} /home/sw/app_server/images/test/fw/.; elif [[ $EVB =~ "rf" ]]; then ip=${EVB:2}; scp ${flist[0]} sw@192.168.177.${ip}:/home/sw/app_server/images/test/fw/.; else scp ${flist[0]} root@$(evb $EVB):/home/root/components/retym_driver/test/fw/.; fi; unset flist; fi'
#alias cphost='if [[ -z $EVB ]]; then echo -e "\033[0;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At build/petalinux/host_*)); scp ${flist[0]} root@$(evb $EVB):/home/root/.; unset flist; fi'
#alias cpapp='if [[ -z $EVB ]]; then echo -e "\033[0;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At griffin_ctrl_*)); if [[ $EVB == "rf" ]]; then cp ${flist[0]} /home/sw/app_server/images/test/app/.; else scp ${flist[0]} root@$(evb $EVB):/home/root/components/retym_driver/test/app/.; fi; unset flist; fi'
alias lfwcp='if [[ -z $EVB ]]; then echo -e "\033[0;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At $(git rev-parse --show-toplevel)/fw/workspace/mide/fw/Release/griffin/fw_v*.bin)); if [[ $EVB =~ "rf" ]]; then tdir=/home/sw/app_server/images/test/fw/.; if [[ $EVB == "rf" ]]; then cmd=cp; else cmd=scp; tgt=sw@192.168.177.${EVB:2}:; fi; else tdir=/home/root/components/retym_driver/test/fw/.; cmd=scp; if [[ $EVB =~ "ip" ]]; then ip=192.168.177.${EVB:2}; else ip=$(evb $EVB); fi; tgt=root@${ip}:; fi; ${cmd} ${flist[0]} ${tgt}${tdir}; fi; unset flist; unset tdir; unset cmd; unset ip; unset tgt'
alias cphost='if [[ -z $EVB ]]; then echo -e "\033[0;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At build/petalinux/host_*)); if [[ $EVB =~ "rf" ]]; then tdir=/home/sw/.; if [[ $EVB == "rf" ]]; then cmd=cp; else cmd=scp; tgt=sw@192.168.175.${EVB:2}:; fi; else tdir=/home/root/.; cmd=scp; if [[ $EVB =~ "ip" ]]; then ip=192.168.177.${EVB:2}; else ip=$(evb $EVB); fi; tgt=root@${ip}:; fi; ${cmd} ${flist[0]} ${tgt}${tdir}; fi; unset flist; unset tdir; unset cmd; unset ip; unset tgt'
alias cpapp='if [[ -z $EVB ]]; then echo -e "\033[;41mEVB is not defined\033[0m\n\033[0;31muse \"EVB=<\033[3mindex\033[0;31m>\" to define evb id\033[0m"; else flist=($(ls -At griffin_ctrl_*)); echo flist: $flist; if [[ $EVB =~ "rf" ]]; then tdir=/home/sw/app_server/images/test/app/.; if [[ $EVB == "rf" ]]; then cmd=cp; else cmd=scp; tgt=sw@192.168.175.${EVB:2}:; fi; else tdir=/home/root/components/retym_driver/test/app/.; cmd=scp; if [[ $EVB =~ "ip" ]]; then ip=192.168.177.${EVB:2}; else ip=$(evb $EVB); fi; tgt=root@${ip}:; fi; ${cmd} ${flist[0]} ${tgt}${tdir}; fi; unset flist; unset tdir; unset cmd; unset ip; unset tgt'

##############################
# search
##############################

# search pattern in .c and .h files
alias ghc="grep -r --include=*.h --include=*.c $1"

##############################
# fw dev
##############################
alias fbuild='$(git rev-parse --show-toplevel)/tools/scripts/fbuild.sh'
alias mapfile='ls $(git rev-parse --show-toplevel)/fw/workspace/mide/fw/Release/griffin/fw.map'


##############################
# git hooks
##############################


##############################
# temp
##############################
alias parc='pushd /home/sw/ARC/MetaWare/arc/../../license/'
alias dis_llic='mv arc.lic expireJan26_arc.lic'
alias en_llic='mv expireJan26_arc.lic arc.lic'
