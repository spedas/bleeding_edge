#include "frame_dcm.h"

#include "wind_pk.h"
#include "string.h"

/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_frame_struct(packet_selector *pks, struct frameinfo_def *frm)
{
    packet *pk;
    
    pk = get_packet(pks);

    if(pk == 0)
    	return(0);
    	
    if(!(pk->quality & (~pkquality))){
	memcpy(frm,pk->data,FRAME_INFO_SIZE);
	return(1);
    }
    else{
    	if(pk->quality & (~pkquality))
    		frm->time = pk->time;
	return(0);
    }

}



int number_of_frame_samples(double t1,double t2)
{
	return(number_of_packets(FRM_INFO_ID,t1,t2));
}


/* Interface routine to IDL */
int  frame_info_to_idl(int argc,void *argv[])
{
	int i,n;
	static frameinfo *frm;
        int size;
        packet_selector pks;

	if(argc == 0)
		return( number_of_frame_samples( 0.,1e12) );
	if(argc != 3){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}


        n    = * ((int4 *)argv[0]);
        size = * ((int4 *)argv[1]);
        frm = (frameinfo *)argv[2];
        if(size != sizeof(frameinfo)){
            printf("Incorrect stucture size.  IDL:%d  C:%d   Aborting.\r\n",
                 size,sizeof(frameinfo));
            return(0);
        }


        for(i=0;i<n;i++){
            SET_PKS_BY_INDEX(pks,i,FRM_INFO_ID);
            get_next_frame_struct(&pks,frm);
            frm++;
        }
        return(n);
}

