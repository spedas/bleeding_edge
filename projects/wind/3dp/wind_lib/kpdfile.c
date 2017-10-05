/*------------------------------------------------------------------------------
|
|				    kpdfile.c
|
|-------------------------------------------------------------------------------
|
| CONTENTS
| --------
| This program reads the specified WIND CDHF data files and writes the file name
| and the corresponding time span.
|
| AUTHOR
| ------
| Davin Larson, wrote original version 3dpfile for 3dp files
| Todd H. Kermit, converted 3dpfile program to read magnetic field instrument
| (mfi), 3DP (3dp) and SWE (swe) key parameter (kp) data files
|
------------------------------------------------------------------------------*/


/* Include files */

/*#include <defs.h> */
#include "windmisc.h"
#include "cdf_time.h"
#include <stdio.h>
#include <string.h>


/* Define local functions */

int determine_kpdfile_times(char* filename, double* t1, double* t2, int *nrecords);

/*------------------------------------------------------------------------------ */

main(int argc, char *argv[])
    {
    char *filename;					/* current filename */
    double t1, t2;					/* start and end times */
    double last_time;					/* previous time */
    int nrecords;
    int n;						/* file name counter */
    int nd;						/* number data files */


    /* Initialize */

    nd = 0;
    last_time = 0;


    /* Error handling */

    if (argc <= 1)
	{
	fprintf(stderr, "%s\n", argv[0]);
	fprintf(stderr, "Usage: %s path/file1 path/file2 ...\n", argv[0]);
	fprintf(stderr, "Purpose: prints file start time; end time; ");
	fprintf(stderr, "file name; and record count to stdout\n");
	fprintf(stderr, "Typical usage: %s dirpath/*.dat | sort > mastfile\n",
		argv[0]);
	}


    /* Loop over all files within specified time range and */
    /* write key parameter file header information to stdout */

    for (n = 1; n < argc; n++)
	{
	filename = argv[n];

	if (determine_kpdfile_times(filename, &t1, &t2, &nrecords))
	    {
	    fprintf(stdout, "%s", time_to_YMDHMS(t1));
	    fprintf(stdout, "  %s",time_to_YMDHMS(t2));
	    fprintf(stdout, "  %s", filename);
	    fprintf(stdout, "  %d\n", nrecords);
	    if(t2 > last_time) last_time = t2;
	    nd++;
	    }
	}


    /* Wrap up */

/*    fprintf(stderr, "%d data files found\n", nd); */

    return(0);
    }

/*------------------------------------------------------------------------------
|			    determine_kdpfile_time()	
|-------------------------------------------------------------------------------
|
| PURPOSE
| -------
| This routine calls GetWindKPTimeSpan() and converts the time values.
|
| ARGUMENTS
| ---------
| filename		input:  complete file name of KPD data file
| t1			output: start time in 
| t2			output: end time in 
| nrecords              output: number of records in the file
|
| RETURN
| ------
| 1 for success, 0 for error 
|
------------------------------------------------------------------------------*/

int determine_kpdfile_times(char* filename, double* time1, double* time2, int *nrecords)
    {
    struct tm t1, t2;					/* ANSI time structures */
    int SYear;						/* start year */
    int SMonth;						/* start month */
    int SDay;						/* start day */
    int SHour;						/* start hour */
    int SMinute;					/* start minute */
    int SSeconds;					/* start seconds */
    int SMsec;						/* start micro-seconds */
    int EYear;						/* end year */
    int EMonth;						/* end month */
    int EDay;						/* end day */
    int EHour;						/* end hour */
    int EMinute;					/* end minute */
    int ESeconds;					/* end seconds */
    int EMsec;						/* end micro-seconds */
    int status;						/* status flag */


    /* Get start and end times from file */

    status = GetWindKPTimeSpan(filename, &SYear, &SMonth, &SDay,
    			       &SHour, &SMinute, &SSeconds, &SMsec,
    			       &EYear, &EMonth, &EDay, &EHour, &EMinute,
    			       &ESeconds, &EMsec, nrecords);

    if (status != 0) return(0);


    /* Convert times to ANSI standards and store */

    t1.tm_year = SYear - 1900;
    t1.tm_mon  = SMonth - 1;
    t1.tm_mday = SDay;
    t1.tm_hour = SHour;
    t1.tm_min  = SMinute;
    t1.tm_sec  = SSeconds;
    t2.tm_year = EYear - 1900;
    t2.tm_mon  = EMonth - 1;
    t2.tm_mday = EDay;
    t2.tm_hour = EHour;
    t2.tm_min  = EMinute;
    t2.tm_sec  = ESeconds;


    /* Convert calendar time to GMT seconds */

    *time1 = (double)(mkgmtime(&t1)) + (double)(SMsec * 1.e-06);
    *time2 = (double)(mkgmtime(&t2)) + (double)(EMsec * 1.e-06);


    /* Done */

    return(1);
    }

