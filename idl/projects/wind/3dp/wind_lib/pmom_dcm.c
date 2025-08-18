#include "pmom_dcm.h"

#include "pesa_cfg.h"
#include "matrix.h"

/*  #include "brst_trig.h"  */

#include "windmisc.h"
#include <stdlib.h>
#include <math.h>

#define TW_MIN 0
#define TW_MAX 23
#define PW_MIN 0
#define PW_MAX 15


/********* Private structures **********/

struct start_val {
	uchar e_start;
	schar p_start;
	uchar p_snap55;
	uchar t_snap55;
	uchar p_snap88;
	uchar t_snap88;
        uchar search_flag;
};


/********* Private functions  **********/
void initialize_pmom_arrays(PCFG *cfg);
void  compute_vel_wghts_gr(uint2 k_sw);  
uint2 decompress_vel_mom(int c,int *dv);
int   compress_vel_mom(uint2 v);
void calc_new_start_gr(comp_pesa_mom *pmom,struct start_val *ms,PCFG *cfg);
void  copy_comp_pesa_mom(comp_pesa_mom *cmom,uchar *d);
void  decompress_pesa_mom( comp_pesa_mom *comp, pesa_mom *mom);
uint4  decomp_dens_mom(uchar nc);
int2  get_log_v(uint2 E_s,uint2 Vc,uchar bndry_pt);



/* Gets next pmom structure with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pmom_struct(packet_selector *pks, pesa_mom_data Pmom[16], pesa_mom_data Amom[16])
{
    packet * pk;
    
    pk = get_packet(pks);
    return( pmom_decom(pk,Pmom,Amom) );
}




/*  returns the number of ion moment samples between time t1 and t2  */
/*  Note:  there are 16 samples per packet  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pmom_struct_samples(double t1,double t2)
{
	return(16*number_of_packets(PMOM_ID,t1,t2));
}

#if 1
int compare_pmom_elems(const void *pmom1, const void *pmom2)
{
	pesa_mom_data Pmom1, Pmom2;
	
	Pmom1 = *((pesa_mom_data *)pmom1);
	Pmom2 = *((pesa_mom_data *)pmom2);
	
	if (Pmom1.time < Pmom2.time)
		return(-1);
	if (Pmom1.time > Pmom2.time)
		return(1);
	return(0);
}

int pmom_to_idl(int argc,void *argv[])
{
	pesa_mom_data Pmom[16],*P;
	pesa_mom_data Amom[16],*A;
	int i,n,ns,size,subtfact;
        packet_selector pks;

	if(argc == 0)
		return( number_of_pmom_struct_samples( 0.,1e12) );
	if(argc != 4){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}

        ns    = * ((int4 *)argv[0]);
        size =  * ((int4 *)argv[1]);
        if(size != sizeof(pesa_mom_data)){
            printf("Incorrect stucture size.  Aborting.\r\n");
            return(0);
        }

        P = (pesa_mom_data *)argv[2];
        A = (pesa_mom_data *)argv[3];
	
	for(n = 0;n<ns/16;n++){
        	SET_PKS_BY_INDEX(pks,n,PMOM_ID);
        
/*		if(get_next_pmom_struct(&pks,Pmom,Amom)==0)   break; */
		get_next_pmom_struct(&pks,Pmom,Amom);
		for(i=0;i<16;i++){
			*P++ = Pmom[i];
			*A++ = Amom[i];
		}
	}
	
	qsort(argv[2],ns,sizeof(pesa_mom_data),compare_pmom_elems);
 	qsort(argv[3],ns,sizeof(pesa_mom_data),compare_pmom_elems);
 	
       return(n);
}
#endif



int fill_pmom_data(pmom_fill_str ptr)
{
	pesa_mom_data Pmom[16];
	pesa_mom_data Amom[16];
	double t;
	int i;
	int n;
        int ns,c;
	static packet_selector pks;

        ns = ptr.num_samples;
        c = 0;
	for(n = 0;n<ns/16;n++){
        	SET_PKS_BY_INDEX(pks,n,PMOM_ID);
        
/*		if(get_next_pmom_struct(&pks,Pmom,Amom)==0)   break; */
		get_next_pmom_struct(&pks,Pmom,Amom);
		for(i=0;i<16;i++){
			if(c >= ns)
				break;
			if(ptr.time) *(ptr.time++) = Pmom[i].time;

			/* first Protons */
			if(ptr.dens_p)  *(ptr.dens_p++) = Pmom[i].dist.dens;
			if(ptr.temp_p) *ptr.temp_p++ = Pmom[i].dist.temp;
			if(ptr.Vpx)   *ptr.Vpx++   = Pmom[i].dist.v[0];
			if(ptr.Vpy)   *ptr.Vpy++   = Pmom[i].dist.v[1];
			if(ptr.Vpz)   *ptr.Vpz++   = Pmom[i].dist.v[2];
			if(ptr.Vc)   *ptr.Vc++   = Pmom[i].Vc;
			if(ptr.Pp){
				*(ptr.Pp)        = Pmom[i].dist.vv[0][0];
				*(ptr.Pp + ns*1) = Pmom[i].dist.vv[1][1];
				*(ptr.Pp + ns*2) = Pmom[i].dist.vv[2][2];
				*(ptr.Pp + ns*3) = Pmom[i].dist.vv[0][1];
				*(ptr.Pp + ns*4) = Pmom[i].dist.vv[0][2];
				*(ptr.Pp + ns*5) = Pmom[i].dist.vv[1][2];
                                ptr.Pp++;
		        }
			/* and Alpha particles */
			if(ptr.dens_a)  *(ptr.dens_a++) = Amom[i].dist.dens;
			if(ptr.temp_a) *ptr.temp_a++ = Amom[i].dist.temp;
			if(ptr.Vax)   *ptr.Vax++   = Amom[i].dist.v[0];
			if(ptr.Vay)   *ptr.Vay++   = Amom[i].dist.v[1];
			if(ptr.Vaz)   *ptr.Vaz++   = Amom[i].dist.v[2];
			if(ptr.Pa){
				*(ptr.Pa)        = Amom[i].dist.vv[0][0];
				*(ptr.Pa + ns*1) = Amom[i].dist.vv[1][1];
				*(ptr.Pa + ns*2) = Amom[i].dist.vv[2][2];
				*(ptr.Pa + ns*3) = Amom[i].dist.vv[0][1];
				*(ptr.Pa + ns*4) = Amom[i].dist.vv[0][2];
				*(ptr.Pa + ns*5) = Amom[i].dist.vv[1][2];
                                ptr.Pa++;
			}
			c++;
		}
		t = 0;
	}
	return(n);
}






/**************************************************************************
Decomutates a pesa moment packet and stores the 16 time samples in the arrays:
	Pmom[16] (Protons) and Amom[16] (Alphas).
Returns 0 on error.
Returns non-zero if succesful.
***************************************************************************/
int pmom_decom(packet *pk,pesa_mom_data Pmom[16],pesa_mom_data Amom[16])
{
	int i,j,k,gap,aoff,valid,E_s,ps;
	double time;
	PCFG *cfg;
	static uint2 spin;
	static double lasttime;
	static struct start_val dp;
	static uchar alpha_offset[16]={  80,120,100,140, 90,110,130,150,
	                                 85, 95,105,115,125,135,145,155  };
	
	if(pk==0){
		for(i=0;i<16;i++){
			Pmom[i].time = Amom[i].time = Pmom[15].time;
			Pmom[i].valid = Amom[i].valid = 0;
			Pmom[i].dist.dens = Amom[i].dist.dens = NaN;
			Pmom[i].dist.temp = Amom[i].dist.temp = NaN;
			for(j=0;j<3;j++) {
				Pmom[i].dist.v[j] = Amom[i].dist.v[j] = NaN;
				Pmom[i].dist.q[j] = Amom[i].dist.q[j] = NaN;
				for(k=0;k<3;k++)
					Pmom[i].dist.vv[j][k] =
						Amom[i].dist.vv[j][k] = NaN;
			}
		}
		return(0);
	}
	
	if(pk->quality & (~pkquality)){
		cfg = get_PCFG(pk->time);
		time = pk->time;
		for(i=0;i<16;i++) {
			Pmom[i].time = Amom[i].time = time;
			Pmom[i].valid = Amom[i].valid = 0;
			Pmom[i].dist.dens = Amom[i].dist.dens = NaN;
			Pmom[i].dist.temp = Amom[i].dist.temp = NaN;
			for(j=0;j<3;j++) {
				Pmom[i].dist.v[j] = Amom[i].dist.v[j] = NaN;
				Pmom[i].dist.q[j] = Amom[i].dist.q[j] = NaN;
				for(k=0;k<3;k++)
					Pmom[i].dist.vv[j][k] =
						Amom[i].dist.vv[j][k] = NaN;
			time += cfg->spin_period;
			}
		}
		return(0);
	}
		
	if( (pk->idtype & 0xf0f0) != 0x6040){
		err_out("Invalid PMOM packet");
		return(0);  /* not pesa moment data */
	}

	cfg = get_PCFG(pk->time);

	gap = 0;
	valid = 1;
	ps  = pk->idtype & 0x000f;
	E_s = pk->instseq >> 8;
	if(pk->spin != spin)
		gap = 1;            /* data gap */
	else if((dp.e_start != E_s) || (dp.p_start != ps) ){
		fprintf(stderr,"Pesa Low Moments: DATA ERROR at %s\n", time_to_YMDHMS(pk->time));
		valid = 0;	    /* sweep error */
	}

	spin = pk->spin;
	lasttime = time = pk->time;
	dp.p_start = ps;
	dp.e_start = E_s;
	
	for(i=0;i<16;i++){
		Pmom[i].E_s  = Amom[i].E_s  = dp.e_start;
		Pmom[i].ps   = Amom[i].ps   = dp.p_start;
		Pmom[i].spin = Amom[i].spin = spin;
		Pmom[i].time = Amom[i].time = time;
		Pmom[i].gap  = Amom[i].gap  = gap;
		Pmom[i].valid= Amom[i].valid= 0;
		Pmom[i].dist.charge = 1;      Amom[i].dist.charge = 2;
		Pmom[i].dist.mass = MASS_P;   Amom[i].dist.mass = MASS_HE;
		copy_comp_pesa_mom(&Pmom[i].cmom,pk->data + i*10);
		calc_pmom_param(&Pmom[i],cfg);

		aoff =  (((uint2)(alpha_offset[i] )) << 1);
		if(aoff < (int)pk->dsize ){      /* now do alphas */
			copy_comp_pesa_mom(&Amom[i].cmom,pk->data + aoff);
			calc_pmom_param(&Amom[i],cfg);
		}
                    /* determine next starting values */
		calc_new_start_gr(&Pmom[i].cmom,&dp,cfg);
                if(dp.search_flag){
			Pmom[i].valid = Amom[i].valid = 0;
			gap = 1;
		}
		else gap = 0;
		spin++;
		time += cfg->spin_period;
	}
	return(1);
}


/***********************************************************************
  Fills in a compressed pesa moment struncture given a character stream.
 ***********************************************************************/
void copy_comp_pesa_mom(comp_pesa_mom *cmom,uchar *d)
{
	cmom->c0 = d[0];
	cmom->c1 = d[1];
	cmom->c2 = d[2];
	cmom->c3 = d[3];
	cmom->c4 = d[4];
	cmom->c5 = d[5];
	cmom->c6 = d[6];
	cmom->c7 = d[7];
	cmom->c8 = d[8];
	cmom->c9 = d[9];
}






#define WS0 6.8e6    /* Note WS0 must be the same as WS1 */
#define WS1 WS0
#define WS2 (WS0*2.79)
#define WS3 (WS0*2.79)                 

#define WS4 (WS1*WS2/WS0)
#define WS5 (WS1*WS3/WS0)
#define WS6 (WS2*WS3/WS0)
#define WS7 (WS1*WS1/WS0)
#define WS8 (WS2*WS2/WS0)
#define WS9 (WS3*WS3/WS0)

static double w_scale[13]= {WS0,WS1,WS2,WS3,WS4,WS5,WS6,WS7,WS8,WS9,1.,1.,1. };
static double dtheta = 5.625;

static uint2 v0[N_ENERGY_PL];     /* proportional to 1/v */
static uint2 v2[N_ENERGY_PL+2];   /* proportional to  v  */


#define NSS 4
#define MD16     65536.

/*************************************************************************
  This routine will evaluate the physical quantities within the substructure
M->dist.  It assumes that the elements E_s, ps, and cmom have already been 
filled in.  It also assumes that the time parameter has been set so that
the correct instrument configuration can be retrieved.
	returns 0 on error;  (which cannot happen)
	returns 1 if succesful;
**************************************************************************/
int calc_pmom_param(pesa_mom_data *M,PCFG *cfg)
{
	double dx,s0,s1,s2,v;
	double m0;
	double n,nv,dt;
	double rot[3][3];
	double energies[15];
	pesa_mom mom;
	pmomdata *P;

	get_esteps_pl14(energies,M->E_s,MIDDLE,cfg);
	initialize_pmom_arrays(cfg);

	decompress_pesa_mom(&(M->cmom),&mom);

	M->E_min = energies[13];
	M->E_max = energies[0];
	M->Vc = get_log_v(M->E_s,M->cmom.c1,cfg->norm_cfg.bndry_pt);

	P = &(M->dist);

	if(P->charge ==0){             /* default to Protons*/
		P->charge=1;
		P->mass=MASS_P;
	}
	v = sqrt(2.*energies[0]*P->charge/P->mass);

	dx = NSS * log((double)MD16/(double)cfg->norm_cfg.pl_sweep.k_sw);
	s0 = ((double)v0[0] * v) /MD16;
	s1 = 1.;
	s2 = ((double)v2[0] / v) /MD16;
	n  = (double)v0[0]*v2[0];
	m0 = n/s0/w_scale[0];
	P->v[0] = mom.m1/s1/w_scale[1] / m0 ;  /* km/sec */
	dt = cfg->spin_period/1024.;
	nv  = mom.m0 * dx / (GEOM_PL*dt*dtheta)/ s1 / w_scale[1] /1e5;
	if(P->v[0]!=0)
		P->dens = nv / P->v[0];
	else
		P->dens = 0;
	P->v[1] =  mom.m2/s1/w_scale[2] / m0 ;
	P->v[2] =  mom.m3/s1/w_scale[3] / m0 ;
	P->vv[0][1] = P->vv[1][0] =  mom.m4 / s2 /w_scale[4]  /m0;
	P->vv[0][2] = P->vv[2][0] =  mom.m5 / s2 /w_scale[5]  /m0;
	P->vv[1][2] = P->vv[2][1] =  mom.m6 / s2 /w_scale[6]  /m0;
	P->vv[0][0] = mom.m7 /s2/w_scale[7]  /m0;
	P->vv[1][1] = mom.m8 /s2/w_scale[8]  /m0;
	P->vv[2][2] = mom.m9 /s2/w_scale[9]  /m0;
	P->temp = (P->vv[0][0] + P->vv[1][1] + P->vv[2][2])*P->mass/3.;

	if(M->ps!=4){
		rot[0][0] =  rot[1][1] = cos((M->ps-4.) * (360./64.)*RAD);
		rot[1][0] =  sin((M->ps-4.) * (360./64.)*RAD);
		rot[0][1] = -rot[1][0];
		rot[2][2] =  1.;
		rot[0][2] = rot[1][2] = rot[2][0] = rot[2][1] = 0;	
	          /*  rotate velocity vector;   V' = (R) (V) */
		rotate(P->v,rot);
/* Note:  the pressure tensor should also be rotated here as well !  */
	}
/*  Now rotate to the (near) GSE frame */
	P->v[0] = - P->v[0];     
        P->v[2] = - P->v[2];
        P->vv[0][1] = P->vv[1][0] =  - P->vv[0][1];     
        P->vv[0][2] = P->vv[2][0] =  - P->vv[0][2];        
/* done */
	M->valid = 1;
	return(1);
}






static uint2 vctable[256];   /* Vx decompression table */

void initialize_pmom_arrays(PCFG *cfg)
{
	static uint2 last_k_sw;
	uint4 v;
	int vc;


	if(cfg->norm_cfg.pl_sweep.k_sw != last_k_sw){    /* Must recalculate */
		last_k_sw = cfg->norm_cfg.pl_sweep.k_sw;

		compute_vel_wghts_gr(last_k_sw);

		for(v=0;v<65536l;v++){
			vc = compress_vel_mom((uint2)v);
			vctable[vc & 255] = (uint2) v;
		}
	}

}



void compute_vel_wghts_gr(uint2 k_sw)   /*  Note:  v should be large  */
{                                   /*   k is slope of sweep   */
	int i;
	uint2 v;
	uint4 lv;
	v = START_V;
	lv = (uint4)v<<16;
	for(i=0;i< N_ENERGY_PL;i++){
		v = (uint2)((lv + 32768)>>16);        /* rounding used here;  */
		v2[i] = v;                             /*   v  array  */
 		v0[N_ENERGY_PL-1-i] = v;               /*  1/v array  */
		lv = lumult_lu_ui(lv,k_sw);       /* compute next value */
		lv = lumult_lu_ui(lv,k_sw);
	}
	v2[i] = (uint2)(lv>>16); /* 15th element;  used in compression scheme */
	v2[i+1] = 0;             /* 16th element  */
}


/***************************************************************************
Decompression of the Vx moments
Initialize_pmom_arrays must be called first!
****************************************************************************/
uint2 decompress_vel_mom(int c,int *dv)
{
	uint4 v1,v2;
	static uint2 last_ksw;

	c &= 255;
	v1 = c ? vctable[c-1] : 0;
	v2 = vctable[c];
	*dv = (uint2)((v2-v1)>>1);
	return((v1+v2)/2);
}


int2  get_log_v(uint2 E_s,uint2 Vc,uchar bndry_pt)
{
	if(E_s >= (uint2)(bndry_pt + OVERLAP))
		E_s -= OVERLAP;
	return(500 - (E_s<<2) + Vc);
}

int compress_vel_mom(uint2 v) /*  returns 8-bit compression of velocity */
{          
	int e,i;
	uint2 vm,vmin,vmax; 
	for(e=0;e<15 && v<v2[e];e++)
		;
	vmin = v2[e];
	if(e==0) vmax=65535;
	else vmax=v2[e-1];
  /*  reverse order of e so that increasing e coresponds to increasing v */
	e = 15-e;    /* error found here file corrupted and fixed 94/11/11 */
  /*  e now contains the first 4 bits of the compression */
  /*  now linearly interpolate to get the other 4 bits  */
	for(i=0;i<4;i++){
		vm = (uint2) (((uint4)vmin + vmax) >>1);      /* get average  */
		e <<= 1;
		if(v>=vm){  vmin = vm; e+=1; }
		else{       vmax = vm;       }
	}		
	return(e & 0x00FF);	
}





void decompress_pesa_mom(comp_pesa_mom *comp,pesa_mom *mom)
{
	int dvx;
	int e0;

#if 0
	mom->m0 = decompress(comp->c0,4) << 13;
#elseif 0
	mom->m0 = decompress(comp->c0,5) << 19;
#else
	mom->m0 = decomp_dens_mom(comp->c0);

#endif
	mom->m1 = (uint4)decompress_vel_mom(comp->c1,&dvx) << 16;
	mom->m2 = (int4)(mom->m1>>7) * comp->c2;
	mom->m3 = (int4)(mom->m1>>7) * comp->c3;
	e0 = 0;
	if(comp->c7 & 0x80) e0 |= 1;
	if(comp->c8 & 0x80) e0 |= 2;
	if(comp->c9 & 0x80) e0 |= 4;
	mom->m4 =  ((int4)comp->c4 << (e0+16))/3;/* this division needs to be improved  */
	mom->m5 =  ((int4)comp->c5 << (e0+16))/3;
	mom->m6 =  (int4)comp->c6 << (e0+16);
	mom->m7 = (int4)(comp->c7 & 0x7f) << (e0+13);
	mom->m8 = (int4)(comp->c8 & 0x7f) << (e0+16);
	mom->m9 = (int4)(comp->c9 & 0x7f) << (e0+16);
}





void calc_new_start_gr(comp_pesa_mom *pmom,struct start_val *ms,PCFG *cfg)
{                    
	int s,E_s;
	schar dp;

	E_s = ms->e_start;        /* last value of e_start */

	if(pmom->c0 < cfg->norm_cfg.N_thresh){ /* insufficient counts in peak, use search mode. */
		s = cfg->norm_cfg.skip_size;
		if(E_s+s > (int)cfg->norm_cfg.E_step_max)
			s -= (cfg->norm_cfg.E_step_max - cfg->norm_cfg.E_step_min+NSS);
		else if(E_s+s < (int)cfg->norm_cfg.E_step_min)
			s += (cfg->norm_cfg.E_step_max - cfg->norm_cfg.E_step_min+NSS); 
		if(s!=cfg->norm_cfg.skip_size){         /* change p_start  */
			dp = 4;
			if(ms->p_start > 4) dp = -5;
		}
		else
			dp = 0;
                ms->search_flag = 1;
	}
	else{                     /* locked in,  calculate slight adjustments */
		s = ((int)cfg->norm_cfg.cbin - (int)pmom->c1) >> 2;  /*sweep adjustment*/
		dp = (pmom->c2 + 16) >> 5; /* Vy; phi adjustment  (-4<=dp<=4) */
                ms->search_flag = 0;
	}
	if(s< -((int)cfg->norm_cfg.hysteresis) || s> (int)cfg->norm_cfg.hysteresis){
		E_s = E_s+s;                 /* do slight correction to sweep */
		E_s &= ~((uint2)cfg->norm_cfg.shiftmask);      /* mask assures boundary */
		if(E_s >(int)cfg->norm_cfg.bndry_pt && E_s<(int)cfg->norm_cfg.bndry_pt+OVERLAP) /* forbidden zone */
			if(s<0) E_s -= OVERLAP;
			else    E_s += OVERLAP;
	}
	if(E_s < (int)cfg->norm_cfg.E_step_min) E_s= cfg->norm_cfg.E_step_min;
	if(E_s > (int)cfg->norm_cfg.E_step_max) E_s = cfg->norm_cfg.E_step_max;
	if(cfg->norm_cfg.shiftmask & 0x02){               /* calibration mode   alter1 */
		if(E_s == cfg->norm_cfg.bndry_pt) E_s += OVERLAP;
		else if(E_s == cfg->norm_cfg.bndry_pt+ OVERLAP) E_s = cfg->norm_cfg.bndry_pt;
	}
	ms->e_start = E_s;     /*  change values */

#if 1   /* Code not needed in ground software */
	ms->p_snap88 = ms->p_start + dp;
	ms->t_snap88 =   4 - ((pmom->c3 + 16) >> 5);  /* Vz; theta adjustment */

	ms->p_snap55 = ms->p_start + 2 + (pmom->c2 >> 5);
	ms->t_snap55 =    5 - (pmom->c3 >> 5);
#endif
	if((pmom->c2 < -cfg->norm_cfg.p_hyst) || (pmom->c2 > cfg->norm_cfg.p_hyst)){
		ms->p_start +=  dp;
	}
	if(ms->p_start < cfg->norm_cfg.psmin) ms->p_start = cfg->norm_cfg.psmin;
	if(ms->p_start > cfg->norm_cfg.psmax) ms->p_start = cfg->norm_cfg.psmax;
#if 1   /* Code not needed in ground software */
	if((int)ms->p_snap55 < PW_MIN)    ms->p_snap55 = PW_MIN;
	if((int)ms->p_snap55 > PW_MAX-5)  ms->p_snap55 = PW_MAX-5;

	if((int)ms->p_snap88 < PW_MIN)    ms->p_snap88 = PW_MIN;
	if((int)ms->p_snap88 > PW_MAX-8)  ms->p_snap88 = PW_MAX-8;

	if((int)ms->t_snap55 < TW_MIN)    ms->t_snap55 = TW_MIN;
	if((int)ms->t_snap55 > TW_MAX-5)  ms->t_snap55 = TW_MAX-5;

	if((int)ms->t_snap88 < TW_MIN)    ms->t_snap88 = TW_MIN;
	if((int)ms->t_snap88 > TW_MAX-8)  ms->t_snap88 = TW_MAX-8;
#endif
}






#define B15 0x8000
uchar comp_fast(uint2 u)   /* compress 16 bit to 8 bit  psuedo-sqrt */
{                 /*   UNTESTED !!!!!  */
	int i;
	uint m,e;
	/*                    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10, 11, 12, 13, 14, 15*/
	static uint msk[16]={ 0, 2, 4, 8,16,24,32,48,64,80,96,112,128,160,192,224};
	if(u <= 16) return(u);
	for(e=15;!(u & B15);u<<=1,e--)
		;
	u = u<<1;   /*  clear first bit */
	u = u>>8;
	u = u>>3;
	if(e<12) u= u>>1;
	if(e<6)  u= u>>1;
	u |= msk[e];
	return(u);
}

uint4  decomp_dens_mom(uchar nc)
{
	uint4 n;
	uchar c;
	static uint2 decomtab[256];

	if(decomtab[255]==0){   /* must initialize the table */
		for(n=0;n< 0x10000; n++){
			c = comp_fast(n);
			decomtab[c & 0xff]= n;
		}
	}

	return((uint4)decomtab[nc] << 16);
}
