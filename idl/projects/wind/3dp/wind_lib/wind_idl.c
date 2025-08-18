#include "filter.h"
#include "windmisc.h"
#include "p3d_dcm.h"
#include "pl_dcm.h"
#include "emom_dcm.h"
#include "pmom_dcm.h"
#include "hkp_dcm.h"
#include "eAtoD_dcm.h"
#include "sst_dcm.h"
#include "p3d_time.h"
#include "fpc_dcm.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef	__cplusplus
extern "C"
{
#endif
    


#if 0
double str_to_time_idl(int argc,void *argv[])
{
	double t;
	IDL_STRING str;

	str = *(IDL_STRING *)argv[0];
	if(str.length)
		t = YMDHMS_to_time(str.s);
	else
		t = 0;
	return(t);
}



int time_to_str_idl(int argc,void *argv[])
{
	double t;
	char *s;
	char *buff;   /* must be at least 40 char long */

	t = *(double *)argv[0];
	buff = (char *)argv[1];
	s = time_to_YMDHMS(t);
	strcpy(buff,s);
	return(strlen(s));
}
#endif




int  load_data_files_idl(int argc,void *argv[])
{
	double *begintime,*endtime;
	char  *mstfilename="mastfile";    /* default value */
	IDL_STRING    str;
	int ok;
        long  size;
	static  long  memsize;
	static  char *bigmem;


	if(argc<1){
		printf("Must pass time interval\n");
		return(0);
	}

	begintime = (double *)argv[0];
	endtime   = begintime + 1;

	if(argc>=2){
		str = *((IDL_STRING *)argv[1]);
		if(str.length)
			mstfilename = str.s;
	}
        if(argc >=3){
                size = *((int2 *)argv[2]);
        }
        else size=25;	

	if(argc >= 4){
		pkquality = *((int2 *)argv[3]);
	}
	else pkquality = 0;

	if(pkquality > 0)
		printf("Packet quality flag set to %d\n",pkquality);
	
        size = size *1024 * 1024;

/*	printf("%s (%f)\n",time_to_YMDHMS(*begintime),*begintime);  */
/*	printf("%s (%f)\n",time_to_YMDHMS(*endtime),*endtime);      */
	
	if(size != memsize){
            if(bigmem) free(bigmem);
            bigmem = (char *) malloc(size);
            memsize = size;
        }
	
	if(bigmem == 0){
            fprintf(debug,"Unable to allocate memory\r\n");
            return(0);
	}
		
	ok=load_all_data_files_p(mstfilename,begintime,endtime,memsize,bigmem);

	if (ok > 0)  {
		realloc((void *)bigmem,memsize - ok);
		memsize = memsize - ok;
	}

	
	return(ok);
}

int change_pkquality(int argc,void *argv[])
{
	if(argc<1){
		printf("Must provide packet quality\r\n");
		return(0);
	}
	
	pkquality = *((int2 *)argv[0]);
	printf("Changed packet quality to %d\r\n",pkquality);
	return(1);
}





typedef struct {
	int4   *options;   /*  options[0] is the data type, options[1] is index */
	double *time;      /*  time[0]=sample time;  time[1]=integration time */
	int2   *sizes;     /*  0: nphi;   1:ntheta;    2:nenergies;   3:nbins */
	int2   *ptmap;     /*  bin map   [ntheta][nphi]   */
	float  *pt_limits; /*  0: phimin,  1:phimax,   2:thetamin;   3:thetamax */
	float  *data;      /*  counts data     [nbins][nenergies] */
	float  *nrgs;      /*  energy steps    [nbins][nenergies] */
	float  *geom;      /*  geometric factors  [nbins] */
	float  *thetas;    /*  theta values  [nbins][nenergies] */
	float  *phis;      /*  phi values  [nbins][nenergies] */
	float  *dnrgs;     /* delta energy values [nbins][nenergies] */
	float  *dtheta;    /* delta theta values  [nbins] */
	float  *dphi;      /* delta phi values  [nbins] */
	float  *domega;    /* solid angle [nbins] */
	float  *eff;       /* duty cycle of each energy step [nenergies] */
	float  *feff;      /* foil electron efficiencies [nenergies] */
	short  *advance;   /* get next point flag */
	int4   *spin;      /* spin */
	short  *magel;     /* mag elevation */
	short  *magaz;     /* mag azimuth */
} idl_3d_data;

int fill_esa_data(idl_3d_data idl);
int make_ptmap(data_map_3d *map,idl_3d_data idl);
int fill_pl_data(idl_3d_data idl);
int fill_plb_data(idl_3d_data idl);
int fill_sst_foil_data(idl_3d_data idl);
int fill_sst_open_data(idl_3d_data idl);
int fill_sst_ft_data(idl_3d_data idl);
int fill_sst_ot_data(idl_3d_data idl);
int fill_sst_f_spectra_data(idl_3d_data idl);
int fill_sst_o_spectra_data(idl_3d_data idl);
int fill_sst_t_spectra_data(idl_3d_data idl);
int fill_sst_fast_rates(idl_3d_data idl);
int fill_sst_slow_rates(idl_3d_data idl);



/* returns 0 on error  */
int  get_3dbins_idl(int argc,void *argv[])
{
	idl_3d_data idl; /*  contains all input/output pointers */

	int data_type;

/*printf("argc= %d\n",argc); */
	idl.options = (int4 *)argv[0];        /*options[0] is data type;
					       *options[1] is index, -1 == get by time
					       *options[2] is selection mode for sst*/
	idl.time    = (double *)argv[1];
	idl.sizes   = (int2*)argv[2];
	idl.ptmap   = (int2 *)argv[3];
	idl.pt_limits = (float *)argv[4];
	idl.data    = (float *)argv[5];  
	idl.nrgs    = (float *)argv[6]; 
	idl.geom    = (float *)argv[7];
	idl.thetas  = (float *)argv[8];
	idl.phis    = (float *)argv[9];
	idl.dnrgs   = (float *)argv[10];
	idl.dtheta  = (float *)argv[11];
	idl.dphi    = (float *)argv[12];
	idl.domega  = (float *)argv[13];
	idl.eff     = (float *)argv[14];
	idl.feff    = (float *)argv[15];
	idl.spin    = (int4 *)argv[16];
	idl.magel   = (int2 *)argv[17];
	idl.magaz   = (int2 *)argv[18];
	idl.advance = (int2 *)argv[19];
	data_type = idl.options[0];

	switch(data_type){
	case 0:   /* EH  */
	case 1:   /* EL  */
	case 2:   /* PH  */
		return( fill_esa_data(idl) );
	case 3:   /* PL  */
		return( fill_pl_data(idl) );
	case 4:   /* SST FOIL */
	case 19:   /* SST FOIL BURST*/
		return( fill_sst_foil_data(idl) );
	case 5:   /* SST OPEN */
	case 20:   /* SST OPEN BURST*/
		return( fill_sst_open_data(idl) );
	case 7:   /* PL Burst */
		return( fill_plb_data(idl) );
	case 8:   /* SST F+T */
		return( fill_sst_ft_data(idl) );
	case 9:   /* SST O+T */
		return( fill_sst_ot_data(idl) );
	case 10:   /* SST FOIL SPECTRA */
	case 17:   /* SST FOIL BURST SPECTRA */
		return( fill_sst_f_spectra_data(idl) );
	case 11:   /* SST OPEN SPECTRA */
	case 18:   /* SST OPEN BURST SPECTRA */
		return( fill_sst_o_spectra_data(idl) );
	case 12:   /* SST F+T % O+T SPECTRA */
		return( fill_sst_t_spectra_data(idl) );
	case 13:   /* EL Burst  */
		return( fill_esa_data(idl) );
	case 14:   /* EH Slice  */ 
		return( fill_esa_data(idl) ); 
	case 15:   /* PH Burst  */
		return( fill_esa_data(idl) );
	case 16:   /* Eesa Low Cuts  */
		return( fill_esa_data(idl) );
	case 21:   /* SST FAST RATES */
		return( fill_sst_fast_rates(idl) );
	case 22:   /* SST SLOW RATES */
		return( fill_sst_slow_rates(idl) );
	default:
		return(0);
	}
}


int  get_fpc_idl(int argc,void *argv[])
{
    /* argv[0] will be the fpc_data struct */

    fpc_xcorr_str	*fpc_idl = (fpc_xcorr_str *) argv[0];
    int 		advance =  *((short *) argv[1]);
    static packet_selector pks; 

    if (advance) {
	SET_PKS_BY_INDEX(pks,pks.index+advance,FPC_D_ID);
    }
    else if (fpc_idl->select_by == BY_INDEX) {
	SET_PKS_BY_INDEX(pks,fpc_idl->index,FPC_D_ID);
    }
    else {
	SET_PKS_BY_TIME(pks,fpc_idl->time,FPC_D_ID);
    }
    
    /* fill idl struct */

    return get_next_fpc(&pks, fpc_idl);
}

int f_bin_channels[48] = {3,3,2,2,2,2,4,4,4,4,4,4,4,4,
			  5,5,5,5,0,0,1,1,1,1,3,3,2,2,
			  2,2,4,4,4,4,4,4,4,4,5,5,5,5,
			  0,0,1,1,1,1};   

int o_bin_channels[48] = {0,0,5,5,5,5,4,4,4,4,4,4,4,4,2,2,
			  2,2,3,3,1,1,1,1,0,0,5,5,5,5,4,4,
			  4,4,4,4,4,4,2,2,2,2,3,3,1,1,1,1};   


int fill_sst_foil_data(idl_3d_data idl)
{
	static sst_3d_F_distribution sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	uint2 validmask;
	packet_selector *pksp;
	static packet_selector pks_sf;
	static packet_selector pks_sfb;
	int id;

	switch( idl.options[0] ){
	case 4:  /* SF */
	    pksp = &pks_sf;
	    id = S_3D_F_ID;
	    break;
	case 19:  /* SFB */
	    pksp = &pks_sfb;
	    id = S_HS_BST_ID;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	
	ok = get_next_sst_3d_F_str(pksp,&sst, idl.options[2], &validmask);
	if(!ok)
		return(0);
	idl.options[1] = pksp->index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 7;
	nb = idl.sizes[3] = 48;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_map[t / 3][p];
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			c = f_bin_channels[bin];
			idl.data[cntr] = sst.flux[e][bin];
			idl.nrgs[cntr] = sst.energies[c][e+7];
			idl.dnrgs[cntr] = sst.e_max[c][e+7]-sst.e_min[c][e+7];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			idl.feff[cntr] = sst.e_eff[c][e];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}


	switch( idl.options[0] ){
	case 4:  /* SF */
	for(e=0;e<ne;e++)
	    idl.eff[e] = sst.duty_cycle[e] * (0x1u&(validmask>>e)) ;
	    break;
	case 19:  /* SFB */
	for(e=0;e<ne;e++)
	    idl.eff[e] = 0.0625 ;
	    break;
	default:
	    ok = 0;
	}
	
	return(1);
}



int fill_sst_open_data(idl_3d_data idl)
{
	static sst_3d_O_distribution sst;
	double time;
	int e,p,t,bin,d;
	int ne,np,nt,nb;
	int ok,cntr;
	uint2 validmask;
	packet_selector *pksp;
	static packet_selector pks_so;
	static packet_selector pks_sob;
	int id;

	switch( idl.options[0] ){
	case 5:  /* SO */
	    pksp = &pks_so;
	    id = S_3D_O_ID;
	    break;
	case 20:  /* SOB */
	    pksp = &pks_sob;
	    id = S_HS_BST_ID;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	
	ok = get_next_sst_3d_O_str(pksp,&sst, idl.options[2], &validmask);
	if(!ok)
		return(0);
	idl.options[1] = pksp->index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 9;
	nb = idl.sizes[3] = 48;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_map[t / 3][p];
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			d = o_bin_channels[bin];
			idl.data[cntr] = sst.flux[e][bin];
			idl.nrgs[cntr] = sst.energies[d][e+9];
			idl.dnrgs[cntr] = sst.e_max[d][e+9]-sst.e_min[d][e+9];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}

	switch( idl.options[0] ){
	case 5:  /* SO */
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e] * (0x1u&(validmask>>e));
	    break;
	case 20:  /* SOB */
	for(e=0;e<ne;e++)
		idl.eff[e] = 0.0625;
	    break;
	default:
	    ok = 0;
	}
	
	return(1);
}

int fill_sst_fast_rates(idl_3d_data idl)
{
	static sst_3d_O_distribution sst;
	double time;
	int e,p,t,bin,d;
	int ne,np,nt,nb;
	int ok,cntr;
	uint2 validmask;
	packet_selector *pksp;
	static packet_selector pks_so;
	int id;

	switch( idl.options[0] ){
	case 21:  /* FAST RATES */
	    pksp = &pks_so;
	    id = S_3D_O_ID;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	
	ok = get_next_sst_3d_O_str(pksp,&sst, idl.options[2], &validmask);
	if(!ok)
		return(0);
	idl.options[1] = pksp->index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 1;
	nb = idl.sizes[3] = 14;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_map[t / 3][p];
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			d = o_bin_channels[bin];
			idl.data[cntr] = sst.rates[bin];
			idl.nrgs[cntr] = 1.;
			idl.dnrgs[cntr] = 1.;
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}

	switch( idl.options[0] ){
	case 21:  /* FAST RATES */
	for(e=0;e<ne;e++)
		idl.eff[e] = 1.;
	    break;
	default:
	    ok = 0;
	}
	
	return(1);
}

int ft_bin_channels[16] = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1};
int ot_bin_channels[16] = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1};



int fill_sst_ft_data(idl_3d_data idl)
{
	static sst_t_distribution sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	static packet_selector pks;

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,S_T_DST_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],S_T_DST_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],S_T_DST_ID) ;
	}
	
	ok = get_next_sst_3d_T_str(&pks,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pks.index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 7;
	nb = idl.sizes[3] = 16;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_FT_map[t / 3][p/4];
		}
	}

	cntr = 0;
	for(bin=0;bin<8;bin++){
		for(e=0;e<ne;e++){
			c = ft_bin_channels[bin];
			idl.data[cntr] = sst.FT2[e][bin];
			idl.nrgs[cntr] = sst.e_FT_mid[c][e];
			idl.dnrgs[cntr] = sst.e_FT_max[c][e]-sst.e_FT_min[c][e];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			idl.feff[cntr] = sst.e_FT_eff[c][e];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}
	for(bin=16;bin<24;bin++){
		for(e=0;e<ne;e++){
			c = ft_bin_channels[bin-8];
			idl.data[cntr] = sst.FT6[e][bin-16];
			idl.nrgs[cntr] = sst.e_FT_mid[c][e];
			idl.dnrgs[cntr] = sst.e_FT_max[c][e]-sst.e_FT_min[c][e];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			idl.feff[cntr] = sst.e_FT_eff[c][e];
			cntr++;
		}
		idl.dtheta[bin-8] = sst.dtheta[bin-8];
		idl.dphi[bin-8] = sst.dphi[bin-8];
		idl.geom[bin-8] = sst.geom[bin-8];
		idl.domega[bin-8] = sst.domega[bin-8];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e];
	
	return(1);
}
int fill_sst_ot_data(idl_3d_data idl)
{
	static sst_t_distribution sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	static packet_selector pks;

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,S_T_DST_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],S_T_DST_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],S_T_DST_ID) ;
	}
	
	ok = get_next_sst_3d_T_str(&pks,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pks.index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 9;
	nb = idl.sizes[3] = 16;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_OT_map[t / 3][p/4];
		}
	}

	cntr = 0;
	for(bin=8;bin<16;bin++){
		for(e=0;e<ne;e++){
			c = ot_bin_channels[bin-8];
			idl.data[cntr] = sst.OT2[e][bin-8];
			idl.nrgs[cntr] = sst.e_OT_mid[c][e];
			idl.dnrgs[cntr] = sst.e_OT_max[c][e]-sst.e_OT_min[c][e];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			cntr++;
		}
		idl.dtheta[bin-8] = sst.dtheta[bin-8];
		idl.dphi[bin-8] = sst.dphi[bin-8];
		idl.geom[bin-8] = sst.geom[bin-8];
		idl.domega[bin-8] = sst.domega[bin-8];
	}
	for(bin=24;bin<32;bin++){
		for(e=0;e<ne;e++){
			c = ot_bin_channels[bin-16];
			idl.data[cntr] = sst.OT6[e][bin-24];
			idl.nrgs[cntr] = sst.e_OT_mid[c][e];
			idl.dnrgs[cntr] = sst.e_OT_max[c][e]-sst.e_OT_min[c][e];
			idl.thetas[cntr] = sst.theta[bin];
			idl.phis[cntr] = sst.phi[bin];
			cntr++;
		}
		idl.dtheta[bin-16] = sst.dtheta[bin-16];
		idl.dphi[bin-16] = sst.dphi[bin-16];
		idl.geom[bin-16] = sst.geom[bin-16];
		idl.domega[bin-16] = sst.domega[bin-16];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e];
	
	return(1);
}

int fill_sst_f_spectra_data(idl_3d_data idl)
{
	static struct sst_spectra_struct sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	packet_selector *pksp;
	static packet_selector pks_fsp;
	static packet_selector pks_fspb;
	int id;

	switch( idl.options[0] ){
	case 10:  /* FSP */
	    pksp = &pks_fsp;
	    id = S_RATE3_ID;
	    break;
	case 17:  /* FSPB */
	    pksp = &pks_fspb;
	    id = S_RS_BST_ID;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	
	ok = get_next_sst_spectra_str(pksp,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pksp->index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 16;
	nb = idl.sizes[3] = 6;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_F_map[t / 3];
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			if (bin==0)	idl.data[cntr] = sst.F1[e];
			if (bin==1)	idl.data[cntr] = sst.F2[e];
			if (bin==2)	idl.data[cntr] = sst.F3[e];
			if (bin==3)	idl.data[cntr] = sst.F4[e];
			if (bin==4)	idl.data[cntr] = sst.F5[e];
			if (bin==5)	idl.data[cntr] = sst.F6[e];
			idl.nrgs[cntr] = sst.e_F_mid[bin][e+16];
			idl.dnrgs[cntr] = sst.e_F_max[bin][e+16]-sst.e_F_min[bin][e+16];
			idl.thetas[cntr] = sst.theta_f[bin];
			idl.phis[cntr] = sst.phi[bin];
			idl.feff[cntr] = sst.e_F_eff[bin][e];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e];
	
	return(1);
}

int fill_sst_o_spectra_data(idl_3d_data idl)
{
	static struct sst_spectra_struct sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	packet_selector *pksp;
	static packet_selector pks_osp;
	static packet_selector pks_ospb;
	int id;

	switch( idl.options[0] ){
	case 11:  /* OSP */
	    pksp = &pks_osp;
	    id = S_RATE3_ID;
	    break;
	case 18:  /* OSPB */
	    pksp = &pks_ospb;
	    id = S_RS_BST_ID;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	
	ok = get_next_sst_spectra_str(pksp,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pksp->index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 24;
	nb = idl.sizes[3] = 6;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= sst.pt_O_map[t / 3];
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			if (bin==0)	idl.data[cntr] = sst.O1[e];
			if (bin==1)	idl.data[cntr] = sst.O2[e];
			if (bin==2)	idl.data[cntr] = sst.O3[e];
			if (bin==3)	idl.data[cntr] = sst.O4[e];
			if (bin==4)	idl.data[cntr] = sst.O5[e];
			if (bin==5)	idl.data[cntr] = sst.O6[e];
			idl.nrgs[cntr] = sst.e_O_mid[bin][e+24];
			idl.dnrgs[cntr] = sst.e_O_max[bin][e+24]-sst.e_O_min[bin][e+24];
			idl.thetas[cntr] = sst.theta_o[bin];
			idl.phis[cntr] = sst.phi[bin];
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e];
	
	return(1);
}

int fill_sst_t_spectra_data(idl_3d_data idl)
{
	static struct sst_spectra_struct sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	static packet_selector pks;

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,S_RATE3_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],S_RATE3_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],S_RATE3_ID) ;
	}
	
	ok = get_next_sst_spectra_str(&pks,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pks.index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 24;
	nb = idl.sizes[3] = 4;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= 0;
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			if (bin==0)	idl.data[cntr] = sst.FT2[e];
			if (bin==1)	idl.data[cntr] = sst.FT6[e];
			if (bin==2)	idl.data[cntr] = sst.OT2[e];
			if (bin==3)	idl.data[cntr] = sst.OT6[e];
			idl.nrgs[cntr]  = sst.e_FT_mid[bin][e];
			idl.dnrgs[cntr] = sst.e_FT_max[bin][e]-sst.e_FT_min[bin][e];
		if (bin<2) idl.feff[cntr] = sst.e_FT_eff[bin][e];
		if (bin>1) {	idl.nrgs[cntr] = sst.e_OT_mid[bin-2][e];
			idl.dnrgs[cntr] = sst.e_OT_max[bin-2][e]-sst.e_OT_min[bin-2][e];}
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = sst.duty_cycle[e];
	
	return(1);
}

int fill_sst_slow_rates(idl_3d_data idl)
{
	static struct sst_spectra_struct sst;
	double time;
	int e,p,t,bin,c;
	int ne,np,nt,nb;
	int ok,cntr;
	static packet_selector pks;

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,S_RATE3_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],S_RATE3_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],S_RATE3_ID) ;
	}
	
	ok = get_next_sst_spectra_str(&pks,&sst);
	if(!ok)
		return(0);
	idl.options[1] = pks.index;
	idl.time[0] = sst.time;
	idl.time[1] = sst.integ_t;
	idl.time[2] = sst.mass;
	idl.time[3] = sst.geom_factor;
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 15;
	ne = idl.sizes[2] = 1;
	nb = idl.sizes[3] = 14;
	idl.pt_limits[0] = -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] = 90.;
	idl.pt_limits[3] = 180.;

	cntr = 0;
	for(t=0;t<nt;t++){
		for(p=0;p<np;p++){
			idl.ptmap[cntr++]= 0;
		}
	}

	cntr = 0;
	for(bin=0;bin<nb;bin++){
		for(e=0;e<ne;e++){
			idl.data[cntr] = sst.rates[bin];
			idl.nrgs[cntr]  = 1.;
			idl.dnrgs[cntr] = 1.;
			cntr++;
		}
		idl.dtheta[bin] = sst.dtheta[bin];
		idl.dphi[bin] = sst.dphi[bin];
		idl.geom[bin] = sst.geom[bin];
		idl.domega[bin] = sst.domega[bin];
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = 1.;
	
	return(1);
}


int fill_pl_data(idl_3d_data idl)
{
	pl_snap_55 snap;
	int ok;
	int e,p,t,b;
	int ne,np,nt,nb;
	int cntr,bin;
	double nrg,phi,theta,dnrg,dtheta,dphi;
	static packet_selector pks;
	
/*	snap.units_format = idl.options[1];  use default (counts) */

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,PLSNAP_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],PLSNAP_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],PLSNAP_ID) ;
	}
	
	ok = get_next_plsnap55_struct(&pks,&snap);
	if(! ok)
		return(0);

	idl.options[1] = pks.index;
	idl.time[0] = snap.time;
	idl.time[1] = snap.integ_t;
	idl.time[2] = snap.mass;
	idl.time[3] = snap.geom_factor;
	*idl.spin = snap.spin;
	np = idl.sizes[0] = 5;
	nt = idl.sizes[1] = 5;
	ne = idl.sizes[2] = 14;
	nb = idl.sizes[3] = 25;
	bin = cntr = 0;
	for(t=0;t<5;t++){
		for(p=0;p<5;p++){
			idl.geom[bin] = 1;
			idl.domega[bin] = snap.domega[t][p];
			theta = snap.theta[t][p][0];
			dtheta = snap.dtheta[t][p][0];
			dphi = snap.dphi[t][p][0];
			phi = snap.phi[t][p][0];
			idl.dtheta[bin] = dtheta;
			idl.dphi[bin] = dphi;
			idl.ptmap[bin] = bin;
			for(e=0;e<14;e++){
				idl.data[cntr] = snap.flux[t][p][e];
				idl.nrgs[cntr] = snap.nrg[t][p][e];
				idl.dnrgs[cntr] = snap.dnrg[t][p][e];
				idl.thetas[cntr] = theta;
				idl.phis[cntr] = phi;
				cntr++;
			}
			bin++;
		}
	}
	for(e=0;e<14;e++){
		idl.eff[e] = 1./64./16.;
	}
	
	return(ok);
}




int fill_plb_data(idl_3d_data idl)
{
	pl_snap_8x8 snap;
	int ok;
	int e,p,t,b;
	int ne,np,nt,nb;
	int cntr,bin;
	double nrg,phi,theta,dnrg,dtheta,dphi;
	static packet_selector pks;
	
	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(pks,pks.index+*idl.advance,P_SNAP_BST_ID) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(pks,idl.time[0],P_SNAP_BST_ID) ;
	}
	else {
	    SET_PKS_BY_INDEX(pks,idl.options[1],P_SNAP_BST_ID) ;
	}
	
	ok = get_next_plsnap88_struct(&pks,&snap);
	if(! ok)
		return(0);

	idl.options[1] = pks.index;
	idl.time[0] = snap.time;
	idl.time[1] = snap.integ_t;
	idl.time[2] = snap.mass;
	idl.time[3] = snap.geom_factor;
	*idl.spin = snap.spin;
	np = idl.sizes[0] = 8;
	nt = idl.sizes[1] = 8;
	ne = idl.sizes[2] = 14;
	nb = idl.sizes[3] = 64;
	bin = cntr = 0;
	for(t=0;t<8;t++){
		for(p=0;p<8;p++){
			idl.geom[bin] = 1;
			idl.domega[bin] = snap.domega[t][p];
			theta = snap.theta[t][p][0];
			dtheta = snap.dtheta[t][p][0];
			dphi = snap.dphi[t][p][0];
			phi = snap.phi[t][p][0];
			idl.dtheta[bin] = dtheta;
			idl.dphi[bin] = dphi;
			idl.ptmap[bin] = bin;
			for(e=0;e<14;e++){
				idl.data[cntr] = snap.flux[t][p][e];
				idl.nrgs[cntr] = snap.nrg[t][p][e];
				idl.dnrgs[cntr] = snap.dnrg[t][p][e];
				idl.thetas[cntr] = theta;
				idl.phis[cntr] = phi;
				cntr++;
			}
			bin++;
		}
	}
	for(e=0;e<14;e++){
		idl.eff[e] = 1./64./16.;
	}
	
	return(1);
}






int fill_esa_data(idl_3d_data idl)
{
	static data_map_3d map;
	packet_selector *pksp;
	static packet_selector pks_el;
	static packet_selector pks_eh;
	static packet_selector pks_ph;
	static packet_selector pks_plb;
	static packet_selector pks_ehs;
	static packet_selector pks_phb;
	static packet_selector pks_elc;
	int ok, exppk;
	int id;

	switch( idl.options[0] ){
	case 0:  /* EH */
	    pksp = &pks_eh;
	    id = E3D_UNK_ID;
	    exppk = 3;
	    break;
	case 1:  /* EL */
	    pksp = &pks_el;
	    id = E3D_88_ID;
	    exppk = 3;
	    break;
	case 2:  /* PH */
	    pksp = &pks_ph;
	    id = P3D_ID;
	    exppk = 4;
	    break;
	case 13: /* PLB */
	    pksp = &pks_plb;
	    id = E3D_BRST_ID;
	    exppk = 1;
	    break;
	case 14: /* EHS */ 
	    pksp = &pks_ehs;
	    id = FPC_P_ID;
	    exppk = 1;
	    break;
	case 15: /* PHB */
	    pksp = &pks_phb;
	    id = P3D_BRST_ID;
	    exppk = 2;
	    break;
	case 16: /* ELC */
	    pksp = &pks_elc;
	    id = E3D_CUT_ID;
	    exppk = 1;
	    break;
	default:
	    ok = 0;
	}

	if ( *idl.advance ) {
	    SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id) ;
	}
	else if (idl.options [1] < 0) {    /* negitive option[1] means get by time*/
	    SET_PKS_BY_TIME(*pksp,idl.time[0],id) ;
	}
	else {
	    SET_PKS_BY_INDEX(*pksp,idl.options[1],id) ;
	}

	ok = get_next_p3d(pksp, &map, exppk);

	make_ptmap(&map,idl);
	idl.time[0] = map.time;
	idl.time[1] = map.integ_t;
	idl.time[2] = map.mass;
	idl.time[3] = map.geom_factor;
	*idl.spin    = map.spin;
	idl.options[1] = pksp->index;
	return(ok);
}



static int tsect[32] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7,
                        8, 9,10,11,12,12,13,13,14,14,14,14,15,15,15,15};



int make_ptmap(data_map_3d *map,idl_3d_data idl)
{
 	int p,t,e;
	int np,nt,ne,nb;
	int ts,n,offset,b;
	int shift,ps;
	int cntr;
	double flux;
/*  Map stuff: */
	np = idl.sizes[0] = 32;
	nt = idl.sizes[1] = 32;
	ne = idl.sizes[2] = map->nenergies;
	nb = idl.sizes[3] = map->nbins;
	shift = map->shift;
	for(t=0;t<32;t++){
		ts = tsect[t];
		for(p=0;p<32;p++){
			b = map->ptmap[ts*32+p];
			ps = (p - map->p0) & 31;
			idl.ptmap[t*np+ps] = b;

/* #define MAKE_PTMAP_DEBUG*/
#if defined (MAKE_PTMAP_DEBUG)
			printf("t: %d, p: %d, ts: %d, ps: %d, idl.ptmap[%d]: %d\r\n",
			       t,p,ts,ps,t*np+ps,idl.ptmap[t*np+ps]);
#endif defined (MAKE_PTMAP_DEBUG)
		}
	}
	idl.pt_limits[0] =  -90.;
	idl.pt_limits[1] = -180.;
	idl.pt_limits[2] =   90.;
	idl.pt_limits[3] =  180.;

/* data and energy steps: */
	*idl.magel = map->magel;
	*idl.magaz = map->magaz;
	cntr =0;
	for(b=0;b<map->nbins;b++){
		idl.geom[b]   = map->bin[b].geom;
		idl.dtheta[b] = map->bin[b].dtheta;
		idl.dphi[b]   = map->bin[b].dphi;
		idl.domega[b] = map->bin[b].domega;
		offset = map->bin[b].offset;
		n = map->bin[b].ne;
		for(e=0;e<ne;e++){
			if(n==ne){  /* number e-steps == overall map e-steps */
				flux = map->data[offset+e];
			}
			else{      /* twice as many e-steps as overall map e-steps */
				flux =  map->data[offset+2*e];
				flux += map->data[offset+2*e+1];
			}
			idl.data[cntr] = flux;
			if(ne == 30){
				idl.nrgs[cntr] = map->nrg30[e];
				idl.dnrgs[cntr] = map->dnrg30[e];
			}
			else {
				idl.nrgs[cntr] = map->nrg15[e];
				idl.dnrgs[cntr] = map->dnrg15[e];
			}

			idl.thetas[cntr] = map->bin[b].theta;
			idl.phis[cntr]   = map->bin[b].phi[e];
			cntr++;
		}
	}
	for(e=0;e<ne;e++)
		idl.eff[e] = 1./32./16.;

	return(1);
}





int  get_emom_data(int argc,void *argv[])
{
	emom_fill_str mom;
	int n;
	if(argc == 0)
		return( number_of_emom_struct_samples( 0.,1e12) );
	if(argc != 9){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
	mom.num_samples = * (int4 *)argv[0];
	mom.time        =   (double *) argv[1];
	mom.dens        =   (float *) argv[2];
	mom.temp        =   (float *) argv[3];
	mom.Vx          =   (float *) argv[4];
	mom.Vy          =   (float *) argv[5];
	mom.Vz          =   (float *) argv[6];
	mom.Pe          =   (float *) argv[7];
	mom.Qe          =   (float *) argv[8];
	n = fill_emom_data(mom);

	return(n);
}




int  get_pmom_data(int argc,void *argv[])
{
	pmom_fill_str mom;
	int n;
	if(argc == 0)
		return( number_of_pmom_struct_samples( 0.,1e12) );
	if(argc != 15){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
	mom.num_samples = * (int4 *)argv[0];
	mom.time        =   (double *) argv[1];
	mom.dens_p      =   (float *) argv[2];
	mom.temp_p      =   (float *) argv[3];
	mom.Vpx         =   (float *) argv[4];
	mom.Vpy         =   (float *) argv[5];
	mom.Vpz         =   (float *) argv[6];
	mom.Pp          =   (float *) argv[7];
	mom.dens_a      =   (float *) argv[8];
	mom.temp_a      =   (float *) argv[9];
	mom.Vax         =   (float *) argv[10];
	mom.Vay         =   (float *) argv[11];
	mom.Vaz         =   (float *) argv[12];
	mom.Pa          =   (float *) argv[13];
        mom.Vc          =   (int2 *) argv[14];

	n = fill_pmom_data(mom);

	return(n);
}



int  get_hkp_data(int argc,void *argv[])
{
	hkp_fill_str ptr;
	int n;
	if(argc == 0)
		return( number_of_hkp_samples( 0.,1e12) );
	if(argc != 16){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
	ptr.num_samples = * (int4 *)argv[0];
	ptr.time        =   (double *) argv[1];
	ptr.magel       =   (float *) argv[2];
	ptr.magaz       =   (float *) argv[3];
	ptr.eesa_temp   =   (float *) argv[4];
	ptr.pesa_temp   =   (float *) argv[5];
	ptr.sst1_temp   =   (float *) argv[6];
	ptr.sst3_temp   =   (float *) argv[7];
	ptr.eesa_mcpl   =   (float *) argv[8];
	ptr.eesa_mcph	=   (float *) argv[9];
	ptr.pesa_mcpl	=   (float *) argv[10];
	ptr.pesa_mcph	=   (float *) argv[11];
	ptr.eesa_pmt	=   (float *) argv[12];
	ptr.pesa_pmt	=   (float *) argv[13];
	ptr.eesa_swp	=   (float *) argv[14];
	ptr.pesa_swp	=   (float *) argv[15];

	n = fill_hkp_data(ptr);

	return(n);
}



#if 0    /* OBSOLETE  */

int  get_eAtoD_data(int argc,void *argv[])
{
	eAtoD_fill_str ptr;
	int n;
	if(argc == 0)
		return( number_of_eAtoD_samples( 0.,1e12) );
	if(argc != 10){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}
	ptr.num_samples = * (int4 *)argv[0];
	ptr.time        =   (double *) argv[1];
	ptr.MCP_low     =   (float *) argv[2];
	ptr.MCP_high    =   (float *) argv[3];
	ptr.waves       =   (float *) argv[4];
	ptr.sweep_low   =   (float *) argv[5];
	ptr.sweep_high  =   (float *) argv[6];
	ptr.def_up      =   (float *) argv[7];
	ptr.def_down    =   (float *) argv[8];
	ptr.PMT         =   (float *) argv[9];

	n = fill_eAtoD_data(ptr);

	return(n);
}
#endif


/* IDL interface to time array get routine */

int get_time_array(int argc, void *argv[])
{
    /* argv's are: */
    /*   0: IDL_STRING packet ID */
    /*   1: long max number of elements in time array */
    /*   2: double * time array */

    /* get argvs locally */
    IDL_STRING *type = (IDL_STRING *) argv[0];
    long  * max_array = (long *) argv[1];
    double * time_array = (double *) argv[2];

    /* get data type */
    PACKET_ID pkid ;
    if ( !strcmp (type->s, "el") )
	pkid = E3D_88_ID ;
    else if ( !strcmp (type->s, "eh") )
	pkid = E3D_UNK_ID ;
    else if ( !strcmp (type->s, "pl") )
	pkid = PLSNAP_ID ;
    else if ( !strcmp (type->s, "ph") )
	pkid = P3D_ID ;
    else if ( !strcmp (type->s, "fpc") )
	pkid = FPC_D_ID ;
    else if ( !strcmp (type->s, "sf") )
	pkid = S_3D_F_ID ;
    else if ( !strcmp (type->s, "so") )
	pkid = S_3D_O_ID ;
    else if ( !strcmp (type->s, "fr") )
	pkid = S_3D_O_ID ;
    else if ( !strcmp (type->s, "sft") )
	pkid = S_T_DST_ID ;
    else if ( !strcmp (type->s, "sot") )
	pkid = S_T_DST_ID ;
    else if ( !strcmp (type->s, "fspc") )
	pkid = S_RATE3_ID ;
    else if ( !strcmp (type->s, "ospc") )
	pkid = S_RATE3_ID ;
    else if ( !strcmp (type->s, "tspc") )
	pkid = S_RATE3_ID ;
    else if ( !strcmp (type->s, "sr") )
	pkid = S_RATE3_ID ;
    else if ( !strcmp (type->s, "plb") )
	pkid = P_SNAP_BST_ID ;
    else if ( !strcmp (type->s, "elb") )
	pkid = E3D_BRST_ID;
    else if ( !strcmp (type->s, "ehs") )
	pkid = FPC_P_ID;
    else if ( !strcmp (type->s, "phb") )
	pkid = P3D_BRST_ID;
    else if ( !strcmp (type->s, "elc") )
	pkid = E3D_CUT_ID;
    else if ( !strcmp (type->s, "sob") )
	pkid = S_HS_BST_ID;
    else if ( !strcmp (type->s, "sfb") )
	pkid = S_HS_BST_ID;
    else
	{
	    fprintf(stderr, "get_time_array: unknown type\r\n");
	    return 0;
	}

    /* get the time array now */
    return get_time_points(pkid, *max_array, time_array) ;
}

#ifdef	__cplusplus
}    /* End extern C */
#endif







