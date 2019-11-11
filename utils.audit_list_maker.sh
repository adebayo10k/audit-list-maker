#!/bin/bash
#: Title		:utils.audit_list_maker.sh
#: Date			:2019-07-05
#: Author		:adebayo10k
#: Version		:1.0
#: Description	:create independently stored reference listings of the media files
#: Description	:on a drive when the backup of those files is not really justified.
#: Description	:backup reacquire recreate 
#: Options		:
##


function main
{

	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	echo "USAGE: $(basename $0) <PROD|DEV>"  

	# Display a program header and give user option to leave if here in error:
    echo
    echo -e "		\033[33m===================================================================\033[0m";
    echo -e "		\033[33m||               Welcome to the AUDIT LIST MAKER                 ||  author: adebayo10k\033[0m";  
    echo -e "		\033[33m===================================================================\033[0m";
    echo
    echo " Type q to quit NOW, or press ENTER to continue."
    echo && sleep 1
    read last_chance

    case $last_chance in 
	[qQ])	echo
			echo "Goodbye!" && sleep 1
			exit 0
				;;
	*) 		echo "You're IN..." && echo && sleep 1
		 		;;
    esac 

	#######################################################################

	# SET PROGRAM RUN MODE:
	# passed in from command line, this is set to:
	# DEV during developemnt. We work on controlled, sample configuration and input data
	# PROD when working on real data using real configuration settings
	RUN_MODE=$1 
	export RUN_MODE

	#######################################################################

	## EXIT CODES:
	E_UNEXPECTED_BRANCH_ENTERED=10
	E_OUT_OF_BOUNDS_BRANCH_ENTERED=11
	E_INCORRECT_NUMBER_OF_ARGS=12
	E_UNEXPECTED_ARG_VALUE=13
	E_REQUIRED_FILE_NOT_FOUND=20
	E_REQUIRED_PROGRAM_NOT_FOUND=21
	E_UNKNOWN_RUN_MODE=30
	E_UNKNOWN_EXECUTION_MODE=31

	export E_UNEXPECTED_BRANCH_ENTERED
	export E_OUT_OF_BOUNDS_BRANCH_ENTERED
	export E_INCORRECT_NUMBER_OF_ARGS
	export E_UNEXPECTED_ARG_VALUE
	export E_REQUIRED_FILE_NOT_FOUND
	export E_REQUIRED_PROGRAM_NOT_FOUND
	export E_UNKNOWN_RUN_MODE
	export E_UNKNOWN_EXECUTION_MODE

	#######################################################################

	# GLOBAL VARIABLE DECLARATIONS:
	line_type="" # global...
	test_line="" # global...
	config_file_fullpath= # a full path to a file

	# explicitly declaring variables to make code bit more robust - move to top
	destination_holding_dir_fullpath="" # single directory in which....# a full path to directory
	source_holding_dir_fullpath="" # single directory from which....# a full path to directory
	declare -a directories_to_ignore=() # set of one or more relative path directories...
	declare -a secret_content_directories=() # set of one or more relative path directories...

	abs_filepath_regex='^(/{1}[A-Za-z0-9\._-~]+)+$' # absolute file (and sanitised directory) path
	all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file (and sanitised directory) path

	declare -a file_fullpaths_to_encrypt=() # set of files created from secret directory data
	string_to_send=""

	#script_dir_fullpath ## a full path to directory
	#test_dir_fullpath ## a full path to directory [[[ LOCAL CONTROL IN 1 FUNC ]]]
	#user_config_file_fullpath # a full path to a file
	#config_file_name # a filename
	#config_dir_fullpath # a full path to directory

	#dir_name # a directory name [[[ LOCAL CONTROL IN 1 MAIN PLACE ]]]
	#test_dir_fullpath # a full path to directory [[[ LOCAL CONTROL IN 1 FUNC ]]]
	#ignore_dir_name # a directory name
	#source_input_dir_fullpath # a full path to directory
	#source_input_dir_name # a directory name
	#destination_output_file_name # a filename date augmented 
	#destination_output_file_fullpath # # a full path to a file (.. to destination_output_file_name)

	#######################################################################

	# TEST COMMAND LINE ARGS
	if [ $# -ne 1 ]
	then
		echo "Incorrect number of command line args. Exiting now..."
		echo "Usage: $(basename $0) <PROD|DEV>"
		exit $E_INCORRECT_NUMBER_OF_ARGS
	fi

	# if ! [[ "${1}" = 'DEV' -o "${1}" = 'PROD' ]]
	if ! [[ "${1}" = 'DEV' || "${1}" = 'PROD' ]] 
	then
		echo "Incorrect command line arg.  Exiting now..."
		echo "Usage: $(basename $0) <PROD|DEV>"
		exit $E_UNEXPECTED_ARG_VALUE
	fi

	#######################################################################

	# SET THE SCRIPT ROOT DIRECTORY (IN WHICH THIS SCRIPT CURRENTLY FINDS ITSELF)
	# 
	echo "Full path to this script: $0" && echo

	## remove from end of full path: a directory delimiter and the basename
	## TODO: if SCRIPT 'SOMEHOW' SITS IN THE ROOT DIRECTORY, WE'D JUST REMOVE "$(basename $0)"
	script_dir_fullpath="${0%'/'"$(basename $0)"}"
	echo "Script root directory set to: $script_dir_fullpath"
	export script_dir_fullpath

	echo;echo




	echo
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "STARTING THE 'SET PATH TO CONFIGURATION FILE' PHASE  in script $(basename $0)" 
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo


	get_config_file_to_use
	unset user_config_file_fullpath

	config_file_fullpath=${user_config_file_fullpath:-"default_config_file"}

	if [ "$config_file_fullpath" == "default_config_file" ]
	then

		config_file_name="audit_config"
		echo "Our configuration filename is set to: $config_file_name" && echo

		#config_dir_fullpath="$(cd $script_dir_fullpath; cd ../; pwd)" ## returns with no trailing /
		config_dir_fullpath="/etc"
		echo "PROVISIONALLY:Our configuration file sits in: $config_dir_fullpath" && echo

		config_file_fullpath="${config_dir_fullpath}/${config_file_name}"
		echo "PROVISIONALLY:The full path to our configuration file is: $config_file_fullpath" && echo

	elif [ "$config_file_fullpath" == "$user_config_file_fullpath" ]
	then

		config_dir_fullpath="${user_config_file_fullpath%'/'*}" # also, try [[:alphanum:]] or [A-Za-z0-9_-]
		echo "PROVISIONALLY:Our configuration file sits in: $config_dir_fullpath" && echo

		config_file_fullpath="$user_config_file_fullpath"
		echo "PROVISIONALLY:The full path to our configuration file is: $config_file_fullpath" && echo
		#exit 0

	else
		echo "path to configuration file set to: $config_file_fullpath so I QUIT"
		echo "failsafe exit. Unable to set up a configuration file" && sleep 2
		echo "Exiting from function \"${FUNCNAME[0]}\" in script $(basename $0)"
		exit $E_OUT_OF_BOUNDS_BRANCH_ENTERED

	fi	

	# WHICHEVER WAY THE CONFIGURATION FILE PATH WAS JUST SET, WE NOW TEST THAT IT IS VALID AND WELL-FORMED:
	test_file_path_valid_form "$config_file_fullpath"
	if [ $? -eq 0 ]
	then
		echo "Configuration file full path is of VALID FORM"
	else
		echo "The valid form test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_UNEXPECTED_ARG_VALUE
	fi	

	# if the above test returns ok, ...
	test_file_path_access "$config_file_fullpath"
	if [ $? -eq 0 ]
	then
		echo "The full path to the CONFIGURATION FILE is: $config_file_fullpath"
	else
		echo "The CONFIGURATION FILE path access test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_REQUIRED_FILE_NOT_FOUND
	fi

	test_dir_path_access "$config_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "The full path to the CONFIGURATION FILE holding directory is: $config_dir_fullpath"
	else
		echo "The CONFIGURATION DIRECTORY path access test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_REQUIRED_FILE_NOT_FOUND
	fi	


	# TEST WHETHER THE CONFIGURATION FILE FORMAT IS VALID
	while read lineIn
	do
		test_and_set_line_type "$lineIn" 

	done < "$config_file_fullpath" 

	echo "exit code after line tests: $?" && echo

	## TODO: if $? -eq 0 ... ANY POINT IN BRINGING BACK A RETURN CODE?

	# if tests passed, configuration file is accepted and used from here on
	echo "we can use this configuration file" && echo
	export config_file_name
	export config_dir_fullpath
	export config_file_fullpath


	# IMPORT CONFIGURATION INTO VARIABLES

	echo
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "STARTING THE 'IMPORT CONFIGURATION INTO VARIABLES' PHASE in script $(basename $0)"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo


	#TODO: CAN ALL THESE BE DONE IN ONE FUNCTION LATER?, ANYWAY... KEEP IT SIMPLE FOR NOW
	# SINGLE FUNCTION WOULD STORE EACH keyword IN AN ARRAY, WHICH WE'D LOOP THROUGH FOR EACH LINE READ
	get_destination_holding_dir_fullpath_config # these should be named set...
	get_source_holding_dir_fullpath_config
	get_directories_to_ignore_config
	get_secret_content_directories_config

	# NOW DO ALL THE DIRECTORY ACCESS TESTS FOR IMPORTED PATH VALUES HERE.
	# REMEMBER THAT ORDER IS IMPORTANT, AS RELATIVE PATHS DEPEND ON ABSOLUTE.
	# debug printouts:
	echo
	echo "FINALLY, destination_holding_dir_fullpath variable now set to: $destination_holding_dir_fullpath" && echo
	#test_directory_accessible "${destination_holding_dir_fullpath}"

	# this valid form test works for sanitised directory paths
	test_file_path_valid_form "$destination_holding_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "DESTINATION HOLDING (PARENT) DIRECTORY PATH IS OF VALID FORM"
	else
		echo "The valid form test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_UNEXPECTED_ARG_VALUE
	fi	

	# if the above test returns ok, ...
	test_dir_path_access "$destination_holding_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "The full path to the DESTINATION HOLDING (PARENT) DIRECTORY is: $destination_holding_dir_fullpath"
	else
		echo "The DESTINATION HOLDING (PARENT) DIRECTORY path access test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_REQUIRED_FILE_NOT_FOUND
	fi	

	# NEXT...

	echo "FINALLY, source_holding_dir_fullpath variable now set to: $source_holding_dir_fullpath" && echo
	#test_directory_accessible "$source_holding_dir_fullpath"

	# this valid form test works for sanitised directory paths
	test_file_path_valid_form "$source_holding_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "SOURCE HOLDING (PARENT) DIRECTORY PATH IS OF VALID FORM"
	else
		echo "The valid form test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_UNEXPECTED_ARG_VALUE
	fi	

	# if the above test returns ok, ...
	test_dir_path_access "$source_holding_dir_fullpath"
	if [ $? -eq 0 ]
	then
		echo "The full path to the SOURCE HOLDING (PARENT) DIRECTORY is: $source_holding_dir_fullpath"
	else
		echo "The SOURCE HOLDING (PARENT) DIRECTORY path access test FAILED and returned: $?"
		echo "Nothing to do now, but to exit..." && echo
		exit $E_REQUIRED_FILE_NOT_FOUND
	fi	

	# NEXT...

	# DO WE REALLY NEED TO TEST ACCESS TO THE DIRECTORIES WE'RE GOING TO IGNORE????
	for dir_name in "${directories_to_ignore[@]}"
	do
		echo -n "FINALLY, directories_to_ignore list ITEM now set to:"
		echo "$dir_name"
		#test_directory_accessible "${source_holding_dir_fullpath}/$dir_name"

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "${source_holding_dir_fullpath}/$dir_name"
		if [ $? -eq 0 ]
		then
			echo "IGNORABLE DIRECTORY PATH IS OF VALID FORM"
		else
			echo "The valid form test FAILED and returned: $?"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_UNEXPECTED_ARG_VALUE
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "${source_holding_dir_fullpath}/$dir_name"
		if [ $? -eq 0 ]
		then
			echo "The full path to the IGNORABLE DIRECTORY is: ${source_holding_dir_fullpath}/$dir_name"
		else
			echo "The IGNORABLE DIRECTORY path access test FAILED and returned: $?"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_REQUIRED_FILE_NOT_FOUND
		fi
	done

	# NEXT...
	echo

	for dir_name in "${secret_content_directories[@]}"
	do
		echo -n "FINALLY, secret_content_directories list ITEM now set to:"
		echo "$dir_name"
		#test_directory_accessible "${source_holding_dir_fullpath}/$dir_name"

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "${source_holding_dir_fullpath}/$dir_name"
		if [ $? -eq 0 ]
		then
			echo "SECRET CONTENT DIRECTORY PATH IS OF VALID FORM"
		else
			echo "The valid form test FAILED and returned: $?"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_UNEXPECTED_ARG_VALUE
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "${source_holding_dir_fullpath}/$dir_name"
		if [ $? -eq 0 ]
		then
			echo "The full path to the SECRET CONTENT DIRECTORY is: ${source_holding_dir_fullpath}/$dir_name"
		else
			echo "The SECRET CONTENT DIRECTORY path access test FAILED and returned: $?"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_REQUIRED_FILE_NOT_FOUND
		fi
	done


	# WRITE SOURCE MEDIA FILENAMES TO THE STORAGE LOCATION
	# the designated storage directory must already exist - it won't be created by this script.

	# TODO: if wc -l destination_output_file_fullpath >= 12000; then continue writing to output_file2

	# 
	#date=$(date +'%T')
	#date=$(date +'%F')
	#date=$(date +'%F@%T')


	echo
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "STARTING THE 'WRITE SOURCE MEDIA FILENAMES TO THE STORAGE LOCATION' PHASE in script $(basename $0)"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo

	# remove previous output files during development
	# in service we could either create another subdirectory, continue to delete, keep one or two previous copies or....
	# no risk of sync conflicts, as date augmented filenames mean completely different files
	# 
	rm "${destination_holding_dir_fullpath}"/*

	for source_input_dir_fullpath in "${source_holding_dir_fullpath}"/*
	do
		# TODO: really? ignore REGULAR files in the source_holding_dir_fullpath? really? yes for now.
		if ! [[ -d "$source_input_dir_fullpath" ]]
		then
			echo "NOT A DIRECTORY ::::::::::::     "$source_input_dir_fullpath""
			continue
		fi

		# find out if the current source_input_dir_fullpath is configured to be ignored, if so we can skip to the next
		test_for_ignore_dir "$source_input_dir_fullpath" 
		return_code=$?; echo "return_code : $return_code"
		if [[ "$return_code" -eq 0 ]]
		then
			echo "IGNORING ::::::::::::     "$source_input_dir_fullpath""
			continue
		fi

		# >>>>>>>>>>>>>>>>>from HERE on we can assume that we're 'OK TO GO' to audit source_input_dir_fullpath...>>>>>>>>>>>>>>>>>
		# also, try [[:alphanum:]] or [A-Za-z0-9_-]


		# we need the directory name (not the whole path to it) in order to name the output file 
		source_input_dir_name="${source_input_dir_fullpath##*'/'}"

		# use an augmented input directory name to name the output file
		destination_output_file_name="${source_input_dir_name}.$(date +'%F@%T')" 

		destination_output_file_fullpath="${destination_holding_dir_fullpath}/${destination_output_file_name}"

		# NOW THAT WE HAVE A $destination_output_file_fullpath WE CAN FIND OUT WHETHER IT NEEDS ENCRYPING (AND SO \
		# +ADDED TO THE file_fullpaths_to_encrypt ARRAY), BY TESTING IF THE CORRESPONDING $source_input_dir_fullpath WAS SECRET.
		# WE'LL CALL A FUNCTION TO LOOP THROUGH THE secret_content_directories ARRAY:
		
		# (THE file_fullpaths_to_encrypt ARRAY WILL BE TURNED INTO A SINGLE STRING ARGUMENT string_to_send (WITH SPACE AS IFS)
		# AND SENT OVER WHEN encryption_services.sh IS CALLED JUST ONCE AT THE END)

		test_for_secret_dir "$source_input_dir_fullpath" 
		return_code=$?; echo "return_code : $return_code"
		if [[ "$return_code" -eq 0 ]]
		then
			# NOW APPEND THE ARRAY
			echo "APPENDING ARRAY  ::::::::::::  WITH $destination_output_file_fullpath   "
			file_fullpaths_to_encrypt+=( "${destination_output_file_fullpath}" )
		fi


		echo "destination_output_file_fullpath set to : $destination_output_file_fullpath" # debug

		printf "filename: %s\t" $destination_output_file_fullpath >> "$destination_output_file_fullpath"
		printf "%s\n" "::  $(date +"	[%Y-%m-%d] [%H:%M:%S]")" >> "$destination_output_file_fullpath"
		printf "%s\n" "@@@@@@@audit@@@@@@@@@@@@@@@@@@@ :: $destination_output_file_fullpath :: @@@@@@@@@@@output@@@@@@@@@@@@@@@" >> "$destination_output_file_fullpath"
		printf "%s\n" "   @@@@@@@  ::  $(date +"	[%Y-%m-%d] [%H:%M:%S]") ::     @@@@@@@    " >> "$destination_output_file_fullpath"


		# output file created for appended redirect, any problem tell the hand
		# TODO: better to use `find`or `du -...`,  and specify a list of file extensions of interest - investigate later
		echo >> "$destination_output_file_fullpath" # empty lines for format
		echo >> "$destination_output_file_fullpath"

		ls -R "$source_input_dir_fullpath" >> "$destination_output_file_fullpath"  2>/dev/null # suppress stderr


		## TODO: WE JUST WANT THE COUNT HERE, SO REDIRECT OR PIPE TO sed || USE VARIABLE EXPANSION ON A VARIABLE
		echo "LINE COUNT OUTPUT FOR FILE: `wc -l "$destination_output_file_fullpath"` "

		echo
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "       JUST ENDED THE WRITE 'FOR' LOOP FOR ONE SOURCE DIRECTORY... NEXT ..."
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo


	done	

	# NOW, AT THIS POINT, ALL AUDIT LISTINGS HAVE BEEN WRITTEN TO THEIR DESTINATIONS.
	# WE CAN NOW PROCEED TO ENCRYPTION OF OUR SECRET STUFF...

	# we test for the existence of a known script that provides encryption services:
	which encryption_services.sh
	if [ $? -eq 0 ]
	then
		echo "THE encryption_services.sh PROGRAM WAS FOUND TO BE INSTALLED OK ON THIS HOST SYSTEM"	
	else
		echo "FAILED TO FIND THE encryption_services.sh PROGRAM ON THIS SYSTEM, SO NO NOTHING LEFT TO DO BUT EXEET, GOODBYE"
		exit $E_REQUIRED_PROGRAM_NOT_FOUND
	fi	

	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	read

	# BASH ARRAYS ARE NOT 'FIRST CLASS VALUES' SO CAN'T BE PASSED AROUND LIKE ONE THING - so since we're only intending to make a single call
	# to encryption_services.sh, we need to make an IFS separated string argument
	for filename in "${file_fullpaths_to_encrypt[@]}"
	do
		#echo "888888888888888888888888888888888888888888888888888888888888888888"
		string_to_send+="${filename} " # with a trailing space character after each
	done

	# now to trim that last trailing space character:
	string_to_send=${string_to_send%[[:blank:]]}

	echo "${string_to_send}"

	# WHY ARE WE HERE AGAIN..?
	# we want to replace EACH destination_output_file_fullpath file that we've written, with an encrypted version...
	# ... so, we call encryption_services.sh script to handle the file encryption jobs
	## the command argument is deliberately unquoted, so the default space character IFS DOES separate the string into arguments
	encryption_services.sh $string_to_send

	##########################################################################################################
	##########################################################################################################

	echo && echo "JUST GOT BACK FROM ENCRYPTION SERVICES"

	echo "audit_list_maker exit code: $?" #&& exit 

} ## end main














###############################################################################################
#### vvvvv FUNCTION DECLARATIONS  vvvvv
###############################################################################################
# 









##########################################################################################################
##########################################################################################################
# return a match for dir paths in the secret_dir_name array, set a result and return immediately
function test_for_secret_dir
{
	test_dir_fullpath="$1"

	for secret_dir_name in "${secret_content_directories[@]}"
	do
		echo
		echo "INSIDE THE SECRET TEST FUNCTION:"
		echo "test_dir_fullpath : $test_dir_fullpath"
		echo "secret_dir_name : $secret_dir_name"

		if [[ "$test_dir_fullpath" == "${source_holding_dir_fullpath}/$secret_dir_name" ]]
		then
			echo "TEST FOUND A MATCH TO LABEL SECRET!!!!!!!!!!!!!!!!!############0000000000 $test_dir_fullpath "
			result=0 # found, so break out of for loop
			return "$result" # found, so break out of for loop
		else 
			result=1
		fi
	done

	return "$result" # returns 1 for failing to find a match

}

##########################################################################################################
# return a match for dir paths in the directories_to_ignore array, set a result and return (break out) immediately
function test_for_ignore_dir
{
	test_dir_fullpath="$1"

	for ignore_dir_name in "${directories_to_ignore[@]}"
	do
		echo
		echo "INSIDE THE IGNORE TEST FUNCTION:"
		echo "test_dir_fullpath : $test_dir_fullpath"
		echo "ignore_dir_name : $ignore_dir_name"

		if [[ "$test_dir_fullpath" == "${source_holding_dir_fullpath}/$ignore_dir_name" ]]
		then
			echo "TEST FOUND A MATCH TO IGNORE!!!!!!!!!!!!!!!!!############0000000000 $test_dir_fullpath "
			result=0 # found, so break out of for loop
			return "$result" # found, so break out of for loop
		else 
			result=1
		fi
	done

	return "$result" # returns 1 for failing to find a match

}

##########################################################################################################
##########################################################################################################
# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE. RENAME CONCEPTUALLY DIFFERENT test_line NAMESAKES
function sanitise_absolute_path_value ##
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim trailing / for all paths
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	# TRIM TRAILING AND LEADING SPACES AND TABS
	test_line=${test_line%%[[:blank:]]}
	test_line=${test_line##[[:blank:]]}

	# TRIM TRAILING / FOR ABSOLUTE PATHS:
    while [[ "$test_line" == *'/' ]]
    do
        echo "FOUND TRAILING SLASH"
        test_line=${test_line%'/'}
    done 

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}


##########################################################################################################
# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE...
function sanitise_relative_path_value
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim leading / for relative paths
	# - trim trailing / for all paths
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	# TRIM TRAILING AND LEADING SPACES AND TABS
	test_line=${test_line%%[[:blank:]]}
	test_line=${test_line##[[:blank:]]}

	# TRIM LEADING AND TRAILING / FOR RELATIVE PATHS:
    while [[ "$test_line" == *'/' ]]
    do
        echo "FOUND TRAILING SLASH"
        test_line=${test_line%'/'}
    done 

	# TRIM LEADING / FOR RELATIVE PATHS:
	# afer this, test_line should just be the directory name
	test_line=${test_line##'/'}

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
##########################################################################################################
##########################################################################################################
# A DUAL PURPOSE FUNCTION - CALLED TO EITHER TEST OR TO SET LINE TYPES:
# TESTS WHETHER THE LINE IS OF EITHER VALID comment, empty/blank OR string (variable or value) TYPE,
# SETS THE GLOBAL line_type AND test_line variableS.
function test_and_set_line_type
{

#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# TODO: ADD ANOTHER CONFIG FILE VALIDATION TEST:
	# TEST THAT THE LINE FOLLOWING A VARIABLE= ALPHANUM STRING MUST BE A VALUE/ ALPHANUM STRING, ELSE FAIL
	test_line="${1}"
	line_type=""

	#debug printouts:
	#echo "$test_line"

	if [[ "$test_line" == "#"* ]] # line is a comment
	then
		line_type="comment"
		#echo "line_type set to: $line_type"
	elif [[ "$test_line" =~ [[:blank:]] || "$test_line" == "" ]] # line empty or contains only spaces or tab characters
	then
		line_type="empty"
		#echo "line_type set to: $line_type"
	elif [[ "$test_line" =~ [[:alnum:]] ]] # line is a string (not commented)
	then
		echo -n "Alphanumeric string  :  "
		if [[ "$test_line" == *"=" ]]
		then
			line_type="variable_string"
			echo "line_type set to: "$line_type" for "$test_line""
		elif [[ "$test_line" =~ $all_filepath_regex ]]	#
		then
			line_type="value_string"
			echo "line_type set to: "$line_type" for "$test_line""
		else
			echo "Failsafe : Couldn't match the Alphanum string"
			echo "Exiting from function ${FUNCNAME[0]} in script $(basename $0)"
			exit $E_UNEXPECTED_BRANCH_ENTERED
		fi

	else
		echo "Failsafe : Couldn't match this line with ANY line type!"
		echo "Exiting from function ${FUNCNAME[0]} in script $(basename $0)"
		exit $E_UNEXPECTED_BRANCH_ENTERED
	fi

#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
##########################################################################################################
## VARIABLE 1:
# TODO: LATER - COULD THESE TWO FUNCTIONS FOR VARIABLES 1 AND 2 BE CONSOLIDATED INTO ONE FOR ABSOLUTED PATH VALUES?
# ...WITH A keyword ARRAY FOR LOOPED THOUGH?
function get_destination_holding_dir_fullpath_config
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	keyword="destination_holding_dir_fullpath="
	line_type=""
	value_collection="OFF"

	while read lineIn
	do

		test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

		if [[ $value_collection == "ON" && $line_type == "value_string" ]]
		then
			sanitise_absolute_path_value "$lineIn"
			echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
			echo "test_line has the value: $test_line"
			echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
			set -- $test_line # using 'set' to get test_line out of this subprocess into a positional parameter ($1)

		elif [[ $value_collection == "ON" && $line_type != "value_string" ]] # last value has been collected for destination_holding_dir_fullpath
		then
			value_collection="OFF" # just because..
			break # end this while loop, as last value has been collected for destination_holding_dir_fullpath
		else
			# value collection must be OFF
			:
		fi
		
		
		# switch value collection ON for the NEXT line read
		# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
		if [[ "$lineIn" == "$keyword" ]]
		then
			value_collection="ON"
		fi

	done < "$config_file_fullpath"

	# ASSIGN
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "test_line has the value: $1"
	echo "destination_holding_dir_fullpath has the value: $destination_holding_dir_fullpath"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	destination_holding_dir_fullpath="$1" # test_line just set globally in sanitise_absolute_path_value function
	set -- # unset that positional parameter we used to get test_line out of that while read subprocess
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "test_line (AFTER set --) has the value: $1"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
## VARIABLE 2:
function get_source_holding_dir_fullpath_config
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	keyword="source_holding_dir_fullpath="
	## ACCESS TO RELATIVE DIRECTORIES CAN ONLY BE TESTED ONCE source_holding_dir_fullpath
	# HAS BEEN TESTED OK AND VARIABLE ASSIGNED
	line_type=""
	value_collection="OFF"

	while read lineIn
	do

		test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

		if [[ $value_collection == "ON" && $line_type == "value_string" ]]
		then
			sanitise_absolute_path_value "$lineIn"
			set -- $test_line # 

		elif [[ $value_collection == "ON" && $line_type != "value_string" ]] # last value has been collected for destination_holding_dir_fullpath
		then
			value_collection="OFF" # just because..
			break # end this while loop, as last value has been collected for destination_holding_dir_fullpath
		else
			# value collection must be OFF
			:
		fi
		
		
		# switch value collection ON for the NEXT line read
		# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
		if [[ "$lineIn" == "$keyword" ]]
		then
			value_collection="ON"
		fi

	done < "$config_file_fullpath"


	# ASSIGN 
	source_holding_dir_fullpath=$1 # test_line was just set globally in sanitise_absolute_path_value function
	set -- # unset that positional parameter we used to get test_line out of that while read subprocess

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
## VARIABLE 3:
function get_directories_to_ignore_config
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	keyword="directories_to_ignore="

	# NOW MULTIPLE LINE VALUES ASSIGNED TO ARRAY ELEMENT, SO BIT DIFFERENCE LOGIC
	line_type=""
	value_collection="OFF"
	# unset path_list?
	declare -a path_list=() # local array to store one or more sanitised relative paths

	while read lineIn
	do

		test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

		if [[ "$value_collection" == "ON" && "$line_type" == "value_string" ]]
		then
			
			sanitise_relative_path_value "$lineIn"
			path_list+=("${test_line}")
			# Not sure why we CAN access test_line here, when we had to use 'set' in the other functions?!?
			# Seems to work ok, so no complaining.
			
		elif [[ "$value_collection" == "ON" && "$line_type" != "value_string" ]] # last value has been collected for ...
		then
			
			value_collection="OFF" # just because..
			break # end this while loop, as last value has been collected for ....y
		else
			# value collection must be OFF
			:
		fi
		
		
		# switch value collection ON for the NEXT line read
		# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
		if [[ "$lineIn" == "$keyword" ]]
		then
			value_collection="ON"
		fi
		
	done < "$config_file_fullpath"

	## debug7..
	echo && echo "The values in the path_list array just before it's cloned by the directories_to_ignore array:"
	for value in "${path_list[@]}"
	do
		echo -n "$value "

	done

	# ASSIGN THE LOCAL ARRAY BY CLONING
	directories_to_ignore=("${path_list[@]}")

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
## VARIABLE 4:
function get_secret_content_directories_config
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	keyword="secret_content_directories="

	# NOW MULTIPLE LINE VALUES ASSIGNED TO ARRAY ELEMENT, SO BIT DIFFERENCE LOGIC
	line_type=""
	value_collection="OFF"
	declare -a path_list=() # local array to store one or more sanitised relative paths

	while read lineIn
	do

		test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

		if [[ $value_collection == "ON" && $line_type == "value_string" ]]
		then
			sanitise_relative_path_value "$lineIn"
			path_list+=( "${test_line}" )
			# Not sure why we CAN access test_line here, when we had to use 'set' in the other functions?!?
			# Seems to work ok, so no complaining.

		elif [[ $value_collection == "ON" && $line_type != "value_string" ]] # last value has been collected for ...
		then
			value_collection="OFF" # just because..
			break # end this while loop, as last value has been collected for ...
		else
			# value collection must be OFF
			:
		fi
		
		
		# switch value collection ON for the NEXT line read
		# THEREFORE WE'RE ASSUMING THAT A KEYWORD CANNOT EXIST ON THE 1ST LINE OF THE FILE
		if [[ "$lineIn" == "$keyword" ]]
		then
			value_collection="ON"
		fi

	done < "$config_file_fullpath"

	# ASSIGN THE LOCAL ARRAY BY CLONING
	secret_content_directories=("${path_list[@]}")

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
##########################################################################################################

# firstly, we test that the parameter we got is of the correct form for an absolute file | sanitised directory path 
# if this test fails, there's no point doing anything further
# 
function test_file_path_valid_form
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1
	
	echo "test_file_fullpath is set to: $test_file_fullpath"
	#echo "test_dir_fullpath is set to: $test_dir_fullpath"

	if [[ $test_file_fullpath =~ $abs_filepath_regex ]]
	then
		echo "THE FORM OF THE INCOMING PARAMETER IS OF A VALID ABSOLUTE FILE PATH"
		test_result=0
	else
		echo "AN INCOMING PARAMETER WAS SET, BUT WAS NOT A MATCH FOR OUR KNOWN PATH FORM REGEX "$abs_filepath_regex"" && sleep 1 && echo
		echo "Returning with a non-zero test result..."
		test_result=1
		return $E_UNEXPECTED_ARG_VALUE
	fi 


	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}

###############################################################################################
# need to test for read access to file 
# 
function test_file_path_access
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1

	echo "test_file_fullpath is set to: $test_file_fullpath"

	# test for expected file type (regular) and read permission
	if [ -f "$test_file_fullpath" ] && [ -r "$test_file_fullpath" ]
	then
		# test file found and accessible
		echo "Test file found to be readable" && echo
		test_result=0
	else
		# -> return due to failure of any of the above tests:
		test_result=1 # just because...
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_REQUIRED_FILE_NOT_FOUND"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################
# need to test for access to the file holding directory
# 
function test_dir_path_access
{
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_dir_fullpath=$1

	echo "test_dir_fullpath is set to: $test_dir_fullpath"

	if [ -d "$test_dir_fullpath" ] && cd "$test_dir_fullpath" 2>/dev/null
	then
		# directory file found and accessible
		echo "directory "$test_dir_fullpath" found and accessed ok" && echo
		test_result=0
	else
		# -> return due to failure of any of the above tests:
		test_result=1
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_REQUIRED_FILE_NOT_FOUND"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################
# IF USE CASES FOR THE COEXISTENCE OF DIFFERENT CONFIGURATION FILES EVER ARISE
# WE CAN USE THIS FUNCTION TO USER OPTIONS:
# USE OPTION MENU, THE $REPLY VARIABLE... FOR BETTER INTERACTION
function get_config_file_to_use
{
	## 
	echo
	echo ":::   [ USING THE DEFAULT CONFIGURATION FILE ]   :::"
	echo
	sleep 2
}

################################################################################################


main "$@"; exit


# TODO:
# when encrypton_services returns control, we test whether the results are as expected before confirming success to user.
# we shred the plain text version of the file(s) - simple test `type`|`file`
# 

# UPDATE TO TRY 'INCLUDING' THE ENCRYPTION SCRIPT USING source OR . COMMAND

# USE THE set COMMAND TO CONTROL THE ENVIRONMENT, DECLARE readonly VARIABLES

# UPDATE THE README.md TO ADD A PRE-REQUISITES SECTION

# UPDATE TO USE OF OPTION SELECTION FUNCTION IF APPROPRIATE

# MULTIPLE UNCONNECTED SOURCE DIRECTORIES
# REGULAR FILES IN SOURCE DIRECTORIES
# 	REGULAR FILES TO IGNORE
#	REGULAR FILES TO ENCRYPT

