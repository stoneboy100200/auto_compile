#!/bin/bash
# **********************************************************************************************
# FILE: StartCompileNaviCore.sh
# AUTHOR: Li Seven
# MAIL: Seven.Li@cn.bosch.com
# ENVIRONMENT: WinSim
# BRIEF: This script is used for A-IVI.
#        It could checkout src code for nincg3 and navi_development
#        automatically, and compile navi core.
#        In order to compile navi core automatically, you should
#        use it along with another script 'StartBabun.bat'
#WIKI: https://inside-docupedia.bosch.com/confluence/display/CARSFW/Auto+Compile+for+Navi+Core
#UPDATE: It's no longer necessary to build NaviSDK,
#        just register at the 'artifactory'-server instead and
#        fetch the already created binaries from there.
#        Please uncomment this part 'Download binaries from artifactory'
#        and comment out this part 'Compile navi_development'
#        if you'd like to download binaries instead of compiling NaviSDK
# **********************************************************************************************
NINCG3_PATH=$1
NAVI_DEVELOPMENT_PATH=$2
NINCG3_ROOT_COMMIT=$3
AI_NAVI_SDK_PATH=ai_navi_sdk/rnaivi
#NINCG3_BRANCH=rn_aivi_16.3_stabi
NINCG3_BRANCH=nissan_ncg3_int
AI_NISSAN_HMI_PATH=ai_nissan_hmi
#AI_NISSAN_HMI_USER_BRANCH=use/lse9szh/bug_fix_stabi
AI_NISSAN_HMI_USER_BRANCH=use/lse9szh/bug_fix_feature

# -------------------------------------------------------------
# Output for pretty printing
# -------------------------------------------------------------
cfont() {
   while (($#!=0))
   do
      case $1 in
         -b)
            echo -ne " ";
            ;;
         -t)
            echo -ne "\t";
            ;;
         -n)
            echo -ne "\n";
            ;;
         -black)
            echo -ne "\033[30m";
            ;;
         -red)
            echo -ne "\033[31m";
            ;;
         -green)
            echo -ne "\033[32m";
            ;;
         -yellow)
            echo -ne "\033[33m";
            ;;
         -blue)
            echo -ne "\033[34m";
            ;;
         -purple)
            echo -ne "\033[35m";
            ;;
         -cyan)
            echo -ne "\033[36m";
            ;;
         -white|-gray)
            echo -ne "\033[37m";
            ;;
         -reset)
            echo -ne "\033[0m";
            ;;
         -h|-help|--help)
            echo "Usage: cfont -color1 message1 -color2 message2 ...";
            echo "eg:       cfont -red [ -blue message1 message2 -red ]";
            ;;
         *)
            echo -ne "$1"
            ;;
      esac
      shift
   done
}

# -------------------------------------------------------------
# Print time
# -------------------------------------------------------------
etime()
{
   cfont -green "End time: `date`" -reset -n
}

# -------------------------------------------------------------
# Remove index.lock for git operation
# -------------------------------------------------------------
check_lock()
{
   LOCK=`find .git -name 'index.lock' -exec ls {} \;`
   if [ -z "$LOCK" ]; then
      cfont -green "There is no index.lock in submodule :)" -reset -n
   else
      cfont -yellow "[Warning] Found index.lock:" -reset -n
      cfont -yellow "$LOCK" -reset -n
      find .git -name 'index.lock' -exec rm -fr {} \;
      if [ "$?" -ne "0" ]; then
         cfont -yellow "[Warning] Remove index.lock failed :(" -reset -n
      else
         cfont -green "Remove all index.lock successful :)" -reset -n
      fi
   fi
}

# -------------------------------------------------------------
# Try to reset submodule which have changed locally
# -------------------------------------------------------------
reset_submodule()
{
   CURRENT_PATH=`pwd`
   CHANGED_SUBMODULES=$(git status -s |awk '{print $2}')
   if [ -z "$CHANGED_SUBMODULES" ]; then
      cfont -green "No changes in submodule :)" -reset -n
   else
      cfont -yellow "[Warning] There are some changes in submodule:" -reset -n
      cfont -yellow "$CHANGED_SUBMODULES" -reset -n
      for SUBMODULE in $CHANGED_SUBMODULES
      do
         cd $CURRENT_PATH/$SUBMODULE
         git reset --hard
         if [ "$?" -ne "0" ]; then
            cfont -yellow "[Warning][$SUBMODULE] git reset --hard failed :(" -reset -n
         else
            cfont -green "[$SUBMODULE] git reset --hard successful :)" -reset -n
         fi
      done
      cd $CURRENT_PATH
   fi
}


cfont -green "*************Start*************" -reset -n
cfont -green "Start time: `date`" -reset -n

if [ $# -eq 2 ]; then
   HAS_NINCG3_ROOT_COMMIT=FALSE
elif [ $# -eq 3 ]; then
   HAS_NINCG3_ROOT_COMMIT=TRUE
else
   cfont -red "[Error] It's necessary to contain 2 args or 3args :(" -reset -n
   etime
   return 1
fi
cfont -green "HAS_NINCG3_ROOT_COMMIT=$HAS_NINCG3_ROOT_COMMIT" -reset -n

echo -e "\n"
# -------------------------------------------------------------
# Checkout the latest source code in nincg3
# -------------------------------------------------------------
cfont -green "*************Checkout source code in nincg3*************" -reset -n
if [ ! -d "$NINCG3_PATH" ]; then
   cfont -red "[Error] $NINCG3_PATH doesn't exist! :(" -reset -n
   etime
   return 1
fi
if [ ! -d "$NAVI_DEVELOPMENT_PATH" ]; then
   cfont -red "[Error] $NAVI_DEVELOPMENT_PATH doesn't exist! :(" -reset -n
   etime
   return 1
fi

cd $NINCG3_PATH
check_lock
cfont -cyan "[nincg3] git fetch origin..." -reset -n
git fetch origin
if [ "$?" -ne "0" ]; then
   cfont -yellow "[Warning][nincg3] git fetch origin failed :(" -reset -n
else
   cfont -green "[nincg3] git fetch origin successful :)" -reset -n
fi

if [ "$HAS_NINCG3_ROOT_COMMIT" = "TRUE" ]; then
   cfont -cyan "[nincg3] git checkout $NINCG3_ROOT_COMMIT..." -reset -n
   git checkout $NINCG3_ROOT_COMMIT
   if [ "$?" -ne "0" ]; then
      cfont -red "[Error][nincg3] git checkout $NINCG3_ROOT_COMMIT failed :(" -reset -n
      etime
      return 1
   else
      cfont -green "[nincg3] git checkout $NINCG3_ROOT_COMMIT successful :)" -reset -n
   fi
else
   CURRENT_NINCG3_BRANCH=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
   cfont -green "[nincg3] CURRENT_NINCG3_BRANCH=${CURRENT_NINCG3_BRANCH}" -reset -n
   if [ "$CURRENT_NINCG3_BRANCH" != "$NINCG3_BRANCH" ]; then
      cfont -cyan "[nincg3] git checkout $NINCG3_BRANCH..." -reset -n
      git checkout $NINCG3_BRANCH
      if [ "$?" -ne "0" ]; then
         cfont -red "[Error][nincg3] git checkout $NINCG3_BRANCH failed :(" -reset -n
         etime
         return 1
      else
         cfont -green "[nincg3] git checkout $NINCG3_BRANCH successful :)" -reset -n
      fi
   fi
   cfont -cyan "[nincg3] git pull --rebase origin $NINCG3_BRANCH:$NINCG3_BRANCH..." -reset -n
   git pull --rebase origin $NINCG3_BRANCH:$NINCG3_BRANCH
   if [ "$?" -ne "0" ]; then
      cfont -yellow "[Warning][nincg3] git pull --rebase origin $NINCG3_BRANCH:$NINCG3_BRANCH failed :(" -reset -n
   else
      cfont -green "[nincg3] git pull --rebase origin $NINCG3_BRANCH:$NINCG3_BRANCH successful :)" -reset -n
   fi
fi

cfont -cyan "[nincg3] git submodule update -f --init --recursive..." -reset -n
git submodule update -f --init --recursive
if [ "$?" -ne "0" ]; then
   reset_submodule
   cfont -cyan "[nincg3] Try again: git submodule update -f --init --recursive..." -reset -n
   git submodule update -f --init --recursive
   if [ "$?" -ne "0" ]; then
      cfont -yellow "[Warning][nincg3] submodule update failed :(" -reset -n
   else
      cfont -green "[nincg3] submodule update successful :)" -reset -n
   fi
else
   cfont -green "[nincg3] submodule update successful :)" -reset -n
fi

echo -e "\n"
# -------------------------------------------------------------
# Switch to user branch in ai_nissan_hmi and checkout src code
# -------------------------------------------------------------
cfont -green "*************Switch to user branch in ai_nissan_hmi and checkout src code*************" -reset -n
check_lock
cd $AI_NISSAN_HMI_PATH
SUBMODULE_STATUS=$(git status -s |awk '{print $2}')
if [ -z "$SUBMODULE_STATUS" ]; then
   cfont -green "[ai_nissan_hmi] No changes in $AI_NISSAN_HMI_PATH :)" -reset -n
else
   cfont -yellow "[Warning][ai_nissan_hmi] There are some changes in $AI_NISSAN_HMI_PATH:" -reset -n
   cfont -cyan "[ai_nissan_hmi] git reset --hard..." -reset -n
   git reset --hard
   if [ "$?" -ne "0" ]; then
      cfont -yellow "[Warning][ai_nissan_hmi] git reset --hard failed :(" -reset -n
   else
      cfont -green "[ai_nissan_hmi] git reset --hard successful :)" -reset -n
   fi
fi

AI_NISSAN_HMI_COMMIT_INFO=`git log -1`
AI_NISSAN_HMI_COMMIT_ID=`echo $AI_NISSAN_HMI_COMMIT_INFO |awk -F ' ' '{print $2}'`
cfont -green "[ai_nissan_hmi] AI_NISSAN_HMI_COMMIT_ID=$AI_NISSAN_HMI_COMMIT_ID" -reset -n

cfont -cyan "[ai_nissan_hmi] git checkout $AI_NISSAN_HMI_USER_BRANCH..." -reset -n
git checkout $AI_NISSAN_HMI_USER_BRANCH
if [ "$?" -ne "0" ]; then
   cfont -yellow "[Warning][ai_nissan_hmi] git checkout $AI_NISSAN_HMI_USER_BRANCH failed :(" -reset -n
else
   cfont -cyan "[ai_nissan_hmi] git reset --hard $AI_NISSAN_HMI_COMMIT_ID..." -reset -n
   git reset --hard $AI_NISSAN_HMI_COMMIT_ID
   if [ "$?" -ne "0" ]; then
      cfont -yellow "[Warning][ai_nissan_hmi] git reset --hard $AI_NISSAN_HMI_COMMIT_ID failed :(" -reset -n
   else
      cfont -green "[ai_nissan_hmi] git reset --hard $AI_NISSAN_HMI_COMMIT_ID successful :)" -reset -n
   fi
fi
cd $NINCG3_PATH

echo -e "\n"
# -------------------------------------------------------------
# Get current middleware tag in ai_navi_sdk/rnaivi
# -------------------------------------------------------------
cfont -green "*************Get middleware tag in nincg3/ai_navi_sdk/rnaivi*************" -reset -n
cd $AI_NAVI_SDK_PATH
MIDDLEWARE_COMMIT_INFO=`git log -1`
MIDDLEWARE_COMMIT_ID=`echo $MIDDLEWARE_COMMIT_INFO |awk -F ' ' '{print $2}'`
cfont -green "[ai_navi_sdk/rnaivi] MIDDLEWARE_COMMIT_ID=$MIDDLEWARE_COMMIT_ID" -reset -n
MIDDLEWARE_TAG_INFO=`git tag --contains $MIDDLEWARE_COMMIT_ID`
MIDDLEWARE_TAG_ID=`echo $MIDDLEWARE_TAG_INFO |awk -F ' ' '{print $1}'`
cfont -green "[ai_navi_sdk/rnaivi] MIDDLEWARE_TAG_ID=$MIDDLEWARE_TAG_ID" -reset -n
cd $NINCG3_PATH

echo -e "\n"
# -------------------------------------------------------------
# Checkout source code by middleware tag in navi_development
# -------------------------------------------------------------
cfont -green "*************Checkout source code in navi_development*************" -reset -n
cd $NAVI_DEVELOPMENT_PATH
check_lock
cfont -cyan "[navi_development] git fetch origin..." -reset -n
git fetch origin
if [ "$?" -ne "0" ]; then
   cfont -yellow "[Warning][navi_development] git fetch origin failed :(" -reset -n
else
   cfont -green "[navi_development] git fetch origin successful :)" -reset -n
fi

cfont -cyan "[navi_development] git checkout $MIDDLEWARE_TAG_ID..." -reset -n
git checkout $MIDDLEWARE_TAG_ID
if [ "$?" -ne "0" ]; then
   cfont -red "[Error][navi_development] git checkout $MIDDLEWARE_TAG_ID failed :(" -reset -n
   etime
   return 1
else
   cfont -green "[navi_development] git checkout $MIDDLEWARE_TAG_ID successful :)" -reset -n
   cfont -cyan "[navi_development] git submodule update -f --init --recursive..." -reset -n
   git submodule update -f --init --recursive
   if [ "$?" -ne "0" ]; then
      reset_submodule
      cfont -cyan "[navi_development] Try again: git submodule update -f --init --recursive..." -reset -n
      git submodule update -f --init --recursive
      if [ "$?" -ne "0" ]; then
         cfont -yellow "[Warning][navi_development] submodule update failed :(" -reset -n
      else
         cfont -green "[navi_development] submodule update successful :)" -reset -n
      fi
   else
      cfont -green "[navi_development] submodule update successful :)" -reset -n
   fi
fi

echo -e "\n"
# -------------------------------------------------------------
# Set up environment for navi_development
# -------------------------------------------------------------
cfont -green "*************Set up environment for navi_development*************" -reset -n
if [ -f "_build_env.sh" ]; then
   . ./_build_env.sh
else
   cfont -red "[Error][navi_development]  _build_env.sh doesn't exist! :(" -reset -n
   etime
   return 1
fi

echo -e "\n"
# -------------------------------------------------------------
# Compile navi_development
# -------------------------------------------------------------
cfont -green "[navi_development] Compile navi_development..." -reset -n
create_sdk --gen3 --rnaivi --debug --info

echo -e "\n"
# -------------------------------------------------------------
# Download binaries from artifactory
# -------------------------------------------------------------
#cfont -green "[navi_development] Download binaries from artifactory..." -reset -n
#perl $_SWROOT/di_misc_tools/tools/artifactory/download_artifact.pl -m -r sw-navi-repos -g navi-sdk/rnaivi/winsim -a debug -v $MIDDLEWARE_TAG_ID -o ./sdk/gen3_rnaivi/Navigation

#echo -e "\n"
etime
cfont -green "*************End*************" -reset -n

echo -e "\n"
echo "Press any key to continue..."


