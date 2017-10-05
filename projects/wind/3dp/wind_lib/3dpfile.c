#include "defs.h"
#include "windmisc.h"
#include "filter.h"

#include <stdio.h>
#include <string.h>

int make_extraction_file(double time);


main(int argc,char *argv[])
{
	char *filename;
	double t1,t2;
	double last_time;
	int type;
	int n;
	int nd;
	int com_flag;

	com_flag = 0;
	nd = 0;
	last_time = 0;

	if(argc <= 1){
		fprintf(stderr,"%s\n",argv[0]);
		fprintf(stderr,"Usage: %s path/file1 path/file2 ...\n",argv[0]);
		fprintf(stderr,"Purpose: prints file start time; end time; and file name to stdout\n");
		fprintf(stderr,"Typical usage: %s dirpath/*.dat | sort > mastfile\n",argv[0]);
	}

	for(n=1;n<argc;n++){

		filename = argv[n];
		if(strcmp(filename,"-nrt")==0){
			com_flag = 1;
			continue;
		}

		if(type = determine_3dpfile_times(filename,&t1,&t2) ){
			printf("%s",time_to_YMDHMS(t1));
			printf(" %s",time_to_YMDHMS(t2));
			printf("  %s (%d)\n",filename,type);
			if(t2>last_time)
				last_time = t2;
			nd++;
		}
	}
/*	fprintf(stderr,"%d data files found\n",nd); */
	if(com_flag)
		make_extraction_file(last_time+30.);
	return(0);
}



/* following routines are used for extracting NRT data */

/* time_to_VMS: returns a statically stored string that contains the time */
char *time_to_VMS(double time)
{
	static char buff[30];
	static char *months[] = {"JAN","FEB","MAR","APR","MAY","JUN","JUL",
                                 "AUG","SEP","OCT","NOV","DEC"};
	time_t t;
	struct tm *ts;

	t = time;
	ts = gmtime(&t);
	sprintf(buff,"%02d-%3s-%04d %02d:%02d:%02d", ts->tm_mday, months[ts->tm_mon], ts->tm_year+1900, ts->tm_hour, ts->tm_min, ts->tm_sec);
	return(buff);
}


/* time_to_filename: returns a filename that contains the time */
char *time_to_filename(double time)
{
	static char buff[30];
	time_t t;
	struct tm *ts;

	t = time;
	ts = gmtime(&t);
	sprintf(buff,"wi_lz_3dp_%04d%02d%02d_nrt.%02d%02d",ts->tm_year+1900,
           ts->tm_mon+1,ts->tm_mday, ts->tm_hour, ts->tm_min);
	return(buff);
}



int make_extraction_file(double time)
{
	FILE *fp;
	fp = fopen("extract.com","w");
	if(fp){
		fprintf(fp,"EXTRACT_NRT_LZ-\n");
		fprintf(fp,"/input=WIND_TL:[WIND_NRT.3DP]WI_LZ_3DP.NRT-\n");
		fprintf(fp,"/output=%s-\n",time_to_filename(time));
		fprintf(fp,"/start=\"%s\"\n",time_to_VMS(time));
		fclose(fp);
		return(1);
	}
	return(0);
}
