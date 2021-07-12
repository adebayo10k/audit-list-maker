#!/bin/bash
#: Title		:utils.audit-list-maker.sh
#: Date			:2019-07-05
#: Author		:adebayo10k
#: Version		:1.0
#: Description	:create independently stored reference listings of the media filenames
#: Description	:on a drive when the backup of those files is not really justified.
#: Description	:backup, reacquire, recreate, jq reinstall reapply repopulate reinstate rewrite
#: Options		:
##

##################################################################
##################################################################
# THIS STUFF IS HAPPENING BEFORE MAIN FUNCTION CALL:
#===================================

# 1. MAKE SHARED LIBRARY FUNCTIONS AVAILABLE HERE

# make all those library function available to this script
shared_bash_functions_fullpath="${SHARED_LIBRARIES_DIR}/shared-bash-functions.sh"
shared_bash_constants_fullpath="${SHARED_LIBRARIES_DIR}/shared-bash-constants.inc.sh"

for resource in "$shared_bash_functions_fullpath" "$shared_bash_constants_fullpath"
do
	if [ -f "$resource" ]
	then
		echo "Required library resource FOUND OK at:"
		echo "$resource"
		source "$resource"
	else
		echo "Could not find the required resource at:"
		echo "$resource"
		echo "Check that location. Nothing to do now, except exit."
		exit 1
	fi
done


# 2. MAKE SCRIPT-SPECIFIC FUNCTIONS AVAILABLE HERE

# must resolve canonical_fullpath here, in order to be able to include sourced function files BEFORE we call main, and  outside of any other functions defined here, of course.

# at runtime, command_fullpath may be either a symlink file or actual target source file
command_fullpath="$0"
command_dirname="$(dirname $0)"
command_basename="$(basename $0)"

# if a symlink file, then we need a reference to the canonical file name, as that's the location where all our required source files will be.
# we'll test whether a symlink, then use readlink -f or realpath -e although those commands return canonical file whether symlink or not.
# 
canonical_fullpath="$(readlink -f $command_fullpath)"
canonical_dirname="$(dirname $canonical_fullpath)"

# this is just development debug information
if [ -h "$command_fullpath" ]
then
	echo "is symlink"
	echo "canonical_fullpath : $canonical_fullpath"
else
	echo "is canonical"
	echo "canonical_fullpath : $canonical_fullpath"
fi

# included source files for json profile import functions
#source "${canonical_dirname}/preset-profile-builder.inc.sh"


# THAT STUFF JUST HAPPENED BEFORE MAIN FUNCTION CALL!
##################################################################
##################################################################


function main
{
	#######################################################################
	# GLOBAL VARIABLE DECLARATIONS:
	#######################################################################

	program_param_0=${1:-"not_set"}

	max_expected_no_of_program_parameters=3
	min_expected_no_of_program_parameters=2
	actual_no_of_program_parameters=$#
	all_the_parameters_string="$@"

	program_title=""
	original_author=""
	program_dependencies=(jq cowsay vi file-encrypter.sh gpg)

	test_line="" # global...
	config_file_fullpath= # a full path to a file

	# explicitly declaring variables to make code bit more robust - move to top so easier to manage

	# THESE ARE ASSIGNED TO THE RAW, IMPORTED CONFIGURATION FILE DATA
	destination_directory="" # single directory in which....# a full path to directory
	source_directory="" # single directory from which....# a full path to directory
	declare -a sub_dirs_to_ignore_array=() # set of one or more relative path directories...
	declare -a sub_dirs_to_keep_secret_array=() # set of one or more relative path directories...

	# THESE ARE ASSIGNED TO CONFIGURATION VALUES THAT HAVE BEEN CONVERTED INTO MORE USEFUL DATA TYPES
	destination_holding_dir_fullpath="" # single directory in which....# a full path to directory
	source_holding_dir_fullpath="" # single directory from which....# a full path to directory
	declare -a directories_to_ignore=() # set of one or more relative path directories...
	declare -a secret_content_directories=() # set of one or more relative path directories...


	declare -a file_fullpaths_to_encrypt=() # set of destination files (reset between device loops)
	#test_subdir_fullpath ## a full path to directory [[[ LOCAL CONTROL IN 1 FUNC ]]]
	#user_config_file_fullpath # a full path to a file
	#config_file_name # a filename
	#config_dir_fullpath # a full path to directory

	#dir_name # a directory name [[[ LOCAL CONTROL IN 1 MAIN PLACE ]]]
	#test_subdir_fullpath # a full path to directory [[[ LOCAL CONTROL IN 1 FUNC ]]]
	#ignore_subdir_fullpath # a directory name
	#src_input_subdir_fullpath # a full path to directory
	#source_input_dir_name # a directory name
	#destination_output_file_name # a filename date augmented 
	#destination_output_file_fullpath # # a full path to a file (.. to destination_output_file_name)

	#######################################################################

	###############################################################################################
	# 'SHOW STOPPER' FUNCTION CALLS:	
	###############################################################################################

	# count program positional parameters
	check_no_of_program_args

	# check program dependencies and requirements
	check_program_requirements "${program_dependencies[@]}"

	# cleanup and validate, test program positional parameters
	# required parameter sequence is : CONFIGURATION_FILE, [MEDIA_DRIVE_ID]...
	cleanup_and_validate_program_arguments

	# entry test to prevent running this program on an inappropriate host
	# entry tests apply only to those highly host-specific or filesystem-specific programs that are hard to generalise
	if [[ $(declare -a | grep 'authorised_host_list' 2>/dev/null) ]]; then
		entry_test
	else
		echo "entry test skipped..." && sleep 1 && echo
	fi
			
	
	###############################################################################################
	# $SHLVL DEPENDENT FUNCTION CALLS:	
	###############################################################################################

	echo "OUR CURRENT SHELL LEVEL IS: $SHLVL"
	# using $SHLVL to show whether this script was called from another script, or from command line
	if [ $SHLVL -le 3 ]
	then
		# Display a descriptive and informational program header:
		display_program_header

		# give user option to leave if here in error:
		get_user_permission_to_proceed
	fi


	###############################################################################################
	# FUNCTIONS CALLED ONLY IF THIS PROGRAM USES A CONFIGURATION FILE:	
	###############################################################################################

	###############################################################################################
	# PROGRAM-SPECIFIC FUNCTION CALLS:	
	###############################################################################################	
	
	if [ -n "$config_file_fullpath" ]
	then		
		display_current_config_file

		# for-loop over
		# incoming array is visible here too! ok cool.
		for elem_num in $(seq 1 $(( ${#incoming_array[@]}-1 ))) #
		do
			#echo -n "$elem_num."
			#echo ${incoming_array[elem_num]}
			# IMPORT CONFIGURATION DATA INTO PROGRAM VARIABLES
			import_audit_configuration "${incoming_array[elem_num]}"
			#
			#exit 0 # debug
			write_src_media_filenames_to_dst_files

			if [ ${#file_fullpaths_to_encrypt[@]} -gt 0 ]
			then
				encrypt_secret_lists
			fi
			echo && echo "JUST GOT BACK FROM ENCRYPTION SERVICES"

		done
		
	else
		msg="NO CONFIG FOR YOU. Exiting now..."
		lib10k_exit_with_error "$E_REQUIRED_FILE_NOT_FOUND" "$msg" 	
	fi

	echo "audit-list-maker exit code: $?" #&& exit 

} ## end main

##########################################################################################################





###############################################################################################
####  FUNCTION DECLARATIONS  
###############################################################################################

# quick check that number of program arguments is within the valid range
function check_no_of_program_args()
{
	#echo && echo "Entered into function ${FUNCNAME[0]}" && echo
	
	# establish that number of parameters is valid
	if [ $actual_no_of_program_parameters -lt $min_expected_no_of_program_parameters -o \
	$actual_no_of_program_parameters -gt $max_expected_no_of_program_parameters  ]
	then
		msg="Incorrect number of command line arguments. Exiting now..."
		lib10k_exit_with_error "$E_INCORRECT_NUMBER_OF_ARGS" "$msg"
	fi
	
	#echo && echo "Leaving from function ${FUNCNAME[0]}" && echo

}

###############################################################################################
# entry test to prevent running this program on an inappropriate host
function entry_test()
{
	#
	:
}

####################################################################################################
function display_program_header()
{

	# Display a program header and give user option to leave if here in error:
    echo
    echo -e "		\033[33m===================================================================\033[0m";
    echo -e "		\033[33m||             Welcome to the AUDIT LIST FILE MAKER               ||  author: adebayo10k\033[0m";  
    echo -e "		\033[33m===================================================================\033[0m";
    echo

	# REPORT SOME SCRIPT META-DATA
	echo "The absolute path to this script is:	$0"
	echo "Script root directory is:		$(dirname $0)"
	echo "Script filename is:			$(basename $0)" && echo

	if type cowsay > /dev/null 2>&1
	then
		cowsay "Hello, ${USER}!"
	fi
}

##########################################################################################################
function get_user_permission_to_proceed
{
	echo " press ENTER to continue, or q to quit program."
    echo && sleep 1
    read last_chance

    case $last_chance in 
	[qQ])	echo
				echo "Goodbye! Exiting now..."
				exit 0 #
				;;
	*) 		echo "You're IN...Welcome!" && echo && sleep 1
		 		;;
    esac 

}
##########################################################################################################
# 
function cleanup_and_validate_program_arguments()
{	

	echo "$all_the_parameters_string" && echo

	incoming_array=( $all_the_parameters_string )
	#echo "incoming_array[@]: ${incoming_array[@]}"

	# test that element 0 is a valid file
		# if so, set the configfile variable
		# test that remaining elements are valid drive ids, by checking config file
	
	sanitise_absolute_path_value "${incoming_array[0]}"
	#echo "test_line has the value: $test_line"
	absolute_path_trimmed=$test_line
	validate_absolute_path_value "$absolute_path_trimmed"	# exits if any problem with path

	config_file_fullpath="$absolute_path_trimmed" # we're trusting that it's a well formatted json, for now!
	echo "config filepath: $config_file_fullpath"

	# test that ALL remaining elements (program args) are valid drive ids, by checking config file
	# (that we've just validated) get the drive ids from the configuration file, as a string
	drive_id_data_string=$(cat "$config_file_fullpath" | jq -r '.mediaDriveAudits[] | .sourceDriveLabel')

	#echo "drive_id_data_string: $drive_id_data_string"
	#echo && echo


	# iterate over program arguments array, starting at element 1
	for elem_num in $(seq 1 $(( ${#incoming_array[@]}-1 )))
	do
		arg_match=1 # initialise to failure
		#echo -n "$elem_num."
		#echo ${incoming_array[elem_num]}

		# hey, we can iterate over a string with newline/return character IFS!
		# make sure ALL user-provided drive ids exist in the configuration file, otherwise fail exit.
		for drive_id in $drive_id_data_string
		do
			#echo "my new $drive_id"
			echo "${incoming_array[elem_num]}" | grep -q "^$drive_id$" # grep for an exact match
			arg_match=$?
			#echo $arg_match
			if [ $arg_match -eq 0 ] # program arg is valid match
			then
				continue 2 # up 2 levels
			fi
		done

		# basically dropping out of this outer loop here, with arg_match=1 means bad argument, so exit
		if [ $arg_match -ne 0 ] # the current program arg is NOT a valid match
		then
			msg="The valid program args test FAILED. Exiting now..."
			lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
		fi
	done

	#exit 0 # debug

}

###############################################################################################
# exits if any problem with path
function validate_absolute_path_value()
{
	#echo && echo "Entered into function ${FUNCNAME[0]}" && echo

	test_filepath="$1"

	# this valid form test works for sanitised file paths
	test_file_path_valid_form "$test_filepath"
	return_code=$?
	if [ $return_code -eq 0 ]
	then
		echo "The absolute filepath is of VALID FORM"
	else
		msg="The valid form test FAILED and returned: $return_code. Exiting now..."
		lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
	fi

	# if the above test returns ok, ...
	test_file_path_access "$test_filepath"
	return_code=$?
	if [ $return_code -eq 0 ]
	then
		echo "The  absolute filepath is ACCESSIBLE OK"
	else
		msg="The configuration filepath ACCESS TEST FAILED and returned: $return_code. Exiting now..."
		lib10k_exit_with_error "$E_FILE_NOT_ACCESSIBLE" "$msg"
	fi


	#echo && echo "Leaving from function ${FUNCNAME[0]}" && echo

}

##########################################################################################################
function display_current_config_file
{
	echo && echo CURRENT CONFIGURATION FILE...
	echo && sleep 1

	cat "$config_file_fullpath" && echo
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

	echo && echo "WARNING: Before continuing, make sure that source content directory contains ONLY expected subdirectories." && echo && echo

	echo "Then press ENTER to start writing the source media filenames to the storage location..." && echo

	read

	# remove previous output files during development
	# in production we could either create another subdirectory, continue to delete, keep one or two previous copies or....
	# no risk of sync conflicts, as date augmented filenames mean completely different files
	# 
	# NOTE: VERY DANGEROUS TO USE * WITHIN THE rm command! eg #rm "${destination_holding_dir_fullpath}"/*
	if [ -d $destination_holding_dir_fullpath ]
	then	
		echo "REMOVE THE EXISTING AUDIT DIRECTORY"
		echo "===================================" && echo
		rm -rfv $destination_holding_dir_fullpath && mkdir $destination_holding_dir_fullpath
	else
		mkdir -p $destination_holding_dir_fullpath
	fi

	# RESET file_fullpaths_to_encrypt BETWEEN DRIVE AUDITS (before we start appending again later in this function)
	file_fullpaths_to_encrypt=()
	#echo "file_fullpaths_to_encrypt: ${file_fullpaths_to_encrypt[@]}" #debug
	#echo "ABOVE SHOULD BE EMPTY NOW" #debug
	#read # debug

	for src_input_subdir_fullpath in "${source_holding_dir_fullpath}"/*
	do
		# TODO: really? ignore REGULAR files in the source_holding_dir_fullpath? really? yes for now.
		if ! [[ -d "$src_input_subdir_fullpath" ]]
		then
			echo "NOT A DIRECTORY ::::::::::::     "$src_input_subdir_fullpath""
			continue
		fi

		# find out if the current src_input_subdir_fullpath is configured to be ignored, if so we can skip to the next
		test_for_ignore_subdir "$src_input_subdir_fullpath" 
		return_code=$?; #echo "return_code : $return_code"
		if [[ "$return_code" -eq 0 ]]
		then
			echo "IGNORING ::::::::::::     "$src_input_subdir_fullpath""
			continue # move on to the next subdirectory
		fi

		# >>>>>>>>>>>>>>>>>from HERE on we can assume that we're 'OK TO GO' to audit src_input_subdir_fullpath...>>>>>>>>>>>>>>>>>
		# also, try [[:alphanum:]] or [A-Za-z0-9_-]


		# we need the directory basename (not the whole path to it) in order to name the output file
		#source_input_dir_name="${src_input_subdir_fullpath##*'/'}"
		#echo "input1: $source_input_dir_name"
		source_input_dir_name=$(basename "$src_input_subdir_fullpath")
		#echo "input2: $source_input_dir_name"

		#exit 0 #debug

		# use an augmented input directory name to name the output file
		destination_output_file_name="${source_input_dir_name}.$(date +'%F@%T')" 

		destination_output_file_fullpath="${destination_holding_dir_fullpath}/${destination_output_file_name}"

		# NOW THAT WE HAVE A $destination_output_file_fullpath WE CAN FIND OUT WHETHER IT NEEDS ENCRYPING \
		#(AND THEREFORE TO BE ADDED TO THE file_fullpaths_to_encrypt ARRAY).
		# WE DO THIS BY TESTING WHETHER THE CORRESPONDING $src_input_subdir_fullpath WAS SECRET.
		# WE'LL CALL A FUNCTION TO LOOP THROUGH THE secret_content_directories ARRAY:
	
		test_for_secret_dir "$src_input_subdir_fullpath" 
		return_code=$?; #echo "test_for_secret_dir return_code : $return_code"
		if [[ "$return_code" -eq 0 ]] # yes, src_input_subdir_fullpath is secret
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

		ls -R "$src_input_subdir_fullpath" >> "$destination_output_file_fullpath" 2>/dev/null # suppress stderr
		# TODO: better to use `find`or `du -...`, 
		# and specify a list of file extensions of interest - investigate later

		## TODO: WE JUST WANT THE COUNT HERE, SO REDIRECT OR PIPE TO sed || USE VARIABLE EXPANSION ON A VARIABLE
		echo "LINE COUNT FOR OUTPUT FILE: $(wc -l "$destination_output_file_fullpath") " && echo

	done	

}
##########################################################################################################
# 
function encrypt_secret_lists
{		
	#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	#echo "file_fullpaths_to_encrypt: ${file_fullpaths_to_encrypt[@]}"
	#echo "ABOVE SHOULD BE EMPTY NOW" #debug
	#read # debug

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

	#echo "string_to_send: ${string_to_send}" && echo ## debug

	# REMIND ME, WHY ARE WE HERE AGAIN..?
	# we want to replace EACH destination_output_file_fullpath file that we've written, with an encrypted version\
	# ... we therefore call file-encrypter.sh script to handle this file encryption task.
	## the command argument is deliberately unquoted, so the default\
	# space character IFS DOES separate the string into arguments
	file-encrypter.sh $string_to_send

	# reset string_to_send before next drive loop
	string_to_send=""

	#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# read in, convert and reassign, validate
function import_audit_configuration()
{
	media_drive_id="$1"

	echo  "Press ENTER to start importing \"$media_drive_id\" configuration to variables..." && echo

	read


	######## READ IN DATA FROM THE JSON CONFIGURATION FILE

	sourceDriveLabel=$(cat "$config_file_fullpath" | jq -r --arg media_drive_id "$media_drive_id" '.mediaDriveAudits[] | select(.sourceDriveLabel==$media_drive_id) | .sourceDriveLabel') 

	#echo "sourceDriveLabel: $sourceDriveLabel"
#	echo && echo

	#########

	source_directory=$(cat "$config_file_fullpath" | jq -r --arg media_drive_id "$media_drive_id" '.mediaDriveAudits[] | select(.sourceDriveLabel==$media_drive_id) | .sourceDirectory') 

	#echo "source_directory: $source_directory"
	#echo && echo

	#########

	subDirsToIgnore=$(cat "$config_file_fullpath" | jq -r --arg media_drive_id "$media_drive_id" '.mediaDriveAudits[] | select(.sourceDriveLabel==$media_drive_id) | .subDirsToIgnore[]')

	#echo $subDirsToIgnore

	sub_dirs_to_ignore_array=( $subDirsToIgnore )
	#echo && echo "###########" && echo

	#########

	subDirsToKeepSecret=$(cat "$config_file_fullpath" | jq -r --arg media_drive_id "$media_drive_id" '.mediaDriveAudits[] | select(.sourceDriveLabel==$media_drive_id) | .subDirsToKeepSecret[]')

	#echo $subDirsToKeepSecret

	sub_dirs_to_keep_secret_array=( $subDirsToKeepSecret )
#	echo && echo "###########" && echo

	#########

	destination_directory=$(cat "$config_file_fullpath" | jq -r --arg media_drive_id "$media_drive_id" '.mediaDriveAudits[] | select(.sourceDriveLabel==$media_drive_id) | .destinationDirectory') 

	#echo "destination_directory: $destination_directory"
	#echo && echo

	######### CONVERT ALL SUBDIRECTORY BASENAMES INTO FULLPATHS, AND ADD THEM TO NEW ARRAYS
	for ((i=0; i<${#sub_dirs_to_ignore_array[@]}; i++));
	do
		#echo $source_directory
		#echo ${sub_dirs_to_ignore_array[$i]}
		fullpath=${source_directory}/${sub_dirs_to_ignore_array[$i]}
		#echo $fullpath
		directories_to_ignore[$i]="$fullpath"
		#echo "${directories_to_ignore[$i]}"
	done
	####
	for ((i=0; i<${#sub_dirs_to_keep_secret_array[@]}; i++));
	do
		fullpath=${source_directory}/${sub_dirs_to_keep_secret_array[$i]}
		secret_content_directories[$i]=$fullpath
	#	echo ${secret_content_directories[$i]}
	done

	#echo "${directories_to_ignore[@]}"
	#echo "${secret_content_directories[@]}"

	######### COPY IMPORTED FULLPATHS TO NEW VARIABLES
	source_holding_dir_fullpath="$source_directory"
	destination_holding_dir_fullpath="$destination_directory"

	echo
#	echo "source_holding_dir_fullpath: $source_holding_dir_fullpath"
#	echo "destination_holding_dir_fullpath: $destination_holding_dir_fullpath"


	##########  NOW DO ALL THE DIRECTORY ACCESS TESTS FOR IMPORTED PATH VALUES HERE.
	##########  REMEMBER THAT ORDER IS IMPORTANT, AS RELATIVE PATHS DEPEND ON ABSOLUTE.
	for dir in "${directories_to_ignore[@]}" "${secret_content_directories[@]}" "$source_holding_dir_fullpath" "$destination_holding_dir_fullpath"
	do

		# this valid form test works for sanitised directory paths
		test_file_path_valid_form "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			echo "DIRECTORY PATH IS OF VALID FORM"
		else
			echo "returned: $return_code"
			msg="The valid form test FAILED. Exiting now..."
			lib10k_exit_with_error "$E_UNEXPECTED_ARG_VALUE" "$msg"
		fi	

		# if the above test returns ok, ...
		test_dir_path_access "$dir"
		return_code=$?
		if [ $return_code -eq 0 ]
		then
			#echo "The full path to the DIRECTORY is: $dir"
			:
		## UNCOMMENT IF WE'RE GONNA MKDIR IN THIS PROGRAM 
		#elif [ $return_code -eq $E_REQUIRED_FILE_NOT_FOUND ]
			#then
			#	echo "The HOLDING (PARENT) DIRECTORY WAS NOT FOUND. test returned: $return_code"
			#	echo "Creating the directory now..." && echo
			#	mkdir "$dir"
		else
			echo "test returned: $return_code"
			msg="The DIRECTORY path NOT FOUND OR NOT ACCESSIBLE. Exiting now..."
			lib10k_exit_with_error "$E_FILE_NOT_ACCESSIBLE" "$msg"
		fi 

	done
	
	# note: there's NO POINT testing access to directories we're going to IGNORE!
	# actually, that NOT completely true. We must positively confirm the existence and identity of the
	# so configured directories, so that we know they have been ignored! Eh?

}

##########################################################################################################
# return a match for dir paths in the secret_subdir_fullpath array, set a result and return immediately
function test_for_secret_dir
{
	test_subdir_fullpath="$1"

	for secret_subdir_fullpath in "${secret_content_directories[@]}"
	do
		#echo
		#echo "INSIDE THE SECRET TEST FUNCTION:"
		#echo "test_subdir_fullpath : $test_subdir_fullpath"
		#echo "secret_subdir_fullpath : $secret_subdir_fullpath"

		if [[ "$test_subdir_fullpath" == "$secret_subdir_fullpath" ]]
		then
			echo "TEST FOUND A MATCH TO LABEL SECRET!!!!!!!!!!!!!!!!!############0000000000 $test_subdir_fullpath "
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
function test_for_ignore_subdir
{
	test_subdir_fullpath="$1"

	for ignore_subdir_fullpath in "${directories_to_ignore[@]}"
	do
		#echo
		#echo "INSIDE THE IGNORE TEST FUNCTION:"
		#echo "test_subdir_fullpath : $test_subdir_fullpath"
		#echo "ignore_subdir_fullpath : $ignore_subdir_fullpath"

	#	if [[ "$test_subdir_fullpath" == "${source_holding_dir_fullpath}/$ignore_subdir_fullpath" ]]
		if [[ "$test_subdir_fullpath" == "$ignore_subdir_fullpath" ]]

		then
			echo "TEST FOUND A MATCH TO IGNORE!!!!!!!!!!!!!!!!!############0000000000 $test_subdir_fullpath "
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

#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim trailing / for all paths
	test_line="${1}"
	#echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

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

	#echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# keep sanitise functions separate and specialised, as we may add more to specific value types in future
# FINAL OPERATION ON VALUE, SO GLOBAL test_line SET HERE...
function sanitise_relative_path_value
{

#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	# sanitise values
	# - trim leading and trailing space characters
	# - trim leading / for relative paths
	# - trim trailing / for all paths
	test_line="${1}"
	#echo "test line on entering "${FUNCNAME[0]}" is: $test_line" && echo

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

#	echo "test line after trim cleanups in "${FUNCNAME[0]}" is: $test_line" && echo

#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

}

##########################################################################################################
# firstly, we test that the parameter we got is of the correct form for an absolute file | sanitised directory path 
# if this test fails, there's no point doing anything further
# 
function test_file_path_valid_form
{
	#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1
	
	#echo "test_file_fullpath is set to: $test_file_fullpath"
	#echo "test_subdir_fullpath is set to: $test_subdir_fullpath"

	if [[ $test_file_fullpath =~ $ABS_FILEPATH_NO_TB_REGEX ]]
	then
		echo "THE FORM OF THE INCOMING PARAMETER IS OF A VALID ABSOLUTE FILE PATH"
		test_result=0
	else
		echo "AN INCOMING PARAMETER WAS SET, BUT WAS NOT A MATCH FOR OUR KNOWN PATH FORM REGEX "$ABS_FILEPATH_NO_TB_REGEX"" && sleep 1 && echo
		echo "Returning with a non-zero test result..."
		test_result=1
		return $E_UNEXPECTED_ARG_VALUE
	fi 


	#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}

###############################################################################################
# need to test for read access to file 
# 
function test_file_path_access
{
	#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_file_fullpath=$1

	#echo "test_file_fullpath is set to: $test_file_fullpath"

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

	#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

	return "$test_result"
}
###############################################################################################
# need to test for access to the file holding directory
# 
function test_dir_path_access
{
	#echo && echo "ENTERED INTO FUNCTION ${FUNCNAME[0]}" && echo

	test_result=
	test_subdir_fullpath=$1

	#echo "test_subdir_fullpath is set to: $test_subdir_fullpath"

	if [ -d "$test_subdir_fullpath" ] && cd "$test_subdir_fullpath" 2>/dev/null
	then
		# directory file found and accessible
		echo "directory "$test_subdir_fullpath" found and accessed ok" && echo
		test_result=0
	elif [ -d "$test_subdir_fullpath" ] ## 
	then
		# directory file found BUT NOT accessible CAN'T RECOVER FROM THIS
		echo "directory "$test_subdir_fullpath" found, BUT NOT accessed ok" && echo
		test_result=1
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_FILE_NOT_ACCESSIBLE"
		return $E_FILE_NOT_ACCESSIBLE
	else
		# -> directory not found: THIS CAN BE RESOLVED BY CREATING THE DIRECTORY
		test_result=1
		echo "Returning from function \"${FUNCNAME[0]}\" with test result code: $E_REQUIRED_FILE_NOT_FOUND"
		return $E_REQUIRED_FILE_NOT_FOUND
	fi

	#echo && echo "LEAVING FROM FUNCTION ${FUNCNAME[0]}" && echo

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

# NOTES:
# ======
# NOTE: jq does not handle hyphenated filter argument quoting and faffing. Think I read something about that
# in the docs. Better to just use camelCased JSON property names universally.
