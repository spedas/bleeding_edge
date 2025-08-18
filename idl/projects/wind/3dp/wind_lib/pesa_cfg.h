#ifndef PESA_CFG_H
#define PESA_CFG_H

#include "pcfg_dcm.h"
#include "esteps.h"
#include "sweeps.h"

/*  The following structure is the MASTER structure that contains ALL info
pertinent to the interpretation of the data.  The user should NEVER change
any elements of this structure!!!!! */


struct PESA_config_str {
	double time;        /* seconds since 1970 */
	double temperature; /* (Crit) */
	double spin_period; /* (Crit) */
	Pconfig norm_cfg;   /* (Crit) useful data from normal config packets*/
/*	PXconfig extd_cfg;  /* (Crit) useful data from extended config pkts */

/* if any of the above critical values change then the folowing are computed: */
	 	/* Pesa Low stuff:  */
	double         pl_geom;                      /* pesa low geom factor */
	sweep_cal      pl_sweep_cal;                 /* calibration coeff.  */
	uint2          pldac_tbl[DAC_TBL_SIZE_PL];   /* sweep table */
        double         pl_volts_tbl[DAC_TBL_SIZE_PL];   /* voltage table */
	energy_steppl  plnrg;                        /* energy steps  */

	 	/* Pesa High stuff:  */
	double         ph_geom;
	sweep_cal      ph_sweep_cal;
	uint2          phdac_tbl[DAC_TBL_SIZE_PH];
        double         ph_volts_tbl[DAC_TBL_SIZE_PH];
	energy_step30  phnrg30;
	energy_step15  phnrg15;

/*	struct PESA_config_str *next;     /* pointer to next config */
/*	struct PESA_config_str *prev; */
	int valid;
};
typedef struct PESA_config_str PCFG;



/* function prototypes:  */


PCFG *get_PCFG(double time);
int set_PCFG(packet *pk);

int  get_esteps_pl14(double y[14],int es,int pos,PCFG *cfg);
int  get_esteps_ph(double *y,int ne,int pos,PCFG *cfg);


#endif
