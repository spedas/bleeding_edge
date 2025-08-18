#include <math.h>
#include "p3d_dcm.h"

#include "eesa_cfg.h"
#include "wind_pk.h"
#include "map3d.h"
#include "pads_dcm.h"

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

static double dphi = 11.25;

static double domega[16] = {
     0.014946219,     0.042563230,     0.029754132,     0.033946244,
     0.018142453,     0.018691368,     0.019060275,     0.019245620,
     0.019245620,     0.019060275,     0.018691368,     0.018142453,
     0.033946244,     0.029754132,     0.042563230,     0.014946219
};

int sum_p3d_selected_channels(data_map_3d *p3d,int *bins,int nbin,spectra_3d_omni *spec);


int number_of_el_omni_samples(double t1,double t2)
{
	return(number_of_packets(E3D_88_ID,t1,t2));
}

int number_of_el_burst_samples(double t1,double t2)
{
	return(number_of_packets(E3D_BRST_ID,t1,t2));
}

int number_of_eh_burst_samples(double t1,double t2)
{
	return(number_of_packets(EH_BRST_ID,t1,t2));
}

int number_of_el_cut_samples(double t1,double t2)
{
	return(number_of_packets(E3D_CUT_ID,t1,t2));
}

int number_of_eh_slice_samples(double t1,double t2)
{
	return(number_of_packets(FPC_P_ID,t1,t2));
}

int number_of_el_merge_samples(double t1,double t2)
{
	return(number_of_packets(E3D_ELM_ID,t1,t2));
}

get_next_el_omni_spec(double time,spectra_3d_omni *spec)
{
	data_map_3d map;
	 
	packet_selector pks;
	
	SET_PKS_BY_TIME(pks,time,E3D_BRST_ID) ;
	if(get_next_p3d(&pks,&map,3)==1){
		sum_p3d_15_channels(&map,0,map.nbins,spec);
		return(1);
	}
	return(0);
}






int number_of_ph_omni_samples(double t1,double t2)
{
	return(number_of_packets(P3D_ID,t1,t2));
}



get_next_ph_omni_spec(double time,spectra_3d_omni *spec)
{
	data_map_3d map;
	packet_selector pks;
	
	SET_PKS_BY_TIME(pks,time,P3D_ID) ;
	 
	if(get_next_p3d(&pks,&map,3)==1){
		sum_p3d_15_channels(&map,0,map.nbins,spec);
		return(1);
	}
	return(0);
}





#if 0
int number_of_eh_omni_samples(double t1,double t2)
{
	int n;
	n = number_of_packets(E3D_UNK_ID,t1,t2);
	n+= number_of_packets(EHPAD_ID,t1,t2);
	return(n);
}


get_next_eh_omni_spec(double time,spectra_3d_omni *spec)
{
	static data_map_3d *map;
	static PADdata *pad;
	static packet_selector pks;

	SET_PKS_BY_TIME (pks,time,EHPAD_ID)
	 
	if(time){
		pad = get_next_ehpad(pks);
		SET_PKS_BY_TIME(pks,time,E3D_UNK_ID);
		map = get_next_p3d(&pks);
	}
	if(pad && (!map || (pad->time1 <= map->time))){
		sum_pad_15_channels(pad,0,pad->num_angles,spec);
		SET_PKS_BY_TIME(pks,time,EHPAD_ID);
		pad = get_next_ehpad(&pks);
		return(1);
	}
	if(map &&  (!pad || (map->time <= pad->time1))){
		sum_p3d_15_channels(map,0,map->nbins,spec);
		SET_PKS_BY_TIME(pks,time,E3D_UNK_ID);
		map = get_next_p3d(&pks);
		return(1);
	}
	if(map==0 && pad==0)
		return(0);

}

#else


int number_of_eh_omni_samples(double t1,double t2)
{
	int n;
	n = number_of_packets(E3D_UNK_ID,t1,t2);
/*	n+= number_of_packets(EHPAD_ID,t1,t2); */
	return(n);
}


int selected_bins[]={
1,5,12,16,22,23,26,27,30,31,32,33,34,37,
38,41,42,43,44,45,48,49,52,53,54,55,56,
59,60,63,64,65
};
#define N_SEL_BINS (sizeof(selected_bins)/sizeof(int))


int get_next_eh_omni_spec(double time,spectra_3d_omni *spec)
{
	data_map_3d map;
	packet_selector pks;
	
	SET_PKS_BY_TIME(pks,time,E3D_88_ID) ;
	 
	if(get_next_p3d(&pks,&map,3)==1){
#if 0
		sum_p3d_15_channels(&map,0,map.nbins,spec);
#else
		sum_p3d_selected_channels(&map,selected_bins,N_SEL_BINS,spec);
#endif
		return(1);
	}
	return(0);
}


#endif



#if 0     /* subroutine no longer required */
static int tsect[32] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7,
                        8, 9,10,11,12,12,13,13,14,14,14,14,15,15,15,15};

int make_3d_array(data_map_3d *map,float *buff)
/* takes filled map structure and fills  the 3d buffer buff[15][32][32] */
{

	int p,t,e;
	int np,nt,ne;
	int ts,n,offset,b;
	double flux;
	np = 32;
	nt = 32;
	ne = 15;
	for(e=0;e<ne;e++){
		for(t=0;t<nt;t++){
			ts = tsect[t];
			for(p=0;p<np;p++){
				b = map->ptmap[ts*32+p];
				offset = map->bin[b].offset;
				n = map->bin[b].ne;
				if(n==15)
					flux = map->data[offset+e];
				else{
					flux =  map->data[offset+2*e];
					flux += map->data[offset+2*e+1];
				}
				*buff++ = flux;
			}
		}
	}
	return(1);
}
#endif




int get_next_p3d(packet_selector *pks,data_map_3d *map,int exppk)
{
	static uint2 spin;
	int mcntr=0;
	packet *pk;

	pk = get_packet(pks);

	if(pk)
		spin = pk->spin;

	/* gather all packets of this type in this spin */
	while(pk){
		mcntr++;
		decom_map3d(pk,map);
		spin = pk->spin;
		if (!pk->next || spin != (pk->next)->spin) break ;
		pk = pk->next;
	}
	if (mcntr < exppk) return(0);
	
	return(pk ? 1 : 0);

}

sum_p3d_15_channels(data_map_3d *p3d,int bin1,int bin2,spectra_3d_omni *spec)
{
	int b,e,ne,offset;
	if(p3d==0)
		return(0);
/*	spec->nsteps = 15; */
	spec->time   = p3d->time;
	spec->integ_t = p3d->integ_t;
	spec->delta_t = p3d->delta_t;
	for(e=0;e<15;e++){
		spec->flux[e] = 0;
		spec->nrg_min[e] = p3d->nrg_min[e*2+1];
		spec->nrg_max[e] = p3d->nrg_max[e*2]; 
	}
	for(b=bin1;b<bin2;b++){
		if(b<0)                    /* safety check */
			continue;
		if(b>=p3d->nbins)          /* safety check */
			break;
		offset = p3d->bin[b].offset;
		ne = p3d->bin[b].ne;
		if(ne==0)
			break;
		for(e=0;e<15;e++){
			spec->flux[e] += p3d->data[offset++];
			if(ne==30)
				spec->flux[e] += p3d->data[offset++];	
		}
	}
	return(1);
}


average_p3d_channels(data_map_3d *p3d,uchar *blanked,spectra_3d_omni *spec)
{
	int b,e,ne,offset,navg;
/*	spec->nsteps = 15; */
	spec->time   = p3d->time;
	spec->integ_t = p3d->integ_t;
	spec->delta_t = p3d->delta_t;
	for(e=0;e<15;e++){
		spec->flux[e] = 0;
		spec->nrg_min[e] = p3d->nrg_min[e*2+1];
		spec->nrg_max[e] = p3d->nrg_max[e*2]; 
	}
	for(navg=b=0; b<p3d->nbins; b++){
		if(blanked && (blanked[b] & 1))
			continue;
		offset = p3d->bin[b].offset;
		ne = p3d->bin[b].ne;
		for(e=0;e<15;e++){
			spec->flux[e] += p3d->data[offset++];
			if(ne==30)
				spec->flux[e] += p3d->data[offset++];	
		}
		navg++;
	}
	for(e=0;e<15;e++)
		spec->flux[e] /= navg;
	
	return(1);
}


sum_p3d_selected_channels(data_map_3d *p3d,int *bins,int nbin,spectra_3d_omni *spec)
{
	int b,i,e,ne,offset;
	if(p3d==0)
		return(0);
/*	spec->nsteps = 15; */
	spec->time   = p3d->time;
	spec->integ_t = p3d->integ_t;
	spec->delta_t = p3d->delta_t;
	for(e=0;e<15;e++){
		spec->flux[e] = 0;
		spec->nrg_min[e] = p3d->nrg_min[e*2+1];
		spec->nrg_max[e] = p3d->nrg_max[e*2]; 
	}
	for(i=0;i<nbin;i++){
		b = bins[i];
		if(b<0)                    /* safety check */
			continue;
		if(b>=p3d->nbins)          /* safety check */
			continue;
		offset = p3d->bin[b].offset;
		ne = p3d->bin[b].ne;
		if(ne==0)
			break;
		for(e=0;e<15;e++){
			spec->flux[e] += p3d->data[offset++];
			if(ne==30)
				spec->flux[e] += p3d->data[offset++];	
		}
	}
	return(1);
}


sum_pad_15_channels(PADdata *pad,int bin1,int bin2,spectra_3d_omni *spec)
{
	int e,a,ne;
	double f;
	if(pad==0)
		return(0);
	ne = pad->num_energies;
/*	spec->nsteps = pad->num_energies; */
	spec->time = pad->time1;
	spec->integ_t = pad->time2 - pad->time1;
	spec->delta_t = spec->integ_t;               /*  kluge */
	for(e=0;e<ne;e++){
		f = 0;
		for(a=bin1;a<bin2 && a<pad->num_angles;a++){
			f += pad->flux[a*ne+e];
		}
		spec->flux[e] = f;
		spec->nrg_min[e] = pad->nrg_min[e];
		spec->nrg_max[e] = pad->nrg_max[e];
	}
	return(1);

}

static int rel_times[88] = {2,2,2,2,2,2,2,2,4,4,8,2,2,2,2,2,2,2,2,4,4,8,
	2,2,2,2,2,2,2,2,4,4,8,2,2,2,2,2,2,2,2,4,4,8,2,2,2,2,2,2,2,2,4,4,8,
	2,2,2,2,2,2,2,2,4,4,8,2,2,2,2,2,2,2,2,4,4,8,2,2,2,2,2,2,2,2,4,4,8};
	
int4 get_next_el_struct(packet_selector *pks, e3d_data *snap, data_map_3d *map,
	int exppk)
{
	int b,e,shift,offset,cntr=0,mcntr=0;
	float spin_period;
        double n0;
        ECFG *cfg;
	static uint2 spin;
	packet *pk;

	pk = get_packet(pks);

        if(pk==0)
                return(0);

	if(pk->quality & (~pkquality)) {
		snap->time = pk->time;
		return(0);
	}

	if(pk)
		spin = pk->spin;

	/* gather all packets of this type in this spin */
	while(pk){
		decom_map3d(pk,map);
		mcntr++;
		spin = pk->spin;
		if (!pk->next || spin != (pk->next)->spin) break ;
		pk = pk->next;
	}

        cfg = get_ECFG(map->time);

        snap->time = map->time;
        snap->spin = map->spin;
        snap->mass = 5.6856591e-6;

        snap->delta_t = map->delta_t;
        snap->integ_t = map->integ_t;
        snap->shift = map->shift;
        
/*        snap->geom_factor = map->geom_factor; */
        spin_period = map->spin_period;
        
      	for(b=0;b<88;b++){
      		offset = map->bin[b].offset;
      		snap->domega[b] = map->bin[b].domega;
      		for(e=0;e<15;e++){
      			snap->dt[b][e] = snap->integ_t*map->bin[b].dt*
      				map->dt[offset+e]/16.;
      			snap->gf[b][e] = map->bin[b].gf;
	                snap->dtheta[b][e] = map->bin[b].dtheta;
	                snap->dphi[b][e] = map->bin[b].dphi;
	                snap->flux[b][e] = map->data[offset+e];
	                snap->nrg[b][e] = map->nrg15[e];
	                snap->dnrg[b][e] = map->dnrg15[e];
	                snap->theta[b][e] = map->bin[b].theta;
	                snap->phi[b][e] = map->bin[b].phi[e];
	                snap->dvolume[b][e] = map->dnrg15[e]/map->nrg15[e]*
	                	snap->domega[b];
               }
	}
	
        for(e=0;e<15*8;e++){
                snap->dac_code[e]     = cfg->eldac_tbl[e];
                snap->volts[e] = cfg->el_volts_tbl[e];
        }

       	if (mcntr < exppk)
       		snap->valid= 0;
      	else
       		snap->valid= 1;
        snap->n_samples++;

        return(1);
}

int4 get_next_eh_struct(packet_selector *pks, e3d_data *snap, data_map_3d *map,
	int exppk)
{
	int b,e,shift,offset,cntr=0,mcntr=0;
	float spin_period;
        double n0;
        ECFG *cfg;
	static uint2 spin;
	packet *pk;

	pk = get_packet(pks);

        if(pk==0)
                return(0);

	if(pk->quality & (~pkquality)) {
		snap->time = pk->time;
		return(0);
	}

	if(pk)
		spin = pk->spin;

	/* gather all packets of this type in this spin */
	while(pk){
		decom_map3d(pk,map);
		mcntr++;
		spin = pk->spin;
		if (!pk->next || spin != (pk->next)->spin) break ;
		pk = pk->next;
	}

        cfg = get_ECFG(map->time);

        snap->time = map->time;
        snap->spin = map->spin;
        snap->mass = 5.6856591e-6;

        snap->delta_t = map->delta_t;
        snap->integ_t = map->integ_t;
        snap->shift = map->shift;
        
/*        snap->geom_factor = map->geom_factor; */
        spin_period = map->spin_period;
        
      	for(b=0;b<88;b++){
      		offset = map->bin[b].offset;
      		snap->domega[b] = map->bin[b].domega;
      		for(e=0;e<15;e++){
      			snap->dt[b][e] = snap->integ_t*map->bin[b].dt*
      				map->dt[offset+e]/16.;
      			snap->gf[b][e] = map->bin[b].gf;
	                snap->dtheta[b][e] = map->bin[b].dtheta;
	                snap->dphi[b][e] = map->bin[b].dphi;
	                snap->flux[b][e] = map->data[offset+e];
	                snap->nrg[b][e] = map->nrg15[e];
	                snap->dnrg[b][e] = map->dnrg15[e];
	                snap->theta[b][e] = map->bin[b].theta;
	                snap->phi[b][e] = map->bin[b].phi[e];
	                snap->dvolume[b][e] = map->dnrg15[e]/map->nrg15[e]*
	                	snap->domega[b];
               }
	}
	
        for(e=0;e<15*8;e++){
                snap->dac_code[e]     = cfg->ehdac_tbl[e];
                snap->volts[e] = cfg->eh_volts_tbl[e];
        }

       	if (mcntr < exppk)
       		snap->valid= 0;
      	else
       		snap->valid= 1;
        snap->n_samples++;

        return(1);
}

int4 get_next_elc_struct(packet_selector *pks, elc_data *snap, data_map_3d *map,
	int exppk)
{
	int b,e,shift,offset,cntr=0,mcntr=0;
	float spin_period;
        double n0;
        ECFG *cfg;
	static uint2 spin;
	packet *pk;

	pk = get_packet(pks);

	if(pk->quality & (~pkquality)) {
		snap->time = pk->time;
		return(0);
	}

	if(pk)
		spin = pk->spin;

	/* gather all packets of this type in this spin */
	while(pk){
		decom_map3d(pk,map);
		mcntr++;
		spin = pk->spin;
		if (!pk->next || spin != (pk->next)->spin) break ;
		pk = pk->next;
	}

        if(pk==0)
                return(0);

        cfg = get_ECFG(map->time);

        snap->time = map->time;
        snap->spin = map->spin;
        snap->mass = 5.6856591e-6;

        snap->delta_t = map->delta_t;
        snap->integ_t = map->integ_t;
        snap->shift = map->shift;
        
/*        snap->geom_factor = map->geom_factor; */
        spin_period = map->spin_period;
        
      	for(b=0;b<32;b++){
      		offset = map->bin[b].offset;
      		snap->domega[b] = map->bin[b].domega;
      		for(e=0;e<15;e++){
      			snap->dt[b][e] = snap->integ_t*map->bin[b].dt*
      				map->dt[offset+e]/16.;
      			snap->gf[b][e] = map->bin[b].gf;
	                snap->dtheta[b][e] = map->bin[b].dtheta;
	                snap->dphi[b][e] = map->bin[b].dphi;
	                snap->flux[b][e] = map->data[offset+e];
	                snap->nrg[b][e] = map->nrg15[e];
	                snap->dnrg[b][e] = map->dnrg15[e];
	                snap->theta[b][e] = map->bin[b].theta;
	                snap->phi[b][e] = map->bin[b].phi[e];
	                snap->dvolume[b][e] = map->dnrg15[e]/map->nrg15[e]*
	                	snap->domega[b];
               }
	}
	
        for(e=0;e<15*8;e++){
                snap->dac_code[e]     = cfg->eldac_tbl[e];
                snap->volts[e] = cfg->el_volts_tbl[e];
        }

       	if (mcntr < exppk)
       		snap->valid= 0;
      	else
       		snap->valid= 1;
        snap->n_samples++;

        return(1);
}

int4 get_next_ehs_struct(packet_selector *pks, ehs_data *snap, data_map_3d *map,
	int exppk)
{
	int b,e,shift,offset,cntr=0,mcntr=0;
	float spin_period;
        double n0;
        ECFG *cfg;
	static uint2 spin;
	packet *pk;

	pk = get_packet(pks);

	if(pk)
		spin = pk->spin;

	/* gather all packets of this type in this spin */
	while(pk){
		decom_map3d(pk,map);
		mcntr++;
		spin = pk->spin;
		if (!pk->next || spin != (pk->next)->spin) break ;
		pk = pk->next;
	}

        if(pk==0)
                return(0);

	if(pk->quality & (~pkquality)) {
		snap->time = pk->time;
		return(0);
	}

        cfg = get_ECFG(map->time);

        snap->time = map->time;
        snap->spin = map->spin;
        snap->mass = 5.6856591e-6;

        snap->delta_t = map->delta_t;
        snap->integ_t = map->integ_t;
        snap->shift = map->shift;
        
/*        snap->geom_factor = map->geom_factor; */
        spin_period = map->spin_period;
        
      	for(b=0;b<24;b++){
      		offset = map->bin[b].offset;
      		snap->domega[b] = map->bin[b].domega;
      		for(e=0;e<30;e++){
      			snap->dt[b][e] = snap->integ_t*map->bin[b].dt*
      				map->dt[offset+e]/16.;
      			snap->gf[b][e] = map->bin[b].gf;
	                snap->dtheta[b][e] = map->bin[b].dtheta;
	                snap->dphi[b][e] = map->bin[b].dphi;
	                snap->flux[b][e] = map->data[offset+e];
	                snap->nrg[b][e] = map->nrg30[e];
	                snap->dnrg[b][e] = map->dnrg30[e];
	                snap->theta[b][e] = map->bin[b].theta;
	                snap->phi[b][e] = map->bin[b].phi[e];
	                snap->dvolume[b][e] = map->dnrg30[e]/map->nrg30[e]*
	                	snap->domega[b];
               }
	}
	
        for(e=0;e<15*8;e++){
                snap->dac_code[e]     = cfg->ehdac_tbl[e];
                snap->volts[e] = cfg->eh_volts_tbl[e];
        }

       	if (mcntr < exppk)
       		snap->valid= 0;
      	else
       		snap->valid= 1;
        snap->n_samples++;

        return(1);
}

int4 e3d88_to_idl(int argc,void *argv[])
{
        e3d_data *snap;
        int4 size,advance,index,*options,ok,exppk=3;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_el_omni_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (e3d_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(E3D_88_ID,size,time);
            return(ok);
        }

        if(size != sizeof(e3d_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }

        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,E3D_88_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],E3D_88_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,E3D_88_ID) ;
        }

        ok = get_next_el_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 1.26e-2/180.*5.625;

        return(ok);

}




int4 elb_to_idl(int argc,void *argv[])
{
        e3d_data *snap;
        int4 size,advance,index,*options,ok,exppk=3;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_el_burst_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (e3d_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(E3D_BRST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(e3d_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,E3D_BRST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],E3D_BRST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,E3D_BRST_ID) ;
        }
	
        ok = get_next_el_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 1.26e-2/180.*5.625;

        return(ok);

}

int4 ehb_to_idl(int argc,void *argv[])
{
        e3d_data *snap;
        int4 size,advance,index,*options,ok,exppk=1;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_eh_burst_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (e3d_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(EH_BRST_ID,size,time);
            return(ok);
        }

        if(size != sizeof(e3d_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,EH_BRST_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],EH_BRST_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,EH_BRST_ID) ;
        }
	
        ok = get_next_eh_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 0.101/360.*5.625;

        return(ok);

}

int4 elm_to_idl(int argc,void *argv[])
{
        e3d_data *snap;
        int4 size,advance,index,*options,ok,exppk=3;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_el_merge_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (e3d_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(E3D_ELM_ID,size,time);
            return(ok);
        }

        if(size != sizeof(e3d_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,E3D_ELM_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],E3D_ELM_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,E3D_ELM_ID) ;
        }
	
        ok = get_next_el_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 1.26e-2/180.*5.625;

        return(ok);

}

int4 e3dunk_to_idl(int argc,void *argv[])
{
        e3d_data *snap;
        int4 size,advance,index,*options,ok,exppk=3;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_eh_omni_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (e3d_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(E3D_UNK_ID,size,time);
            return(ok);
        }

        if(size != sizeof(e3d_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,E3D_UNK_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],E3D_UNK_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,E3D_UNK_ID) ;
        }
	
        ok = get_next_eh_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 0.101/360.*5.625;

        return(ok);

}

int4 elc_to_idl(int argc,void *argv[])
{
        elc_data *snap;
        int4 size,advance,index,*options,ok,exppk=1;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_el_cut_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (elc_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(E3D_CUT_ID,size,time);
            return(ok);
        }

        if(size != sizeof(elc_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,E3D_CUT_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],E3D_CUT_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,E3D_CUT_ID) ;
        }
	
        ok = get_next_elc_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 1.26e-2/180.*5.625;

        return(ok);

}

int4 ehs_to_idl(int argc,void *argv[])
{
        ehs_data *snap;
        int4 size,advance,index,*options,ok,exppk=1;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        static data_map_3d map;

        if(argc == 0)
                return( number_of_eh_slice_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        snap = (ehs_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(FPC_P_ID,size,time);
            return(ok);
        }

        if(size != sizeof(ehs_data)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(e3d_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,FPC_P_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],FPC_P_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,FPC_P_ID) ;
        }
	
        ok = get_next_ehs_struct(&pks,snap,&map,exppk);
        snap->index = pks.index;
        snap->geom_factor = 1.26e-2/180.*5.625;

        return(ok);

}
