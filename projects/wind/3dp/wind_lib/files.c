




int determine_3dpfile_times(char *filename,double *begin_time,double *end_time)
{
	FILE *fp;
	int n;
	file_info file;

	fp = fopen(filename,"rb");
	if(fp==0){
		fprintf(stderr,"File %s not found!\n",filename);
		return(0);
	}

	determine_file_type(fp,&file); /* file pointer left at beginning of 1st rec */
	
	if(file.file_type == FILE_INVALID){
		fclose(fp);
		fprintf(stderr,"File %s is not a WIND-3DP data file!\n",
filename);
		return(0);
	}
	if(file.file_type == FILE_GSE_HKP){
		fclose(fp);
		return(0);    /* housekeeping files no longer supported */
	}
	       /* determine time of first frame */
	n=fread((char*)recbuff,1,file.rcd_size,fp);
	frame.time = 0;
	set_frame_time(recbuff);
	*begin_time = frame.time;

		/* determine time of last frame */
	fseek(fp,-(long)file.rcd_size,SEEK_END);  /* set to last record */
	n=fread((char*)recbuff,1,file.rcd_size,fp);
	frame.time = 0;
	set_frame_time(recbuff);
	*end_time = frame.time;
	
	fclose(fp);
	return(file.file_type);
}




/*****************************************************************************
This subroutine determines file characteristics (hdr_size, rcd_size, etc.)
given a file pointer.  The file is left pointing to the first data record.
*****************************************************************************/
void determine_file_type(FILE *fp,file_info *file)
{
	int n;
	char hdr[300];
	int4 spacecraft_id,instrument_id,record_length;
	char spc_name[5];

	fseek(fp,0l,SEEK_SET);            /* set back to beginning */
	n = fread(hdr,1,300,fp);
	fseek(fp,0l,SEEK_SET);            /* set back to beginning */
	if(n==0){
		file->file_type = FILE_INVALID;        /* error */
		return;
	}
	if(memcmp(hdr,"NEWPKT",6)==0){            /* HKP file */
		file->file_type = FILE_GSE_HKP;
		return;
	}
	if(memcmp(hdr,"NEWFRAME",8)==0){        /* original version gse data */
		file->file_type=FILE_GSE_RAW;
		file->hdr_size = gse_header_size(hdr,300);
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NEWFR+TH",8)==0){  /* raw with thermister values*/
		file->file_type=FILE_GSE_THERM;
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NFRM/",5)==0){
		file->file_type = FILE_GSE_FLT;  /* flight version */
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NFNT/",5)==0){
		file->file_type = FILE_GSE_ENG;  /* flight version */
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	spacecraft_id = str_to_int4((uchar*)hdr);
	instrument_id = str_to_int4((uchar*)hdr+4);
	record_length = str_to_int4((uchar*)hdr+176);
	if(record_length ==0)
		record_length = NASA_REC_LEN;
	memcpy(spc_name,hdr+8,4);  spc_name[4]=0;
	if(spacecraft_id==25 && instrument_id==6) { /* WIND 3DP LZ data file */
		file->file_type = FILE_NASA_LZ;
		file->file_hdr_size = record_length;
		file->hdr_size      = NASA_HDR_LEN;
		file->rcd_size      = record_length;
		fseek(fp, (long) file->rcd_size, SEEK_SET);
		return;
	}
	if(spacecraft_id==0 && instrument_id==0) { /* WIND 3DP NRT data file */
		file->file_type = FILE_NRT_LZ;
		file->file_hdr_size = NASA_REC_LEN;
		file->hdr_size      = NASA_HDR_LEN;
		file->rcd_size      = NASA_REC_LEN;
		fseek(fp, (long) file->rcd_size, SEEK_SET);
		return;
	}
	file->file_type = FILE_INVALID;
}




/*  Used for GSE files only to determine the frame record header size */  
int gse_header_size(char *hdr,int n)  
{	
	int i,len;

	len = -1;               /* illegal header */
	for(i=0;i<n;i++){
		if(hdr[i]==':' && hdr[i+1]==':'){   /* NEW FORMAT  '::'  */
			len = i+2;
			break;
		}
	}

	if (i>=n){       /* OLD FORMAT HAS HEADER OF 10 OR 20  */
		if (hdr[18] == ':' && (hdr[19]==':' || hdr[19]==' '))
			len = 20; 
		else if (hdr[9] == ':')
			len = 10;
	}
	return(len);
}






/*------------------------------------------------------------------------------
|				SPACECRAFT_CLOCK()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function converts an 8-byte stream to the current data record header    |
| spacecraft clock time value (seconds since midnight).			       |
|									       |
| NOTES									       |
| -----									       |
| The conversion used is described in the "Data Format Control Document", page |
| 3-7 (March 1993).							       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| stream			input:  raw byte stream			       |
|									       |
| RETURN								       |
| ------								       |
| seconds								       |
|									       |
| AUTHOR								       |
| ------								       |
| Todd H. Kermit, January 31 1994					       |
|									       |
------------------------------------------------------------------------------*/

static double spacecraft_clock(uchar* stream)
    {
    double seconds;					/* decimal seconds    */
    uchar buf[8];					/* reverse byte stream*/
    uchar lsb;						/* least signif. byte */
    uchar msb;						/* most  signif. byte */
    uchar xsb;						/* extended byte      */
    int2  i;						/* generic counter    */
    int2  msec;						/* milli-seconds      */
    int2  usec;						/* micro-seconds      */
    int2  usec_tenths;					/* micro-seconds / 10 */
    int2  tjd;						/* trunc. Julian date */
    int4  sec;						/* seconds into day   */

									      /*
    Reverse the byte stream
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    for (i = 0; i < 8; i++)
        buf[i] = stream[7 - i];

									      /*
    Compute time values
    ~~~~~~~~~~~~~~~~~~~							      */

    usec_tenths = (int2) (buf[0] & 0x1f);

    msb  = (buf[1] >> 5) & 0x03;
    lsb  = (buf[1] << 3)  | (buf[0] >> 5);

    usec = (int2) ((msb << 8) + lsb);


    msb  = ((buf[3] << 1) & 0x02) | (buf[2] >> 7);
    lsb  = (buf[2] << 1) | (buf[1] >> 7);

    msec = (int2) ((msb << 8) + lsb);

    xsb  = (buf[5] >> 1) & 0x01;
    msb  = (buf[5] << 7) | (buf[4] >> 1);
    lsb  = (buf[4] << 7) | (buf[3] >> 1);

    sec  = (int4) ((xsb << 16) + (msb << 8) + lsb);

    msb  = (buf[6] >> 2);
    lsb  = (buf[6] << 6) | (buf[5] >> 2);

    tjd  = (int2) ((msb << 8) + lsb);		/* <---- NOT YET IMPLEMENTED  */

									      /*
    Compute decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    seconds = sec + (msec / 1000.) + (usec / 1.e+6) + (usec_tenths / 1.e+7);

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }


#define YEAR_START	1970			/* time zero (00:00:00) year  */


/*------------------------------------------------------------------------------
|				     ATC_CLOCK()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function converts a 16-byte (four 4-byte integers) stream containing the|
| Absolute Time Code (ATC) to time in units of seconds.			       |
|									       |
| NOTES									       |
| -----									       |
| The conversion used is described in the "Data Format Control Document", page |
|   3-8 (March 1993).							       |
| The ATC time is converted to seconds since January 1, 1900 (00:00:00).       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| byte				input:  raw byte stream			       |
|									       |
| RETURN								       |
| ------								       |
| seconds								       |
|									       |
| AUTHOR								       |
| ------								       |
| Todd H. Kermit, February 03 1994					       |
|									       |
------------------------------------------------------------------------------*/

static double atc_clock(uchar* byte)
    {
    double seconds;					/* decimal seconds    */
    int4  day;						/* day of year        */
    int4  msec;						/* milli-seconds      */
    int4  usec;						/* micro-seconds      */
    int4  year;						/* year    	      */

									      /*
    Swap bytes and load time values
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    year = str_to_int4(byte);
    day  = str_to_int4(byte+4);
    msec = str_to_int4(byte+8);
    usec = str_to_int4(byte+12);

    if(year<1970)
	year = 1970;
    if(year>2040)
	year = 2040;
    if(day<1)   day =1;
    if(day>366) day =1;

									      /*
    Compute decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    seconds = (double) ((msec / 1000.) + (usec / 1.e+6));

									      /*
    Convert to seconds since January 1, 1900 (00:00:00)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			      */

    seconds = seconds_since_year(YEAR_START, year, day-1, seconds);
          /* edited 9-14-94 to subtract 1 day */

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }

/*------------------------------------------------------------------------------
|			      SECONDS_SINCE_YEAR()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function computes the number of seconds between the input start year at |
| 00:00:00 and the input date/time (year, day-of-year, decimal seconds).       |
|									       |
| NOTES									       |
| -----									       |
| The date notation conforms to ASCII standards.			       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| year0			input:  start year				       |
| year			input:  year					       |
| yday			input:  day of year (0 - 365)			       |
| sec			input:  decimal seconds				       |			       |									       |
| RETURN								       |
| ------								       |
| seconds		total decimal seconds since start year		       |
|									       |
------------------------------------------------------------------------------*/

#define leap(y)	(!((y) % 4) && ((y) % 100) || !((y) % 400) && ((y) % 4000))

static double seconds_since_year(int4 year0, int4 year, int4 yday, double sec)
    {
    double seconds;					/* seconds since year0*/
    uint4 ndays = 0;					/* day number total   */
    int4  iyear = year0;				/* year value	      */

									      /*
    Compute number of days
    ~~~~~~~~~~~~~~~~~~~~~~						      */

    while (iyear < year)
	{
	ndays += (leap(iyear)) ? 366 : 365;
	iyear++;
	}

    ndays += yday;

									      /*
    Compute total decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    seconds = ndays * 86400 + sec;

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }


