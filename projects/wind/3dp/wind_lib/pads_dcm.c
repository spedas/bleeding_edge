#include "pads_dcm.h"

#include "eesa_cfg.h"
#include "windmisc.h"

#define ARC_TABLE_SIZE 256
#define NPAD 16
#define DEBUG

#if 0
typedef struct {
	int t_start;
	int t_stop;
	int map;
	int n_alpha;
	int size;
	int bts;
	int pa_bin[ARC_TABLE_SIZE];
}  padstruct;
#endif


int sector_size[40] = { 4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,
                        4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,
                        4,4,4,4,4,4,4,4};

static int2 cos_sec[24] = {    /* cosines of the 24 sectors */
   32012,    27139,    20706,    15386,
   10996,     7931,     4789,     1602,
   -1602,    -4789,    -7931,   -10996,
  -15386,   -20706,   -27139,   -32012,
  -32012,   -27139,   -18134,    -6368,
    6368,    18134,    27139,    32012,
};

int2 sin_sec[24] = {  /*   sines of the 24 sectors   ROM */
   6368,  18134,  25231,  28786,
  30732,  31662,  32287,  32601,
  32601,  32287,  31662,  30732,
  28786,  25231,  18134,   6368,
  -6368, -18134, -27139, -32013,
 -32013, -27139, -18134,  -6368,
};



static int2 cos_gr[65] ={   /* cosine table                stored in ROM  */
 32767, 32758, 32728, 32679, 32610, 32521, 32413, 32285,
 32138, 31971, 31785, 31581, 31357, 31114, 30852, 30572,
 30273, 29956, 29621, 29269, 28898, 28511, 28106, 27684,
 27245, 26790, 26319, 25832, 25330, 24812, 24279, 23732,
 23170, 22595, 22005, 21403, 20787, 20160, 19520, 18868,
 18205, 17531, 16846, 16151, 15446, 14733, 14010, 13279,
 12540, 11793, 11039, 10279,  9512,  8740,  7962,  7179,
  6393,  5602,  4808,  4011,  3212,  2411,  1608,   804,
     0,
};



static int2 cosib[24];
static int2 sinib[24];

/****  private functions   *****/


int cosb256_gr(uchar p);
int sinb256_gr(uchar p);
int init_arc_cos_table_gr(int map,uint2 *pa_map,ECFG *ecfg);
int accum_npad_samp(uint bth,uint bph,PADdata *pad,uint2 *pa_map,ECFG *ecfg);

/*
int get_next_ehpad(packet_selector *pks,PADdata *pad)
{
    pk = get_packet(pks);
    return(pads_decom(pk,pad));
}
*/






int pads_decom(packet *pk,PADdata *pad)
{
	int i,na,ne,ns;
	int d,a,e,u;
	uint4 cnts;
	uint bth,bph;
	int bdir[32];
	uchar *dp;
	static uint2 pa_map[ARC_TABLE_SIZE];
	ECFG *ecfg;

	if(pk==0)
		return(0);

        if(pk->quality & (~pkquality)) {
                pad->time1 = pk->time;
                pad->time2 = pk->time;
                return(0);
        }

	ecfg = get_ECFG(pk->time);

	pad->num_angles = na = 16;     /* ???? */
	pad->num_angles = na = (pk->instseq & 0x0f)+1;

	pad->num_energies = ne = 15;   /* ???? */
	
	pad->num_samples  = ns = ((int)pk->dsize - na*ne)/2;

	pad->time1 = pk->time;
	pad->time2 = pad->time1 + ecfg->spin_period * pad->num_samples;

	i = (pk->instseq >> 4) &0x0f;
	if(i == 0x02){      pad->t_start = 0; pad->t_stop=16; }
	else if(i == 0x06){ pad->t_start =16; pad->t_stop=32; }
	else if(i == 0x07){ pad->t_start =16; pad->t_stop=40; }
	else if(i == 0x05){ pad->t_start =32; pad->t_stop=40; }
	else fprintf(stderr,"Pad seq code not recognized\n");

	pad->map = 0;             /*  ???? */

/*	acc.t_start = pad->t_start;     */
/*	acc.t_stop  = pad->t_stop;      */
/*	acc.map     = pad->map;         */  

	init_arc_cos_table_gr(pad->map,pa_map,ecfg);

	if(pad->t_start)
		u = get_esteps_eh(pad->energies,15,MIDDLE,ecfg);
	else
		u = get_esteps_el(pad->energies,15,MIDDLE,ecfg);
	pad->units.nrg = u;

	dp = pk->data;
	for(a=d=0; a<na; a++){
		for(e=0;e<ne;e++){
			cnts = decomp19_8(*dp++);
			pad->flux[d++] = cnts;
		}
	}
	for(a=0;a<na;a++)
		pad->area[a]= 0;
	for(a=0;a< ns*2 ;){    /* store b directions */
		bph = bdir[a++] = *dp++;
		bth = bdir[a++] = *dp++;
		accum_npad_samp(bth,bph,pad,pa_map,ecfg);
	}
	return(1);
}


init_arc_cos_table_gr(int map,uint2 *pa_map,ECFG *ecfg)
{                 /* not finalized */
	int i,a,b;
	int cpa;
	uchar *arc_codes;
	
	a = b = 0;
	if(map & 1)
		arc_codes = ecfg->extd_cfg.arc_cos_def2;
	else
		arc_codes = ecfg->extd_cfg.arc_cos_def1;

	while(arc_codes[b]){
		for(i=0; i< (int)(arc_codes[b] & 0x7f); i++){
#ifdef DEBUG
			if(a>=ARC_TABLE_SIZE){
				fprintf(stderr,"Outside arctable limits");
				return(0);
			}
#endif
			pa_map[a++] = b | (arc_codes[b] & 0x80) ;
		}
		b++;
	}
#ifdef DEBUG
	if(b>NPAD){
		err_out("Too many PAD angles"); 
		return(0); 
	}
#endif
	return(b);
}



int cosb256_gr(uchar p)   /* cosine function with period of 256 */
{
	p &= 0xff;   
	if(p > 128) p = 256-p;
	if(p > 64) return( -((uint) cos_gr[128-p]) );
	else return( cos_gr[p] );
}

int sinb256_gr(uchar p)   /* sine function with period of 256 */
{
	return( cosb256_gr( p+192 ));
}



int accum_npad_samp(uint bth,uint bph,PADdata *pad,uint2 *pa_map,ECFG *ecfg)
{
	int i,p,t,cpa,b,phase,dt;
	uchar pblank;
	int2 cbth,sbth;
	int2 cosp;
	uchar tempblk;


	cbth = cosb256_gr(bth);
	sbth = sinb256_gr(bth);
	for(i=0;i<24;i++){                /*  48 multiplies  */
		cosib[i] = (((long) cbth * cos_sec[i] ) >> 15) + 127;
		sinib[i] =  ((long) sbth * sin_sec[i] ) >> 15;
	}
	
	dt = 16;
	if(pad->t_start==0)
		dt = 0;
	for(p = 0;p<32;p++){
		pblank = ecfg->extd_cfg.p_blank[p];
		cosp = cosb256_gr( (p << 3) - ecfg->extd_cfg.pad_shift - bph );  /* rotate phi */
		for(t=pad->t_start;t < pad->t_stop;t++){
			cpa = (((long) sinib[t - dt] * cosp ) >> 15)
			             + cosib[t - dt];
			cpa = cpa >> 8;
			cpa += 128;                /* make it positive */
#ifdef	DEBUG
   			if(cpa & 0xff00) err_out("pitch angle error");
#endif
			b = pa_map[cpa];
			tempblk = ecfg->extd_cfg.t_blank[t];
			if( ( (b & 0xc0) | pblank) & tempblk ) 
				continue;
			b &= 15;
			pad->area[b] += sector_size[t];
		}
	}
	return(1);
}


