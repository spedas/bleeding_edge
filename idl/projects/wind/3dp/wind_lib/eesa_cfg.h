#ifndef EESA_CFG_H
#define EESA_CFG_H

#include "ecfg_dcm.h"
#include "sweeps.h"
#include "esteps.h"

/*  The following structure is the MASTER structure that contains ALL info
pertinent to the interpretation of the data.  The user should NEVER change
any elements of this structure!!!!! */


struct EESA_config_str {
	double time;        /* seconds since 1970 */
	double temperature; /* (Crit) */
	double spin_period; /* (Crit) */
	Econfig norm_cfg;   /* (Crit) useful data from normal config packets*/
	EXconfig extd_cfg;  /* (Crit) useful data from extended config pkts */

/* if any of the above critical values change then the folowing are computed: */
	 	/* Eesa Low stuff:  */
	double         el_geom;                      /* eesa low geom factor */
	sweep_cal      el_sweep_cal;                 /* calibration coeff.  */
	uint2          eldac_tbl[DAC_TBL_SIZE_EL];   /* sweep table */
        double         el_volts_tbl[DAC_TBL_SIZE_EL];   /* voltage table */	
	energy_step30  elnrg30;                      /* energy steps  */
	energy_step15  elnrg15;                      /* summed energy steps */

	 	/* Eesa High stuff:  */
	double         eh_geom;
	sweep_cal      eh_sweep_cal;
	uint2          ehdac_tbl[DAC_TBL_SIZE_EH];
	double	       eh_volts_tbl[DAC_TBL_SIZE_EH];
	energy_step30  ehnrg30;
	energy_step15  ehnrg15;

	struct EESA_config_str *next;     /* pointer to next config */
	struct EESA_config_str *prev;
	int valid;
};
typedef struct EESA_config_str ECFG;



/* function prototypes:  */


ECFG *get_ECFG(double time);



int  get_esteps_eh(double *y,int ne,int pos,ECFG *cfg);
int  get_esteps_el(double *y,int ne,int pos,ECFG *cfg);




#endif
