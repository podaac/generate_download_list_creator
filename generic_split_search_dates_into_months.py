#***************************************************************************
#
# Copyright 2017, by the California Institute of Technology. ALL
# RIGHTS RESERVED. United States Government Sponsorship acknowledged.
# Any commercial use must be negotiated with the Office of Technology
# Transfer at the California Institute of Technology.
#
# @version $Id$
#
#****************************************************************************
#
# Python script to split the search paramters into individual months between the start and end dates.

import os
import sys

def is_year_leap(the_year_start):
   o_year_is_leap_flag = 0;

   #  A year is a leap year if it is:
   #      divisible by 4
   #      but if it is divisible by 100 then it isn't
   #      unless it is divisible by 400
   #

   debug_module = "is_year_leap:";
   debug_mode  = 0;

   if ((the_year_start % 4) == 0):
        # divisible by 4
        if ((the_year_start % 100) == 0):
            # divisible by 100, 4
            if ((the_year_start % 400) == 0):
                if (debug_mode):
                    print(debug_module + "the_year_start",the_year_start,"is divisible by 4, 100 and 400.  It is indeed a leap year");
                # divisible by 4, 100 and 400, then a leap year.
                o_year_is_leap_flag = 1; # it is a leap year
            else:
                if (debug_mode):
                    print(debug_module + "the_year_start",the_year_start,"is divisible by 4, 100 but not 400.  It is not a leap year");
                # divisible by 4, and 100 but not by 400, then not a leap year.
                o_year_is_leap_flag = 0; # not a leap year
        else:
            # divisible by 4, and not divibble by 100 is a leap year.
            if (debug_mode):
                print(debug_module + "the_year_start",the_year_start,"is divisible by 4 but not divisible 100.  It is indeed a leap year.");
            o_year_is_leap_flag = 1; # it is a leap year
        # end if ((the_year_start % 100) == 0) 
   else:
       # not divisible by 4
       if (debug_mode):
           print(debug_module + "the_year_start",the_year_start,"is not divisible by 4");
       o_year_is_leap_flag = 0;

   return(o_year_is_leap_flag);


def generic_split_search_dates_into_months(i_search_sdate,i_search_edate):
    # Given a search start and end dates, function returns an array of start and end dates, broken up by months.
    # The first element of the o_search_sdates array will contain the search start date.
    # The last element of the o_search_edates array will contain the search end date. 
    # i_search_sdate    = ""  # "2015-01-01" (must be inside double quotes)
    # i_search_edate    = ""  # "2015-11-30" (must be inside double quotes)
    global g_debug_flag; # Make variable global.
    global g_trace_flag; # Make variable global.
    g_debug_flag = 0     # Change to 1 if want to see debug prints.
    g_trace_flag = 0     # Change to 1 if want to see trace prints.  Typically used by developer to see more of the under the hood.
    g_module_name = 'create_generic_download_list:'

    if (os.getenv("CRAWLER_SEARCH_DEBUG_FLAG") == "true"):
        g_debug_flag = 1
    if (os.getenv("CRAWLER_SEARCH_TRACE_FLAG") == "true"):
        g_trace_flag = 1

    o_search_sdates = [];
    o_search_edates = [];


    # Get the individual fields from "2015-01-01" as integer.
    the_year_start  = int(i_search_sdate[0:4]);
    the_month_start = int(i_search_sdate[5:7]);
    the_day_start   = int(i_search_sdate[8:10]);

    the_year_end  = int(i_search_edate[0:4]);
    the_month_end = int(i_search_edate[5:7]);
    the_day_end   = int(i_search_edate[8:10]);


    if (g_debug_flag):
        print("i_search_sdate", i_search_sdate);
        print("the_year_start", the_year_start);
        print("the_month_start", the_month_start);
        print("the_day_start", the_day_start);
        print("i_search_edate", i_search_edate);
        print("the_year_end", the_year_end);
        print("the_month_end", the_month_end);
        print("the_day_end", the_day_end);
#    sys.exit(0);

    # Do a sanity check if the end year is less than the start year.
    if (the_year_end < the_year_start):
        print("WARN: The end year",the_year_end,"in search parameter i_search_edate " + i_search_edate + " is earlier than i_search_sdate " + i_search_sdate);
        return(o_search_sdates,o_search_edates);


    #year_is_leap = is_year_leap(the_year_start);
    #if (g_debug_flag):
    #    print("the_year_start",the_year_start,"year_is_leap",year_is_leap)

    regular_days    = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    leap_days    = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];

    # The last day of each month is:
    #                                 1   2   3   4   5   6   7    8  9   10  11  12
    regular_last_days_of_the_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    leap_last_days_of_the_month    = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    # Loop from the_month_start through the_month_end

    done_flag = False;

    array_index = 0;
    start_year = the_year_start;
    start_month = the_month_start; 
    next_month = 0;

    first_date_flag = True; 
    while not done_flag:
        year_is_leap = is_year_leap(start_year);
        if (g_trace_flag):
            print("array_index",array_index,"start_year",start_year,"year_is_leap",year_is_leap);
        
        # If we are processing the first month, we use the date from the i_search_sdate, otherwise, set the date to the first date of the month.
        if (first_date_flag):
            o_search_sdates.append(str(start_year) + "-" + ("%02d" % start_month) + "-" + ("%02d" % the_day_start));
            first_date_flag = False;
        else:
            o_search_sdates.append(str(start_year) + "-" + ("%02d" % start_month) + "-" + "01");

        # If the month and year is the same as the month in i_search_edate, we just set the o_search_edates to that and be done
        if (start_month == the_month_end) and (start_year == the_year_end):
                o_search_edates.append(i_search_edate);
                done_flag = True;
        else:
            # We set the o_search_edates array differently depending on if the year is leap or not.
            if (year_is_leap):
                o_search_edates.append(str(start_year) + "-" + ("%02d" % start_month) + "-" + ("%02d" % leap_last_days_of_the_month[start_month-1]));
            else:
                o_search_edates.append(str(start_year) + "-" + ("%02d" % start_month) + "-" + ("%02d" % regular_last_days_of_the_month[start_month-1]));


        # Check to see if we are done, i.e. have processed up to the year and month of the i_search_edate input.
        if (g_trace_flag):
            print(" array_index",array_index,"start_year",start_year,"the_year_end",the_year_end,"start_month",start_month,"the_month_end",the_month_end);
        if (start_year >= the_year_end) and (start_month == the_month_end):
            done_flag = True;

        # Keep track how many times we have looped in this while loop.
        array_index += 1;

        # Bump to next month for the next iteration.
        start_month += 1;
        # If the start_month is 13, we know that we have crossed the year boundary.  Reset it back to 1 (for January) and increase the year to next year.
        if (start_month == 13):
            start_month  = 1;
            start_year  += 1; 
    # end while not done_flag:

    if (g_debug_flag):
        print("i_search_sdate",i_search_sdate);
        print("i_search_edate",i_search_edate);
        print("o_search_sdates",o_search_sdates);
        print("o_search_edates",o_search_edates);
        print("");
#    sys.exit(0);


    return(o_search_sdates,o_search_edates);


if __name__ == "__main__":

    search_sdate    = "2015-01-01"; # (must be inside double quotes)
    search_edate    = "2015-02-15"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "2015-01-01"; # (must be inside double quotes)
    search_edate    = "2016-01-15"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "2016-01-01"; # (must be inside double quotes)
    search_edate    = "2016-11-30"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);
#    sys.exit(0);

    search_sdate    = "2016-01-01"; # (must be inside double quotes)
    search_edate    = "2015-11-30"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "2018-01-01"; # (must be inside double quotes)
    search_edate    = "2018-11-30"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "2019-01-01"; # (must be inside double quotes)
    search_edate    = "2019-11-30"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "2020-01-01"; # (must be inside double quotes)
    search_edate    = "2015-11-30"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1200-01-01"; # (must be inside double quotes)
    search_edate    = "1200-03-04"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1201-01-01"; # (must be inside double quotes)
    search_edate    = "1201-02-03"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1202-01-01"; # (must be inside double quotes)
    search_edate    = "1202-03-06"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1700-01-01"; # (must be inside double quotes)
    search_edate    = "1700-03-08"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1900-01-01"; # (must be inside double quotes)
    search_edate    = "1900-04-16"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);

    search_sdate    = "1900-01-01"; # (must be inside double quotes)
    search_edate    = "1900-01-17"; # (must be inside double quotes)
    (o_search_sdates,o_search_edates) = generic_split_search_dates_into_months(search_sdate,search_edate);
