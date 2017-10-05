
#include "eesa_cfg.h"
#include "wind_pk.h"
#include "frame_dcm.h"

#include <string.h>  /* for memcmp */




int initialize_eesa_high(ECFG *cfg);
int initialize_eesa_low(ECFG *cfg);

ECFG *get_ECFG(double time)
{
	static ECFG Ecfg; 
	static uchar last_ndata[ECONFIG_SIZE];
	static packet *pkn,*pkx;
	static int different=1;
	static packet_selector pks;
/* static packet_selector frmpks;  */
/* static struct frameinfo_def frame; */

	SET_PKS_BY_LASTT(pks,time,E_CFG_ID);
/*SET_PKS_BY_TIME(frmpks,time,E_CFG_ID);  */
/*get_next_frame_struct(&frmpks,&frame);*/
	Ecfg.time = time;

	Ecfg.spin_period = SPIN_PERIOD;   /* this must be made more dynamic */
/*Ecfg.spin_period = frame.spin_period; */

	Ecfg.temperature = 9.3;   /* default */
	Ecfg.el_geom = GEOM_EL;
	Ecfg.eh_geom = GEOM_EH;

	pkn = get_packet(&pks);
	if(pkn && !(pkn->quality & (~pkquality)))
		different = memcmp(last_ndata, pkn->data, ECONFIG_SIZE);
	if(different && check_econfig_pk_validity(pkn)){
		if(pkn && !(pkn->quality & (~pkquality)))
			memcpy(last_ndata,pkn->data,ECONFIG_SIZE);
		decom_econfig(pkn,&Ecfg.norm_cfg);
		initialize_eesa_high(&Ecfg);
		initialize_eesa_low(&Ecfg);
		different = 0;
		Ecfg.valid++;
	}

	SET_PKS_BY_LASTT(pks,time,E_XCFG_ID);
	pkx = get_packet(&pks);

	decom_exconfig(pkx,&Ecfg.extd_cfg);

	return(&Ecfg);
}



initialize_eesa_high(ECFG *cfg)
{
	int e;	

	compute_dac_table(&cfg->norm_cfg.eh_sweep,cfg->ehdac_tbl, DAC_TBL_SIZE_EH);

	cfg->eh_sweep_cal.sweep_par = cfg->norm_cfg.eh_sweep;

	initialize_cal_coeff(EH,cfg->temperature,&cfg->eh_sweep_cal);

	init_estep30_array(&cfg->ehnrg30,cfg->ehdac_tbl,&cfg->eh_sweep_cal);

	init_estep15_array(&cfg->ehnrg15,&cfg->ehnrg30);

        for(e=0;e<DAC_TBL_SIZE_EH;e++)
           cfg->eh_volts_tbl[e]=dac_to_voltage(cfg->ehdac_tbl[e],&cfg->eh_sweep_cal);

	return(1);
}



initialize_eesa_low(ECFG *cfg)
{	
	int e;
		

	compute_dac_table(&cfg->norm_cfg.el_sweep,cfg->eldac_tbl, DAC_TBL_SIZE_EL);

	cfg->el_sweep_cal.sweep_par = cfg->norm_cfg.el_sweep;

	initialize_cal_coeff(EL,cfg->temperature,&cfg->el_sweep_cal);

	init_estep30_array(&cfg->elnrg30,cfg->eldac_tbl,&cfg->el_sweep_cal);

	init_estep15_array(&cfg->elnrg15,&cfg->elnrg30);

        for(e=0;e<DAC_TBL_SIZE_EL;e++)
           cfg->el_volts_tbl[e]=dac_to_voltage(cfg->eldac_tbl[e],&cfg->el_sweep_cal);

	return(1);
}






int  get_esteps_eh(double *y,int ne,int pos,ECFG *cfg)
{
	int e;
	double *source;
	
	source = NULL;
	switch(pos){
	case MIN:
		if(ne==15)  source = cfg->ehnrg15.lower;
		if(ne==30)  source = cfg->ehnrg30.lower;
		break;
	case MAX:
		if(ne==15)  source = cfg->ehnrg15.upper;
		if(ne==30)  source = cfg->ehnrg30.upper;
		break;
	case WIDTH:
		if(ne==15)  source = cfg->ehnrg15.wid;
		if(ne==30)  source = cfg->ehnrg30.wid;
		break;
	case MIDDLE:
		if(ne==15)  source = cfg->ehnrg15.mid;
		if(ne==30)  source = cfg->ehnrg30.mid;
		break;
	}
	if(source){
		for(e=0;e<ne;e++)
			y[e] = source[e];
		return(1);
	}
	return(0);
}


int  get_esteps_el(double *y,int ne,int pos,ECFG *cfg)
{
	int e;
	double *source=NULL;
	
	switch(pos){
	case MIN:
		if(ne==15)  source = cfg->elnrg15.lower;
		if(ne==30)  source = cfg->elnrg30.lower;
		break;
	case MAX:
		if(ne==15)  source = cfg->elnrg15.upper;
		if(ne==30)  source = cfg->elnrg30.upper;
		break;
	case WIDTH:
		if(ne==15)  source = cfg->elnrg15.wid;
		if(ne==30)  source = cfg->elnrg30.wid;
		break;
	case MIDDLE:
		if(ne==15)  source = cfg->elnrg15.mid;
		if(ne==30)  source = cfg->elnrg30.mid;
		break;
	}
	if(source){
		for(e=0;e<ne;e++)
			y[e] = source[e];
		return(1);
	}
	return(0);
}









#if 0
#include <stdlib.h>

static ECFG *first_ECFG;
static ECFG *last_ECFG;


make_ECFG(packet *pk)
{
	Econfig ec;
	EXconfig exc;
	ECFG  *ecfg;
	int different;

	if(pk==0)
		return(0);

/*	ecfg = get_eesa_configuration(pk->time);  /* get last one */

	different = 0;
	if(check_econfig_pk_validity(pk)){        /* normal config packet */
		decom_econfig(pk,&ec);
		different = memcmp(&ec,&(ecfg->norm_cfg),sizeof(Econfig));
		if(different){
			if(ecfg->valid != 0){  /* create a new one  */
				
			}
		}
	}
}


ECFG *get_eesa_configuration(double time)
{
	ECFG *ecfg;

	if(first_ECFG==0){
		ecfg = last_ECFG = first_ECFG = (ECFG *)malloc(sizeof(ECFG));
		ecfg->valid=0;
		ecfg->next = ecfg->prev = NULL;		

			memcpy(init_pk.data,default_ecfg_data,ECONFIG_SIZE);
			init_pk.time = 0;
			init_pk.idtype = 1;    /* may need changing in future */
			init_pk.prev = NULL;
			init_pk.next = NULL;
		return(ecfg);
	}
	return(last_ECFG);
}
#endif
