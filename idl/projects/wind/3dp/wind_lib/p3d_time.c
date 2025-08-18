
#include "p3d_dcm.h"

#include "wind_pk.h"
#include "map3d.h"
#include "pads_dcm.h"

/* routine to get an array of time points for a data quantity, */
/* given by PACKET_ID.  Time array must be pre-allocated to */
/* at lead max_array elements.  the return value will be */
/* number of points if successful, 0 if there is an error */
/* getting the packet list or if time_array is too small. */

int get_time_points(PACKET_ID pkid, int max_array, double * time_array)
{
    pklist *pkl;
    int i ;

    /* get the packet plist for pkid type */
    pkl = packet_type_ptr(pkid);
    if(pkl==0)
	return(0);

    for (i = 0; i < pkl->numarray && i < max_array; i ++)
	time_array[i] = (pkl->array[i])->time ;

    return(max_array < pkl->numarray ? 0 : i-1);

}

