#!/bin/bash
#
# Agent to Monitoring Oracle via sqlPlus
#
# S E T U P
#   - Install Oracle Client
#   ln -s /omd/tools/jq /omd/sites/*/jq
#   chmod +x /omd/agent_oracle.sh
#   ln -s /omd/agent_oracle.sh /omd/versions/default/share/check_mk/agents/special/agent_oracle
#
# R E F
#   - https://docs.oracle.com/cd/E71909_01/html/E71922/index.html
#   - https://stedolan.github.io/jq
#   - ./etc/check_mk/conf.d/wato/passwords.mk
#
# (c) 2019-07-10 Antonio Pos-de-Mina


# -----------------------------------------------------------------------------

# -------------------------------------
# Oracle Settings need adjustments to your environment!
#

#PATH=$PATH:$HOME/bin
#export PATH

ORACLE_BASE=/opt/oracle
export ORACLE_BASE

ORACLE_HOME=$ORACLE_BASE/product/12.1.0/client_1
export ORACLE_HOME

PATH=$PATH:$ORACLE_HOME/bin
export PATH

# -------------------------------------
# Parameters

#$ tnsping dapp7
#Attempting to contact (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=apexa2ip-scan.besp.dsp.gbes)(PORT=1533))(CONNECT_DATA=(SERVICE_NAME=DAPP7)))
#/omd/agent_oracle.sh 'apexa2ip-scan.besp.dsp.gbes' DAPP7 nagios N4gi1os2k19 (['version']=3600 ['processes']=60 ['logswitches']=60 ['locks']=60 ['performance']=60 ['dataguard_stats']=60 ['asm_diskgroup']=60 ['longactivesessions']=60 ['recovery_status']=60 ['sessions']=60 ['resumable']=60 ['rman']=60 ['tablespaces']=60 ['recovery_area']=60 ['undostat']=60 ['jobs']=60 ['ts_quotas']=60 ['instance']=60)

# $1
ORACLE_HOST=$1
# $2
ORACLE_SID=$2
# $3
ORACLE_USR=$3
# $4
ORACLE_PWD=$4
# $5
declare -A ORACLE_SECTIONS=$5


# -----------------------------------------------------------------------------


# -------------------------------------
# Query Oracle via SQL Plus
# P A R A M S
#   - $1: Section to run
#   - $2: SQL Query
# O U T P U T
#   - return the output from 

oracle_query ()
{
    ORACLE_SECTION=$1
    ORACLE_SECTION_AGE=$2
    ORACLE_FILE_AGE=0
    ORACLE_FILE="/tmp/${ORACLE_HOST}_${ORACLE_SID}_oracle_${ORACLE_SECTION}.log"

    # verify file age
    if [[ -f $ORACLE_FILE ]]
    then
        ORACLE_FILE_AGE=$(( $(date +%s) - $(stat -c %Y ${ORACLE_FILE}) ))
    else
        ORACLE_FILE_AGE=$ORACLE_SECTION_AGE
    fi

    echo "<<<oracle_${ORACLE_SECTION}:sep(124)>>>"
    # verify file age
    if [[ $ORACLE_FILE_AGE -gt $ORACLE_SECTION_AGE ]]
    then
        cat /omd/oracle_$ORACLE_SECTION.sql | sqlplus -s $ORACLE_USR/$ORACLE_PWD@$ORACLE_SID > ${ORACLE_FILE}
    fi
    cat ${ORACLE_FILE}
}


# -----------------------------------------------------------------------------


# -------------------------------------
# Check_MK Agent Protocol Header

echo '<<<check_mk>>>
Version: 1.0
AgentOS: Oracle'

# -------------------------------------
# Dump all Sections 

for section in "${!ORACLE_SECTIONS[@]}"
do
    # verify if section can be called. Zero means this sections can't call.
    if [ ${ORACLE_SECTIONS[$section]} -gt 0 ]
    then
        oracle_query $section ${ORACLE_SECTIONS[$section]};
    fi
done
