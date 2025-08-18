#include "p3d_dcm.h"
#include "map3d.h"
#include "pckt_prt.h"
#include "esteps.h"
#include "pesa_cfg.h"
#include "eesa_cfg.h"
#include "brst_dcm.h"

#include "windmisc.h"
#include <stdlib.h>
#include <string.h>

#include "map_88.h"
#include "map_11b.h"
#include "map_0.h"
#include "map_5.h"
#include "map_8.h"
#include "map_elc.h"
#include "map_ehs.h"





static float geom_area_eh[24] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,4,4,4,4,4,4,4,4};
static float geom_area_el[16] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4};
static float geom_area_ph[24] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,4,4,4,4,4,4,4,4};
static float geom_area_pl[16] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4};

static float gf_el[16] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4};
static float gf_eh[24] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,4,4,4,4,4,4,4,4};
static float gf_ph[24] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,4,4,4,4,4,4,4,4};

static uchar no_blank[32] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

#if 1
static double theta[24] = {    /*   -90 < theta < 90   latitude */
  -78.7500, -56.2500, -39.3750, -28.1250
, -19.6875, -14.0625, -8.43750, -2.81250
,  2.81250,  8.43750,  14.0625,  19.6875
,  28.1250,  39.3750,  56.2500,  78.7500
,  78.7500,  56.2500,  33.7500,  11.2500 /* back half */
, -11.2500, -33.7500, -56.2500, -78.7500
};
#else
static double theta[24] = {    /*   0 < theta < 180   Co-latitude */
  168.75000, 146.25000, 129.37500, 118.12500
, 109.68750, 104.06250, 98.437500, 92.812500
, 87.187500, 81.562500, 75.937500, 70.312500
, 61.875000, 50.625000, 33.750000, 11.250000
, 168.75000, 146.25000, 123.75000, 101.25000 /* back half */
, 78.750000, 56.250000, 33.750000, 11.250000

};
#endif

static double dtheta[24] = { 22.5,  22.5, 11.25, 11.25, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 5.625, 11.25, 11.25,  22.5,  22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5, 22.5 };

static double phi[32] = {
   174.37500,  163.12500,  151.87500,  140.62500,  129.37500
,  118.12500,  106.87500,  95.625000,  84.375000,  73.125000
,  61.875000,  50.625000,  39.375000,  28.125000,  16.875000
,  5.6250000, -5.6250000, -16.875000, -28.125000, -39.375000
, -50.625000, -61.875000, -73.125000, -84.375000, -95.625000
, -106.87500, -118.12500, -129.37500, -140.62500, -151.87500
, -163.12500, -174.37500
};

static double dphi = 11.25;

static double domegas[16] = {
     0.014946219,     0.042563230,     0.029754132,     0.033946244,
     0.018142453,     0.018691368,     0.019060275,     0.019245620,
     0.019245620,     0.019060275,     0.018691368,     0.018142453,
     0.033946244,     0.029754132,     0.042563230,     0.014946219
};


uint2 get_map_code(packet *pk);
uint2 get_ph_map_code(packet *pk);
int get_3d_inst(packet *pk);
int get_3d_integ_t(packet *pk);
int get_3d_delta_t(packet *pk);

int get_esteps(double *nrgs,int ne,int pos,int inst,ECFG *ecfg,PCFG *pcfg);






int decom_map3d(packet *pk,data_map_3d *map)
{
	int i;
	int offset;
	int seq;
	int ndata;
	uchar *data;
	packet decomp_pk;
	int mapcode;

	decompress_burst_packet(&decomp_pk,pk);  /* won't do anything if not burst type */

	if(decomp_pk.spin != map->spin || map->status<=0){
                                    /* clear array with each new spin */
	    switch ( mapcode = get_map_code(pk) ) {
	    case MAP_ehs:
		init_data_map_3d_ehs( pk , map );
		break;
	    default:
		init_data_map_3d( pk , map );  /* will initialize map */
		break;
	    }
	}

	if (map->mapcode == MAP_ehs) 
	    seq = decomp_pk.instseq & 0x03;
	else
	    seq = decomp_pk.instseq & 0x07;

	offset = seq * map->max_bytes_per_packet;
	ndata = map->max_bytes_per_packet;
	if(ndata>(int)decomp_pk.dsize)
		ndata = decomp_pk.dsize;

	if (map->mapcode == MAP_ehs)
	    data = decomp_pk.data + 2;
	else
	    data = decomp_pk.data;

	for(i=0;i<ndata;i++){
/*		if(offset >= map->nsamples) */
		if(offset >= (map->nsamples + 5))  {  /* The previous line should work */
		    char instStr[12];
		    switch (map->inst){
		    case EESAL_INST:
			strcpy (instStr, "EESA LOW");
			break;
		    case EESAH_INST:
			strcpy (instStr, "EESA HIGH");
			break;
		    case PESAH_INST:
			strcpy (instStr, "PESA HIGH");
			break;
		    }
		    fprintf(stderr,"3D binning error: offset(%d) >= map->nsampes(%d)\n\r",
			    offset, map->nsamples);
		    fprintf(stderr,"    ndata: %d, map type: %s\r\n", ndata, instStr);
		}
		if(offset < map->nsamples) {
			map->dt[offset] = 1;
			map->data[offset++] = decomp19_8(*data++);
		}
	}
	map->status--;
#if 0
	if(map->status==0){    /* all packets received */
		convert_3dmap_units(map);
	}
#endif

/*#define PK_DEBUG */
#if defined (PK_DEBUG)
	{
	    int l;
	    printf("%s:\n\r", __FILE__);
	    printf("&packet %lx\n\r",
		   __FILE__, pk);
	    printf("packet {"
		   "\n\r\ttime:       %lf"
		   "\n\r\tspin:       %hd"
		   "\n\r\tdsize:      %hd"
		   "\n\r\tidtype      %hd"
		   "\n\r\tinstseq:    %hd"
		   "\n\r\tterrors:    %hd"
		   "\n\r\tprev:       %lx"
		   "\n\r\tnext:       %lx"

		   "\n\r\tdata:       \r\n",
		   decomp_pk.time, decomp_pk.spin, decomp_pk.dsize, decomp_pk.idtype, decomp_pk.instseq,
		   decomp_pk.errors, decomp_pk.prev, decomp_pk.next);
	    for ( l=0; l<MAX_PACKET_SIZE ; l++ )
		printf("%s%2hx", l%16 ? " " : "\n\r\t\t", decomp_pk.data[l]);
	    printf("\n\r\t}\n\r");

	    printf("map\t{"
		   "\n\r\ttime:       %lf"
		   "\n\r\tspin:       %hd"
		   "\n\r\tdata:       \r\n",
		   map->time, map->spin);
	    for ( l=0; l<MAX3DSAMPLES ; l++ )
		printf("%s%8.2f", l%8 ? " " : "\n\r\t", map->data[l]);
	    printf("\n\r\t}\n\r");
	}
#endif /* defined (PK_DEBUG) */

	return(1);

}


int get_esteps(double *nrgs,int ne,int pos,int instrument,ECFG *ecfg,PCFG *pcfg)
{
	if(instrument == EESAL_INST)
		return(get_esteps_el(nrgs,ne,pos,ecfg));
	else if(instrument == EESAH_INST)
		return(get_esteps_eh(nrgs,ne,pos,ecfg));
	else if(instrument == PESAH_INST)
		return(get_esteps_ph(nrgs,ne,pos,pcfg));
	fprintf(stderr,"WIND_LIB: MAP3D: error in get_esteps\n");
	return(0);
}



init_data_map_3d(packet *pk,data_map_3d *map)
{
	uint i,p,ps,t,b,ne,offset, e;
	uint *ptmap;
	uchar *t_blank,*p_blank;
	float *geom,*gf;
	double emin[30];
	double emax[30];
	static int theta_slots[32][125];
	static int phi_slots[16][125];
	static int num_theta[125];
	static int num_phi[125];
	static int num_gf[125];
	static int num_dt[125];
	static int gf_slots[32][125];
	static int dt_slots[24][125];
	PCFG *pcfg;
	ECFG *ecfg;


	if(pk==NULL)
		return(0);
	map->inst    = get_3d_inst(pk);
	ecfg = get_ECFG(pk->time);
	pcfg = get_PCFG(pk->time);

	switch(map->inst){
		case EESAH_INST:
			t_blank = ecfg->extd_cfg.t_blank+16;
			p_blank = ecfg->extd_cfg.p_blank;
			map->geom_factor  = ecfg->eh_geom;
			geom  = geom_area_eh;
			gf = gf_eh;
			map->spin_period = ecfg->spin_period;
			map->p0 = 12;
			break;
		case EESAL_INST:
			t_blank = ecfg->extd_cfg.t_blank;
			p_blank = ecfg->extd_cfg.p_blank;
			map->geom_factor  = ecfg->el_geom;
			geom  = geom_area_el;
			gf = gf_el;
			map->spin_period = ecfg->spin_period;
			map->p0 = 20;
			break;
		case PESAH_INST:
			t_blank = no_blank;  /* blanking not possible on PESA */
			p_blank = no_blank;
			map->geom_factor  = pcfg->ph_geom;
			geom  = geom_area_ph;
			gf = gf_ph;
			map->spin_period = pcfg->spin_period;
			map->p0 = 28;
			break;
		case PESAL_INST:   /* this should never be used   */
			t_blank = no_blank;  /* blanking not possible on PESA */
			p_blank = no_blank;
			map->geom_factor  = pcfg->pl_geom;
			geom  = geom_area_pl;
			map->spin_period = pcfg->spin_period;
			map->p0 = 4;
			break;
		default:
			return(0);
	}		

	map->time    = pk->time;
	map->integ_t = get_3d_integ_t(pk) * map->spin_period;
	map->delta_t = get_3d_delta_t(pk) * map->spin_period;
	map->spin = pk->spin;

	map->mapcode = get_map_code(pk);
	map->shift = (pk->instseq >> 3) & 0x1f;
/*	init_map(map); */

	switch(map->mapcode){
	case(MAP_MOM):     /*  88 angle map  */
		map->nbins = 88;
		map->nenergies = 15;
		map->nsamples = 1320;
		map->ntheta = 16;
		map->max_bytes_per_packet = 495;
		map->npackets = 3;
		ptmap = ptmap_88;
		break;
	case(MAP11d):        /* PESAH S2x  */
		map->nbins = 121;
		map->nenergies = 15;
		map->nsamples = 1890;
		map->ntheta = 24;
		map->max_bytes_per_packet = 390;
		map->npackets = 5;
		ptmap   = ptmap_5;
		break;
	case(MAP_8):        /* PESAH burst  */
		map->nbins = 56;
		map->nenergies = 15;
		map->nsamples = 960;
		map->ntheta = 24;
		map->max_bytes_per_packet = 390;
		map->npackets = 3;
		ptmap   = ptmap_8;
		break;
	case(MAP_0):         /* PESAH  */
		map->nbins = 65;
		map->nenergies = 15;
		map->nsamples = 1050;
		map->ntheta = 24;
		map->max_bytes_per_packet = 390;
		map->npackets = 3;
		ptmap   = ptmap_0;
		break;
	case(MAP11b):        /* PESAH S1x */
		map->nbins = 97;
		map->nenergies = 15;
		map->nsamples = 1530;
		map->ntheta = 24;
		map->max_bytes_per_packet = 390;
		map->npackets = 4;
		ptmap   = ptmap_11b;
		break;
	case(MAP_elc):        /* EESA Low Cuts */
		map->nbins = 32;
		map->nenergies = 15;
		map->nsamples = 480;
		map->ntheta = 16;
		map->max_bytes_per_packet = 495;
		map->npackets = 1;
		ptmap   = ptmap_elc;
		break;
	case(MAP_ehs):        /* EESA high slice */
		map->nbins = 24;
		map->nenergies = 30;
		map->nsamples = 720;
		map->ntheta = 24;
		map->max_bytes_per_packet = 480;
		map->npackets = 2;
		ptmap   = ptmap_ehs;
		break;
	default:
		return(0);
	}

	map->status = map->npackets;

	for(b=0;b<map->nbins;b++){
		map->bin[b].geom = 0.;
		map->bin[b].gf = 0.;
		map->bin[b].dt = 0.;
		map->bin[b].theta = 0.;
		map->bin[b].dtheta = 0.;
		map->bin[b].dphi = 0.;
		map->bin[b].offset = 0;
		map->bin[b].domega = 0;
		num_theta[b]=0;
		num_phi[b]=0;
		num_gf[b]=0;
		num_dt[b]=0;
		for (e=0; e<30; e++)
		    map->bin[b].phi[e] = 0.;
		for (p=0; p<32; p++){
		  theta_slots[p][b]=0;
		  gf_slots[p][b]=0;
		}
		for (t=0; t<16; t++)
		  phi_slots[t][b]=0;
		for (t=0; t<24; t++)
		  dt_slots[t][b]=0;
	}

	for(p=0;p<32;p++){
		for(t=0;t<map->ntheta;t++){
			b = ptmap[t*32+p];

			switch (b & 0xc000) {
			case E30:
			    ne = 30;
			    break;
			case E0:
			    ne = 0;
			    break;
			default:
			    ne=15;
			    break;
			}
			
			b &= 0x3fff;


			if(b > map->nbins && ne ){
				fprintf(stderr,"3D bin error\n");
				return(0);
			}
			ps = (p - map->shift) & 0x1f;
			map->ptmap[t*32+ps] = (ne == 0) ? -1 : b;
			if(ne == 0)
				continue;
			if (b < map->nbins ) map->bin[b].ne = ne;

			if(p_blank[p] & t_blank[t])
				continue;     /* skip blanked anodes */
			if(t<16){
				map->bin[b].phi[0] += phi[p];
				map->bin[b].theta  += theta[t] * dtheta[t];
				map->bin[b].domega += domegas[t];
				map->bin[b].offset += 1;
				map->bin[b].dphi   += dphi;
				map->bin[b].dtheta += dtheta[t];
				theta_slots[p][b] += 1;
				phi_slots[t][b] += 1;
			}
			map->bin[b].geom += geom[t];
			map->bin[b].gf += gf[t];
			map->bin[b].dt += 1./32.;
			gf_slots[p][b] += 1;
			dt_slots[t][b] += 1;
		}
	}
	for(b=0;b<map->nbins;b++){
		float phi0 = map->bin[b].phi[0];
		for (p=0; p<32; p++){
		    if (num_theta[b] < theta_slots[p][b])
		      num_theta[b] = theta_slots[p][b];
		    if (num_gf[b] < gf_slots[p][b])
		      num_gf[b] = gf_slots[p][b];
		}
		for (t=0; t<16; t++)
		    if (num_phi[b] < phi_slots[t][b])
		      num_phi[b] = phi_slots[t][b];
		for (t=0; t<24; t++)
		    if (num_dt[b] < dt_slots[t][b])
		      num_dt[b] = dt_slots[t][b];
		    
		if(map->bin[b].offset ==0){
/*			fprintf(stderr,"Invalid bin #%d\n",b); */
			continue;
		}
		map->bin[b].theta /= map->bin[b].dtheta;
		phi0   /= map->bin[b].offset;
		phi0   +=  ((double)map->shift + (double)map->p0) * 360./32.;
		if(phi0 < 0.)
			phi0 +=360.;
		if(phi0 >= 360.)
			phi0 -=360.;
		map->bin[b].dtheta /= num_phi[b];
		map->bin[b].dphi /= num_theta[b];
		map->bin[b].gf /= num_dt[b];
		map->bin[b].dt /= num_gf[b];

		/* build up phi across energy bins */
		for (e=0; e<map->bin[b].ne ; e ++)
		    map->bin[b].phi[e] = phi0 +	(.5 - (e+.5)/map->bin[b].ne)*dphi;
	}
	offset = 0;
	for(b=0;b<map->nbins;b++){
		map->bin[b].offset = offset;
		offset += map->bin[b].ne;
	}
	if(offset != map->nsamples)
		fprintf(stderr,"3d Initialization error, offset: %d, map->nsamples: %d\n\r",
			 offset, map->nsamples);

	for(i=0; i<map->nsamples; i++) {     /* clear data array  */
		map->data[i] = 0;
		map->dt[i] = 0;
	}

		/*Get energy steps:  */
	get_esteps(map->nrg_min,30,MIN,map->inst,ecfg,pcfg);
	get_esteps(map->nrg_max,30,MAX,map->inst,ecfg,pcfg);
	get_esteps(map->nrg30,30,MIDDLE,map->inst,ecfg,pcfg);
	get_esteps(map->nrg15,15,MIDDLE,map->inst,ecfg,pcfg);
	get_esteps(map->dnrg15,15,WIDTH,map->inst,ecfg,pcfg);
	
	map->nrg_units = ENERGY_UNITS;

/*#define MAPINIT_DEBUG */
#if defined (MAPINIT_DEBUG)
	printf ("map: {\r\n");
	printf ("\ttime:                  %lf\r\n", map->time);
	printf ("\tinteg_t:               %f\r\n", map->integ_t);
	printf ("\tdelta_t:               %f\r\n", map->delta_t); 
	printf ("\tspin_period:           %f\r\n", map->spin_period);
	printf ("\tgeom_factor:           %f\r\n", map->geom_factor);
	printf ("\tmass:                  %f\r\n", map->mass);
	printf ("\tinst:                  %d\r\n", map->inst);          
	printf ("\tspin:                  %hd\r\n", map->spin);
	printf ("\tmapcode:               %hd\r\n", map->mapcode);
	printf ("\terescode:              %hd\r\n", map->erescode);
	printf ("\tntheta:                %d\r\n", map->ntheta);
	printf ("\tnbins:                 %d\r\n", map->nbins);
	printf ("\tnsamples:              %d\r\n", map->nsamples);
	printf ("\tmax_bytes_per_packet:  %d\r\n", map->max_bytes_per_packet);  
	printf ("\tflux_units:            %d\r\n", map->flux_units); 
	printf ("\tnrg_units:             %d\r\n", map->nrg_units);
	printf ("\tstatus:                %d\r\n", map->status);
	printf ("\tnpackets:              %d\r\n", map->npackets);
	printf ("\tmap_is_initialized:    %d\r\n", map->map_is_initialized);
	printf ("\tp0:                    %uhd\r\n", map->p0&0x00ff);
	printf ("\tshift:                 %uhd\r\n", map->shift&0x00ff);
	printf ("\tmagel:                 %uhd\r\n", map->magel&0x00ff);
	printf ("\tmagaz:                 %uhd\r\n", map->magaz&0x00ff);
	for(b=0; b<map->nbins ; b++) {
		printf("bin[%d] {\r\n",b);
		printf("\t\tphi:\r\n");
		for (e=0; e<map->bin[b].ne; e++)
		        printf("%f%s", map->bin[b].phi[e], (e+1)%6? " ":"\r\n\t");
		printf("\t\ttheta:  %f\r\n", map->bin[b].theta);
		printf("\t\tdphi:   %f\r\n", map->bin[b].dphi);
		printf("\t\tdtheta: %f\r\n", map->bin[b].dtheta);
		printf("\t\tdomega: %f\r\n", map->bin[b].domega);
		printf("\t\toffset: %d\r\n", map->bin[b].offset);
		printf("\t\tne:     %d\r\n", map->bin[b].ne);
		printf("\t\tgeom:   %f\r\n", map->bin[b].geom);
		printf("}\r\n");
	    }
#endif /* defined (MAPINIT_DEBUG)*/

	return(1);
}

init_data_map_3d_ehs(packet *pk,data_map_3d *map)
{
	int t,b,e;
	uint *ptmap;
	uchar *t_blank,*p_blank;
	float *geom;
	double emin[30];
	double emax[30];
	PCFG *pcfg;
	ECFG *ecfg;
	int phase_bin;

	if(pk==NULL)
		return(0);
	ecfg = get_ECFG(pk->time);

	t_blank = ecfg->extd_cfg.t_blank+16;
	p_blank = ecfg->extd_cfg.p_blank;
	map->geom_factor  = ecfg->eh_geom;
	geom  = geom_area_eh;
	map->spin_period = ecfg->spin_period;
	map->p0 = 12;

	map->time    = pk->time;
	map->integ_t = get_3d_integ_t(pk) * map->spin_period;
	map->delta_t = get_3d_delta_t(pk) * map->spin_period;
	map->spin = pk->spin;

	map->mapcode = MAP_ehs;
	map->nbins = 24;
	map->nenergies = 30;
	map->nsamples = 720;
	map->ntheta = 24;
	map->max_bytes_per_packet = 480;
	map->npackets = 2;
	map->magel = pk->instseq>>8;
	map->magaz = ((pk->data[1]<<8) + pk->data[0]) & 0x1ff ;
	ptmap   = ptmap_ehs;
	map->status = map->npackets;
	phase_bin = (pk->instseq >> 2) & 0x1f;

	/* zero out bin information */

	for(b=0;b<map->nbins;b++){
		map->bin[b].geom = 0.;
		map->bin[b].gf = 0.;
		map->bin[b].dt = 0.;
		map->bin[b].theta = 0.;
		map->bin[b].dtheta = 0.;
		map->bin[b].dphi = 0.;
		map->bin[b].offset = 0;
		map->bin[b].domega = 0;
		for (e=0; e<30; e++)
		    map->bin[b].phi[e] = 0.;
	}

	/* build up bin info */
	
	for(t=0;t<24;t++){
	    b = t ;
	    map->bin[b].ne = 30;
	    map->bin[b].theta  = theta[t];
	    map->bin[b].dphi   = dphi;
	    map->bin[b].dtheta = dtheta[t];
	    map->bin[b].domega = domegas[t];
	    map->bin[b].offset = 1;
	    map->bin[b].geom = geom[t];
	    map->bin[b].gf = gf_eh[t];
	    map->bin[b].dt = 1./32.;
	    map->bin[b].offset = 30 * b;
	    for ( e=0; e<30; e ++) {
		map->bin[b].phi[e] = (360./32.)*((double)phase_bin + (float)map->p0 - e/32.)
		    + ((t > 15) ? 180. : 0.) ;
		if (map->bin[b].phi[e] > 360.)
		    map->bin[b].phi[e] -= 360. ;
	    }
	}
	
	/* build up map */

	memset (map->ptmap, -1, sizeof(int2)*24*32);
	for (t=0;t<24;t++)
	    map->ptmap[t*32+phase_bin] = t ;

	for(b=0; b<map->nsamples; b++) {     /* clear data array  */
		map->data[b] = 0;
		map->dt[b] = 0;
	}

		/*Get energy steps:  */
	get_esteps(map->nrg_min,30,MIN,map->inst,ecfg,pcfg);
	get_esteps(map->nrg_max,30,MAX,map->inst,ecfg,pcfg);
	get_esteps(map->nrg30,30,MIDDLE,map->inst,ecfg,pcfg);
	get_esteps(map->dnrg30,30,WIDTH,map->inst,ecfg,pcfg);
	get_esteps(map->nrg15,15,MIDDLE,map->inst,ecfg,pcfg);
	get_esteps(map->dnrg15,15,WIDTH,map->inst,ecfg,pcfg);
	
	map->nrg_units = ENERGY_UNITS;

/*#define MAPINIT_DEBUG */
#if defined (MAPINIT_DEBUG)
	printf ("map: {\r\n");
	printf ("\ttime:                  %lf\r\n", map->time);
	printf ("\tinteg_t:               %f\r\n", map->integ_t);
	printf ("\tdelta_t:               %f\r\n", map->delta_t); 
	printf ("\tspin_period:           %f\r\n", map->spin_period);
	printf ("\tgeom_factor:           %f\r\n", map->geom_factor);
	printf ("\tmass:                  %f\r\n", map->mass);
	printf ("\tinst:                  %d\r\n", map->inst);          
	printf ("\tspin:                  %hd\r\n", map->spin);
	printf ("\tmapcode:               %hd\r\n", map->mapcode);
	printf ("\terescode:              %hd\r\n", map->erescode);
	printf ("\tntheta:                %d\r\n", map->ntheta);
	printf ("\tnbins:                 %d\r\n", map->nbins);
	printf ("\tnsamples:              %d\r\n", map->nsamples);
	printf ("\tmax_bytes_per_packet:  %d\r\n", map->max_bytes_per_packet);  
	printf ("\tflux_units:            %d\r\n", map->flux_units); 
	printf ("\tnrg_units:             %d\r\n", map->nrg_units);
	printf ("\tstatus:                %d\r\n", map->status);
	printf ("\tnpackets:              %d\r\n", map->npackets);
	printf ("\tmap_is_initialized:    %d\r\n", map->map_is_initialized);
	printf ("\tp0:                    %hu\r\n", map->p0&0x00ff);
	printf ("\tshift:                 %hu\r\n", map->shift&0x00ff);
	printf ("\tmagel:                 %hu\r\n", map->magel&0x00ff);
	printf ("\tmagaz:                 %hu\r\n", map->magaz&0x00ff);
	for(b=0; b<map->nbins ; b++) {
		printf("bin[%d] {\r\n",b);
		printf("\t\tphi:\r\n\t\t");
		for (e=0; e<map->bin[b].ne; e++)
		        printf("%f%s", map->bin[b].phi[e], (e+1)%6? " ":"\r\n\t\t");
		printf("theta:  %f\r\n", map->bin[b].theta);
		printf("\t\tdphi:   %f\r\n", map->bin[b].dphi);
		printf("\t\tdtheta: %f\r\n", map->bin[b].dtheta);
		printf("\t\tdomega: %f\r\n", map->bin[b].domega);
		printf("\t\toffset: %d\r\n", map->bin[b].offset);
		printf("\t\tne:     %d\r\n", map->bin[b].ne);
		printf("\t\tgeom:   %f\r\n", map->bin[b].geom);
		printf("}\r\n");
	    }
#endif /* defined (MAPINIT_DEBUG)*/

	return(1);
}




int get_3d_integ_t(packet *pk)
{
	int n;
	uint2 id;
	id = pk->idtype;
	n  = (pk->instseq & 0x0f00u) >> 8;
	if((id & 0x3000) == 0x3000)  /* burst */
		return(n);
	else
		n += (id & 0x000f) << 4;
	return(n);
}


int get_3d_delta_t(packet *pk)
{
	int n;
	uint2 id;
	id = pk->idtype;
	n  = (pk->instseq & 0x0f00u) >> 8;
	if((id & 0x3000) == 0x3000)  /* burst */
		return(n);
	else
		n += (id & 0x000f) << 4;
	if(((pk->idtype & 0xfff0) ==0x5030) && ((pk->instseq & 0xf000)==0x0000))
		return(64);
	return(n);
}



int get_3d_inst(packet *pk)
{
	int instrument;
	int id,mp;
	id = (0x7700u & pk->idtype) >> 8;
	mp = pk->instseq >> 12;    /* 4 bit map number */
	if(id == 0x60 || id== 0x36)
		return(PESAH_INST);
	if(id == 0x50 || id== 0x35){
		if((mp & 1) == 0)
			return(EESAL_INST);
		else
			return(EESAH_INST);
	}
	if(id== 0x37)
	    return(EESAH_INST);

	return(INVALID_INST);

}


uint2 get_map_code(packet *pk)
{
        /* Eesa Low Burst  */
	if(((pk->idtype & 0x7ff0) ==0x3530) && ((pk->instseq & 0x0000)==0x0000))
	    return(MAP_MOM);
	/* 88 angle Eesa */
	if(((pk->idtype & 0xfff0) ==0x5030) && ((pk->instseq & 0xf000)==0x0000))
	    return(MAP_MOM);
	/* Eesa Cut */
	if(((pk->idtype & 0x7ff0) ==0x5030) && ((pk->instseq & 0xf000)==0x2000))
	    return(MAP_elc);
	/* Eesa High Slice */
	if(((pk->idtype & 0x7ff0) ==0x3730))
	    return(MAP_ehs);
	/* Eesa mom */
	if(((pk->idtype & 0xfff0) ==0x5030) && ((pk->instseq & 0xf000)==0x3000))
	    return(MAP_MOM);
	/* Pesa 3D burst */
	if((pk->idtype & 0x77f0) ==0x3630)
	    return(get_ph_map_code(pk));
	/* Pesa 3D */
	if((pk->idtype & 0xfff0) ==0x6030)
	    return(get_ph_map_code(pk));
	return(0);                /* unknown map */
}


uint2 get_ph_map_code(packet *pk)
{
	PCFG *pcfg;
	uint2 mapnum;
	
	mapnum = (pk->instseq & 0xf000) >> 12;
	pcfg = get_PCFG(pk->time);
	
	if((mapnum <= 3) && (mapnum >= 0))
		return(pcfg->norm_cfg.init_proc[mapnum]);
	
	return(0);
}
		




#if 0 
int convert_3dmap_units(data_map_3d *map)
{
	int b,e,ne;
	double dth,dt;
	double *nrg;
	int funits;
	int offset;
	int inst;

	if(map == 0)
		return(0);
/*	if(map->flux_units != COUNTS)  
		return(0);     */
	if(map->nrg_units != ENERGY_UNITS)	
		return(0);

	inst = map->inst;
	funits = map->flux_units;
	for(b=0;b<map->nbins;b++){
		dth = map->bin[b].geom * 5.625;
		ne = map->bin[b].ne;
		offset = map->bin[b].offset;
		if(ne==15){
			dt  = map->integ_t/(32*16);
			nrg = map->nrg15;
		}
		else{
			dt  = map->integ_t/(32*32);
			nrg = map->nrg30;
		}
		convert_units(ne,nrg,map->data+offset,dt,dth, map->geom_factor,funits);
	}	
	return(1);
}

#endif
