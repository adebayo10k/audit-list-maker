#!/bin/bash
#: Title		:utils.audit-list-maker.sh
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
	###############################################################################################
	# GLOBAL VARIABLE DECLARATIONS:
	###############################################################################################
	
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

	expected_no_of_program_parameters=0
	actual_no_of_program_parameters=$#

	line_type="" # global...
	test_line="" # global...
	config_file_fullpath="/etc/audit-config" # a full path to a file

	# explicitly declaring variables to make code bit more robust - move to top
	destination_holding_dir_fullpath="" # single directory in which....# a full path to directory
	source_holding_dir_fullpath="" # single directory from which....# a full path to directory
	declare -a directories_to_ignore=() # set of one or more relative path directories...
	declare -a secret_content_directories=() # set of one or more relative path directories...

	#abs_filepath_regex='^(/{1}[A-Za-z0-9\._-~]+)+$' # absolute file (and sanitised directory) path
	#all_filepath_regex='^(/?[A-Za-z0-9\._-~]+)+$' # both relative and absolute file (and sanitised directory) path . CAREFUL, THIS.
    # MATCHES NEARLY ANY STRING!
	abs_filepath_regex='^(/{1}[A-Za-z0-9\.\ _~:@-]+)+$' # absolute file path, ASSUMING NOT HIDDEN FILE, placing dash at the end!...
	all_filepath_regex='^(/?[A-Za-z0-9\.\ _~:@-]+)+$' # both relative and absolute file path

	declare -a file_fullpaths_to_encrypt=() # setdestinationory
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

	###############################################################################################
	# 'SHOW STOPPER' FUNCTION CALLS:	
	###############################################################################################

	# verify and validate program positional parameters
	verify_and_validate_program_arguments

	#declare -a authorised_host_list=($E530c_hostname $E6520_hostname $E5490_hostname)

	# entry test to prevent running this program on an inappropriate host
	# entry tests apply only to those highly host-specific or filesystem-specific programs that are hard to generalise
	if [[ $(declare -a | grep "authorised_host_list" 2>/dev/null) ]]; then
		entry_test
	else
		echo "entry test skipped..." && sleep 2 && echo
	fi
			
	
	###############################################################################################
	# $SHLVL DEPENDENT FUNCTION CALLS:	
	###############################################################################################

	# using $SHLVL to show whether this script was called from another script, or from command line
	if [ $SHLVL -le 2 ]
	then
		# Display a descriptive and informational program header:
		display_program_header

		# give user option to leave if here in error:
		get_user_permission_to_proceed
	fi


	###############################################################################################
	# FUNCTIONS CALLED ONLY IF THIS PROGRAM USES A CONFIGURATION FILE:	
	###############################################################################################

	if [ -n "$config_file_fullpath" ]
	then
		display_current_config_file

		get_user_config_edit_decision

		# test whether the configuration files' format is valid, and that each line contains something we're expecting
		validate_config_file_content

		# IMPORT CONFIGURATION INTO PROGRAM VARIABLES
		import_audit_configuration
	fi

	#exit 0 #debug

	###############################################################################################
	# PROGRAM-SPECIFIC FUNCTION CALLS:	
	###############################################################################################	

	write_src_media_filenames_to_dst_files

	check_encryption_platform
	if [[ $? -eq 0 && ${#file_fullpaths_to_encrypt[@]} -gt 0 ]]
	then
		encrypt_secret_lists
	fi

	echo && echo "JUST GOT BACK FROM ENCRYPTION SERVICES"

	echo "audit-list-maker exit code: $?" #&& exit 

} ## end main

##########################################################################################################





###############################################################################################
####  FUNCTION DECLARATIONS  
###############################################################################################

# entry test to prevent running this program on an inappropriate host
function entry_test()
{
	#
	:
}

####################################################################################################
function display_program_header
{
	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	# Display a program header and give user option to leave if here in error:
    echo
    echo -e "		\033[33m===================================================================\033[0m";
    echo -e "		\033[33m||             Welcome to the AUDIT LIST FILE MAKER               ||  author: adebayo10k\033[0m";  
    echo -e "		\033[33m===================================================================\033[0m";
    echo

	# REPORT SOME SCRIPT META-DATA
	echo "The absolute path to this script is:	$0"
	echo "Script root directory set to:		$(dirname $0)"
	echo "Script filename set to:			$(basename $0)" && echo
}

##########################################################################################################
function get_user_permission_to_proceed
{
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

}
##########################################################################################################
function verify_and_validate_program_arguments
{
	echo; echo; echo "USAGE: $(basename $0)"

	# TEST # COMMAND LINE ARGS
	if [ $actual_no_of_program_parameters -ne $expected_no_of_program_parameters ]
	then
		echo "Incorrect number of command line args. Exiting now..."
		echo "Usage: $(basename $0)"
		exit $E_INCORRECT_NUMBER_OF_ARGS
	fi

}
##########################################################################################################
function display_current_config_file
{
	echo && echo CURRENT CONFIGURATION FILE...
	echo && sleep 1

	cat "$config_file_fullpath"
}
##########################################################################################################
function get_user_config_edit_decision
{
	echo " Edit configuration file? [Y/N]"
	echo && sleep 1

	read edit_config
	case $edit_config in 
	[yY])	echo && echo "Opening an editor now..." && echo && sleep 2
    		sudo nano "$config_file_fullpath" # /etc exists, so no need to test access etc.
    		# TODO: yes, we now need to revalidate
				;;
	[nN])	echo
			echo " Ok, using the  current configuration" && sleep 1
				;;			
	*) 		echo " Give me a Y or N..." && echo && sleep 1
			get_user_config_edit_decision
				;;
	esac 
}

##########################################################################################################
function write_src_media_filenames_to_dst_files
{

	# WRITE SOURCE MEDIA FILENAMES TO THE STORAGE LOCATION
	# the designated storage directory must already exist - it won't be created by this script.

	# TODO: if wc -l destination_output_file_fullpath >= 12000; then continue writing to output_file2
	# 
	#date=$(date +'%T')
	#date=$(date +'%F')
	#date=$(date +'%F@%T')

	echo "WARNING: Make sure that source content directory is \"dressed appropriately\"." && echo

	echo  "Then press ENTER to start writing the source media filenames to the storage location..." && echo

	read

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
	
		test_for_secret_dir "$source_input_dir_fullpath" 
		return_code=$?; echo "test_for_secret_dir return_code : $return_code"
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

		echo >> "$destination_output_file_fullpath" # empty lines for format
		echo >> "$destination_output_file_fullpath"

		ls -R "$source_input_dir_fullpath" >> "$destination_output_file_fullpath" 2>/dev/null # suppress stderr
		# TODO: better to use `find`or `du -...`, 
		# and specify a list of file extensions of interest - investigate later

		## TODO: WE JUST WANT THE COUNT HERE, SO REDIRECT OR PIPE TO sed || USE VARIABLE EXPANSION ON A VARIABLE
		echo "LINE COUNT OUTPUT FOR FILE: $(wc -l "$destination_output_file_fullpath") " && echo

	done	

}
##########################################################################################################
# 
function encrypt_secret_lists
{
		
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# BASH ARRAYS ARE NOT 'FIRST CLASS VALUES' SO CAN'T BE PASSED AROUND LIKE ONE THING\
	# - so since we're only intending to make a single call\
	# to file-encrypter.sh, we need to make an IFS separated string argument
	for filename in "${file_fullpaths_to_encrypt[@]}"
	do
		#echo "888888888888888888888888888888888888888888888888888888888888888888"
		string_to_send+="${filename} " # with a trailing space character after each
	done

	# now to trim that last trailing space character:
	string_to_send=${string_to_send%[[:blank:]]}

	echo "${string_to_send}" ## debug

	# WHY ARE WE HERE AGAIN..?
	# we want to replace EACH destination_output_file_fullpath file that we've written, with an encrypted version\
	# ... so, we call file-encrypter.sh script to handle this file encryption job
	## the command argument is deliberately unquoted, so the default\
	# space character IFS DOES separate the string into arguments
	file-encrypter.sh $string_to_send

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# check that the OpenPGP tool gpg is installed on the system
# check that the file-encrypter.sh program is accessible
function check_encryption_platform
{
		
	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# NOW, AT THIS POINT, ALL AUDIT LISTINGS HAVE BEEN WRITTEN TO THEIR DESTINATIONS.
	# WE CAN NOW PROCEED TO ENCRYPTION OF OUR SECRET STUFF...

	bash -c "which gpg 2>/dev/null" # suppress stderr (but not stdout for now)
	if [ $? -eq 0 ]
	then
		echo "OpenPGP PROGRAM INSTALLED ON THIS SYSTEM OK"
	else
		echo "FAILED TO FIND THE REQUIRED OpenPGP PROGRAM"
		# -> exit due to failure of any of the above tests:
		echo "Exiting from function \"${FUNCNAME[0]}\" in script $(basename $0)"
		exit $E_REQUIRED_PROGRAM_NOT_FOUND
	fi

	# we test for the existence of a known script that provides encryption services:
	which file-encrypter.sh
	if [ $? -eq 0 ]
	then
		echo "THE file-encrypter.sh PROGRAM WAS FOUND TO BE INSTALLED OK ON THIS HOST SYSTEM"	
	else
		echo "FAILED TO FIND THE file-encrypter.sh PROGRAM ON THIS SYSTEM, SO NO NOTHING LEFT TO DO BUT EXEET, GOODBYE"
		exit $E_REQUIRED_PROGRAM_NOT_FOUND
	fi

	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}
###########################################################
# 
function import_audit_configuration()
{

	echo  "Press ENTER to start importing to variables..." && echo

	read

	# get the values and assign to program variables:
	get_holding_dirs_fullpath_config
	get_directories_to_ignore_config
	get_secret_content_directories_config

	# NOW DO ALL THE DIRECTORY ACCESS TESTS FOR IMPORTED PATH VALUES HERE.
	# REMEMBER THAT ORDER IS IMPORTANT, AS RELATIVE PATHS DEPEND ON ABSOLUTE.

	for dir in "$destination_holding_dir_fullpath" "$source_holding_dir_fullpath"
	do

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "HOLDING (PARENT) DIRECTORY PATH IS OF VALID FORM"
		else
			echo "The valid form test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_UNEXPECTED_ARG_VALUE
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "The full path to the HOLDING (PARENT) DIRECTORY is: $dir"
		else
			echo "The HOLDING (PARENT) DIRECTORY path access test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_REQUIRED_FILE_NOT_FOUND
		fi

	done
	
	# note: there's NO POINT testing access HERE to directories we're going to IGNORE!

	for dir_name in "${secret_content_directories[@]}"
	do
		echo -n "FINALLY, secret_content_directories list ITEM now set to:"
		echo "$dir_name"

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "${source_holding_dir_fullpath}/$dir_name"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "SECRET CONTENT DIRECTORY PATH IS OF VALID FORM"
		else
			echo "The valid form test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_UNEXPECTED_ARG_VALUE
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "${source_holding_dir_fullpath}/$dir_name"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "The full path to the SECRET CONTENT DIRECTORY is: ${source_holding_dir_fullpath}/$dir_name"
		else
			echo "The SECRET CONTENT DIRECTORY path access test FAILED and returned: $return_code"
			echo "Nothing to do now, but to exit..." && echo
			exit $E_REQUIRED_FILE_NOT_FOUND
		fi
	done


}

##########################################################################################################
# test whether the configuration files' format is valid,
# and that each line contains something we're expecting
function validate_config_file_content()
{
	while read lineIn
	do
		# any content problems handled in the test_and_set_line_type function:
        test_and_set_line_type "$lineIn"
        return_code="$?"
        echo "exit code for tests on that line was: $return_code"
        if [ $return_code -eq 0 ]
        then
            # tested line must have contained expected content
            # this function has no need to know which type of line it was
            echo "That line was expected!" && echo
        else
            echo "That line was NOT expected!"
            echo "Exiting from function \"${FUNCNAME[0]}\" in script \"$(basename $0)\""
            exit 0
        fi

	done < "$config_file_fullpath" 

}
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
# keep sanitise functions separate and specialised, as we may add more to specific value types in future
# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE. RENAME CONCEPTUALLY DIFFERENT test_line NAMESAKES
function sanitise_absolute_path_value ##
{

echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim trailing / for all paths
	test_line="${1}"
	echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

	while [[ "$test_line" == *'/' ]] ||\
	 [[ "$test_line" == *[[:blank:]] ]] ||\
	 [[ "$test_line" == [[:blank:]]* ]]
	do 
		# TRIM TRAILING AND LEADING SPACES AND TABS
		# backstop code, as with leading spaces, config file line wouldn't even have been
		# recognised as a value!
		test_line=${test_line%%[[:blank:]]}
		test_line=${test_line##[[:blank:]]}

		# TRIM TRAILING / FOR ABSOLUTE PATHS:
		test_line=${test_line%'/'}
	done

	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# keep sanitise functions separate and specialised, as we may add more to specific value types in future
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

	while [[ "$test_line" == *'/' ]] ||\
	 [[ "$test_line" == [[:blank:]]* ]] ||\
	 [[ "$test_line" == *[[:blank:]] ]]
	do 
		# TRIM TRAILING AND LEADING SPACES AND TABS
		# backstop code, as with leading spaces, config file line wouldn't even have been
		# recognised as a value!
		test_line=${test_line%%[[:blank:]]}
		test_line=${test_line##[[:blank:]]}

		# TRIM TRAILING / FOR ABSOLUTE PATHS:
		test_line=${test_line%'/'}
	done

	# FINALLY, JUST THE ONCE, TRIM LEADING / FOR RELATIVE PATHS:
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

	#[[ "$test_line" == "#"* ]] && line_type="comment"
	#[[ "$test_line" =~ [[:blank:]] || "$test_line" == "" ]] && line_type="empty"
	#[[ "$test_line" =~ [[:alnum:]] && "$test_line" == *"=" ]] && line_type="variable_string"
	#[[ "$test_line" =~ [[:alnum:]] && "$test_line" =~ $all_filepath_regex ]] && line_type="value_string"
#
	#case $line_type in
	#"comment")		echo "line_type set to: $line_type"
	#				;;
	#"empty")		echo "line_type set to: $line_type"
	#				;;
	#"variable_string")	echo "line_type set to: "$line_type" for "$test_line""
	#					;;
	#"value_string")		echo "line_type set to: "$line_type" for "$test_line""
	#					;;									
	#*) 				echo "line_type set to: \"UNKNOWN\" for "$test_line""
	#				echo "Failsafe : Couldn't match this line with ANY line type!"
	#				return $E_UNEXPECTED_BRANCH_ENTERED
	#	 			;;
    #esac

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
            echo "line_type set to: \"UNKNOWN\" for "${test_line}""
			echo "Failsafe : Couldn't match the Alphanum string"
			return $E_UNEXPECTED_BRANCH_ENTERED
		fi
	else
	    echo "line_type set to: \"UNKNOWN\" for "$test_line""
		echo "Failsafe : Couldn't match this line with ANY line type!"
		return $E_UNEXPECTED_BRANCH_ENTERED
	fi
	#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# for any absolute file path value to be imported...
function get_holding_dirs_fullpath_config
{

	echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	for keyword in "destination_holding_dir_fullpath=" "source_holding_dir_fullpath="
	do

		#keyword="destination_holding_dir_fullpath="
		line_type=""
		value_collection="OFF"

		while read lineIn
		do

			test_and_set_line_type "$lineIn" # interesting for the line FOLLOWING that keyword find

			if [[ $value_collection == "ON" && $line_type == "value_string" ]]
			then
				sanitise_absolute_path_value "$lineIn"
				echo "test_line has the value: $test_line"
				set -- $test_line # using 'set' to get test_line out of this subprocess into a positional parameter ($1)

			elif [[ $value_collection == "ON" && $line_type != "value_string" ]]
			# last value has been collected for this holding directory
			then
				value_collection="OFF" # just because..
				break # end this while loop, as last value has been collected for this holding directory
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
		echo "test_line has the value: $1"
		echo "the keyword on this for-loop is set to: $keyword"

		if [ "$keyword" == "destination_holding_dir_fullpath=" ]
		then
			destination_holding_dir_fullpath="$1"
			# test_line just set globally in sanitise_absolute_path_value function
		elif [ "$keyword" == "source_holding_dir_fullpath=" ]
		then
			source_holding_dir_fullpath="$1"
			# test_line just set globally in sanitise_absolute_path_value function
		else
			echo "Failsafe branch entered"
			exit $E_UNEXPECTED_BRANCH_ENTERED
		fi

		set -- # unset that positional parameter we used to get test_line out of that while read subprocess
		echo "test_line (AFTER set --) has the value: $1"

	done

	echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# CAN THESE TWO ALSO BE CONSOLIDATED?
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
# CAN THESE TWO ALSO BE CONSOLIDATED?
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

