#ifndef KPD_DCM_H
#define KPD_DCM_H


#include "eesa_cfg.h"
#include "pesa_cfg.h"
#include "wind_pk.h"
#include "emom_dcm.h"
#include "pmom_dcm.h"


typedef struct  {
	double time;
	int valid;

	uint4 sst_foil_0_1;
	uint4 sst_foil_2_3;
	uint4 sst_foil_4;
	uint4 sst_open_0;
	uint4 sst_open_1;
	uint4 sst_open_2_3;

	eesa_mom_data   Emom;   /* Structure containing Eesa moment data  */

	uint2 eesa_qdotb;

	uint4 eesa_flux_0;
	uint4 eesa_flux_1;
	uint4 eesa_flux_2;
	uint4 eesa_flux_3;

	pesa_mom_data   Pmom;  /* Structure containing Pesa moment data */

	uint4 pesa_flux_0;
	uint4 pesa_flux_1;
	uint4 pesa_flux_2;
	uint4 pesa_flux_3;
} kpd_struct;



int  kpd_decom(packet *pk,kpd_struct *kpd);
int unpack_to_kpd_def(uchar *s,double time,uint2 spin,kpd_struct *kpd,
   ECFG *ecfg,PCFG *pcfg);

#endif
