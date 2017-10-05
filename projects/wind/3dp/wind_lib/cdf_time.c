/*------------------------------------------------------------------------------

Here is the routine which you can use to get the time span of a KP file.
Note that the only INPUT argument is "path", which is the full pathname
to the KP file you wish to query.  All of the other arguments are output
arguments.  EPOCH_breakdown function source code has been added to this
file.

Jack Vernetti, February 22 1995

------------------------------------------------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <math.h>
#include "cdf/include/cdf.h"

void EPOCH_breakdown (double *epoch, long *year, long *month, long *day,
     long *hour, long *minute, long *second, long *msec) ;

int GetWindKPTimeSpan (char *path, int *SYear, int *SMonth, int *SDay,
    int *SHour, int *SMinute, int *SSeconds, int *SMsec,
    int *EYear, int *EMonth, int *EDay, int *EHour, int *EMinute,
    int *ESeconds, int *EMsec, int *nrecords)
{
    int        i ;
    CDFstatus  cstatus ;
    CDFid      cid ;
    long       version ;
    long       release ;
    char       copyRight[CDF_COPYRIGHT_LEN+1] ;
    long       numDims ;
    long       dimSizes[CDF_MAX_DIMS] ;
    long       encoding ;
    long       majority ;
    long       maxRec ;
    long       numVars ;
    long       numAttrs ;
    long       varEpoch ;
    long       varGSMdec ;
    static long       indices[10] = {0,0,0,0,0,0,0,0,0,0};
    void       *vptr ;
    double     stime, etime ;
    long       syear, smon, sday, shour, sminute, ssecond, smsec ;
    long       eyear, emon, eday, ehour, eminute, esecond, emsec ;
    CDFstatus  rstat ;
    char       pathname[500] ;
    char       *cptr ;
    int        epoch_is_rvar = -1;
    char       error_message[100];

    /* Make sure that we don't pass the final ".cdf": */
    (void) strncpy (pathname, path, 256) ;
    i = strlen (pathname) ;
    cptr = pathname + i - 4 ;

    if (!strcmp (cptr, ".cdf") || !strcmp (cptr, ".CDF") ||
	!strcmp (cptr, ".Cdf"))
        {
	*cptr = '\0' ;
        }

    /* Open the file as a CDF file: */
    cstatus = CDFopen (pathname, &cid) ;

    if (cstatus != CDF_OK)
    {
	if (cstatus < CDF_WARN)
	{
            fprintf(stderr, "Unable to open CDF file: %s (%s)\n", path, pathname) ;
            fprintf(stderr, "status = %ld\n", cstatus);
            CDFerror(cstatus, error_message);
            fprintf(stderr,"%s\n", error_message);
            return (-1) ;
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

    /* Get the version, etc: */
    cstatus = CDFdoc (cid, &version, &release, copyRight) ;

    if (cstatus != CDF_OK)
       {
       fprintf (stderr, "Error in CDFdoc:  cstatus= %ld \n", cstatus) ;
       cstatus = CDFclose (cid) ;
       return (-1) ;
       }

    /* test whether Epoch is an r variable or z variable */
    cstatus = CDFlib(CONFIRM_, rVAR_EXISTENCE_, "Epoch", NULL_);
    if (cstatus >= CDF_WARN)
    {
	/* In this case, Epoch is an r variable */
	epoch_is_rvar = 1;
        varEpoch = CDFvarNum(cid, "Epoch") ;
	if (varEpoch < 0)
	{
	    fprintf(stderr, "Error: could not get rvar number for 'Epoch'.\n");
            cstatus = CDFclose(cid);
	    return(-1);
	}

        cstatus = CDFinquire (cid, &numDims, dimSizes, &encoding, &majority,
	    &maxRec, &numVars, &numAttrs) ;
        if (cstatus != CDF_OK)
        {
            fprintf (stderr, "Error in CDFinquire:  cstatus= %ld \n", cstatus) ;
            cstatus = CDFclose (cid) ;
            return (-1) ;
        }
        if (maxRec < 0)
        {
            fprintf(stderr, "Number records:  %d  is too small in file: %s\n", maxRec,path);
            cstatus = CDFclose(cid);
            return(-1);
        }
	*nrecords = (int) (maxRec + 1);
        rstat = CDFvarGet (cid, varEpoch, (long) 0, indices, &stime);
        rstat = CDFvarGet (cid, varEpoch, (long) maxRec, indices, &etime);
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
	        fprintf(stderr,"Error: could not find zvar 'Epoch'.\n");
                cstatus = CDFclose(cid);
	        return(-1);
	    }
	    cstatus = CDFlib(SELECT_, zVAR_RECNUMBER_, 0, 
			     GET_, zVAR_DATA_, &stime,
			     NULL_);
	    if (cstatus != CDF_OK)
	    {
	        fprintf(stderr,"Error: could not get starttime from zvariable 'Epoch'.\n");
                cstatus = CDFclose(cid);
	        return(-1);
	    }
	    cstatus = CDFlib(GET_, zVAR_MAXREC_, &maxRec, NULL_);
	    if (cstatus != CDF_OK)
	    {
		fprintf(stderr,"Error: could not get number of records in zvar 'Epoch'.\n");
                cstatus = CDFclose(cid);
		return(-1);
	    }
	    *nrecords = (int) (maxRec + 1);
	    cstatus = CDFlib(SELECT_, zVAR_RECNUMBER_, maxRec,
			     GET_, zVAR_DATA_, &etime, 
			     NULL_);
	    if (cstatus != CDF_OK)
	    {
	        fprintf(stderr,"Error: could not get endtime value for zvariable 'Epoch'.\n");
	        return(-1);
	    }
	}
    }
    if (epoch_is_rvar == -1)
    {
        fprintf(stderr, "Error: could not find either rvar or zvar named 'Epoch'.\n");
	return(-1);
    }

    EPOCH_breakdown (&stime, &syear, &smon, &sday, &shour,
	&sminute, &ssecond, &smsec) ;

    *SYear = (int) syear ;
    *SMonth = (int) smon ;
    *SDay = (int) sday ;
    *SHour = (int) shour ;
    *SMinute = (int) sminute ;
    *SSeconds = (int) ssecond ;
    *SMsec = (int) smsec ;

    EPOCH_breakdown (&etime, &eyear, &emon, &eday, &ehour,
	&eminute, &esecond, &emsec) ;

    *EYear = (int) eyear ;
    *EMonth = (int) emon ;
    *EDay = (int) eday ;
    *EHour = (int) ehour ;
    *EMinute = (int) eminute ;
    *ESeconds = (int) esecond ;
    *EMsec = (int) emsec ;

    cstatus = CDFclose (cid) ;

    return (0) ;
}

/* ---------------------------------------------------------------------- */
void EPOCH_breakdown (double *epoch, long *year, long *month, long *day,
    long *hour, long *minute, long *second, long *msec)
{
/* Taken from:  ../cdf21-dist/src/tools/epochu.c */
	long jd,i,j,k,l,n;
	double msec_AD, second_AD, minute_AD, hour_AD, day_AD;

	msec_AD = *epoch;
	second_AD = msec_AD / 1000.0;
	minute_AD = second_AD / 60.0;
	hour_AD = minute_AD / 60.0;
	day_AD = hour_AD / 24.0;

	jd = 1721060 + day_AD;
	l=jd+68569;
	n=4*l/146097;
	l=l-(146097*n+3)/4;
	i=4000*(l+1)/1461001;
	l=l-1461*i/4+31;
	j=80*l/2447;
	k=l-2447*j/80;
	l=j/11;
	j=j+2-12*l;
	i=100*(n-49)+i+l;

	*year = i;
	*month = j;
	*day = k;

	*hour   = fmod(hour_AD,   24.0);
	*minute = fmod(minute_AD, 60.0);
	*second = fmod(second_AD, 60.0);
	*msec   = fmod(msec_AD,   1000.0);
	return;
}  /* end EPOCH_breakdown */
