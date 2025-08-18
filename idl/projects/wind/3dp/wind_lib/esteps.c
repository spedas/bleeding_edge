#include "esteps.h"
#include "sweeps.h"
#include <math.h>


    /* this routine is to be used only for  el,eh and ph */
void init_estep30_array(energy_step30 *nrg30,uint2 *dactable,sweep_cal *cal)
{
	int e,i,d=0;
	double nrg,anrg0,anrg9;
	
	for(e=0;e<30;e++){
		for(i=0;i<4;i++,d++){
			nrg = dac_to_energy(dactable[d],cal);
			if(i==0) nrg30->upper[e] = nrg;
			if((e==0) && (i==1)) anrg0 = nrg;
			if(i==2) anrg9 = nrg;
		}
		nrg30->lower[e] = nrg;
		nrg30->wid[e] = nrg30->upper[e] - nrg30->lower[e];
		nrg30->unc[e] = 1.0;      /* TBD later */
		if(e>0){
			nrg = (nrg30->lower[e-1]+nrg30->upper[e])/2.;
			nrg30->lower[e-1] = nrg;
			nrg30->upper[e] = nrg;
			nrg30->mid[e-1] = (nrg30->lower[e-1]+nrg30->upper[e-1])/2.;
			nrg30->wid[e-1] = (nrg30->upper[e-1] - nrg30->lower[e-1]);
		}

	}
	nrg30->upper[0] = nrg30->upper[0]+(nrg30->upper[0]-anrg0)/2.;
	nrg30->mid[0] = (nrg30->upper[0] + nrg30->lower[0])/2.;
	nrg30->wid[0] = nrg30->upper[0] - nrg30->lower[0];
	nrg30->lower[29] = nrg30->lower[29]-(anrg9-nrg30->lower[29])/2.;
	nrg30->mid[29] = (nrg30->upper[29] + nrg30->lower[29])/2.;
	nrg30->wid[29] = nrg30->upper[29] - nrg30->lower[29];

#if 1   /* special case for EESA LOW  sweep problem */
	if(nrg30->upper[0] < nrg30->upper[1])
		nrg30->upper[0] = dac_to_energy(dactable[1],cal);
	
#endif	
}



void init_estep15_array(struct energy_step15_def *nrg15,struct energy_step30_def *nrg30)
{
	int e;
	for(e=0;e<15;e++){
		nrg15->upper[e] = nrg30->upper[2*e];
		nrg15->lower[e] = nrg30->lower[2*e+1];
		nrg15->mid[e] = (nrg15->upper[e] + nrg15->lower[e])/2.;
		nrg15->wid[e]   = (nrg15->upper[e] - nrg15->lower[e]);
		nrg15->unc[e] = (nrg30->unc[2*e] + nrg30->unc[2*e+1]) / 2.;
	}
}


  /* this routine is to be used only for pesal */
void init_esteppl_array2(energy_steppl *snrg,uint2 *dactable,sweep_cal *cal,
	uint2 bndry)
{  
	int e,i,j,a=0,d=0;
	double nrg,anrg[8];

	for(e=0;e<bndry;e++){
		d=e;
		if(bndry-e < 4) j=bndry-e;
		else j=4;
		for(i=0;i<j;i++,d++){
			nrg = dac_to_energy(dactable[d],cal);
			if(i==0) snrg->upper[e] = nrg;
			if((e<4) && (i==1)) anrg[a++] = nrg;
			if((i==j-2) && (e>=bndry-4)) anrg[a++] = nrg;
		}
		snrg->lower[e] = nrg;
		snrg->wid[e] = snrg->upper[e] - snrg->lower[e];
		snrg->unc[e] = 1.0;      /* TBD later */
		if(e>3){
			nrg = (snrg->lower[e-4]+snrg->upper[e])/2.;
			snrg->lower[e-4] = nrg;
			snrg->upper[e] = nrg;
			snrg->mid[e-4] = (snrg->lower[e-4]+snrg->upper[e-4])/2.;
			snrg->wid[e-4] = (snrg->upper[e-4] - snrg->lower[e-4]);
		}

	}
	anrg[7]=anrg[6];
	e--;
	for(a=0;a<4;a++){
		snrg->upper[a] = snrg->upper[a]+(snrg->upper[a]-anrg[a])/2.;
		snrg->mid[a] = (snrg->upper[a] + snrg->lower[a])/2.;
		snrg->wid[a] = snrg->upper[a] - snrg->lower[a];
		snrg->lower[e-a] = snrg->lower[e-a]-(anrg[7-a]-snrg->lower[e-a])/2.;
		snrg->mid[e-a] = (snrg->upper[e-a] + snrg->lower[e-a])/2.;
		snrg->wid[e-a] = snrg->upper[e-a] - snrg->lower[e-a];
	}
	a=0;
	for(e=bndry;e<(DAC_TBL_SIZE_PL-3);e++){
		d=e;
		for(i=0;i<4;i++,d++){
			nrg = dac_to_energy(dactable[d],cal);
			if(i==0) snrg->upper[e] = nrg;
			if((e<bndry+4) && (i==1)) anrg[a++] = nrg;
			if((i==2) && (e>DAC_TBL_SIZE_PL-8)) anrg[a++] = nrg;
		}
		snrg->lower[e] = nrg;
		snrg->wid[e] = snrg->upper[e] - snrg->lower[e];
		snrg->unc[e] = 1.0;      /* TBD later */
		if(e>bndry+3){
			nrg = (snrg->lower[e-4]+snrg->upper[e])/2.;
			snrg->lower[e-4] = nrg;
			snrg->upper[e] = nrg;
			snrg->mid[e-4] = (snrg->lower[e-4]+snrg->upper[e-4])/2.;
			snrg->wid[e-4] = (snrg->upper[e-4] - snrg->lower[e-4]);
		}

	}
	e--;
	for(a=0;a<4;a++){
		snrg->upper[bndry+a] = snrg->upper[bndry+a]+(snrg->upper[bndry+a]-anrg[a])/2.;
		snrg->mid[bndry+a] = (snrg->upper[bndry+a] + snrg->lower[bndry+a])/2.;
		snrg->wid[bndry+a] = snrg->upper[bndry+a] - snrg->lower[bndry+a];
		snrg->lower[e-a] = snrg->lower[e-a]-(anrg[7-a]-snrg->lower[e-a])/2.;
		snrg->mid[e-a] = (snrg->upper[e-a] + snrg->lower[e-a])/2.;
		snrg->wid[e-a] = snrg->upper[e-a] - snrg->lower[e-a];
	}
}



/* converts spectrum to proper units */

/* dt is the duration of one energy step */
/* dth is the number of sweeps times the angular range theta */
int convert_units(int ne,double *nrg,float *counts,
                  double dt,double dth,double geom,int flux_units)
{
	int e;
	double scale;
	double A;

	geom = geom * dth;
	A = 1.;  /* ERROR must be fixed !!!  */

	switch(flux_units){
		case NCOUNTS_UNITS:
			scale = dth/(22.5*2);
			for(e=0;e<ne;e++)
				counts[e] /= scale;
			break;
		case RATE_UNITS:
			scale = dt;
			for(e=0;e<ne;e++)
				counts[e] /= scale;
			break;
		case EFLUX_UNITS:
			scale = dt*geom;
			for(e=0;e<ne;e++)
				counts[e] /= scale;
			break;
		case FLUX_UNITS:
			scale = dt*geom;
			for(e=0;e<ne;e++)
				counts[e] /= scale*(nrg[e]/1000.);
			break;
		case DISTF_UNITS:
			scale = dt*geom*A;
			for(e=0;e<ne;e++)
				counts[e] /= scale*nrg[e]*nrg[e];
			break;
		default:
			flux_units = COUNTS_UNITS;
			break;
	}
	return(flux_units);
}




