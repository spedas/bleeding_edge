

#include "pAtoD_dcm.h"

#include <stdio.h>
#include <string.h>



/* this function fills the pAtoD structure */
int fill_pAtoD_struct(packet *pk,pAtoD_struct *pAtoD)
{
	uchar *u;

	if(pk==0)
		return(0);
		
	if(pk->quality & (~pkquality)){
		pAtoD->time = pk->time;
		return(0);
	}
	
	u = (uchar *)pk->data;
	pAtoD->time = pk->time;
	pAtoD->waves = str_to_int2(u +2*2);
	pAtoD->eesa_p5 = str_to_int2(u +2*22);
	pAtoD->cover = str_to_int2(u +2*25); 

	return(1);
}


/* Gets the next eesa_AtoD with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pAtoD_struct(packet_selector *pks, pAtoD_struct *pAtoD)
{
    packet *pk;
    
    pk = get_packet(pks);
    return( fill_pAtoD_struct(pk,pAtoD) );
}




/*  returns the number of eesa_AtoD 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pAtoD_samples(double t1,double t2)
{
	return(number_of_packets(P_A2D_ID,t1,t2));
}


/***************************************************************/
/* Printing routines */



FILE *pAtoD_fp;

int print_pAtoD_packet(packet *pk)
{
	static pAtoD_struct pAtoD;
	if(pAtoD_fp){
		fill_pAtoD_struct(pk,&pAtoD);
		print_pAtoD_struct(pAtoD_fp,&pAtoD);
		return(1);
	}
	return(0);
}

int print_pAtoD_struct(FILE *fp,  pAtoD_struct *pAtoD)
{
	if(fp==0)
		return(0);

	fprintf(fp,"%11.1f ",pAtoD->time);
	fprintf(fp," %5.0f", pAtoD->waves);
	fprintf(fp," %5.0f", pAtoD->eesa_p5);
	fprintf(fp," %5.0f", pAtoD->cover);
	fprintf(fp," `%s", time_to_YMDHMS(pAtoD->time));
	fprintf(fp,"\n");

	return(1);
}

