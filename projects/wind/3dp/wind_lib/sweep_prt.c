#include "sweep_prt.h"


FILE *elswp_fp;
FILE *ehswp_fp;


void print_dac_table(FILE *fp,sweep_cal *cal,uint2 *tbl,int n);

void print_sweep_el(FILE *fp,ECFG *cfg)
{
	print_dac_table(fp,&cfg->el_sweep_cal,cfg->eldac_tbl,DAC_TBL_SIZE_EL);
}

void print_sweep_eh(FILE *fp,ECFG *cfg)
{
	print_dac_table(fp,&cfg->eh_sweep_cal,cfg->ehdac_tbl,DAC_TBL_SIZE_EH);
}


void print_sweep_pl(FILE *fp,PCFG *cfg)
{
	print_dac_table(fp,&cfg->pl_sweep_cal,cfg->pldac_tbl,DAC_TBL_SIZE_PL);
}


void print_sweep_ph(FILE *fp,PCFG *cfg)
{
	print_dac_table(fp,&cfg->ph_sweep_cal,cfg->phdac_tbl,DAC_TBL_SIZE_PH);
}










void print_dac_table(FILE *fp,sweep_cal *cal,uint2 *tbl,int n)
{
	int i;
	uint2 e;
	uint4 el;
	int c,g,ct;
	double vltg,nrg;
	sweep_def *swp;

	if(fp==0)
		return;
	swp = &cal->sweep_par;

	fprintf(fp,"`%8s: \n",cal->inst_name);
	fprintf(fp," E0= %04X k= %04X  s1=%04X  m2=%04X s2=%04X  gs2=%04X\n",
	   swp->start_E,swp->k_sw,swp->s1, swp->m2,swp->s2,swp->gs2);
	fprintf(fp," E0=%5u k=%5u  s1=%4d  m2=%4u s2=%4d  gs2=%4d\n",
	   swp->start_E,swp->k_sw,swp->s1, swp->m2,swp->s2,swp->gs2);
	fprintf(fp," Temperature: %.1f C\n",cal->temperature);
	fprintf(fp," high gain: DH=%.2f  MH=%.6f\n",cal->offset_high, cal->slope_high);
	fprintf(fp," low gain:  DL=%.2f  ML=%.6f\n",cal->offset_low, cal->slope_low);
	fprintf(fp," k_analyser = %.3f\n",cal->k_analyser);
	fprintf(fp,"step  hex   dac gain  val    volts       nrg\n"); 

 	el = (uint4)swp->start_E << 16;
	for(i=0;i<n;i++){
		c = ct = tbl[i];
		e = (uint2)( el>>16 );
		vltg = dac_to_voltage(ct,cal);
		nrg  = dac_to_energy(ct,cal);
		g = (ct & 0x1000) ? 1 : 0;
		c &= 0x0fff;
		fprintf(fp,"%3d  %04x  %4d  %1d  %5u  %6f  %6f", i,ct,c,g,e,vltg,nrg);
		fprintf(fp,"\n");
		if(swp->k_sw)
			el = lumult_lu_ui(el,swp->k_sw);
	}	
	fprintf(fp,"\n");
}


