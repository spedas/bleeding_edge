/* VERSION:  @(#)scan_index.c	1.5:     @(#)scan_index.c	1.5 96/02/21 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "windmisc.h"
#include <time.h>

/* Usage:  scan_index index_file1 index_file2 index_file3 ... */

/* Some code stolen from Davin Larson's make_doc.c.
   fvm Wed Oct  4 10:55:44 PDT 1995 */

/* The purpose of this file is to check the master files for files with 
   duplicate or overlapping time ranges.  The names of the duplicate files
   with lower revision numbers will be reported.
   The master files are contained in ~wind/index.  Older revision files should
   be moved to the 'extra' directory.  
   The master files contain 3 to 4 fields: 
   date date filename [file_type]
   char date1[19], char date2[19], char filename[100], [ char file_type[4] ] 
   This program does not change the input files in any way or move any cdf 
   files.  It only reports duplications. */

/* Editing to check version number instead of order in index file.
   Version numbers can appear in formats:  "_v##.cdf", "yymmdd##" 
   Make sure not to confuse "yyyymmdd" with "yymmdd##"
   */

int get_ver(char[]);

main(int argc, char *argv[]){

  int i=0,j=0,num_files=0;          /*loop varaibles*/
  FILE *fp;                         /*file pointer*/
  char s[200];                      /*input buffer*/
  char *p;                          /*EOF test variable*/
  char *mdir[1];                    /*the directory to look in*/
  char date1[30];                   /*start date entry from the file*/
  char date2[30];                   /*end date entry from the file*/
  char fname[100], old_fname[100];  /*current and previous filename*/
  double time1;                     /*current file start time in seconds*/
  double time2;                     /*current file end time in seconds*/
  double old_time1=0;               /*previous file start time in seconds*/
  double old_time2=1;               /*previous file end time in seconds*/
  int ver=0,old_ver=0;              /*current and previous file versions*/
    
  mdir[0]="/disks/aeolus/disk1/wind/index/"; /*master file home*/ /*not used*/

  for(i=0;i<argc-1;i++){
    printf("File: %s\n",argv[i+1]);
    fp = fopen(argv[i+1], "r");
    if (fp==0) continue;
    old_time1=0;               /*backups*/
    old_time2=1;
    old_fname[0]=0;
    old_ver=0;
      while(p=fgets(s,200,fp))
      {
	sscanf(s,"%s %s %s",date1,date2,fname);
	if(s[0]=='#' || fname[0]=='#') 
	  continue;             /* comment line */
	time1 = YMDHMS_to_time(date1);
	time2 = YMDHMS_to_time(date2);
	ver=get_ver(fname);
	if (((time2-time1) > 3600) && (time1 > 3.155328e8)) {
	  if ((time1 <= old_time1) || (time2 <= old_time2)){
	    if ((ver > 0) && (old_ver > 0)) {
	      if (ver >= old_ver) printf("  %s\n",old_fname);
	      else printf("  %s\n",fname);
	    }
	  }
	  else if ((old_time1 <= time1) && (time1 < old_time2) && 
		   (time2 >= old_time2))
	    printf("  %s  partial overlap\n",old_fname);
	}
	for (j=0;j<200;j++) old_fname[j]=fname[j];
	old_time1=time1;
	old_time2=time2;
	old_ver=ver;
      }
    fclose(fp);
  }
}


int
get_ver(char fname[100]){
  int version;
  int junk;
  char *vpos, *onnpos, *dotpos, *npos;
  char strver[2];

  vpos   = strstr(fname, "_v"  );
  dotpos = strstr(fname, "."   );
  npos   = strstr(fname, "/9"  );

  if (vpos != NULL) {
    /* file contains _v## version signature */
    junk = sprintf(strver,"%c%c",*(vpos+2),*(vpos+3));
  }
  else if (dotpos == npos+9) { /* file contains yymmdd##. version signature */
    junk = sprintf(strver,"%c%c",*(dotpos-2),*(dotpos-1));
  }
  else {
    return(-1);
  }
  version = atoi(strver);
  return(version);
}
