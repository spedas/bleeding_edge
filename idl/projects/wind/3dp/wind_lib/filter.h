#ifndef FILTER_H
#define FILTER_H

#include "defs.h"
#include "frame_dcm.h"

extern double cur_spin_period;

int load_all_data_files_p(char *mastfilename,double *begin, double *end, 
      int buffsize, void *buffptr);
int load_all_data_files(char *mastfilename,double begin, double end, 
      int buffsize, void *buffptr);
/*  This is the first subroutine that should be called.  It will load all
    data between time begin and end into the memory pointed to by buffptr 
    the times begin and end are total seconds since 1970. and can be
   determined using the subroutines YMDHMS_to_time() or MDYHMS_to_time() */



int determine_3dpfile_times(char *filename,double *begin_time,double *end_time);
/* This subroutine prints to stderr only if there is an error */
/* otherwise it fills the starting and ending times of the file */
/* and returns the file type  (0 on error)  */


#endif
