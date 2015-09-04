# bash
My scripts.

I've written many bash scripts and I realized that I repeat myself :)
So I gather a few functions in one place: _bash_.sh.
Download this file and run it to see some examples:

$ chmod +x _bash_.sh
$ ./_bash_.sh

You can use this functions in your own script, just add this line:

source /path/to/_bash_.sh

Help:

################ Nice printing on terminal

_info_()
  #################
  # Print your MASSAGE in green colour
  # Usage: _info_ "MESSAGE"
  #################

_warning_()
  #################
  # Print your MASSAGE in yellow colour
  # Usage: _warning_ "MESSAGE"
  #################

_error_()
  #################
  # Print your MASSAGE in red colour
  # Usage: _error_ "MESSAGE"
  #################

_printSeparator_()
  #################
  # Print line full of '#' or any char/string you want.
  # Usage: _printSeparator_ [string]
  # e.g.:  _printSeparator_
  # e.g.:  _printSeparator_ '+'
  #################

_printComment_()
  #################
  # Add PREFIX (default: '# ') at the beginning each line and print it
  # Usage: _printSeparator_ PREFIX MESSAGE
  # Usage: command | _printSeparator_ - [PREFIX]
  #################

_printEllipsizedLine_()
  #################
  # Ellipsize a line. This is better then truncate the line... sometimes...
  # Usage: _ellipsizeLine_ #COLUMN MESSAGE
  # Usage: command | _ellipsizeLine_ - [#COLUMN]
  #################

_printWithBorder_()
  #################
  # Print text suraounded by simple border
  # Usage: _printWithBorder_ #COLUMN MESSAGE
  # Usage: command | _printWithBorder_ - [#COLUMN]
  #################

_runJob_()
  #################
  # Run a job and display how it ends.
  # Usage: _runJob_ "DESCRIPTION" "COMMAND"
  #################

_softwareINeed_()
  #################
  # You can easly find out if required commands are available
  # Usage: _softwareINeed_ COMMAND1 [COMMANDX]
  # e.g.:  _softwareINeed_ ls dd aabbccdd git || _die_ "Die hard"
  #################

############################## Trap signals

_cleaning_(){
  #################
  # You have chance to clean up before you script dies.
  # You should define you own _cleaning_ function!!!
  #################

_die_(){
  #################
  # Die, but clean up first.
  # Usage: _die_ [ "MESSAGE" [ "SIGNAL" ] ]
  ################

_trap_() {
  #################
  # Trap all signals one by one
  # Usage: _trap_ "FUNCTION" "SIGNAL1" [ "SIGNAL2" [...]]
  ################

Default: # Defined exceptions:
# INT  <- CTRL-C
# TERM <- kill $$
# QUIT <- CTRL-\

