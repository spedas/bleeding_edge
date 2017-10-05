/*
 *  Title: makemastfile.c
 *
 *  Usage: makemastfile foo1.cdf foo2.cdf foo3.cdf ...
 *
 *  Purpose: writes to stdout an ascii file containing one line per input argument:
 *               start_date_and_time   end_date_and_time   filename   number_of_records
 *           Expects that each input arg is the name of a CDF file that contains a
 *           CDF variable named 'Epoch'.  Reads the times associated with the first
 *           and last records in the file, and counts the number of records in the file.
 *           Typical use is to create a mastfile for a given set of CDF files.
 *
 *  Author: Vince Saba (code is a simplified version of the "kpdfile" program, taken from
 *          "kpdfile.c", "cdf_time.c", and parts of "windmisc.c" from the WIND software)
 *
 *  Version: @(#)makemastfile.c	1.2 01/17/97
 */

static char SccsId_makemastfile_c[] = "@(#)makemastfile.c	1.2 01/17/97 UCB SSL";

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <cdf.h>

int get_start_and_end_times(char *filename, double *starttime, double *endtime, int *nrecords);

void epoch_to_str(double epoch, char *date);


main(int argc, char *argv[])
{
    char *filename;
    double starttime;
    double endtime;
    char startdate[100];
    char enddate[100];
    int nrecords;
    int n;

    if (argc < 2)
    {
	fprintf(stderr, "Usage: makemastfile path/file1 path/file2 ...\n");
        return(1);
    }

    /* Loop over all input files, writing out filename, startdate, enddate, and num records */
    for (n = 1; n < argc; n++)
    {
	filename = argv[n];

	if (get_start_and_end_times(filename, &starttime, &endtime, &nrecords) == 1)
	{
	    epoch_to_str(starttime, startdate);
	    epoch_to_str(endtime, enddate);
	    printf("%s %s  %s  %d\n", startdate, enddate, filename, nrecords);
	}
    }
    return(1);
}


/* get the starttime, endtime, and number of records for the specified CDF file */
int get_start_and_end_times(char *filename, double *starttime, double *endtime, int *nrecords)
{
    int          i;
    CDFstatus    cstatus;
    CDFid        cid;
    long         version;
    long         release;
    char         copyRight[CDF_COPYRIGHT_LEN+1];
    long         numDims;
    long         dimSizes[CDF_MAX_DIMS];
    long         encoding;
    long         majority;
    long         maxRec;
    long         numVars;
    long         numAttrs;
    long         varEpoch;
    static long  indices[10] = {0,0,0,0,0,0,0,0,0,0};
    CDFstatus    rstat;
    char         pathname[500];
    char         *cptr;
    int          epoch_is_rvar = -1;
    char         error_message[100];

    /* Remove any trailing ".cdf", ".CDF", ".Cdf" extensions */
    (void) strncpy(pathname, filename, 256);
    i = strlen(pathname);
    cptr = pathname + i - 4;
    if (!strcmp (cptr, ".cdf") || !strcmp (cptr, ".CDF") || !strcmp (cptr, ".Cdf"))
    {
	*cptr = '\0';
    }

    /* Open the file as a CDF file */
    cstatus = CDFopen (pathname, &cid);

    if (cstatus != CDF_OK)
    {
	if (cstatus < CDF_WARN)
	{
            fprintf(stderr, "Unable to open CDF file: %s (%s)\n", filename, pathname);
            fprintf(stderr, "status = %ld\n", cstatus);
            CDFerror(cstatus, error_message);
            fprintf(stderr,"%s\n", error_message);
            return(-1);
	}
	else
	{
	       /*  Let's ignore non-error warning messages here for now, at Davin's request.
            CDFerror(cstatus, error_message);
            fprintf(stderr, "%s  ", error_message);
            fprintf(stderr, "This is a warning only, continuing...\n");
		*/
	}
    }

    /* Get the version, etc */
    cstatus = CDFdoc (cid, &version, &release, copyRight);

    if (cstatus != CDF_OK)
    {
        fprintf(stderr, "Error in CDFdoc: filename = %s, cstatus= %ld \n", filename, cstatus);
        cstatus = CDFclose(cid);
        return(-1);
    }

    /* test whether Epoch is an r variable or z variable */
    cstatus = CDFlib(CONFIRM_, rVAR_EXISTENCE_, "Epoch", NULL_);
    if (cstatus >= CDF_WARN)
    {
	/* In this case, Epoch is an r variable */
	epoch_is_rvar = 1;
        varEpoch = CDFvarNum(cid, "Epoch");
	if (varEpoch < 0)
	{
	    fprintf(stderr, "Error: filename = %s, could not get rvar number for 'Epoch'.\n",
		filename);
            cstatus = CDFclose(cid);
	    return(-1);
	}

        cstatus = CDFinquire (cid, &numDims, dimSizes, &encoding, &majority,
	    &maxRec, &numVars, &numAttrs);
        if (cstatus != CDF_OK)
        {
            fprintf(stderr, "Error in CDFinquire: filename = %s, cstatus= %ld \n",
		filename, cstatus);
            cstatus = CDFclose(cid);
            return(-1);
        }
        if (maxRec < 0)
        {
            fprintf(stderr, "Number records: %d is too small in file: %s\n", maxRec,filename);
            cstatus = CDFclose(cid);
            return(-1);
        }
	*nrecords = (int) (maxRec + 1);
        rstat = CDFvarGet (cid, varEpoch, (long) 0, indices, starttime);
        rstat = CDFvarGet (cid, varEpoch, (long) maxRec, indices, endtime);
    }
    else
    {
	/* In this case, Epoch is a z variable */
        cstatus = CDFlib(CONFIRM_, zVAR_EXISTENCE_, "Epoch", NULL_);
	if (cstatus >= CDF_WARN)
	{
	    epoch_is_rvar = 0;
	    cstatus = CDFlib(SELECT_, zVAR_NAME_, "Epoch", NULL_);
	    if (cstatus != CDF_OK)
	    {
	        fprintf(stderr,"Error: filename = %s, could not find zvar 'Epoch'.\n",
		    filename);
                cstatus = CDFclose(cid);
	        return(-1);
	    }
	    cstatus = CDFlib(SELECT_, zVAR_RECNUMBER_, 0, 
			     GET_, zVAR_DATA_, starttime,
			     NULL_);
	    if (cstatus != CDF_OK)
	    {
	        fprintf(stderr, "Error: filename = %s,", filename);
		fprintf(stderr, " could not get first time record of zvariable 'Epoch'.\n");
                cstatus = CDFclose(cid);
	        return(-1);
	    }
	    cstatus = CDFlib(GET_, zVAR_MAXREC_, &maxRec, NULL_);
	    if (cstatus != CDF_OK)
	    {
		fprintf(stderr, "Error: filename = %s,", filename);
		fprintf(stderr, " could not get number of records for zvar 'Epoch'.\n");
                cstatus = CDFclose(cid);
		return(-1);
	    }
	    *nrecords = (int) (maxRec + 1);
	    cstatus = CDFlib(SELECT_, zVAR_RECNUMBER_, maxRec,
			     GET_, zVAR_DATA_, endtime, 
			     NULL_);
	    if (cstatus != CDF_OK)
	    {
	        fprintf(stderr, "Error: filename = %s,", filename);
		fprintf(stderr, " could not get last time record of zvariable 'Epoch'.\n");
	        return(-1);
	    }
	}
    }
    if (epoch_is_rvar == -1)
    {
        fprintf(stderr, "Error: filename = %s,", filename);
	fprintf(stderr, " could not find either rvar or zvar named 'Epoch'.\n");
	return(-1);
    }

    cstatus = CDFclose(cid);
    return(1);
}


void epoch_to_str(double epoch, char *date)
{
    long year;
    long month;
    long day;
    long hour;
    long minute;
    long second;
    long msec;

    EPOCHbreakdown(epoch, &year, &month, &day, &hour, &minute, &second, &msec);
    sprintf(date,"%4d-%02d-%02d/%02d:%02d:%02d",year,month,day,hour,minute,second);
}
