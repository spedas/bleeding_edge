
#include "pesa_cfg.h"
#include "wind_pk.h"
#include "frame_dcm.h"


#include <string.h>  /* for memcmp */


static PCFG Pcfg;        


int initialize_pesa_high(PCFG *cfg);
int initialize_pesa_low(PCFG *cfg);

/* The get_PCFG routine must work for two different modes: 
1. random access mode,  Configuration returned for a specified time.  In this
mode it is assumed that configuration packets are stored in memory.
2. sequential access mode,  (batch_print = 1) here it is assumed the most
recent configuration is desired. (Configuration packets may, or may not
be stored.)
*/


int set_PCFG(packet *pk)
{
	static uchar  last_data[PCONFIG_SIZE];   
	static int different =1;
	Pconfig old_cfg;
/* static packet_selector frmpks;   */
/* static struct frameinfo_def frame;   */

        if(pk && !(pk->quality & (~pkquality))){
            Pcfg.time = pk->time;
/* SET_PKS_BY_TIME(frmpks,Pcfg.time,P_CFG_ID);  */
/* get_next_frame_struct(&frmpks,&frame);  */
/* Pcfg.spin_period = frame.spin_period;   */
	Pcfg.spin_period = SPIN_PERIOD;   /* ????? */
	}
else{
	Pcfg.spin_period = SPIN_PERIOD;   /* this must be made more dynamic */
}
	Pcfg.temperature = 9.3;   /* default */
	Pcfg.pl_geom = GEOM_PL;
	Pcfg.ph_geom = GEOM_PH;


	if(pk && !(pk->quality & (~pkquality)))
		different = memcmp(last_data,pk->data,PCONFIG_SIZE);
	if(different){
		old_cfg = Pcfg.norm_cfg;
		decom_pconfig(pk,&Pcfg.norm_cfg);
		if(Pcfg.norm_cfg.valid == 1){
			if(pk && !(pk->quality & (~pkquality)))
				memcpy(last_data,pk->data,PCONFIG_SIZE);
			initialize_pesa_high(&Pcfg);
			initialize_pesa_low(&Pcfg);
			different = 0;
			Pcfg.valid++;
		}
		else
			Pcfg.norm_cfg = old_cfg;
	}


	return(1);
    
}


PCFG *get_PCFG(double time)
{
    packet * pk;
    static packet_selector pks;

    SET_PKS_BY_LASTT(pks,time,P_CFG_ID);

    if(batch_print)
	return(&Pcfg);

    pk = get_packet(&pks);
    set_PCFG(pk);

    return(&Pcfg);
}






initialize_pesa_high(PCFG *cfg)
{
	int e=0;	

	compute_dac_table(&cfg->norm_cfg.ph_sweep,cfg->phdac_tbl, DAC_TBL_SIZE_PH);

	cfg->ph_sweep_cal.sweep_par = cfg->norm_cfg.ph_sweep;

	initialize_cal_coeff(PH,cfg->temperature,&cfg->ph_sweep_cal);

	init_estep30_array(&cfg->phnrg30,cfg->phdac_tbl,&cfg->ph_sweep_cal);

	init_estep15_array(&cfg->phnrg15,&cfg->phnrg30);

	for(e=0;e<DAC_TBL_SIZE_PH;e++)
	   cfg->ph_volts_tbl[e]=dac_to_voltage(*(cfg->phdac_tbl+e),&cfg->ph_sweep_cal);

	return(1);
}



initialize_pesa_low(PCFG *cfg)
{
	sweep_def sweep;
	uint2     *dactable,size,bndry_pt;
        int e;	

	dactable = cfg->pldac_tbl;
	bndry_pt = cfg->norm_cfg.bndry_pt;

		/* Calculate first portion of table:  (high gain) */
	sweep = cfg->norm_cfg.pl_sweep;
	size = bndry_pt + OVERLAP;
	compute_dac_table(&sweep,dactable,bndry_pt+OVERLAP);

		/* Calculate remainder of table  (low gain)  */
	sweep.start_E = (uint2)(((uint4)(dactable[bndry_pt])<<4) - sweep.s1);
	sweep.gs2 = cfg->norm_cfg.gs1_pl;
	size = DAC_TBL_SIZE_PL - bndry_pt - OVERLAP;
	compute_dac_table(&sweep,dactable+bndry_pt+OVERLAP,size);

	cfg->pl_sweep_cal.sweep_par = cfg->norm_cfg.pl_sweep;

	initialize_cal_coeff(PL,cfg->temperature,&cfg->pl_sweep_cal);

	init_esteppl_array2(&cfg->plnrg,cfg->pldac_tbl,&cfg->pl_sweep_cal,
		bndry_pt+OVERLAP);
	for(e=0;e<DAC_TBL_SIZE_PL;e++)
	   cfg->pl_volts_tbl[e]=dac_to_voltage(dactable[e],&cfg->pl_sweep_cal);


	return(1);
}


int  get_esteps_pl14(double y[14],int es,int pos,PCFG *cfg)
{
	int e,i;
	switch(pos){
	case MIN:
		for(e=0,i=es;e<14;e++,i+=4)
			y[e] = cfg->plnrg.lower[i];
		break;
	case MAX:
		for(e=0,i=es;e<14;e++,i+=4)
			y[e] = cfg->plnrg.upper[i];
		break;
	case WIDTH:
		for(e=0,i=es;e<14;e++,i+=4)
			y[e] = cfg->plnrg.wid[i];
		break;
	case MIDDLE:
		for(e=0,i=es;e<14;e++,i+=4)
			y[e] = cfg->plnrg.mid[i];
		break;
	}
	return(1);
}



int  get_esteps_ph(double *y,int ne,int pos,PCFG *cfg)
{
	int e;
	double *source=NULL;
	
	switch(pos){
	case MIN:
		if(ne==15)  source = cfg->phnrg15.lower;
		if(ne==30)  source = cfg->phnrg30.lower;
		break;
	case MAX:
		if(ne==15)  source = cfg->phnrg15.upper;
		if(ne==30)  source = cfg->phnrg30.upper;
		break;
	case WIDTH:
		if(ne==15)  source = cfg->phnrg15.wid;
		if(ne==30)  source = cfg->phnrg30.wid;
		break;
	case MIDDLE:
		if(ne==15)  source = cfg->phnrg15.mid;
		if(ne==30)  source = cfg->phnrg30.mid;
		break;
	}
	if(source){
		for(e=0;e<ne;e++)
			y[e] = source[e];
		return(1);
	}
	return(0);
}




