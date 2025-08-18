/*------------------------------------------------------------------------------
|				      DCM_HKP				       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This module contains functions for loading WIND housekeeping values.         |
|									       |
| AUTHOR:								       |									       | -------								       |
| Todd H. Kermit, Space Sciencs Laboratory, U.C. Berkeley		       |
|	edited by Davin Larson						       |
------------------------------------------------------------------------------*/

/*Include header files
/*~~~~~~~~~~~~~~~~~~~~							      */

#include "hkp_dcm.h"
#include "tmp_dcm.h"   /*  temperature decomutation  */

#include <stdio.h>
#include <string.h>



/*Declare private functions
/*~~~~~~~~~~~~~~~~~~~~~~~~~						      */
/*  none  */




/* Gets the next hkpPktStruct with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_hkp_struct(packet_selector *pks, hkpPktStruct *hkp)
{
    packet *pk;
    
    pk = get_packet(pks);
    return(fill_hkp_struct(pk,hkp));

}


/*  returns the number of hkpPktStruct 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_hkp_samples(double t1,double t2)
{
	return(number_of_packets(HKP_ID,t1,t2));
}


/* Interface routine to IDL */
int  hkp_to_idl(int argc,void *argv[])
{
	int i,n;
        static hkpPktStruct *hkp,lasthkp;
        int size;
        packet_selector pks;

	if(argc == 0)
		return( number_of_hkp_samples( 0.,1e12) );
	if(argc != 3){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}


        n    = * ((int4 *)argv[0]);
        size = * ((int4 *)argv[1]);
        hkp = (hkpPktStruct *)argv[2];
        if(size != sizeof(hkpPktStruct)){
            printf("Incorrect stucture size.  Aborting.\r\n");
            return(0);
        }


        for(i=0;i<n;i++){
            SET_PKS_BY_INDEX(pks,i,HKP_ID);
            *hkp = lasthkp;
            if(get_next_hkp_struct(&pks,hkp) == 0) break;
            lasthkp = *hkp;
            hkp++;
        }
        return(n);
}








/* this function fills the hkp structure */
int fill_hkp_struct(packet *pk,hkpPktStruct *hkp)
{
	uchar *u;
	schar *s;

	if(pk==0){
		hkp->valid = 0;
		return(0);
	}
	s = (schar *)pk->data;
	u = (uchar *)pk->data;

	hkp->time = pk->time;
	hkp->errors = pk->errors;
	hkp->inst_mode =       u[0];
	hkp->mode =	      u[0] & 0x03;
	hkp->burst_stat =    ((u[0] >> 2) & 0x01);
	hkp->rate = 	     (u[0] >> 3) & 0x01;
	hkp->frame_seq =       u[1];
	hkp->offset =         (u[3]<<8)+u[2];
	hkp->spin =           (u[5]<<8)+u[4];
	hkp->phase =           u[7]>>4;
	hkp->magaz =         ((u[7]<<8)+u[6]) & 0x0fff;
	hkp->magel =           u[8];
	hkp->num_commands =    u[9];
	memcpy(hkp->lastcmd,u+10,5);
	hkp->main_version =    u[15];
	hkp->main_status =     u[16];
	hkp->main_last_error = u[17];
	hkp->main_num_errors = u[18];
	hkp->main_num_resets = u[19];
	hkp->main_burst_stat = u[20];
	hkp->fspin  =         (double)hkp->spin + ((double)hkp->phase)/16.;
	hkp->main_p5 =         s[21] * 1.89e-04 * 256;
	hkp->main_m5 =         s[22] * 1.89e-04 * 256;
	hkp->main_p12 =        s[23] * 4.26e-04 * 256;
	hkp->main_m12 =        s[24] * 4.19e-04 * 256;
	hkp->sst_p9 =          s[25] * 3.52e-04 * 256;
	hkp->sst_p5 =          s[26] * 1.87e-04 * 256;
	hkp->sst_m4 =          s[27] * 1.90e-04 * 256;
	hkp->sst_m9 =          s[28] * 3.47e-04 * 256;
	hkp->sst_hv =          s[29] * 1.18e-02 * 256;
	hkp->eesa_version =    u[30];
	hkp->eesa_status =     u[31];
	hkp->eesa_last_error = u[32];
	hkp->eesa_num_errors = u[33];
	hkp->eesa_num_resets = u[34];
	hkp->eesa_p5 =         s[35] * 1.74e-04 * 256;
	hkp->eesa_p12 =        s[36] * 4.20e-04 * 256;
	hkp->eesa_m12 =        s[37] * 4.21e-04 * 256;
	hkp->eesa_mcpl =       s[38] * 1.71e-01 * 256;
	hkp->eesa_mcph =       s[39] * 1.72e-01 * 256;
	hkp->eesa_pmt =        s[40] * 5.79e-02 * 256;
	hkp->eesa_swp =       (s[41] & 0x80) ? 1 : 0;
	if (hkp->eesa_swp)
		hkp->eesa_swph = (s[41] & 0x7f) * 2.178e-01 * 256;
	else 
		hkp->eesa_swpl = (s[41] & 0x7f) * 1.745e-01 * 256;
	hkp->pesa_version =    u[42];
	hkp->pesa_status =     u[43];
	hkp->pesa_last_error = u[44];
	hkp->pesa_num_errors = u[45];
	hkp->pesa_num_resets = u[46];
	hkp->pesa_p5 =         s[47] * 1.74e-04 * 256;
	hkp->pesa_p12 =        s[48] * 4.17e-04 * 256;
	hkp->pesa_m12 =        s[49] * 4.18e-04 * 256;
	hkp->pesa_mcpl =       s[50] * 1.72e-01 * 256;
	hkp->pesa_mcph =       s[51] * 1.74e-01 * 256;
	hkp->pesa_pmt =        s[52] * 5.80e-02 * 256;
	hkp->pesa_swp =       (s[53] & 0x80) ? 1 : 0;
	if (hkp->pesa_swp)
		hkp->pesa_swph =   (s[53] & 0x7f) * 3.14e-01 * 256;
	else
		hkp->pesa_swpl =   (s[53] & 0x7f) * 2.05e-01 * 256;
   /* Temperature data */
	hkp->eesa_temp =       raw_to_temperature(u[MAX_HKPBYTES]);
	hkp->pesa_temp =       raw_to_temperature(u[MAX_HKPBYTES+1]);
	hkp->sst1_temp =       raw_to_temperature(u[MAX_HKPBYTES+2]);
	hkp->sst3_temp =       raw_to_temperature(u[MAX_HKPBYTES+3]);
	hkp->valid = 1;

	return(1);
}





int fill_hkp_data(hkp_fill_str ptr)
{
	hkpPktStruct hkp;
	int n;
	packet_selector pks;

	n = 0;

	SET_PKS_BY_TIME(pks,0.,HKP_ID);
	while(get_next_hkp_struct(&pks,&hkp)){
		if(n >= ptr.num_samples)
			break;
		if(ptr.time)
			*(ptr.time++) = hkp.time;
		if(ptr.magel)
			*(ptr.magel++) = hkp.magel;
		if(ptr.magaz)
			*(ptr.magaz++) = hkp.magaz;
		if(ptr.eesa_temp)
			*(ptr.eesa_temp++) = hkp.eesa_temp;
		if(ptr.pesa_temp)
			*(ptr.pesa_temp++) = hkp.pesa_temp;
		if(ptr.sst1_temp)
			*(ptr.sst1_temp++) = hkp.sst1_temp;
		if(ptr.sst3_temp)
			*(ptr.sst3_temp++) = hkp.sst3_temp;
		if(ptr.eesa_mcpl)
			*(ptr.eesa_mcpl++) = hkp.eesa_mcpl;
		if(ptr.eesa_mcph)
			*(ptr.eesa_mcph++) = hkp.eesa_mcph;
		if(ptr.pesa_mcpl)
			*(ptr.pesa_mcpl++) = hkp.pesa_mcpl;
		if(ptr.pesa_mcph)
			*(ptr.pesa_mcph++) = hkp.pesa_mcph;
		if(ptr.eesa_pmt)
			*(ptr.eesa_pmt++) = hkp.eesa_pmt;
		if(ptr.pesa_pmt)
			*(ptr.pesa_pmt++) = hkp.pesa_pmt;
		if(ptr.eesa_swp)
			*(ptr.eesa_swp++) = hkp.eesa_swp;
		if(ptr.pesa_swp)
			*(ptr.pesa_swp++) = hkp.pesa_swp;

		n++;
		pks.index = n;
	}
	return(n);
}


