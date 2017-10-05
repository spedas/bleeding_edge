#include "brst_trig.h"
#include "pmom_dcm.h"
#include "windmisc.h"
#include "pcfg_dcm.h"

uint2 comp16_8(uint2 u);


/*#define DEBUG */

#if 1
burst_trigger_pl(uchar e_start,comp_pesa_mom *cmp)
{
	static int4 vavg=~0;
	static int4 dvavg;
	int4 ddv;
	int4 dv;
	int4 v;
	int2 brst;
	
	if(cmp ==0){
		vavg = ~0;
		return(0);
	}
	if(cmp->c0 < pcfg.brst_NV_thresh){
		brst = 0;
		goto end;
	}
	v = get_log_v(e_start,cmp->c1,pcfg.bndry_pt);

	if(vavg == ~0)
		vavg = v;

	vavg = vavg * ( (1<<pcfg.brst_v_n2) -1 );  /*  mult by 2^n-1 */
	vavg += v;
	vavg = vavg >> pcfg.brst_v_n2;  /* div by 2^n */
	if(vavg > v)
		vavg--;    /* force tracking */
	else
		vavg++;

	dv = v-vavg;
	if(dv < 0) 
		dv = -dv;

	dvavg = dvavg * ( (1<<pcfg.brst_v_n1) -1 );  /*  mult by 2^n-1 */
	dvavg += dv;
	dvavg = dvavg >> pcfg.brst_v_n1;  /* div by 2^n */
	if(dvavg > dv)
		dvavg--;
	else
		dvavg++;

	ddv = dv-dvavg;
	if(ddv < 0)
		ddv = -ddv;
	if(ddv < pcfg.brst_v_offset)
		brst = 0;
	brst = comp19_8(ddv);
/*	if(brst>15)
//		brst = 15; */
	end:
#ifdef DEBUG
	static FILE *fp;
	static int count;
	if(fp==0){
		fp = fopen("brsttest.dat","w");
		if(fp==0)
			exit(0);
		fprintf(fp,"set NV_thresh %d\n",pcfg.brst_NV_thresh);
		fprintf(fp,"set n1 %d\n",pcfg.brst_v_n1);
		fprintf(fp,"set n2 %d\n",pcfg.brst_v_n2);
		fprintf(fp,"set offset %d\n",pcfg.brst_v_offset);
		fprintf(fp,"  cnt   v bst vav  dv dva ddv \n");
	}
	fprintf(fp,"%5d ",count++);
	fprintf(fp,"%3d ",v);
	fprintf(fp,"%3d ",brst);
	fprintf(fp,"%3d ",vavg);
	fprintf(fp,"%3d ",dv);
	fprintf(fp,"%3d ",dvavg);
	fprintf(fp,"%3d ",ddv);
	fprintf(fp,"\n");
#endif
	return(brst);
}



#else
burst_trigger_pl(uchar e_start,comp_pesa_mom *cmp)
{
	static int2 vavg=0xffff;
	static int2 dvavg;
	int2 dv;
	int2 v;
	uint2 bst;
	
	if(cmp == 0){
		vavg = 0xffff;    /*  reset  */
		return(0);
	}
	if(cmp->c0 < pcfg.brst_NV_thresh)    /* in search mode */
		return(0);
#if 1
	v =  get_log_v(e_start,cmp->c1,pcfg.bndry_pt) << 6  ;/*multiply by 64 */
	if(vavg == 0xffff){  vavg = v;  dvavg= 0;  }
	dv = v - vavg;
	vavg  +=  (v-vavg) >> pcfg.brst_v_n2;
	dvavg  +=  (dv-dvavg) >> pcfg.brst_v_n1;
#else
	v =  get_log_v(e_start,cmp->c1) << 4  ;    /* multiply by 16  */
	if(vavg == 0xffff){  vavg = v;  dvavg= 0;  }
	dv = v - vavg;
	vavg  = ( ((long) vavg<<pcfg.brst_v_n2) -  vavg +  v) >> pcfg.brst_v_n2;
	dvavg = ( ((long)dvavg<<pcfg.brst_v_n1) - dvavg + dv) >> pcfg.brst_v_n1;
#endif
	dv = comp16_8( dvavg<0 ? -dvavg : dvavg );      /*  log the log  */
	dv = dv - pcfg.brst_v_offset;
	if(dv<0) bst=0;
	else bst = dv;
/*	bst = (bst * pcfg.brst_v_mult) >> pcfg.brst_v_shift; */
#ifdef FLIGHT
	if(bst>15) bst=15;
#endif
	return(bst);
}
#endif




uint2 comp16_8(uint2 u)  
{
	return( comp19_8( (uint4) u ));
}











#if 0
#define B11 0x0800
comp12(uint2 u)   /* compress 12 bit to 8 bit  for testing only!!! */
{                 /*   UNTESTED !!!!!  */
	int i;
	uint2 m,e;
	if(u <= 64) return((uint2) u);
	if(u >= 4032) return(255); 
	for(e=7;!(u & B11);u<<=1,e--)
		;
	m = u >> 6;     
	m &= 0x1f;      /*  keep only 5 bits */
	e <<= 5;
	return(m+e);
}

#endif

