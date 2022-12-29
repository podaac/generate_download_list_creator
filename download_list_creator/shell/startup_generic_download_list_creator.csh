#!/bin/csh
#
#  Copyright 2017, by the California Institute of Technology.  ALL RIGHTS
#  RESERVED. United States Government Sponsorship acknowledged. Any commercial
#  use must be negotiated with the Office of Technology Transfer at the
#  California Institute of Technology.
#
# $Id$
# DO NOT EDIT THE LINE ABOVE - IT IS AUTOMATICALLY GENERATED BY CM
#
#
# This is the C-shell wrapper to create download list from OBPG due to the "Recent" interface disappearing.
#
# It will usually be ran as part of a crontab but can also be called directly.
#
# The log files created will be in directory $HOME/logs with the extension .log
#
################################################################################################################################################################

# Set the environments.
source /app/config/download_list_creator_config    # NET edit. (Docker container)

# By default, the output of this C-shell script will go to a log file defined in downloader_log_name variable below.  If you want to see the log file as it is running, the following can be set:
#
setenv SHOW_LOGGING_TO_TERMINAL false    # NET edit.

set show_logging = 0
if ($?SHOW_LOGGING_TO_TERMINAL) then
    if $SHOW_LOGGING_TO_TERMINAL == "true" then
        set show_logging = 1
    endif
endif

# The below setting prints out some debug statements from this C-shell
set debug_mode = 1

# Get the input.
set num_args = $#

# Some example for crawling for new naming convention if GHRSST_OBPG_USE_2019_NAMING_PATTERN is set to true:

# source startup_generic_download_list_creator.csh 'SST.|SST3.' /home/qchau/scratch/viirs_level2_download_list/     VIIRS    L2  /home/qchau/scratch/viirs_level2_download_list/viirs_daily_current_state 5 dummy dummy GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE

# This below should pick up old OC and new OC format.  This filter should work when they start producing new OC format for MODIS Aqua. 
#
# source startup_generic_download_list_creator.csh 'L2.SST4.|L2.SST.|L2.OC.|L2_LAC_OC.' /home/qchau/scratch/modis_level2_download_list/  MODIS_A  L2  /home/qchau/scratch/modis_level2_download_list/modis_aqua_level2_daily_current_state  5 dummy dummy GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE

# This below should pick up old OC and new OC format.  This filter should work when they start producing new OC format for MODIS Terra. 
#
# source startup_generic_download_list_creator.csh 'L2.SST4.|L2.SST.|L2.OC.|L2_LAC_OC.' /home/qchau/scratch/modis_level2_download_list/  MODIS_T  L2  /home/qchau/scratch/modis_level2_download_list/modis_terra_level2_daily_current_state  5 dummy dummy GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE


if ($# < 6) then
    echo $#
    echo "startup_generic_download_list_creator:Usage:"
    echo ""
    echo "    source startup_generic_download_list_creator.csh search_pattern output_directory                                    processing_type processing_level state_file_name  num_days_back"
    echo "    source startup_generic_download_list_creator.csh '_SST.|_SST3.' /home/qchau/scratch/viirs_level2_download_list/     VIIRS    L2  /home/qchau/scratch/viirs_level2_download_list/viirs_daily_current_state              1"
    echo "    source startup_generic_download_list_creator.csh 'SST.|SST3.' /home/qchau/scratch/viirs_level2_download_list/     VIIRS    L2  /home/qchau/scratch/viirs_level2_download_list/viirs_daily_current_state              1"
    echo "    source startup_generic_download_list_creator.csh 'L2_LAC_SST4.|L2_LAC_SST.|L2_LAC_OC.' /home/qchau/scratch/modis_level2_download_list/  MODIS_A  L2  /home/qchau/scratch/modis_level2_download_list/modis_aqua_level2_daily_current_state  1"
    echo "    source startup_generic_download_list_creator.csh 'L2.SST4.|L2.SST.|L2.OC.|L2_LAC_OC.' /home/qchau/scratch/modis_level2_download_list/  MODIS_A  L2  /home/qchau/scratch/modis_level2_download_list/modis_aqua_level2_daily_current_state  1"
    echo "    source startup_generic_download_list_creator.csh 'L2_LAC_SST4.|L2_LAC_SST.|L2_LAC_OC.' /home/qchau/scratch/modis_level2_download_list/  MODIS_T  L2  /home/qchau/scratch/modis_level2_download_list/modis_terra_level2_daily_current_state 1"
    echo "    source startup_generic_download_list_creator.csh 'DAY_SST|DAY_NSST|8D_SST|8D_NSST|MO_SST|MO_NSST|YR_SST|YR_NSST|DAY_CHL_chlor_a|MO_CHL_chlor_a'  /home/qchau/scratch/modis_level3_download_list/     MODIS_A  L3m /home/qchau/scratch/modis_level3_download_list/modis_aqua_level3_daily_current_state  1"
    echo "    source startup_generic_download_list_creator.csh 'DAY_SST|DAY_NSST|8D_SST|8D_NSST|MO_SST|MO_NSST|YR_SST|YR_NSST|DAY_CHL_chlor_a|MO_CHL_chlor_a'  /home/qchau/scratch/modis_level3_download_list/     MODIS_A  L3m dummy_state dummy_days_back '2016-12-08' '2016-12-08'"
    echo "    source startup_generic_download_list_creator.csh 'DAY_SST|DAY_NSST|8D_SST|8D_NSST|MO_SST|MO_NSST|YR_SST|YR_NSST|DAY_CHL_chlor_a|MO_CHL_chlor_a'  /home/qchau/scratch/modis_level3_download_list/     MODIS_T  L3m /home/qchau/scratch/modis_level3_download_list/modis_terra_level3_daily_current_state 1"
    echo "    source startup_generic_download_list_creator.csh 'DAY_SST|DAY_NSST|8D_SST|8D_NSST|MO_SST|MO_NSST|YR_SST|YR_NSST|DAY_CHL_chlor_a|MO_CHL_chlor_a'  /home/qchau/scratch/modis_level3_download_list/     MODIS_T  L3m dummy_state dummy_days_back '2016-12-08' '2016-12-08'"
    exit
endif

# Some notes about the search_pattern parameter.
#
# 1.  It should be enclosed with single or double quotes.
# 2.  The '|' symbol is the OR logic.
# 3.  The '.' dot in the pattern is the wild card for 1 character.
#
# The parameters for startup_generic_download_list_creator.csh are:
#
#  search_pattern   = $1  Usually ''_SST.|_SST3.' for VIIRS, '_SST4_|SST_' for MODIS_A and MODIS_T and 'L3m' for AQUARIUS
#  output_directory = $2  Where the download list will be saved to.  Make sure you have write permission to this directory.
#  processing_type  = $3  {VIIRS,MODIS_A,MODIS_T,AQUARIUS}
#  processing_level = $4  {L2,L3m,L3b}
#  state_file_name  = $5  How the script know files it has seen before by saving the state of previous query.
#  num_days_back    = $6  How many days ago of file processing time do you want?  If just starting out, run it with 3 or 4 manually and then reduced to 1 as part of the crontab when all files have been processed.
#
# For fetching specific granule start and end dates, we have provided 2 optional parameters.  Which means the parameters state_file_name and num_days_back will not be used so any dummy parameters can be entered.
#
#  granule_start_date = $7
#  granule_end_date   = $8
#
# The format of the fields are 'yyyy-mm-dd' as in:
#
#     '2015-06-01'
#     '2015-06-07'"
# to get granules with start time on June 1, 2015 and stop time the end of June 7, 2015.

# REMOVE FOR DOCKER CONTAINER
if ($debug_mode == 1) then
    echo "num_args $num_args"
    echo "arg_1 [$1]"
    echo "arg_2 [$2]"
    echo "arg_3 [$3]"
    echo "arg_4 [$4]"
    echo "arg_5 [$5]"
    echo "arg_6 [$6]"
    if ($num_args >= 8) then
        echo "arg_7 [$7]"
        echo "arg_8 [$8]"
    endif
endif

# Fetch the optional granule start and end dates.
set granule_start_date = ""
set granule_end_date   = ""
if ($num_args >= 8) then
    set granule_start_date = $7
    set granule_end_date   = $8
endif

# Check for optional parameter to look for new names format.
if ($num_args >= 9) then
echo "9 [$9]"
    if $9 == 'GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE' then
       echo "9 is GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE, setting GHRSST_OBPG_USE_2019_NAMING_PATTERN to true"
       setenv GHRSST_OBPG_USE_2019_NAMING_PATTERN true
echo "GHRSST_OBPG_USE_2019_NAMING_PATTERN [$GHRSST_OBPG_USE_2019_NAMING_PATTERN]"
    endif
    # Set granule_start_date and granule_end_date back to empty string.
    if $granule_start_date == 'dummy' then
        set granule_start_date = ""
    endif
    if $granule_end_date == 'dummy' then
        set granule_end_date = ""
    endif
endif

# Check if a flag indicating using 2019 naming pattern

set num_lines_of_USE_2019_NAMING_PATTERN = `printenv | grep GHRSST_OBPG_USE_2019_NAMING_PATTERN | wc -l`

echo "num_lines_of_USE_2019_NAMING_PATTERN [$num_lines_of_USE_2019_NAMING_PATTERN]"
set value_of_USE_2019_NAMING_PATTERN = ""
echo "value_of_USE_2019_NAMING_PATTERN [$value_of_USE_2019_NAMING_PATTERN]"

#if (! $?use_2019_naming_pattern_flag) then
if ($num_lines_of_USE_2019_NAMING_PATTERN > 0) then
    echo "value_of_USE_2019_NAMING_PATTERN is indeed set to [$value_of_USE_2019_NAMING_PATTERN]"
    set value_of_USE_2019_NAMING_PATTERN = `printenv | grep GHRSST_OBPG_USE_2019_NAMING_PATTERN | awk -F= '{print $2}'`
    echo "value_of_USE_2019_NAMING_PATTERN [$value_of_USE_2019_NAMING_PATTERN]"
else
    echo "USE_2019_NAMING_PATTERN is not set yet"
    set value_of_USE_2019_NAMING_PATTERN = "" 
    echo "value_of_USE_2019_NAMING_PATTERN [$value_of_USE_2019_NAMING_PATTERN]"
endif

# Note:  We have to enclose the search_pattern value in quotes since the '|' will confuse the command intepreter as a pipe if no quotes are surrounding it.

set search_pattern   = "$1"
set output_directory = $2
set processing_type  = $3
set processing_level = $4
set state_file_name  = $5
set num_days_back    = $6
set granule_start_date = $7
set granule_end_date   = $8

# Fetch the optional granule start and end dates.
set granule_start_date = ""
set granule_end_date   = ""
if ($num_args >= 8) then
    set granule_start_date = $7
    set granule_end_date   = $8
endif

# Check for optional parameter and set to blanks if the dates parameters are dummy.
if ($num_args >= 9) then
    # Set granule_start_date and granule_end_date back to empty string.
    if $granule_start_date == 'dummy' then
        set granule_start_date = ""
    endif
    if $granule_end_date == 'dummy' then
        set granule_end_date = ""
    endif
endif

#echo "value_of_USE_2019_NAMING_PATTERN [$value_of_USE_2019_NAMING_PATTERN]"
#exit

# Set the filter of files we wish to get from OBPG based on the processing_type.
# The Python script needs both of these settings to know which file names it should retrieve and where to put the download list to.
setenv CRAWLER_SEARCH_FILE_PATTERN "$search_pattern"
# Set the output directory for the lists.  Default is ./
setenv CRAWLER_SEARCH_DEFAULT_OUTPUT_DIRECTORY $output_directory

if ($debug_mode == 1) then
    echo "CRAWLER_SEARCH_FILE_PATTERN             " "$CRAWLER_SEARCH_FILE_PATTERN"
    echo "CRAWLER_SEARCH_DEFAULT_OUTPUT_DIRECTORY "  $CRAWLER_SEARCH_DEFAULT_OUTPUT_DIRECTORY
    echo "search_pattern                          " "$search_pattern"
    echo "state_file_name                         " $state_file_name
    echo "granule_start_date                      " $granule_start_date
    echo "granule_end_date                        " $granule_end_date
endif

# Create the $HOME/logs directory if it does not exist yet
set logging_dir = `printenv | grep OBPG_DOWNLOAD_LIST_CREATOR_LOGGING | awk -F= '{print $2}'`
echo "LOGGING: " "$logging_dir"
if (! -e $logging_dir) then    # NET edit.
    mkdir $logging_dir    # NET edit.
endif

set log_top_level_directory = $logging_dir    # NET edit.

# Get today's date so we can name our log file.
# The format will be mm_dd_yy_HH_MM as in 09_19_12_16_02
# The touch command is to create an empty file if it does not exist yet.

# Note: This date is to be Pacific Time.
setenv TZ PST8PDT
set today_date = `date '+%m_%d_%y_%H_%M'`

if ($processing_type == "VIIRS") then
   # Set the processing to lowercase "viirs"
   set actual_processing_type = "viirs"
   set actual_filter = "SNPP_VIIRS*202*"    # NET edit.
   echo "value_of_USE_2019_NAMING_PATTERN [$value_of_USE_2019_NAMING_PATTERN]"
   if ($value_of_USE_2019_NAMING_PATTERN == "true") then
       set actual_filter = "SNPP_VIIRS*202*.nc"
   endif
   if ($processing_level == "L2") then
       set name_snippet = "viirs_level2"
   endif
endif


if ($processing_type == "MODIS_A") then
   # Set the processing to lowercase "aqua"
   set actual_processing_type = "aqua"
   set actual_filter = "A*202*.nc"    # NET edit.
   if ($value_of_USE_2019_NAMING_PATTERN == "true") then
       set actual_filter = "A*202*.nc"
   endif
   set name_snippet = "modis_aqua"
   if ($processing_level == "L2") then
       set name_snippet = "modis_level2_aqua"
   endif
   if ($processing_level == "L3") then
       set name_snippet = "modis_level3_aqua"
   endif
   if ($processing_level == "L3m") then
       set name_snippet = "modis_level3m_aqua"
   endif
   if ($processing_level == "L3b") then
       set name_snippet = "modis_level3b_aqua"
   endif

endif

if ($processing_type == "MODIS_T") then
   # Set the processing to lowercase "terra"
   set actual_processing_type = "terra"
   set actual_filter = "T*202*.nc";    # NET edit.
   if ($value_of_USE_2019_NAMING_PATTERN == "true") then
       set actual_filter = "T*202*.nc";
   endif
   set name_snippet = "modis_terra"
   if ($processing_level == "L2") then
       set name_snippet = "modis_level2_terra"
   endif
   if ($processing_level == "L3") then
       set name_snippet = "modis_level3_terra"
   endif
   if ($processing_level == "L3m") then
       set name_snippet = "modis_level3m_terra"
   endif
   if ($processing_level == "L3b") then
       set name_snippet = "modis_level3b_terra"
   endif

endif

if ($processing_type == "AQUARIUS") then
   # Set the processing to lowercase "aquarius"
   set actual_processing_type = "aquarius"
   set actual_filter = "Q2019*.bz2";
   set name_snippet = "aquarius"
   if ($processing_level == "L2") then
       set name_snippet = "aquarius_level2"
   endif
   if ($processing_level == "L3m") then
       set name_snippet = "aquarius_level3m"
   endif
   if ($processing_level == "L3b") then
       set name_snippet = "aquarius_level3b"
   endif
endif

# Reset the time zone back to GMT so we can have the correct current date when the Python script runs.
setenv TZ GMT

set digits_in_name = "0001"
set downloader_log_name = "$log_top_level_directory/$name_snippet""_${processing_type}_download_list_creator_output_${today_date}_list_${digits_in_name}.log"
if (-e $downloader_log_name) then
   rm -f $downloader_log_name
endif
touch $downloader_log_name
echo "downloader_log_name $downloader_log_name"
setenv TZ PST8PDT
echo 'create_generic_download_list:BEGIN_PROCESSING_TIME ' `date` | tee $downloader_log_name

# Now, we can call the Python script to do file search.
# Note that the value of $actual_filter has to be enclosed in double quotes as it may contain the '|' character which may confused the C-shell interpreter.

#echo "granule_start_date [$granule_start_date]\n"
#echo "granule_end_date   [$granule_end_date]\n"
#exit
set python_exe = `printenv | grep PYTHON3_EXECUTABLE_PATH | awk -F= '{print $2}'`    # NET edit.
if ($granule_start_date != "" && $granule_end_date != "") then
    echo "RUNNING_CREATE_GENERIC_DOWNLOAD_LIST_WITH_ACTUAL_START_AND_DATE"
    echo "$python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n $actual_processing_type -l $processing_level -t "  "'$actual_filter'" " -d 0 -f 1 -a 1 -c 1 -g daily -s $granule_start_date -e $granule_end_date -i $state_file_name"    # NET edit.
    # Reset the time zone back to GMT so we can have the correct current date when the Python script runs.
    setenv TZ GMT
    if $show_logging == 1 then
        $python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n "$actual_processing_type" -l "$processing_level" -t "$actual_filter" -d 0 -f 1 -a 1 -c 1 -g "daily" -s "$granule_start_date" -e "$granule_end_date" -i "$state_file_name"    # NET edit.
        setenv TZ PST8PDT
        echo 'create_generic_download_list:END_PROCESSING_TIME ' `date`
    else
        $python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n "$actual_processing_type" -l "$processing_level" -t "$actual_filter" -d 0 -f 1 -a 1 -c 1 -g "daily" -s "$granule_start_date" -e "$granule_end_date" -i "$state_file_name" | tee $downloader_log_name    # NET edit.
        setenv TZ PST8PDT
        echo 'create_generic_download_list:END_PROCESSING_TIME ' `date` | tee $downloader_log_name
    endif
else
    # If the granule_start_date and granule_start_date are empty string, we use the -b crawl_current to get files from a few days ago.
    echo "RUNNING_CREATE_GENERIC_DOWNLOAD_LIST_WITH_EMPTY_START_AND_DATE"
    echo "$python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n $actual_processing_type -l $processing_level -t " "'$actual_filter'" " -d 0 -f 1 -a 1 -c 1 -g daily -b crawl_current -i $state_file_name -z $num_days_back" | tee $downloader_log_name   # NET edit.
    # Reset the time zone back to GMT so we can have the correct current date when the Python script runs.
    setenv TZ GMT


    if $show_logging == 1 then
        $python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n "$actual_processing_type" -l "$processing_level "-t "$actual_filter" -d 0 -f 1 -a 1 -c 1 -g "daily" -b "crawl_current" -i "$state_file_name" -z "$num_days_back"    # NET edit.
        setenv TZ PST8PDT
        echo 'create_generic_download_list:END_PROCESSING_TIME ' `date`
    else
        $python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n "$actual_processing_type" -l "$processing_level" -t "$actual_filter" -d 0 -f 1 -a 1 -c 1 -g "daily" -b "crawl_current" -i "$state_file_name" -z "$num_days_back" | tee $downloader_log_name    # NET edit.
        echo "$python_exe $OBPG_RUNENV_PYTHON_HOME/create_generic_download_list.py -n $actual_processing_type -l $processing_level -t "$actual_filter" -d 0 -f 1 -a 1 -c 1 -g daily -b crawl_current -i $state_file_name -z $num_days_back | tee $downloader_log_name"    # NET edit.
        setenv TZ PST8PDT
        echo 'create_generic_download_list:END_PROCESSING_TIME ' `date` | tee $downloader_log_name
    endif
endif
setenv TZ GMT
exit(1)