

#include "eAtoD_dcm.h"

#include <stdio.h>
#include <string.h>

/* this function fills the eAtoD structure */
int fill_eAtoD_struct(packet *pk,eAtoD_struct *eAtoD)
{
	uchar *u;
	
	eAtoD->valid = 0;
	
	if(pk==0)
		return(0);

	if(pk->quality & (~pkquality)){
		eAtoD->time = pk->time;
		return(0);
	}

	u = (uchar *)pk->data;
	eAtoD->time = pk->time;
	eAtoD->spin = pk->spin;
	eAtoD->MCP_low = str_to_int2(u +2*1)  * 1.71e-1 ;
	eAtoD->waves = str_to_int2(u +2*2)  * 2.96e-5  ;
	eAtoD->MCP_high = str_to_int2(u +2*3)  *1.72e-1;
	eAtoD->PMT = str_to_int2(u +2*5)  *5.79e-2;
	eAtoD->sweep_low = (str_to_int2(u +2*7)+28940 )  *1.745e-1;
	eAtoD->sweep_high = (str_to_int2(u +2*9)+28964 )  *2.178e-1;
	eAtoD->def_up = str_to_int2(u +2*11)  *1.74e-1;
	eAtoD->def_down = str_to_int2(u +2*13)  *1.74e-1;
	eAtoD->tp_0 = str_to_int2(u +2*15)  *4.01e-4;
	eAtoD->tp_1 = str_to_int2(u +2*17)  *4.16e-4;
	eAtoD->ref_plus = str_to_int2(u +2*19)  *1.74e-4;
	eAtoD->gnd_adc = str_to_int2(u +2*20)  *1.39e-4;
	eAtoD->ref_minus = str_to_int2(u +2*21)  *1.74e-4;
	eAtoD->eesa_p5 = str_to_int2(u +2*22)  *1.94e-4;
	eAtoD->boom_p5 = str_to_int2(u +2*23)  *1.74e-4;
	eAtoD->eesa_m5 = str_to_int2(u +2*24)  *1.87e-4;
	eAtoD->cover = str_to_int2(u +2*25)  *3.46e-5;
	eAtoD->eesa_p12 = str_to_int2(u +2*26)  *4.26e-4;
	eAtoD->boom_p12 = str_to_int2(u +2*27)  *4.20e-4;
	eAtoD->eesa_m12 = str_to_int2(u +2*28)  *4.23e-4;
	eAtoD->boom_m12 = str_to_int2(u +2*29)  *4.21e-4;
	eAtoD->eesa_ref = str_to_int2(u +2*30)  *1.74e-4;
	eAtoD->gnd_eesa = str_to_int2(u +2*31)  *1.39e-4;
	eAtoD->valid = 1;

	return(1);
}






/* Gets the next eesa_AtoD with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eAtoD_struct(packet_selector *pks, eAtoD_struct *eAtoD)
{
	static packet *pk;

	pk = get_packet(pks);
	return( fill_eAtoD_struct(pk,eAtoD) );
}


/*  returns the number of eesa_AtoD 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_eAtoD_samples(double t1,double t2)
{
	return(number_of_packets(E_A2D_ID,t1,t2));
}


/* Interface routine to IDL */
int  eAtoD_to_idl(int argc,void *argv[])
{
	int i,n;
	static eAtoD_struct *eAtoD;
        int size;
        packet_selector pks;

	if(argc == 0)
		return( number_of_eAtoD_samples( 0.,1e12) );
	if(argc != 3){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}


        n    = * ((int4 *)argv[0]);
        size = * ((int4 *)argv[1]);
        eAtoD = (eAtoD_struct *)argv[2];
        if(size != sizeof(eAtoD_struct)){
            printf("Incorrect stucture size.  IDL:%d    C:%d Aborting.\r\n",
                 size,sizeof(eAtoD_struct));
            return(0);
        }


        for(i=0;i<n;i++){
            SET_PKS_BY_INDEX(pks,i,E_A2D_ID);
            get_next_eAtoD_struct(&pks,eAtoD);
            eAtoD++;
        }
        return(n);
}





#if 0   /* OBSOLETE */
int fill_eAtoD_data(eAtoD_fill_str ptr)
{
	static eAtoD_struct eAtoD;
	double t;
	int n;
	static packet_selector  pks;

	n = 0;
	SET_PKS_BY_INDEX(pks,n,E_A2D_ID);
	while(get_next_eAtoD_struct(&pks,&eAtoD)){
		if(n >= ptr.num_samples)
			break;
		if(ptr.time)
			*(ptr.time++) = eAtoD.time;
		if(ptr.MCP_low)
			*(ptr.MCP_low++) = eAtoD.MCP_low;
		if(ptr.MCP_high)
			*(ptr.MCP_high++) = eAtoD.MCP_high;
		if(ptr.waves)
			*(ptr.waves++) = eAtoD.waves;
		if(ptr.sweep_low)
			*(ptr.sweep_low++) = eAtoD.sweep_low;
		if(ptr.sweep_high)
			*(ptr.sweep_high++) = eAtoD.sweep_high;
		if(ptr.def_up)
			*(ptr.def_up++) = eAtoD.def_up;
		if(ptr.def_down)
			*(ptr.def_down++) = eAtoD.def_down;
		if(ptr.PMT)
			*(ptr.PMT++) = eAtoD.PMT;
		n++;
		pks.index = n;
	}
	return(n);
}
#endif





/***************************************************************/
/* Printing routines */



FILE *eAtoD_fp;

int print_eAtoD_packet(packet *pk)
{
	static eAtoD_struct eAtoD;
	if(eAtoD_fp){
		fill_eAtoD_struct(pk,&eAtoD);
		print_eAtoD_struct(eAtoD_fp,&eAtoD);
		return(1);
	}
	return(0);
}

int print_eAtoD_struct(FILE *fp,  eAtoD_struct *eAtoD)
{
	if(fp==0)
		return(0);

	fprintf(fp,"%11.1f ",eAtoD->time);
	fprintf(fp," %5d",eAtoD->spin);
	fprintf(fp," %5.0f", eAtoD->waves);
	fprintf(fp," %5.0f", eAtoD->eesa_p5);
	fprintf(fp," %5.0f", eAtoD->cover);
	fprintf(fp," `%s", time_to_YMDHMS(eAtoD->time));
	fprintf(fp,"\n");

	return(1);
}

