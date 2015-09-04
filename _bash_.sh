#!/bin/bash -e
# vim: ts=2 shiftwidth=2 expandtab

########################################################################
#
#  Copyright (C) 2014 Mariusz Bartusiak <mariushko@gmail.com>
#
#  http://github.com/mariushko
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################


#################################### DEFAULTS ###################################

declare -i _MIN_COLUMN_COUNT_=60
declare -u _SCRIPT_MODE_=${_SCRIPT_MODE_:-OFF}
declare -u _COLOR_MODE_=${_COLOR_MODE_:-ON}

#################################### SETTINGS ###################################
# basic checks

# No terminal or tput is unavaible = script mode and no colors. Let's force these.
if [[ ! -t 1 ]] || ! tput cols > /dev/null 2>&1
then
  _SCRIPT_MODE_=ON
  _COLOR_MODE_=OFF
fi
[[ ${_SCRIPT_MODE_} == "ON" ]] && _COLOR_MODE_=OFF

# Confirm correct mode values
case ${_COLOR_MODE_} in
  OFF)  _COLOR_MODE_=OFF;;
  *)    _COLOR_MODE_=ON;;
esac
case ${_SCRIPT_MODE_} in
  ON)   _SCRIPT_MODE_=ON;;
  *)    _SCRIPT_MODE_=OFF;;
esac

_get_max_column_count_(){
  [[ ${_SCRIPT_MODE_} == "ON" ]] && echo ${_MIN_COLUMN_COUNT_} || tput cols
}

#################################### SIGNALS / EXCEPTIONS ######################

_cleaning_(){

  #################
  # You have chance to clean up before you script dies.
  # You should define you own _cleaning_ function.
  #################

  :
}

_die_(){

  #################
  # Die, but clean up first.
  # Usage: _die_ [ "MESSAGE" [ "SIGNAL" ] ]
  ################

  local MESSAGE="${1}"
  local SIGNAL="${2:-NONE}"

  _cleaning_
  [[ ${SIGNAL} != NONE ]] && MESSAGE+=${SIGNAL}
  [[ -n ${MESSAGE} ]] && _error_ "[EXIT]: ${MESSAGE}" > /dev/stderr
  exit 1
}

_trap_() {

  #################
  # Trap all signals one by one
  # Usage: _trap_ "FUNCTION" "SIGNAL1" [ "SIGNAL2" [...]]
  ################

  local func="$1"; shift
  for sig
  do
    trap "$func 'Caught a signal: ' $sig" "$sig"
  done
}

# Define exceptions:
# INT  <- CTRL-C
# TERM <- kill PID
# QUIT <- CTRL-\
_trap_ _die_ INT TERM QUIT

#################################### INTERNAL USE ##############################

_paintItRed_(){

  #################
  # Print your MASSAGE in * colour without new line character
  # Usage: _printIn*_ "MESSAGE"
  #################

  case ${_COLOR_MODE_} in
    OFF)  echo -ne "${@}";;
    ON)   echo -ne "$(tput setaf 1)${@}$(tput sgr0)";;
  esac
}

_paintItGreen_(){

  #################
  # Print your MASSAGE in * colour without new line character
  # Usage: _printIn*_ "MESSAGE"
  #################

  case ${_COLOR_MODE_} in
    OFF)  echo -ne "${@}";;
    ON)   echo -ne "$(tput setaf 2)${@}$(tput sgr0)";;
  esac
}

_paintItYellow_(){

  #################
  # Print your MASSAGE in * colour without new line character
  # Usage: _printIn*_ "MESSAGE"
  #################

  case ${_COLOR_MODE_} in
    OFF)  echo -ne "${@}";;
    ON)   echo -ne "$(tput setaf 3)${@}$(tput sgr0)";;
  esac
}

_paintItBlue_(){

  #################
  # Print your MASSAGE in * colour without new line character
  # Usage: _printIn*_ "MESSAGE"
  #################

  case ${_COLOR_MODE_:-NONE} in
    OFF)  echo -ne "${@}";;
    ON)   echo -ne "$(tput setaf 4)${@}$(tput sgr0)";;
  esac
}

_paintItCyan_(){

  #################
  # Print your MASSAGE in * colour without new line character
  # Usage: _printIn*_ "MESSAGE"
  #################

  case ${_COLOR_MODE_:-NONE} in
    OFF)  echo -ne "${@}";;
    ON)   echo -ne "$(tput setaf 6)${@}$(tput sgr0)";;
  esac
}

_breakLine_(){

  #################
  # Break line at # column
  # Usage: _breakLine_ #COLUMN MESSAGE
  # Usage: command | _breakLine_ - [#COL]
  #################

  local PIPE="false"
  [ "${1}" == "-" ] && PIPE="true" && shift

  local BREAKING_POINT=${1:-$(_get_max_column_count_)}
  [[ $# -gt 0 ]] && shift
  local line

  if [[ ${PIPE} == "true" ]]; then cat; else echo "$@"; fi | {
    while read line
    do
      echo ${line} | fold -w ${BREAKING_POINT} -s | sed 's/ $//'
    done
  }
}

_multiplyString_(){

  #################
  # Multiply string (default: '#') as many as you want but less then terminal can handle
  # Usage: _multiplyString_ [ "char" [#] ]
  # e.g.:  _multiplyString_ '#' 100
  # e.g.:  _multiplyString_ '+'
  # e.g.:  _multiplyString_
  #################

  local BRICK=${1:-#}
  [[ $# -gt 0 ]] && shift

  local -i BREAKING_POINT=${1:-$(_get_max_column_count_)}
  [[ $# -gt 0 ]] && shift
  [[ ${BREAKING_POINT} -le 0 ]] && echo -n "" && return 0

  local line=""
  local -i multiply=$[ BREAKING_POINT/${#BRICK} ]
  [ $[ BREAKING_POINT%${#BRICK} ] -ne 0 ] && (( multiply++ ))
  for i in $(seq 1 ${multiply})
  do
    line+="${BRICK}"
  done
  echo "${line}" | cut -c-${BREAKING_POINT} | tr -d '\n'
}

_runCommandInBackground_(){

  #################
  # Run a command in background
  # Usage: _runCommandInBackground_ "COMMAND"
  #################

  [[ $# -eq 1 ]] || _die_ "_runCommandInBackground_: 1 arg needed"
  ( eval ${1} ) > /dev/null 2>&1 &
  local -i pid=$!
  local -i count=0

  while [[ -d /proc/${pid} ]]
  do
    if [[ ${_SCRIPT_MODE_} == "OFF" ]]; then
      [[ ${count} -eq 0 ]] && tput sc
      tput rc
      tput ed
      case $[count%4] in
        0) echo -n '[|]';;
        1) echo -n '[/]';;
        2) echo -n '[-]';;
        3) echo -n '[\]';;
      esac
    fi
    sleep .2
    count+=1
  done
  [[ ${_SCRIPT_MODE_} == "OFF" ]] && tput rc && tput ed
  wait ${pid}
  return $?
}

################################################ EXTERNAL USE ######################

_info_(){

  #################
  # Print your MASSAGE in green colour
  # Usage: _info_ "MESSAGE"
  #################

  _paintItGreen_ "*** ${@}\n"
}

_warning_(){

  #################
  # Print your MASSAGE in yellow colour
  # Usage: _warning_ "MESSAGE"
  #################

  _paintItYellow_ "*** ${@}\n"
}

_error_(){

  #################
  # Print your MASSAGE in red colour
  # Usage: _error_ "MESSAGE"
  #################

  _paintItRed_ "*** ${@}\n"
}

_printSeparator_(){

  #################
  # Print line full of '#' or any char/string you want.
  # Usage: _printSeparator_ [string]
  # e.g.:  _printSeparator_
  # e.g.:  _printSeparator_ '+'
  #################

  _multiplyString_ ${1:-#}
  echo
}

#######################################################
# Nice printing
#######################################################

_printComment_(){

  #################
  # Add PREFIX (default: '# ') at the beginning each line and print it
  # Usage: _printSeparator_ PREFIX MESSAGE
  # Usage: command | _printSeparator_ - [PREFIX]
  #################

  local PIPE="false"
  [ "${1}" == "-" ] && PIPE="true" && shift

  local PREFIX="${1:-# }"
  [[ $# -gt 0 ]] && shift
  local line

  if [[ ${PIPE} == "true" ]]; then cat; else echo "$@"; fi \
    | _breakLine_ - $[ $(_get_max_column_count_) - ${#PREFIX} ] \
    | sed "s/^/${PREFIX}/"
}

_printEllipsizedLine_(){

  #################
  # Ellipsize a line. This is better then truncate the line... sometimes...
  # Usage: _ellipsizeLine_ #COLUMN MESSAGE
  # Usage: command | _ellipsizeLine_ - [#COLUMN]
  #################

  local PIPE="false"
  [ "${1}" == "-" ] && PIPE="true" && shift

  local -i BREAKING_POINT=${1:-$(_get_max_column_count_)}
  [[ $# -gt 0 ]] && shift
  local line

  if [[ ${PIPE} == "true" ]]; then cat; else echo "$@"; fi | {
    while read line
    do
      if [[ ${#line} -le ${BREAKING_POINT} ]]; then
         echo "${line}"
      else
        line=$(echo ${line} | cut -c-$[ ${BREAKING_POINT} - 4 ])
        echo "${line}(..)"
      fi
    done
  }
}

_printWithBorder_(){

  #################
  # Print text suraounded by simple border
  # Usage: _printWithBorder_ #COLUMN MESSAGE
  # Usage: command | _printWithBorder_ - [#COLUMN]
  #################

  local PIPE="false"
  [ "${1}" == "-" ] && PIPE="true" && shift

  local -i BREAKING_POINT=${1:-$(_get_max_column_count_)}
  [[ $# -gt 0 ]] && shift
  local line
  local -i space=0

  BREAKING_POINT=$[ BREAKING_POINT - 4 ]
  echo ' +'$(_multiplyString_ '-' ${BREAKING_POINT})'+'
  if [[ ${PIPE} == "true" ]]; then cat; else echo "$@"; fi \
    | _breakLine_ - $[ BREAKING_POINT - 2 ] \
    | {
      while read line
      do
        space=$[ BREAKING_POINT - ${#line} - 2 ]
        [[ ${space} -gt 0 ]] && line+=$(_multiplyString_ ' ' $[ BREAKING_POINT - ${#line} - 2 ])
        echo "${line}"
      done
    } \
    | sed 's/^/ | /' \
    | sed "s/$/ |/"
  echo ' +'$(_multiplyString_ '-' ${BREAKING_POINT})'+'

}

_runJob_(){

  #################
  # Run a job and display how it ends.
  # Usage: _runJob_ "DESCRIPTION" "COMMAND"
  #################

  [[ $# -eq 2 ]] || _die_ "_runJob_: 2 args needed"
  local DESC="${1}"
  local COMM="${2}"
  local -i RET_CODE
  local -i BREAKING_POINT=$(_get_max_column_count_)
  BREAKING_POINT=$[ BREAKING_POINT - 10 ]
  DESC=$(_printEllipsizedLine_ ${BREAKING_POINT} ${DESC})

  _paintItYellow_ '* '
  _paintItCyan_ "${DESC}"
  [[ ${#DESC} -lt ${BREAKING_POINT} ]] && {
    _multiplyString_ '.' $[ BREAKING_POINT - ${#DESC} ]
  }
  # run a command in sub-shell
  # ( eval ${COMM} ) > /dev/null 2>&1
  _runCommandInBackground_ "${COMM}"
  RET_CODE=$?
  if [[ ${RET_CODE} -eq 0 ]]; then
    echo "... ["$(_paintItGreen_ ok)"]"
  else
    echo " ["$(_paintItRed_ error)"]"
  fi

  return ${RET_CODE}
}

_softwareINeed_(){

  #################
  # You can easly find out if required commands are available
  # Usage: _softwareINeed_ COMMAND1 [COMMANDX]
  # e.g.:  _softwareINeed_ ls dd aabbccdd git || _die_ "Die hard"
  #################

  local stat="true"
  _info_ "Have you got all software you need?"
  for comm in "${@}"
  do
    if ! _runJob_ "Does command \"${comm}\" exist\?" "which ${comm}"
    then
      stat="false"
    fi
  done
  if [[ ${stat} == "true" ]]; then
    _info_ "It seems you have all software you need!!!"
    return 0
  else
    _warning_ "Something is missing..."
    return 1
  fi
}

################################ TEST

_printTestText_(){
cat <<EOF
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eleifend neque nunc. Duis dapibus sapien eget sapien consectetur, sit amet blandit arcu rhoncus. Suspendisse pellentesque odio vitae volutpat iaculis. Etiam sed gravida tellus, eget imperdiet felis. Donec tempus risus a lobortis bibendum. Cras felis leo, pharetra ut velit eget, cursus cursus erat. Pellentesque turpis turpis, ultricies a laoreet sit amet, ullamcorper a nisl. Morbi nulla justo, scelerisque sit amet nulla quis, dictum pulvinar ipsum. Interdum et malesuada fames ac ante ipsum primis in faucibus. Proin ac sagittis felis. Morbi consectetur purus rutrum nunc scelerisque feugiat.
Aenean hendrerit nec eros et ornare. Donec sit amet rutrum elit, ac lobortis purus. Maecenas nec ex eu magna tempus aliquet. Phasellus eu ante ac tellus consectetur dapibus. Vivamus ut egestas nunc. Nulla facilisi. Suspendisse euismod ante non vestibulum sodales. Aliquam lacinia nec velit eu lobortis. Aenean congue mauris id feugiat dapibus. Vestibulum vitae augue a justo sodales pharetra in sed mi. Vivamus eleifend, nunc nec consequat laoreet, mi sapien rhoncus risus, sit amet ultricies ex risus vel lorem.
Nunc eleifend vehicula diam id interdum. Quisque quam ex, commodo nec venenatis id, congue eu ligula. Aliquam erat volutpat. Vivamus in rutrum ipsum. Nullam dignissim, dolor vel mattis vestibulum, lacus ante mattis tellus, vel mattis neque sem quis enim. In dictum tincidunt turpis eget blandit. Nam tincidunt mauris felis, non auctor nisl bibendum sed. Aliquam semper gravida placerat. Etiam volutpat efficitur justo a feugiat. Mauris sed sem volutpat quam malesuada convallis et ac diam. Aliquam erat volutpat. Quisque ac fermentum mauris. Donec condimentum consequat pellentesque.
Integer tincidunt a nulla at sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris finibus sollicitudin est, id elementum leo lobortis eget. Fusce at massa sit amet mi iaculis scelerisque eu eget nulla. Proin felis mi, aliquam eu purus feugiat, semper ullamcorper libero. Curabitur efficitur viverra sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Maecenas condimentum quis arcu vitae lacinia. Nam placerat euismod libero, in scelerisque neque faucibus vel. Nunc vel vestibulum arcu. Sed varius lorem id dictum interdum.
EOF
}

_printTestText2_(){
cat <<EOF
Integer tincidunt a nulla at sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris finibus sollicitudin est, id elementum leo lobortis eget. Fusce at massa sit amet mi iaculis scelerisque eu eget nulla. Proin felis mi, aliquam eu purus feugiat, semper ullamcorper libero. Curabitur efficitur viverra sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Maecenas condimentum quis arcu vitae lacinia. Nam placerat euismod libero, in scelerisque neque faucibus vel. Nunc vel vestibulum arcu. Sed varius lorem id dictum interdum.
EOF
}
######################################################################################

_main_(){

  _printSeparator_ '-'
  _info_ "Examples"
  _printSeparator_ '-'
  _softwareINeed_ ls dd ll pp gg ff || true
  _info_ "Ellipsized line"
  _printTestText_  | _printEllipsizedLine_ -
  _info_ "Text with border"
  _printTestText2_ | _printWithBorder_ -
  _info_ "Separator"
  _printSeparator_
  _info_ "Commented line"
  _printTestText2_ | _printComment_ -
  _info_ "Next separators:"
  _printSeparator_ '-'
  _printSeparator_ '+'
  _printSeparator_ '+-'
  _softwareINeed_ ls dd
  _runJob_ "sleep 5; Press CTRL-C to send INT signal"        "sleep 5"
  _runJob_ "sleep 5; false; Press CTRL-C to send INT signal" "sleep 5; false" || true
}

# run _main_ only if this script is run directly (no sorce command used)
[[ ${BASH_SOURCE[0]} == ${0} ]] && _main_ "${@}" || true

