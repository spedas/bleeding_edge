#include <math.h>
#include "sst_dcm.h"
#include "main_cfg.h"
#include "windmisc.h"

#include "brst_dcm.h"

#define DOMEGA1 0.299995
#define DOMEGA2 0.392699
#define DOMEGA3 0.242701
 
static float domega_OF[48] = {
       DOMEGA1,      DOMEGA1,      DOMEGA2,      DOMEGA2,      DOMEGA2,      DOMEGA2,
       DOMEGA3,       DOMEGA3,     DOMEGA3,       DOMEGA3,       DOMEGA3,       DOMEGA3,
       DOMEGA3,       DOMEGA3,     DOMEGA2,     DOMEGA2,       DOMEGA2,     DOMEGA2,
       DOMEGA1,     DOMEGA1,      DOMEGA2,      DOMEGA2,      DOMEGA2,      DOMEGA2,
       DOMEGA1,      DOMEGA1,      DOMEGA2,      DOMEGA2,      DOMEGA2,      DOMEGA2,
       DOMEGA3,       DOMEGA3, DOMEGA3,       DOMEGA3,       DOMEGA3,       DOMEGA3,
       DOMEGA3,       DOMEGA3,     DOMEGA2,     DOMEGA2,    DOMEGA2,     DOMEGA2,
       DOMEGA1,     DOMEGA1,      DOMEGA2,      DOMEGA2,      DOMEGA2,      DOMEGA2
};

static float gf_F[48] = {1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,1,1,0.075,0.075,0.075,0.075,
	1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,1,1,0.075,0.075,0.075,0.075};
	
static float gf_O[48] = {1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,0.75,0.75,0.075,0.075,0.075,0.075,
	1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,0.75,0.75,0.075,0.075,0.075,0.075};

static float gf_FT[16] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

static float gf_OT[16] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

static int rel_times[48] = {4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,2,2,2,2,
			    4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,2,2,2,2};
			    
int number_of_sst_3d_burst_samples(double t1,double t2)
{
	return(number_of_packets(S_HS_BST_ID,t1,t2));
}

int number_of_sst_3d_O_samples(double t1,double t2)
{
	return(number_of_packets(S_3D_O_ID,t1,t2));
}


static uchar ptmap_O48[5][32] = {
24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,25,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,2,2,2,2,3,3,3,3, 4, 4, 4, 4, 5, 5, 5, 5,26,
30,31,31,32,32,33,33,34,34,35,35,36,36,37,37,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,30,
14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,38,38,38,38,39,39,39,39,40,40,40,40,41,41,41,41,
18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,42,42,42,42,42,42,42,42,43,43,43,43,43,43,43,43,
};

    static float phimap_O[48] = {
           0,     270,   33.75,  348.75,  303.75,  258.75,      45,    22.5,
           0,   337.5,     315,   292.5,     270,   247.5,   202.5,   157.5,
       112.5,    67.5,     180,      90,    22.5,   337.5,   292.5,   247.5,
         180,      90,  213.75,  168.75,  123.75,   78.75,     225,   202.5,
         180,   157.5,     135,   112.5,      90,    67.5,    22.5,   337.5,
       292.5,   247.5,       0,     270,   202.5,   157.5,   112.5,    67.5
    };

    static float thetamap_O[48] = {
          72,      72,      36,      36,      36,      36,       0,       0,
           0,       0,       0,       0,       0,       0,     -36,     -36,
         -36,     -36,     -72,     -72,      36,      36,      36,      36,
          72,      72,      36,      36,      36,      36,       0,       0,
           0,       0,       0,       0,       0,       0,     -36,     -36,
         -36,     -36,     -72,     -72,      36,      36,      36,      36
    };

static float dphi_O[48] = {
90., 90., 45., 45., 45., 45., 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5,
45., 45., 45., 45., 90., 90., 45., 45., 45., 45., 90., 90., 45., 45., 
45., 45., 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 45., 45., 45., 45., 
90., 90., 45., 45., 45., 45.
};

static float dtheta_O[48] = {
36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 
};



static int geom_O[48] = {4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,
                         2,2,2,2,
                         4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,
                         2,2,2,2,  };


static int duty_cycle_O[9] = { 1,1,2,2,4,4,8,8,8 };


/* The following routine is preliminary! */
/* It must be made more robust. */
/* It currently assumes that all 8 packets in a sequence, exist and are in order */

/* The mode parameter determines if we get all energy channels or only the */
/* ones available at the time selected.  mode == 0 means get all channels, */
/*   else get just the ones arriving in the selected packet. */
/* The validmask will be a bitmask of good energy channels retrieved */

get_next_sst_3d_O_str(packet_selector *pksel,sst_3d_O_distribution *dist, int mode,
		      uint2 *validmask)
{
	static packet *pk;

	packet *pkt, *pks[8];
	int    base;   /* base integration rate */
	uint2  spin; 
	int    seq;    /* sequence in packet stream */
	int  a,e,t,p;   
	int i;
	int valid = 0;
	MCFG *mcfg;

	dist->valid = 0;

	pk = get_packet(pksel);
	if(pk==0)
		return(0);

	if(pk->quality & (~pkquality)) {
		dist->time = pk->time;
		return(0);
	}
	
	mcfg = get_MCFG(pk->time);

	/* get energy values  */

	get_nrg_3d_O(dist->e_min,108,SSTMIN,mcfg);
	get_nrg_3d_O(dist->e_max,108,SSTMAX,mcfg);
	get_nrg_3d_O(dist->energies,108,SSTMID,mcfg);


	for(t=0;t<5;t++)
		for(p=0;p<32;p++)
			dist->pt_map[t][p] = ptmap_O48[t][p];

	for(a=0;a<48;a++){
		dist->theta[a] = thetamap_O[a];
		dist->phi[a] = phimap_O[a];
		dist->geom[a] = geom_O[a];
		dist->dtheta[a] = dtheta_O[a];
		dist->dphi[a] = dphi_O[a];
		dist->domega[a] = domega_OF[a];
	}

	for(e=0;e<9;e++)
		dist->duty_cycle[e] = duty_cycle_O[e]/16.;


	if((pk->idtype & 0xff00) == 0xb400) {		


        packet temp;

                decompress_burst_packet(&temp,pk);
        fill_sst_3d_O_distribution(&temp,dist);
			pk = pk->next;
	if(pk==0)
		return(0);
		
	if(pk->quality & (~pkquality)) {
		dist->time = pk->time;
		return(0);
	}
	
        decompress_burst_packet(&temp,pk);
        fill_sst_3d_O_distribution(&temp,dist);
        dist->spin_period = mcfg->spin_period;
	dist->valid = 1;
	dist->integ_t = mcfg->spin_period;
	dist->delta_t = mcfg->spin_period;
	dist->ne =  9 ;
	    *validmask |= 0x0003 ;

        return(1);
}
	else {

	/* collect next 8 packet pointers */

	pkt = pk;
	for(i=0;i<8;i++){
		pks[i] = pkt;
		if(pkt)
			pkt = pkt->next;
		else                        /* quick bug fix */
			return(0);          /* quick bug fix */
	}

	/* clear data */

	for(a=0;a<14;a++)
		dist->rates[a] = 0;
	for(a=0;a<48;a++)
		for(e=0;e<9;e++) {
			dist->flux[e][a] = 0;
			dist->dt[e][a] = 0;
		}

	base = pk->idtype & 0x0f;
	spin = pk->spin;

	if (base == 0) {
		dist->valid = 0;
		return(0);
	}
	
	seq = ((int)spin/base + 7) % 8;

	/* make sure all 8 packets are present (no gaps) and in order */

	for (i = 1; i < 8; i++)
	    if ((pks[i]->spin - pk->spin) != (i * base))
		{
		    *validmask = 0;
		    return(1);
		}
	
	dist->integ_t = base * mcfg->spin_period;
	dist->delta_t = base * mcfg->spin_period;


	{
	int flag = 0;
	*validmask = 0;
	switch(seq){
	case 0:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[7],dist);
		flag |= fill_sst_3d_O_distribution(pks[3],dist);
		flag |= fill_sst_3d_O_distribution(pks[1],dist);
		*validmask |= 0x01fc ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 1:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[6],dist);
		flag |= fill_sst_3d_O_distribution(pks[2],dist);
		*validmask |= 0x01f0 ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x000f ;
	    break;
	case 2:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[5],dist);
		flag |= fill_sst_3d_O_distribution(pks[1],dist);
		*validmask |= 0x01fc ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 3:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[4],dist);
		*validmask |= 0x01c0 ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x003f ;
	    break;
	case 4:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[3],dist);
		flag |= fill_sst_3d_O_distribution(pks[1],dist);
		*validmask |= 0x01fc ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 5:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[2],dist);
		*validmask |= 0x01f0 ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x000f ;
	    break;
	case 6:
	    if (!mode) {
		flag |= fill_sst_3d_O_distribution(pks[1],dist);
		*validmask |= 0x01fc ;
	    }
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 7:
	    flag |= fill_sst_3d_O_distribution(pks[0],dist);
	    *validmask |= 0x01ff ;
	    break;
	}
	valid = ((flag + seq) == 15) ? 1 : 0;
	}

	/* If everything went ok then 'valid' should have non-zero value */

	dist->ne = (valid) ? 9 : 0;

	return(1);
    }
}


int number_of_sst_3d_F_samples(double t1,double t2)
{
	return(number_of_packets(S_3D_F_ID,t1,t2));
}



static uchar ptmap_F48[5][32] = {
24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,25,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
26,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,2,2,2,2,3,3,3,3, 4, 4, 4, 4, 5, 5, 5, 5,
6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,30,30,31,31,32,32,33,33,34,34,35,35,36,36,37,37,6,
14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,38,38,38,38,39,39,39,39,40,40,40,40,41,41,41,41,14,
18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,42,42,42,42,42,42,42,42,43,43,43,43,43,43,43,43,
};

    static float phimap_F[48] = {
           0,     270,    22.5,   337.5,   292.5,   247.5,     225,   202.5,
         180,   157.5,     135,   112.5,      90,    67.5,  213.75,  168.75,
      123.75,   78.75,     180,      90,   202.5,   157.5,   112.5,    67.5,
         180,      90,   202.5,   157.5,   112.5,    67.5,      45,    22.5,
           0,   337.5,     315,   292.5,     270,   247.5,   33.75,  348.75,
      303.75,  258.75,       0,     270,    22.5,   337.5,   292.5,   247.5
    };

    static float thetamap_F[48] = {
          72,      72,      36,      36,      36,      36,       0,       0,
           0,       0,       0,       0,       0,       0,     -36,     -36,
         -36,     -36,     -72,     -72,     -36,     -36,     -36,     -36,
          72,      72,      36,      36,      36,      36,       0,       0,
           0,       0,       0,       0,       0,       0,     -36,     -36,
         -36,     -36,     -72,     -72,     -36,     -36,     -36,     -36
    };

static float dphi_F[48] = {
90., 90., 45., 45., 45., 45., 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5,
45., 45., 45., 45., 90., 90., 45., 45., 45., 45., 90., 90., 45., 45., 
45., 45., 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 45., 45., 45., 45., 
90., 90., 45., 45., 45., 45.
};

static float dtheta_F[48] = {
36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36., 36.,
36., 36., 
};

static int geom_F[48] = {4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,
                         2,2,2,2,
                         4,4,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,4,4,
                         2,2,2,2,  };

static int duty_cycle_F[7] = { 1,1,2,2,4,4,4 };


/* The following routine is preliminary! */
/* It must be made more robust. */
/* It currently assumes that all 4 packets in a sequence, exist and are in order */

/* The mode parameter determines if we get all energy channels or only the */
/* ones available at the time selected.  mode == 0 means get all channels, */
/*   else get just the ones arriving in the selected packet. */
/* The validmask will be a bitmask of good energy channels retrieved */

get_next_sst_3d_F_str(packet_selector *pksel,sst_3d_F_distribution *dist, int mode,
		      uint2 *validmask)
{
	static packet *pk;

	packet *pkt, *pks[4];
	int    base;   /* base integration rate */
	uint2  spin; 
	int    seq;    /* sequence in packet stream */
	int  a,e,t,p;   
	int i;
	int valid = 0;
	MCFG *mcfg;

	dist->valid = 0;

	pk = get_packet(pksel);
	if(pk==0)
		return(0);

	if(pk->quality & (~pkquality)){
		dist->time = pk->time;
		return(0);
	}

	mcfg = get_MCFG(pk->time);

	/* get energy values  */

	get_nrg_3d_F(dist->e_min,84,SSTMIN,mcfg);
	get_nrg_3d_F(dist->e_max,84,SSTMAX,mcfg);
	get_nrg_3d_F(dist->energies,84,SSTMID,mcfg);
	get_nrg_3d_F(dist->e_eff,84,SSTEFF,mcfg);
	

	for(t=0;t<5;t++)
		for(p=0;p<32;p++)
			dist->pt_map[t][p] = ptmap_F48[t][p];

	for(a=0;a<48;a++){
		dist->theta[a] = thetamap_F[a];
		dist->phi[a] = phimap_F[a];
		dist->geom[a] = geom_F[a];
		dist->dtheta[a] = dtheta_F[a];
		dist->dphi[a] = dphi_F[a];
		dist->domega[a] = domega_OF[a];
	}

	for(e=0;e<7;e++)
		dist->duty_cycle[e] = duty_cycle_F[e]/16.;


	if((pk->idtype & 0xff00) == 0xb400) {		

        packet temp;

                decompress_burst_packet(&temp,pk);
	fill_sst_3d_F_distribution(&temp,dist);
			pk = pk->next;
	if(pk==0)
		return(0);
	
	if(pk->quality & (~pkquality)){
		dist->time = pk->time;
		return(0);
	}
	
        decompress_burst_packet(&temp,pk);
	fill_sst_3d_F_distribution(&temp,dist);
        dist->spin_period = mcfg->spin_period;
	dist->valid = 1;
	dist->integ_t = mcfg->spin_period;
	dist->delta_t = mcfg->spin_period;
	dist->ne =  7 ;
	    *validmask |= 0x0003 ;

        return(1);
}
	else {

	pkt = pk;

	/* collect next 4 packet pointers */

	for(i=0;i<4;i++){
		pks[i] = pkt;
		if(pkt)
			pkt = pkt->next;
		else                        /* quick bug fix */
			return(0);          /* quick bug fix */
		 
	}

	/*  clear data */

	for(a=0;a<48;a++)
		for(e=0;e<7;e++) {
			dist->flux[e][a] = 0;
			dist->dt[e][a] = 0;
		}

	base = pk->idtype & 0x0f;
	spin = pk->spin;
	if (base == 0) {
		dist->valid = 0;
		return(0);
	}
	
	seq = ((int)spin/base + 3) % 4;

	/* make sure all 4 packets are present (no gaps) and in order */

	for (i = 1; i < 4; i++)
	    if ((pks[i]->spin - pk->spin) != (i * base))
		{
		    *validmask = 0;
		    return(1);
		}

	*validmask = 0;
        dist->spin_period = mcfg->spin_period;


	{
	int flag = 0;
	switch(seq){
	case 0:
	    if (!mode) {
		flag |= fill_sst_3d_F_distribution(pks[3],dist);
		flag |= fill_sst_3d_F_distribution(pks[1],dist);
		*validmask |= 0x007c ;
	    }
	    flag |= fill_sst_3d_F_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 1:
	    if (!mode) {
		flag |= fill_sst_3d_F_distribution(pks[2],dist);
		*validmask |= 0x0070 ;
	    }
	    flag |= fill_sst_3d_F_distribution(pks[0],dist);
	    *validmask |= 0x000f ;
	    break;
	case 2:
	    if (!mode) {
		flag |= fill_sst_3d_F_distribution(pks[1],dist);
		*validmask |= 0x007c ;
	    }
	    flag |= fill_sst_3d_F_distribution(pks[0],dist);
	    *validmask |= 0x0003 ;
	    break;
	case 3:
	    flag |= fill_sst_3d_F_distribution(pks[0],dist);
	    *validmask |= 0x007f ;
	    break;
	}
	valid = ((flag + seq) == 7) ? 1 : 0;
	}

	/* If everything went ok then 'valid' should have non-zero value */

	dist->ne = (valid) ? 7 : 0;

	return(1);
   }
}

int number_of_sst_T_samples(double t1,double t2)
{
	return(number_of_packets(S_T_DST_ID,t1,t2));
}


/*
static uchar ptmap_FT2_8[8] = {0,1,2,3,4,5,6,7};
static uchar ptmap_OT2_8[8] = {12,13,14,15,8,9,10,11};
*/
static int2 ptmap_FT6_16[5][8]= {-1,-1,-1,-1,-1,-1,-1,-1,
				  -1,-1,-1,-1,-1,-1,-1,-1,
				  -1,-1,-1,-1,-1,-1,-1,-1,
				   0, 1, 2, 3, 4, 5, 6, 7,
				  -1,-1,-1,-1,-1,-1,-1,-1};
static int2 ptmap_OT6_16[5][8]= {-1,-1,-1,-1,-1,-1,-1,-1,
				   4, 5, 6, 7, 0, 1, 2, 3,
				  -1,-1,-1,-1,-1,-1,-1,-1,
				  -1,-1,-1,-1,-1,-1,-1,-1,
				  -1,-1,-1,-1,-1,-1,-1,-1};

static float phimap_FT2[32]  = {337.5,22.5,67.5,112.5,157.5,202.5,247.5,292.5,
/*static float phimap_OT2[8] =*/ 337.5,22.5,67.5,112.5,157.5,202.5,247.5,292.5,
/*static float phimap_FT6[8] =*/ 326.25,11.25,56.25,101.25,146.25,191.25,236.25,281.25,
/*static float phimap_OT6[8] =*/ 326.25,11.25,56.25,101.25,146.25,191.25,236.25,281.25};

static float thetamap_FT2[32]  = {-36.,-36.,-36.,-36.,-36.,-36.,-36.,-36.,
	-36.,-36.,-36.,-36.,-36.,-36.,-36.,-36.,
	-36.,-36.,-36.,-36.,-36.,-36.,-36.,-36.,
	-36.,-36.,-36.,-36.,-36.,-36.,-36.,-36.};


/* The following routine is preliminary! */
/* It must be made more robust. */

get_next_sst_3d_T_str(packet_selector *pksel,sst_t_distribution *tdist)
{
	static packet *pk;

	packet *pkt, *pks[4];
	int    base;   /* base integration rate */
	uint2  spin; 
	int    seq;    /* sequence in packet stream */
	int  a,e,t,p;   
	int i;
	int valid = 0;
	MCFG *mcfg;

	tdist->valid = 0;

	pk = get_packet(pksel);
	if(pk==0)
		return(0);

	if(pk->quality & (~pkquality)){
		tdist->time = pk->time;
		return(0);
	}
			
	mcfg = get_MCFG(pk->time);

	/* get energy values  */

	get_nrg_3d_FT(tdist->e_FT_min,14,SSTMIN,mcfg);
	get_nrg_3d_FT(tdist->e_FT_max,14,SSTMAX,mcfg);
	get_nrg_3d_FT(tdist->e_FT_mid,14,SSTMID,mcfg);
	get_nrg_3d_FT(tdist->e_FT_eff,14,SSTEFF,mcfg);
	get_nrg_3d_OT(tdist->e_OT_min,18,SSTMIN,mcfg);
	get_nrg_3d_OT(tdist->e_OT_mid,18,SSTMID,mcfg);
	get_nrg_3d_OT(tdist->e_OT_max,18,SSTMAX,mcfg);

	for(t=0;t<5;t++) {
		for(p=0;p<8;p++) {
			tdist->pt_FT_map[t][p] = ptmap_FT6_16[t][p];
			tdist->pt_OT_map[t][p] = ptmap_OT6_16[t][p];}}

	for(a=0;a<32;a++){
		tdist->theta[a] = thetamap_FT2[a];
		tdist->phi[a] = phimap_FT2[a];
		tdist->geom[a] = 2;
		tdist->dtheta[a] = 36;
		tdist->dphi[a] = 45;
	}

	for(e=0;e<9;e++)
		tdist->duty_cycle[e] = 1/16.;

	pkt = pk;

	base = pk->idtype & 0x0f;
	spin = pk->spin;

	tdist->integ_t = 8 * base * mcfg->spin_period;
	tdist->delta_t = 8 * base * mcfg->spin_period;
	tdist->spin_period = mcfg->spin_period;

	tdist->valid |=  fill_sst_t_distribution(pk,tdist);
	
	return(1);
}

static uchar ptmap_F6[6]= {3,2,4,5,0,1};
static float thetamap_F6[6]  = {72.,36.,0.,-36.,-72.,-36.};
static uchar ptmap_O6[6]= {0,5,4,2,3,1};
static float thetamap_O6[6]  = {72.,36.,0.,-36.,-72.,36.};

int number_of_sst_spectra_samples(double t1,double t2)
{
	return(number_of_packets(S_RATE3_ID,t1,t2));
}

/* The following routine is preliminary! */
/* It must be made more robust. */

get_next_sst_spectra_str(packet_selector *pksel,struct sst_spectra_struct *sst)
{
	static packet *pk;

	packet *pkt;
	int    base;   /* base integration rate */
	uint2  spin; 
	int    seq;    /* sequence in packet stream */
	int  a,e,t,p;   
	int i;
	int valid = 0;
	MCFG *mcfg;

	sst->valid = 0;

	pk = get_packet(pksel);
	if(pk==0)
		return(0);

	if(pk->quality & (~pkquality)){
		sst->time = pk->time;
		return(0);
	}

	mcfg = get_MCFG(pk->time);

	/* get energy values  */
	get_nrg_spect_F(sst->e_F_min,192,SSTMIN,mcfg);
	get_nrg_spect_F(sst->e_F_mid,192,SSTMID,mcfg);
	get_nrg_spect_F(sst->e_F_max,192,SSTMAX,mcfg);
	get_nrg_spect_F(sst->e_F_eff,192,SSTEFF,mcfg);
	get_nrg_spect_O(sst->e_O_min,288,SSTMIN,mcfg);
	get_nrg_spect_O(sst->e_O_mid,288,SSTMID,mcfg);
	get_nrg_spect_O(sst->e_O_max,288,SSTMAX,mcfg);
	get_nrg_spect_FT(sst->e_FT_min,48,SSTMIN,mcfg);
	get_nrg_spect_FT(sst->e_FT_mid,48,SSTMID,mcfg);
	get_nrg_spect_FT(sst->e_FT_max,48,SSTMAX,mcfg);
	get_nrg_spect_FT(sst->e_FT_eff,48,SSTEFF,mcfg);
	get_nrg_spect_OT(sst->e_OT_min,48,SSTMIN,mcfg);
	get_nrg_spect_OT(sst->e_OT_mid,48,SSTMID,mcfg);
	get_nrg_spect_OT(sst->e_OT_max,48,SSTMAX,mcfg);


	for(t=0;t<6;t++) {
			sst->pt_F_map[t] = ptmap_F6[t];
		sst->theta_f[t] = thetamap_F6[t];
			sst->pt_O_map[t] = ptmap_O6[t];}
		sst->theta_o[t] = thetamap_F6[t];

	for(a=0;a<6;a++){
		sst->phi[a] = 0;
		sst->geom[a] = 1;
		sst->dtheta[a] = 36;
		sst->dphi[a] = 45;
	}

	for(e=0;e<24;e++)
		sst->duty_cycle[e] = 1;

	if((pk->idtype & 0xff00) == 0xb400) {		

        packet temp;

                decompress_burst_packet(&temp,pk);
        sst->valid |=  fill_sst_spectra_struct(&temp,sst);
        
	spin = sst->spin;

	sst->integ_t = mcfg->spin_period;
	sst->delta_t = mcfg->spin_period;

        return(1);
}
	else {

	pkt = pk;

	base = pk->idtype & 0x0f;
	spin = pk->spin;


	sst->integ_t = 8 * base * mcfg->spin_period;
	sst->delta_t = 8 * base * mcfg->spin_period;


	sst->valid |=  fill_sst_spectra_struct(pk,sst);

	return(1);
}
}


/* to be used with packets of type 0880   */

int fill_sst_flat_rate_str(packet *pk,struct sst_flat_rate_str *sst)
{
	uchar *d;
	int i,j;

	sst->time = pk->time;
        sst->spin = pk->spin;
	d = pk->data;
	sst->magaz = str_to_uint2(d);
	sst->magel = d[2];
	d +=3;
	for(i=0;i<16;i++)
		for(j=0;j<14;j++)
			sst->flux[j][i] = decomp19_8(*d++);
	return(1);
}





/* to be used with packets of type 0810, 341x, and 401x */

int fill_sst_spectra_struct(packet *pk,struct sst_spectra_struct *sst)
{
	uchar *d;
	int i;

	if(pk==0){
		sst->valid =0;
		return(0);
	}

	sst->time = pk->time;
	sst->spin = pk->spin;
	sst->pulse_mode  = (pk->instseq & 0xf0u) >> 4;
	sst->operating_mode = (pk->instseq & 0x0f);
	if((pk->idtype & 0xff00) == 0x4000)		
		sst->integration_factor = (pk->idtype & 0x0f);
	else
		sst->integration_factor = 1;    /* not known!  */
	d = pk->data;
	sst->magaz = str_to_uint2(d);
	sst->magel = d[2];


	d +=3;
	for(i=0;i<14;i++)
		sst->rates[i] = decomp19_8(*d++);

	for(i=0;i<24;i++)
		sst->FT2[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->OT2[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->FT6[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->OT6[i] = decomp19_8(*d++);

	for(i=0;i<16;i++)
		sst->F6[i] = decomp19_8(*d++);
	for(i=0;i<16;i++)
		sst->F2[i] = decomp19_8(*d++);
	for(i=0;i<16;i++)
		sst->F3[i] = decomp19_8(*d++);
	for(i=0;i<16;i++)
		sst->F4[i] = decomp19_8(*d++);
	for(i=0;i<16;i++)
		sst->F5[i] = decomp19_8(*d++);
	for(i=0;i<16;i++)
		sst->F1[i] = decomp19_8(*d++);

	for(i=0;i<24;i++)
		sst->O6[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->O2[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->O3[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->O4[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->O5[i] = decomp19_8(*d++);
	for(i=0;i<24;i++)
		sst->O1[i] = decomp19_8(*d++);
	for(i=0;i<6;i++)
		if(pk->idtype == 0x0810)
			sst->calib_control[i] = *d++;
		else
			sst->calib_control[i] = 0;
	return(1);
}




/********* T-distributions   (342x, 402x)   ****************/


int fill_sst_t_distribution(packet *pk, sst_t_distribution *tdist)
{
	int e,p;
	uchar *d;

	if(pk==0){
		tdist->valid =0;
		return(0);
	}
	tdist->time = pk->time;
        tdist->spin = pk->spin;
	d = pk->data;
		for(p=0;p<8;p++) {
	for(e=0;e<7;e++) {
			tdist->FT2[e][p] = decomp19_8(*d++);
			tdist->dt_FT[e][p] = 1.;
	}
	for(e=0;e<9;e++) {
			tdist->OT2[e][p] = decomp19_8(*d++);
			tdist->dt_OT[e][p] = 1.;
	}
	for(e=0;e<7;e++) {
			tdist->FT6[e][p] = decomp19_8(*d++);
			tdist->dt_FT[e][p+8] = 1.;
	}
	for(e=0;e<9;e++) {
			tdist->OT6[e][p] = decomp19_8(*d++);
			tdist->dt_OT[e][p+8] = 1.;
	}
		}

	return(1);
}








/******** 3D-O distributions  (343x,404x) ************************/

int fill_sst_3d_O_distribution(packet *pk, sst_3d_O_distribution *dist)
{
	int e,a;
	uchar *u;
	int status;
	int slseq;
	MCFG *mcfg;

	if(pk==0){
		dist->valid =0;
		return(0);
	}
	mcfg = get_MCFG(pk->time);
	
	dist->spin_period = mcfg->spin_period;
	dist->time = pk->time;
        dist->spin = pk->spin;
	dist->base = pk->idtype & 0xf;

	if(dist->base == 0){
		dist->valid = 0;
		return(0);
	}

        dist->seqn = ((int)dist->spin/dist->base +3) % 4;
	dist->integ_t = dist->base * dist->spin_period;
	dist->delta_t = dist->base * dist->spin_period;

	if((pk->idtype & 0xff00) == 0x3400) {		
	slseq = (pk->instseq) & 0xff;
	u = (pk->data+168);  
	if (slseq==0) {
	for(a=0;a<24;a++)
		for(e=0;e<9;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = 1*rel_times[a];
		}
	}	
	if (slseq==1) {
	for(a=24;a<48;a++)
		for(e=0;e<9;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = 1*rel_times[a];
		}
	}	

	dist->ne = 9;

	return(slseq);  
/*	return(1);      */
}

	else

	switch (pk->dsize)
	    {
	    case(14 +48 * 2): {dist->ne = 2; status = 0x01; break;}
	    case(14 +48 * 4): {dist->ne = 4; status = 0x02; break;}
	    case(14 +48 * 6): {dist->ne = 6; status = 0x04; break;}
	    case(14 +48 * 9): {dist->ne = 9; status = 0x08; break;}
	    default:       {dist->ne = 0; status = 0x00; return(status);}
	    }

	u = pk->data;

	for(a=0;a<14;a++)
		dist->rates[a] = decomp19_8(*u++);
	for(a=0;a<48;a++)
		for(e=0;e<dist->ne;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = duty_cycle_O[e]*rel_times[a];
		}
		
	return(status);

}


/******** 3D-F distributions  (343x,405x) ************************/

int fill_sst_3d_F_distribution(packet *pk, sst_3d_F_distribution *dist)
{
	int e,a;
	uchar *u;
	int status;
	int slseq;
	MCFG *mcfg;

	if(pk==0){
		dist->valid = 0;
		return(0);
	}
	mcfg = get_MCFG(pk->time);

	dist->spin_period = mcfg->spin_period;
	dist->time = pk->time;
	dist->base = pk->idtype & 0xf;
        dist->spin = pk->spin;
        
	if(dist->base == 0){
		dist->valid = 0;
		return(0);
	}
	
       	dist->seqn = ((int)dist->spin/dist->base +3) % 4;
	dist->integ_t = dist->base * dist->spin_period;
	dist->delta_t = dist->base * dist->spin_period;

	if((pk->idtype & 0xff00) == 0x3400) {		
	slseq = (pk->instseq) & 0xff;
	u = (pk->data);
	if (slseq==0) {
	for(a=0;a<24;a++)
		for(e=0;e<7;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = 1*rel_times[a];
		}
	}	
	if (slseq==1) {
	for(a=24;a<48;a++)
		for(e=0;e<7;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = 1*rel_times[a];
		}
	}	
	dist->ne = 7;


	return(slseq);  
/*	return(1);      */
}

	else

	switch (pk->dsize)
	    {
	    case (48 * 2): {dist->ne = 2; status = 0x01; break;}
	    case (48 * 4): {dist->ne = 4; status = 0x02; break;}
	    case (48 * 7): {dist->ne = 7; status = 0x04; break;}
	    default:       {dist->ne = 0; status = 0x00; return(status);}
	    }

	u = pk->data;

	for(a=0;a<48;a++)
		for(e=0;e<dist->ne;e++) {
			dist->flux[e][a] = decomp19_8(*u++);
			dist->dt[e][a] = duty_cycle_F[e]*rel_times[a];
		}

	return(status);
}

int4 get_next_sf_struct(packet_selector *pksp, sst_foil_data *snap,
	 sst_3d_F_distribution *sst,int4 mode)
{
        int b,c,e,i,ok;
	int f_bin_channels[48] = {3,3,2,2,2,2,4,4,4,4,4,4,4,4,
                          5,5,5,5,0,0,1,1,1,1,3,3,2,2,
                          2,2,4,4,4,4,4,4,4,4,5,5,5,5,
                          0,0,1,1,1,1};   
        uint2 validmask;
        double spin_period;

	ok = get_next_sst_3d_F_str(pksp,sst,mode,&validmask);

	if(!ok){
		if(sst->time)
			snap->time = sst->time;
		return(0);
	}
		
        snap->time = sst->time;
        snap->spin = sst->spin;
        snap->mass = 5.6856591e-6;
	snap->geom_factor = 0.3;
	
        snap->delta_t = sst->delta_t;
        snap->integ_t = sst->integ_t;
        spin_period = sst->spin_period;
        
        for(b=0;b<48;b++){
                c = f_bin_channels[b];
                snap->detector[b] = f_bin_channels[b]+1;
                snap->domega[b] = sst->domega[b];
                for(e=0;e<7;e++){
			snap->dt[b][e] = sst->integ_t*sst->dt[e][b]/16.;
			snap->gf[b][e] = gf_F[b];
                        snap->dtheta[b][e] = sst->dtheta[b];
                        snap->dphi[b][e] = sst->dphi[b];
                        snap->flux[b][e] = sst->flux[e][b];
                        snap->nrg[b][e] = sst->energies[c][e+7];
                        snap->dnrg[b][e] = sst->e_max[c][e+7]-sst->e_min[c][e+7];
                        snap->theta[b][e] = sst->theta[b];
                        snap->phi[b][e] = sst->phi[b];
                        snap->feff[b][e] = sst->e_eff[c][e];
                }
        }

       snap->valid= 1;
       snap->n_samples++;
       
       return(1);
}

int4 get_next_so_struct(packet_selector *pksp, sst_open_data *snap,
	 sst_3d_O_distribution *sst,int4 mode)
{
        int b,c,e,i,ok;
	int o_bin_channels[48] = {0,0,5,5,5,5,4,4,4,4,4,4,4,4,2,2,
			  2,2,3,3,1,1,1,1,0,0,5,5,5,5,4,4,
			  4,4,4,4,4,4,2,2,2,2,3,3,1,1,1,1};   

        uint2 validmask;
        double spin_period;

	ok = get_next_sst_3d_O_str(pksp,sst,mode,&validmask);
	if(!ok) {
		if(sst->time)
			snap->time = sst->time;
		return(0);
	}
		
        snap->time = sst->time;
        snap->spin = sst->spin;
        snap->mass = 1836.0*5.6856591e-6;
	snap->geom_factor = 0.3;
	
        snap->delta_t = sst->delta_t;
        snap->integ_t = sst->integ_t;
        spin_period = sst->spin_period;
        
        for(b=0;b<48;b++){
                c = o_bin_channels[b];
                snap->detector[b] = o_bin_channels[b]+1;
                snap->domega[b] = sst->domega[b];
                for(e=0;e<9;e++){
			snap->dt[b][e] = sst->integ_t*sst->dt[e][b]/16.;
			snap->gf[b][e] = gf_O[b];
                        snap->dtheta[b][e] = sst->dtheta[b];
                        snap->dphi[b][e] = sst->dphi[b];
                        snap->flux[b][e] = sst->flux[e][b];
                        snap->nrg[b][e] = sst->energies[c][e+9];
                        snap->dnrg[b][e] = sst->e_max[c][e+9]-sst->e_min[c][e+9];
                        snap->theta[b][e] = sst->theta[b];
                        snap->phi[b][e] = sst->phi[b];
                }
        }

       snap->valid= 1;
       snap->n_samples++;
       
       return(1);
}


int4 get_next_sft_struct(packet_selector *pksp, sft_data *snap,
	 sst_t_distribution *sst)
{
        int b,c,e,i,ok;
	int ft_bin_channels[16] = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1};   
        uint2 validmask;
        double spin_period;

	ok = get_next_sst_3d_T_str(pksp,sst);
	if(!ok){
		if(sst->time)
			snap->time = sst->time;
		return(0);
	}
		
        snap->time = sst->time;
        snap->spin = sst->spin;
        snap->mass = 5.6856591e-6;
	snap->geom_factor = 0.3;
	
        snap->delta_t = sst->delta_t;
        snap->integ_t = sst->integ_t;
        spin_period = sst->spin_period;
        
        for(b=0;b<8;b++){
                c = ft_bin_channels[b];
                snap->detector[b] = ft_bin_channels[b]+1;
                for(e=0;e<7;e++){
			snap->dt[b][e] = sst->integ_t*sst->dt_FT[e][b]/8.;
			snap->gf[b][e] = gf_FT[b];
                        snap->dtheta[b][e] = sst->dtheta[b];
                        snap->dphi[b][e] = sst->dphi[b];
                        snap->flux[b][e] = sst->FT2[e][b];
                        snap->nrg[b][e] = sst->e_FT_mid[c][e];
                        snap->dnrg[b][e] = sst->e_FT_max[c][e]-sst->e_FT_min[c][e];
                        snap->theta[b][e] = sst->theta[b];
                        snap->phi[b][e] = sst->phi[b];
                        snap->feff[b][e] = sst->e_FT_eff[c][e];
                }
        }
        for(b=16;b<24;b++){
                c = ft_bin_channels[b-8];
                snap->detector[b-8] = ft_bin_channels[b-8]+1;
                for(e=0;e<7;e++){
			snap->dt[b-8][e] = sst->integ_t*sst->dt_FT[e][b-16]/8.;
			snap->gf[b-8][e] = gf_FT[b-8];
                        snap->dtheta[b-8][e] = sst->dtheta[b-8];
                        snap->dphi[b-8][e] = sst->dphi[b-8];
                        snap->flux[b-8][e] = sst->FT6[e][b-16];
                        snap->nrg[b-8][e] = sst->e_FT_mid[c][e];
                        snap->dnrg[b-8][e] = sst->e_FT_max[c][e]-sst->e_FT_min[c][e];
                        snap->theta[b-8][e] = sst->theta[b];
                        snap->phi[b-8][e] = sst->phi[b];
                        snap->feff[b-8][e] = sst->e_FT_eff[c][e];
                }
        }

       snap->valid= 1;
       snap->n_samples++;
       
       return(1);
}

int4 get_next_sot_struct(packet_selector *pksp, sot_data *snap,
	 sst_t_distribution *sst)
{
        int b,c,e,i,ok;
	int ot_bin_channels[16] = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1};   
        uint2 validmask;
        double spin_period;

	ok = get_next_sst_3d_T_str(pksp,sst);
	if(!ok){
		if(sst->time)
			snap->time = sst->time;
		return(0);
	}
		
        snap->time = sst->time;
        snap->spin = sst->spin;
        snap->mass = 5.6856591e-6;
	snap->geom_factor = 0.3;
	
        snap->delta_t = sst->delta_t;
        snap->integ_t = sst->integ_t;
        spin_period = sst->spin_period;
        
        for(b=8;b<16;b++){
                c = ot_bin_channels[b-8];
                snap->detector[b-8] = ot_bin_channels[b-8]+1;
                for(e=0;e<9;e++){
			snap->dt[b-8][e] = sst->integ_t*sst->dt_OT[e][b-8]/8.;
			snap->gf[b-8][e] = gf_OT[b-8];
                        snap->dtheta[b-8][e] = sst->dtheta[b-8];
                        snap->dphi[b-8][e] = sst->dphi[b-8];
                        snap->flux[b-8][e] = sst->OT2[e][b-8];
                        snap->nrg[b-8][e] = sst->e_OT_mid[c][e];
                        snap->dnrg[b-8][e] = sst->e_OT_max[c][e]-sst->e_OT_min[c][e];
                        snap->theta[b-8][e] = sst->theta[b];
                        snap->phi[b-8][e] = sst->phi[b];
                }
        }
        for(b=24;b<32;b++){
                c = ot_bin_channels[b-16];
                snap->detector[b-16] = ot_bin_channels[b-16]+1;
                for(e=0;e<9;e++){
			snap->dt[b-16][e] = sst->integ_t*sst->dt_OT[e][b-16]/8.;
			snap->gf[b-16][e] = gf_OT[b-16];
                        snap->dtheta[b-16][e] = sst->dtheta[b-16];
                        snap->dphi[b-16][e] = sst->dphi[b-16];
                        snap->flux[b-16][e] = sst->OT6[e][b-24];
                        snap->nrg[b-16][e] = sst->e_OT_mid[c][e];
                        snap->dnrg[b-16][e] = sst->e_OT_max[c][e]-sst->e_OT_min[c][e];
                        snap->theta[b-16][e] = sst->theta[b];
                        snap->phi[b-16][e] = sst->phi[b];
                }
        }

       snap->valid= 1;
       snap->n_samples++;
       
       return(1);
}

int4 get_next_fspc_struct(packet_selector *pksp, fspc_data *fspc_idl)
{
	static struct sst_spectra_struct sst;
        int b,c,e,i,ok;

	ok = get_next_sst_spectra_str(pksp,&sst);

	if(!ok){
		if(sst.time)
			fspc_idl->time = sst.time;
		return(0);
	}
		
        fspc_idl->time = sst.time;
        fspc_idl->spin = sst.spin;
        fspc_idl->mass = 5.6856591e-6;
	fspc_idl->geom_factor = 0.3;
	
        fspc_idl->delta_t = sst.delta_t;
        fspc_idl->integ_t = sst.integ_t;
        
        for(b=0;b<6;b++){
                fspc_idl->detector[b] = b+1;
		fspc_idl->domega[b] = sst.domega[b];
                for(e=0;e<16;e++){
			fspc_idl->dt[b][e] = sst.integ_t;
			fspc_idl->gf[b][e] = 1;
                        fspc_idl->dtheta[b][e] = sst.dtheta[b];
                        fspc_idl->dphi[b][e] = sst.dphi[b];
                        if (b==0)	fspc_idl->flux[b][e] = sst.F1[e];
                        if (b==1)	fspc_idl->flux[b][e] = sst.F2[e];
                        if (b==2)	fspc_idl->flux[b][e] = sst.F3[e];
                        if (b==3)	fspc_idl->flux[b][e] = sst.F4[e];
                        if (b==4)	fspc_idl->flux[b][e] = sst.F5[e];
                        if (b==5)	fspc_idl->flux[b][e] = sst.F6[e];
                        fspc_idl->nrg[b][e] = sst.e_F_mid[b][e+16];
                        fspc_idl->dnrg[b][e] = sst.e_F_max[b][e+16]-sst.e_F_min[b][e+16];
                        fspc_idl->theta[b][e] = sst.theta_f[b];
                        fspc_idl->phi[b][e] = sst.phi[b];
                        fspc_idl->feff[b][e] = sst.e_F_eff[b][e];
                }
        }

       fspc_idl->valid= 1;
       fspc_idl->n_samples++;
       
       return(1);
}

int4 get_next_ospc_struct(packet_selector *pksp, ospc_data *ospc_idl)
{
	static struct sst_spectra_struct sst;
        int b,c,e,i,ok;

	ok = get_next_sst_spectra_str(pksp,&sst);

	if(!ok){
		if(sst.time)
			ospc_idl->time = sst.time;
		return(0);
	}
		
        ospc_idl->time = sst.time;
        ospc_idl->spin = sst.spin;
        ospc_idl->mass = 5.6856591e-6;
	ospc_idl->geom_factor = 0.3;
	
        ospc_idl->delta_t = sst.delta_t;
        ospc_idl->integ_t = sst.integ_t;
        
        for(b=0;b<6;b++){
                ospc_idl->detector[b] = b+1;
		ospc_idl->domega[b] = sst.domega[b];
                for(e=0;e<24;e++){
			ospc_idl->dt[b][e] = sst.integ_t;
			ospc_idl->gf[b][e] = 1;
                        ospc_idl->dtheta[b][e] = sst.dtheta[b];
                        ospc_idl->dphi[b][e] = sst.dphi[b];
                        if (b==0)	ospc_idl->flux[b][e] = sst.O1[e];
                        if (b==1)	ospc_idl->flux[b][e] = sst.O2[e];
                        if (b==2)	ospc_idl->flux[b][e] = sst.O3[e];
                        if (b==3)	ospc_idl->flux[b][e] = sst.O4[e];
                        if (b==4)	ospc_idl->flux[b][e] = sst.O5[e];
                        if (b==5)	ospc_idl->flux[b][e] = sst.O6[e];
                        ospc_idl->nrg[b][e] = sst.e_O_mid[b][e+24];
                        ospc_idl->dnrg[b][e] = sst.e_O_max[b][e+24]-sst.e_O_min[b][e+24];
                        ospc_idl->theta[b][e] = sst.theta_o[b];
                        ospc_idl->phi[b][e] = sst.phi[b];
                }
        }

       ospc_idl->valid= 1;
       ospc_idl->n_samples++;
       
       return(1);
}

int4 get_next_tspc_struct(packet_selector *pksp, tspc_data *tspc_idl)
{
	static struct sst_spectra_struct sst;
        int b,c,e,i,ok;

	ok = get_next_sst_spectra_str(pksp,&sst);

	if(!ok){
		if(sst.time)
			tspc_idl->time = sst.time;
		return(0);
	}
		
        tspc_idl->time = sst.time;
        tspc_idl->spin = sst.spin;
        tspc_idl->mass = 5.6856591e-6;
	tspc_idl->geom_factor = 0.3;
	
        tspc_idl->delta_t = sst.delta_t;
        tspc_idl->integ_t = sst.integ_t;
        
        for(b=0;b<4;b++){
        	if ((b==0) || (b==2))	tspc_idl->detector[b] = 2;
        	if ((b==1) || (b==3))	tspc_idl->detector[b] = 6;
		tspc_idl->domega[b] = sst.domega[b];
                for(e=0;e<24;e++){
			tspc_idl->dt[b][e] = sst.integ_t;
			tspc_idl->gf[b][e] = 1;
                        tspc_idl->dtheta[b][e] = sst.dtheta[b];
                        tspc_idl->dphi[b][e] = sst.dphi[b];
                        if (b==0)	tspc_idl->flux[b][e] = sst.FT2[e];
                        if (b==1)	tspc_idl->flux[b][e] = sst.FT6[e];
                        if (b==2)	tspc_idl->flux[b][e] = sst.OT2[e];
                        if (b==3)	tspc_idl->flux[b][e] = sst.OT6[e];
                        tspc_idl->nrg[b][e] = sst.e_FT_mid[b][e];
                        tspc_idl->dnrg[b][e] = sst.e_FT_max[b][e]-sst.e_FT_min[b][e];
                        if (b<2) tspc_idl->feff[b][e] = sst.e_FT_eff[b][e];
                        if (b>1) {
                        	tspc_idl->nrg[b][e] = sst.e_OT_mid[b-2][e];
				tspc_idl->dnrg[b][e] =
				sst.e_OT_max[b-2][e]-sst.e_OT_min[b-2][e];
			}

                }
        }

       tspc_idl->valid= 1;
       tspc_idl->n_samples++;
       
       return(1);
}

int4 sst_foil_to_idl(int argc,void *argv[])
{
        sst_foil_data *snap;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_3d_F_distribution sst;

        if(argc == 0)
                return( number_of_sst_3d_F_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sst_foil_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];
        mode = options[3];

        if(argc ==2){
            ok = get_time_points(S_3D_F_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sst_foil_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_foil_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_3D_F_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_3D_F_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_3D_F_ID) ;
        }

        ok = get_next_sf_struct(&pks,snap,&sst,mode);
        snap->index = pks.index;

        return(ok);

}

int4 sst_open_to_idl(int argc,void *argv[])
{
        sst_open_data *snap;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_3d_O_distribution sst;

        if(argc == 0)
                return( number_of_sst_3d_O_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sst_open_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];
        mode = options[3];

        if(argc ==2){
            ok = get_time_points(S_3D_O_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sst_open_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_open_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_3D_O_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_3D_O_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_3D_O_ID) ;
        }

        ok = get_next_so_struct(&pks,snap,&sst,mode);
        snap->index = pks.index;

        return(ok);

}

int4 sfb_to_idl(int argc,void *argv[])
{
        sst_foil_data *snap;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_3d_F_distribution sst;

        if(argc == 0)
                return( number_of_sst_3d_burst_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sst_foil_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];
        mode = 0;

        if(argc ==2){
            ok = get_time_points(S_HS_BST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sst_foil_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_foil_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_HS_BST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_HS_BST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_HS_BST_ID) ;
        }

        ok = get_next_sf_struct(&pks,snap,&sst,mode);
        snap->index = pks.index;

        return(ok);

}

int4 sob_to_idl(int argc,void *argv[])
{
        sst_open_data *snap;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_3d_O_distribution sst;

        if(argc == 0)
                return( number_of_sst_3d_burst_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sst_open_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];
        mode = 0;

        if(argc ==2){
            ok = get_time_points(S_HS_BST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sst_open_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_open_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_HS_BST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_HS_BST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_HS_BST_ID) ;
        }

        ok = get_next_so_struct(&pks,snap,&sst,mode);
        snap->index = pks.index;

        return(ok);

}



int4 sft_to_idl(int argc,void *argv[])
{
        sft_data *snap;
        int4 size,advance,index,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_t_distribution sst;

        if(argc == 0)
                return( number_of_sst_T_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sft_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_T_DST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sft_data)){
            printf("Incorrect structure size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_foil_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_T_DST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_T_DST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_T_DST_ID) ;
        }

        ok = get_next_sft_struct(&pks,snap,&sst);
        snap->index = pks.index;

        return(ok);

}


int4 sot_to_idl(int argc,void *argv[])
{
        sot_data *snap;
        int4 size,advance,index,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static sst_t_distribution sst;

        if(argc == 0)
                return( number_of_sst_T_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (sot_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_T_DST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(sot_data)){
            printf("Incorrect structure size %d (should be %d).  Aborting.\r\n",size,sizeof(sst_foil_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_T_DST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_T_DST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_T_DST_ID) ;
        }

        ok = get_next_sot_struct(&pks,snap,&sst);
        snap->index = pks.index;

        return(ok);

}

int4 fspc_to_idl(int argc,void *argv[])
{
        fspc_data *fspc_idl;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_packets(S_RATE3_ID,0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        fspc_idl = (fspc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_RATE3_ID,size,time);
            return(ok);
        }

        if(size != sizeof(fspc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(fspc_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_RATE3_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_RATE3_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_RATE3_ID) ;
        }

        ok = get_next_fspc_struct(&pks,fspc_idl);
        fspc_idl->index = pks.index;

        return(ok);

}


int4 fspb_to_idl(int argc,void *argv[])
{
        fspc_data *fspb_idl;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_packets(S_RS_BST_ID,0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        fspb_idl = (fspc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_RS_BST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(fspc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(fspc_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_RS_BST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_RS_BST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_RS_BST_ID) ;
        }

        ok = get_next_fspc_struct(&pks,fspb_idl);
        fspb_idl->index = pks.index;

        return(ok);

}


int4 ospc_to_idl(int argc,void *argv[])
{
        ospc_data *ospc_idl;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_packets(S_RATE3_ID,0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        ospc_idl = (ospc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_RATE3_ID,size,time);
            return(ok);
        }

        if(size != sizeof(ospc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(ospc_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_RATE3_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_RATE3_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_RATE3_ID) ;
        }

        ok = get_next_ospc_struct(&pks,ospc_idl);
        ospc_idl->index = pks.index;

        return(ok);

}

int4 ospb_to_idl(int argc,void *argv[])
{
        ospc_data *ospb_idl;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_packets(S_RS_BST_ID,0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        ospb_idl = (ospc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_RS_BST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(ospc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(ospc_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_RS_BST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_RS_BST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_RS_BST_ID) ;
        }

        ok = get_next_ospc_struct(&pks,ospb_idl);
        ospb_idl->index = pks.index;

        return(ok);

}


int4 tspc_to_idl(int argc,void *argv[])
{
        tspc_data *tspc_idl;
        int4 size,advance,index,mode,*options,ok;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_packets(S_RATE3_ID,0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        tspc_idl = (tspc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(S_RATE3_ID,size,time);
            return(ok);
        }

        if(size != sizeof(tspc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(tspc_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,S_RATE3_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],S_RATE3_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,S_RATE3_ID) ;
        }

        ok = get_next_tspc_struct(&pks,tspc_idl);
        tspc_idl->index = pks.index;

        return(ok);

}



