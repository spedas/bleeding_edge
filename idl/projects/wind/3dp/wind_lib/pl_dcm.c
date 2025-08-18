#include <math.h>
#include "pl_dcm.h"
#include "windmisc.h"
#include "esteps.h"
#include "pcfg_dcm.h"
#include "pesa_cfg.h"
#include "brst_dcm.h"


int get_next_plsnap55_struct(packet_selector *pks,pl_snap_55 *snap)
{
    packet *pk;
    
    pk = get_packet(pks);
    return( decom_pl_snapshot_5x5(pk,snap) );
}

int get_next_plsnap88_struct(packet_selector *pks,pl_snap_8x8 *snap)
{
    int ok;
    packet *pk;

        snap->valid=0;
        pk = get_packet(pks);
        while(snap->valid == 0){
                if(pk==0)
                        return(0);
                if(pk->quality & (~pkquality)) {
			snap->time = pk->time;
			return(0);
		}
                ok = decom_pl_snapshot_8x8(pk,snap);
                pk=pk->next;
        }
        return( 1 );
}

/*  returns the number of plsnap55 samples between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_plsnap55_samples(double t1,double t2)
{
	return(number_of_packets(PLSNAP_ID,t1,t2));
}

int number_of_plsnap88_samples(double t1,double t2)
{
	return(number_of_packets(P_SNAP_BST_ID,t1,t2)/2);
}
/*  All angles represent FLOW direction NOT LOOK direction ! */

static double phi[16] = { 
  222.18750, 216.56250, 210.93750, 205.31250
, 199.68750, 194.06250, 188.43750, 182.81250
, 177.18750, 171.56250, 165.93750, 160.31250
, 154.68750, 149.06250, 143.43750, 137.81250  };


#if 1
static double theta[16] = {    /*   -90 < theta < 90   latitude */
  -78.7500, -56.2500, -39.3750, -28.1250
, -19.6875, -14.0625, -8.43750, -2.81250
,  2.81250,  8.43750,  14.0625,  19.6875
,  28.1250,  39.3750,  56.2500,  78.7500
};
#else
static double theta[16] = {    /*   0 < theta < 180   Co-latitude */
  168.75000, 146.25000, 129.37500, 118.12500
, 109.68750, 104.06250, 98.437500, 92.812500
, 87.187500, 81.562500, 75.937500, 70.312500
, 61.875000, 50.625000, 33.750000, 11.250000
};
#endif


static double dphi = 5.625;

static double dtheta[16] = { 22.5,  22.5, 11.25, 11.25, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 11.25, 11.25,  22.5,  22.5  };
static double gf[16] = {      4.0,   4.0,   2.0,   2.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   1.0,   2.0,   2.0,   4.0,   4.0  };



static float domega[]={
    0.0074731094,   0.021281615,    0.014877066,      0.016973122,
    0.0090712266,    0.0093456840,    0.0095301373,    0.0096228102,
    0.0096228102,    0.0095301373,    0.0093456840,   0.0090712266,
     0.016973122,     0.014877066,     0.021281615,    0.0074731094
 };



int decom_pl_snapshot_5x5(packet *pk,pl_snap_55 *snap)
{
	int p,e,t,i,ts,ps1,es;
	double nrg[14], dnrg[14], n0;
	uchar *d;
	PCFG *cfg;

	if(pk==0)
		return(0);

	snap->time = pk->time;
	
	if(pk->quality & (~pkquality)) {
		return(0);
	}

	cfg = get_PCFG(pk->time);
	snap->spin = pk->spin;

	es = (pk->instseq >> 8) & 0xff;
	ts = (pk->instseq     ) & 0x0f;
	ps1 = (pk->instseq >> 4) & 0x0f;
	
	snap->e_shift = (uchar) es;
	snap->t_shift = (uchar) ts;
	snap->p_shift = (uchar) ps1;
	
	snap->delta_t = cfg->spin_period*4;    /*  Quick fix; must be fixed */
	snap->integ_t = cfg->spin_period;
	d = pk->data;

	for(p=0;p<5;p++)
		for(e=0;e<14;e++)
			for(t=0;t<5;t++){
				snap->flux[t][p][e] = decomp19_8( *d++ );
				snap->dt[t][p][e] = snap->integ_t/64./16.;
/*				snap->gf[t][p][e] = 1.;  */
			}

	for(e=0;e<14*4;e++){
		snap->dac_code[e]     = cfg->pldac_tbl[e+es];
		snap->volts[e] = cfg->pl_volts_tbl[e+es];
	}

	get_esteps_pl14(nrg,es,MIDDLE,cfg);
	get_esteps_pl14(dnrg,es,WIDTH,cfg);

	for(p=0;p<5;p++)
		for(t=0;t<5;t++)
			snap->domega[t][p] = domega[t+ts];

        for(e=0;e<14;e++)
	for(p=0;p<5;p++)
	for(t=0;t<5;t++){
		snap->phi[t][p][e] = 225.- ((p+ps1)*16+e)*(5.625/16.);
		snap->dphi[t][p][e] = dphi;
		snap->theta[t][p][e] = theta[t+ts];
		snap->dtheta[t][p][e] = dtheta[t+ts];
		snap->gf[t][p][e] = gf[t+ts];
		snap->nrg[t][p][e] = nrg[e];
		snap->dnrg[t][p][e] = dnrg[e];
		snap->dvolume[t][p][e] = dnrg[e]/nrg[e]*snap->domega[t][p];
	}


	snap->valid= 1;

	return(1);
}

int decom_pl_snapshot_8x8_2(packet *pk1, packet *pk2, pl_snap_8x8 *snap)
{
	packet *pk;
	int p,e,t,i,es,ts,ps1,ps2,ps;
	double nrg[14], dnrg[14], n0;
	uchar *d;
	PCFG *cfg;

	snap->valid = 0;
	if(pk1==0 || pk2==0)
		return(0);
	if(pk1->spin != pk2->spin)
		return(1);

	ps1 = (pk1->instseq >> 4) & 0x0f;
	ps2 = (pk2->instseq >> 4) & 0x0f;

	if(ps2 < ps1){   /* packets out of order; swap them  */
		pk = pk1; pk1 = pk2;  pk2 = pk;
		ps = ps1; ps1 = ps2;  ps2 = ps;
	}
	if(ps2 != ps1 + 4){
		return(1);
	}
	
	pk = pk1;

	cfg = get_PCFG(pk->time);
	snap->time = pk->time;
	snap->spin = pk->spin;

	es = (pk->instseq >> 8) & 0xff;
	ts = (pk->instseq     ) & 0x0f;
	ps1 = (pk->instseq >> 4) & 0x0f;

	snap->e_shift = (uchar) es;
	snap->t_shift = (uchar) ts;
	snap->p_shift = (uchar) ps1;

	snap->delta_t = cfg->spin_period*4;    /*  Quick fix; must be fixed */
	snap->integ_t = cfg->spin_period;

	d = pk1->data;
	for(p=0;p<4;p++)
		for(e=0;e<14;e++)
			for(t=0;t<8;t++){
				snap->flux[t][p][e] = decomp19_8( *d++ );
				snap->dt[t][p][e] = snap->integ_t/64./16.;
/*				snap->gf[t][p][e] = 1.; */
			}

	d = pk2->data;
	for(p=4;p<8;p++)
		for(e=0;e<14;e++)
			for(t=0;t<8;t++){
				snap->flux[t][p][e] = decomp19_8( *d++ );
				snap->dt[t][p][e] = snap->integ_t/64./16.;
/*				snap->gf[t][p][e] = 1.; */
			}

	for(e=0;e<14*4;e++){
		snap->dac_code[e]     = cfg->pldac_tbl[e+es];
		snap->volts[e] = cfg->pl_volts_tbl[e+es];
	}

	get_esteps_pl14(nrg,es,MIDDLE,cfg);
	get_esteps_pl14(dnrg,es,WIDTH,cfg);

	for(p=0;p<8;p++)
		for(t=0;t<8;t++)
			snap->domega[t][p] = domega[t+ts];

        for(e=0;e<14;e++)
	for(p=0;p<8;p++)
	for(t=0;t<8;t++){
		snap->phi[t][p][e] = 225.- ((p+ps1)*16+e)*(5.625/16.);
		snap->dphi[t][p][e] = dphi;
		snap->theta[t][p][e] = theta[t+ts];
		snap->dtheta[t][p][e] = dtheta[t+ts];
		snap->gf[t][p][e] = gf[t+ts];
		snap->nrg[t][p][e] = nrg[e];
		snap->dnrg[t][p][e] = dnrg[e];
		snap->dvolume[t][p][e] = dnrg[e]/nrg[e]*snap->domega[t][p];
	}


	snap->valid= 1;


	return(1);
}





/* 
returns a valid snap structure on every other call 
*/
#if 1
int decom_pl_snapshot_8x8(packet *pk, pl_snap_8x8 *snap)
{
	static packet buffpk1;   /* temporary packet buffer */
	static packet buffpk2;
	int s1;
	
	snap->valid = 0;
	if(pk==0) {
		return(0);
	}
	
	if(pk->quality & (~pkquality)) {
		snap->time = pk->time;
		return(0);
	}

	decompress_burst_packet(&buffpk2,pk);
	if(buffpk1.idtype){
		decom_pl_snapshot_8x8_2(&buffpk1,&buffpk2,snap);
		if(snap->valid){
			buffpk1.idtype=0;
			return(1);
		}
	}
	buffpk1 = buffpk2;
	return(1);
}

#endif
#if 0

/*
decom_pl_snapshot_8x8_2:
Extracts information from a pair of (uncompressed) packets and puts the
results in a structure of type pl_snap_8x8
*/
int decom_pl_snapshot_8x8_2(packet *pk1,packet *pk2, pl_snap_8x8 *snap)
{
	packet *pk;
	int p,e,t,ts;
	int ps1,ps2,ps;
	double nrg[14], dnrg[14];
	uchar *d;
	PCFG *cfg;

	snap->valid = 0;
	if(pk1==0 || pk2==0)
		return(0);
	if(pk1->spin != pk2->spin)
		return(1);
	
	ps1 = (pk1->instseq >> 4) & 0x0f;
	ps2 = (pk2->instseq >> 4) & 0x0f;

	if(ps2 < ps1){   /* packets out of order; swap them  */
		pk = pk1; pk1 = pk2;  pk2 = pk;
		ps = ps1; ps1 = ps2;  ps2 = ps;
	}
	if(ps2 != ps1 + 4)
		return(1);

	pk = pk1;
	cfg = get_PCFG(pk->time);
	snap->time = pk->time;
	snap->spin = pk->spin;
	snap->ps1 = ps1;
	snap->ps2 = ps2;
	snap->es = (pk->instseq >> 8) & 0xff;
	snap->ts = (pk->instseq     ) & 0x0f;
	snap->delta_t = cfg->spin_period;    /* Quick fix; must be improved */
	snap->integ_t = cfg->spin_period;

	d = pk1->data;
	for(p=0;p<4;p++)
		for(e=0;e<14;e++)
			for(t=0;t<8;t++){
				snap->flux[t][p][e] = decomp19_8( *d++ );
			}

	d = pk2->data;
	for(p=4;p<8;p++)
		for(e=0;e<14;e++)
			for(t=0;t<8;t++){
				snap->flux[t][p][e] = decomp19_8( *d++ );
			}

	for(e=0;e<14*4;e++){
		snap->dac_code[e]     = cfg->pldac_tbl[e+snap->es];
		snap->volts[e] = cfg->pl_volts_tbl[e+snap->es];
	}

	get_esteps_pl14(nrg,snap->es,MIDDLE,cfg);
	get_esteps_pl14(dnrg,snap->es,WIDTH,cfg);

	ps1 = snap->ps1;
        for(e=0;e<14;e++)
	for(p=0;p<8;p++)
	for(t=0;t<8;t++){
		snap->phi[t][p][e] = 225.- ((p+ps1)*16+e)*(5.625/16.);
		snap->dphi[t][p][e] = dphi;
		snap->theta[t][p][e] = theta[t+ts];
		snap->dtheta[t][p][e] = dtheta[t+ts];
		snap->nrg[t][p][e] = nrg[e];
		snap->dnrg[t][p][e] = dnrg[e];
	}
	for(p=0;p<8;p++)
		for(t=0;t<8;t++)
			snap->domega[t][p] = domega[t+ts];

	snap->valid= 1;

/* The following are retained for SDT compatibility  */

	get_esteps_pl14(snap->nrg_min,snap->es,MIN,cfg);
	get_esteps_pl14(snap->nrg_max,snap->es,MAX,cfg);

	for(p=0;p<8;p++){
		snap->phi_min[p] = snap->phi[t][p][7] - 5.625/2.;
		snap->phi_max[p] = snap->phi[t][p][7] + 5.625/2.;
	}
	for(t=0;t<8;t++){
		snap->theta_min[t] = snap->theta[t][p][7] - 5.625/2.;
		snap->theta_max[t] = snap->theta[t][p][7] + 5.625/2.;
	}
	

	return(1);
}
#endif



int4 pl5x5_to_idl(int argc,void *argv[])
{
	pl_snap_55 *snap;
	int4 size,advance,index,*options,ok;
 	double *time;
        static packet_selector pks;
        pklist *pkl;

	if(argc == 0)
		return( number_of_plsnap55_samples( 0.,1e12) );
	if(argc != 3 && argc !=2){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
        options = (int4 *)argv[0];
	time = (double *)argv[1];
        snap = (pl_snap_55 *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(PLSNAP_ID,size,time);
            return(ok);
        }

        if(size != sizeof(pl_snap_55)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(pl_snap_55));
            return(0);
        }

	if (advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+advance,PLSNAP_ID) ;
	}
	else if (index < 0) {    /* negative index means get by time*/
	    SET_PKS_BY_TIME(pks,time[0],PLSNAP_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,index,PLSNAP_ID) ;
	}
	
	ok = get_next_plsnap55_struct(&pks,snap);
        snap->index = pks.index;

	return(ok);

}

int4 pl8x8_to_idl(int argc,void *argv[])
{
	pl_snap_8x8 *snap;
	int4 size,advance,index,*options,ok;
 	double *time;
        static packet_selector pks;
        pklist *pkl;

	if(argc == 0)
		return( number_of_plsnap88_samples( 0.,1e12) );
	if(argc != 3 && argc !=2){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
        options = (int4 *)argv[0];
	time = (double *)argv[1];
        snap = (pl_snap_8x8 *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(P_SNAP_BST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(pl_snap_8x8)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(pl_snap_8x8));
            return(0);
        }

	if (advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+advance,P_SNAP_BST_ID) ;
	}
	else if (index < 0) {    /* negative index means get by time*/
	    SET_PKS_BY_TIME(pks,time[0],P_SNAP_BST_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,index,P_SNAP_BST_ID) ;
	}
	
	ok = get_next_plsnap88_struct(&pks,snap);
        snap->index = pks.index;

	return(ok);

}
