//#include "rates_dcm.h"

//#include "esteps.h"
#include "windmisc.h"
//#include "eesa_cfg.h"
//#include "pesa_cfg.h"


typedef struct {
	double time;
	float delta_t;
	float flux[16];
}
rates_el;

typedef struct {
	double time;
	float delta_t;
	float flux[24];
}
rates_eh;


#if 0

/* Gets next Pesa LOW rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesal_rates(double time, rates_el *rate)
{
	pklist *pkl;
	packet *pk;

	pkl = packet_type_ptr(E_F_RATE_ID);
	if(pkl){
		pk = get_next_packet(time,pkl);
		if(pk){
			extract_pl_rates(pk,rate);
			return(1);
		}
		else
			return(0);
	}
	fprintf(stderr,"Decom error.  Invalid ID\n");
	return(0);
}




/* Gets next Pesa HIGH rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pesah_rates(double time, rates_30 *rate)
{
	pklist *pkl;
	packet *pk;

	pkl = packet_type_ptr(E_F_RATE_ID);
	if(pkl){
		pk = get_next_packet(time,pkl);
		if(pk){
			extract_ph_rates(pk,rate);
			return(1);
		}
		else
			return(0);
	}
	fprintf(stderr,"Decom error.  Invalid ID\n");
	return(0);
}


/*  returns the number of pesa (low or high) rates between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pesa_rates_samples(double t1,double t2)
{
	return(number_of_packets(PSPECT_ID,t1,t2));
}




/* Gets next EESA LOW rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesal_rates(double time, rates_30 *rate)
{
	pklist *pkl;
	packet *pk;

	pkl = packet_type_ptr(E_F_RATE_ID);
	if(pkl){
		pk = get_next_packet(time,pkl);
		if(pk){
			extract_el_rates(pk,rate);
			return(1);
		}
		else
			return(0);
	}
	fprintf(stderr,"Decom error.  Invalid ID\n");
	return(0);
}


/* Gets next EESA HIGH rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesah_rates(double time, rates_30 *rate)
{
	pklist *pkl;
	packet *pk;

	pkl = packet_type_ptr(E_F_RATE_ID);
	if(pkl){
		pk = get_next_packet(time,pkl);
		if(pk){
			extract_eh_rates(pk,rate);
			return(1);
		}
		else
			return(0);
	}
	fprintf(stderr,"Decom error.  Invalid ID\n");
	return(0);
}


/*  returns the number of eesa (low or high) rates between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_eesa_rates_samples(double t1,double t2)
{
	return(number_of_packets(E_F_RATE_ID,t1,t2));
}


#endif




extract_eh_rates(packet *pk,rates_eh *rate)
{
	int i;
	uchar *d;

	rate->time = pk->time;
	rate->delta_t = 3.;

	d = pk->data + 11+16;
	for(i=0;i<24;i++)
		rate->flux[i] = decomp19_8( *d++ );

	return(1);
}


extract_el_rates(packet *pk,rates_el *rate)
{
	int i;
	uchar *d;

	rate->time = pk->time;
	rate->delta_t = 3.;

	d = pk->data + 11;
	for(i=0;i<16;i++)
		rate->flux[i] = decomp19_8( *d++ );

	return(1);
}



#if 0
extract_ph_rates(packet *pk,rates_30 *rate)
{
	int i;
	rates_format *fmt;
	double nrglim[31];

	fmt = &rate->fmt;

	set_pesa_configuration(pk->time);
	rate->time = pk->time;
	rate->delta_t = 3.;

	get_nrg_limits_ph31(nrglim,ENERGY_UNITS);

	for(i=0;i<30;i++)
		rate->flux[i] = decomp19_8( pk->data[12+2*i] );

	convert_units(30,nrglim,NULL,rate->flux,NULL,1.,1.,fmt->flux_units);

	if(fmt->nrg_units == VELOCITY_UNITS)
		get_nrg_limits_ph31(nrglim,fmt->nrg_units);
	else
		fmt->nrg_units = ENERGY_UNITS;

	for(i=0;i<30;i++){
		rate->max_nrg[i] = nrglim[i];
		rate->min_nrg[i] = nrglim[i+1];
	}

	return(1);
}



extract_pl_rates(packet *pk,rates_14 *rate)
{
	int i;
	double z[30];
	rates_format *fmt;
	double nrglim[15];

	fmt = &rate->fmt;
	set_pesa_configuration(pk->time);

	rate->time = pk->time;
	rate->delta_t = 3.;

	for(i=0;i<30;i++)
		z[i] = decomp19_8( pk->data[11+2*i] );

	for(i=0;i<14;i++){
		switch(fmt->type){
		case SPECTRA_PL_1:
			rate->flux[i] = z[i];
			break;
		case SPECTRA_PL_2:
			rate->flux[i] = z[i+16];
			break;
		case SPECTRA_PL_DIF:
			rate->flux[i] = (z[i]-z[i+16]);
			break;
		case SPECTRA_PL_SUM:
		default:
			rate->flux[i] = (z[i]+z[i+16])/2.;
			break;
		}
	}

	rate->es = pk->instseq>>8;
	get_nrg_limits_pl15(nrglim,rate->es,ENERGY_UNITS);
	convert_units(14,nrglim,NULL,rate->flux,NULL,1.,1.,fmt->flux_units);
	if(fmt->nrg_units == VELOCITY_UNITS)
		get_nrg_limits_pl15(nrglim,fmt->nrg_units,rate->es);
	else
		fmt->nrg_units = ENERGY_UNITS;

	for(i=0;i<14;i++){
		rate->max_nrg[i] = nrglim[i];
		rate->min_nrg[i] = nrglim[i+1];
	}

	return(1);
}


#endif



FILE *elrate_fp;
FILE *ehrate_fp;
FILE *plrate_fp;
FILE *phrate_fp;

int print_eesah_rates(FILE *fp,packet *pk);
int print_eesal_rates(FILE *fp,packet *pk);
int print_pesah_rates(FILE *fp,packet *pk);
int print_pesal_rates(FILE *fp,packet *pk);


int print_eesa_rates(packet *pk)
{
	if(ehrate_fp)
		print_eesah_rates(ehrate_fp,pk);
	if(elrate_fp)
		print_eesal_rates(elrate_fp,pk);
	return(1);
}

int print_pesa_rates(packet *pk)
{
	if(phrate_fp)
		print_pesah_rates(phrate_fp,pk);
	if(plrate_fp)
		print_pesal_rates(plrate_fp,pk);
	return(1);
}



int print_eesah_rates(FILE *fp, packet *pk)
{
	int i,n;
	static uint lasttime;
	uint ptime;
	static rates_eh rate;

	if(fp==0)
		return(0);
	n = 24;

	extract_eh_rates(pk,&rate);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n`        ");
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",rate.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",rate.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}



int print_eesal_rates(FILE *fp, packet *pk)
{
	int i,n;
	static uint lasttime;
	uint ptime;
	static rates_eh rate;

	if(fp==0)
		return(0);
	n = 16;

	extract_eh_rates(pk,&rate);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n`        ");
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",rate.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",rate.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}


#if 0 
int print_pesah_rates(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static uint lasttime;
	static rates_30 rate;

	if(fp==0)
		return(0);
	n = 30;

	rate.fmt.nrg_units = ENERGY_UNITS;
	rate.fmt.flux_units = COUNTS_UNITS;
	extract_ph_rates(pk,&rate);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n`        ");
		for(i=0;i<n;i++)
			fprintf(fp," %3.0f",(rate.min_nrg[i]+rate.max_nrg[i])/2.);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",rate.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",rate.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}



int print_pesal_rates(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static rates_14 rate;
	static uint lasttime;
	static double last_step;

	if(fp==0)
		return(0);
	n = 14;

	rate.fmt.nrg_units = ENERGY_UNITS;
	rate.fmt.flux_units = COUNTS_UNITS;
	rate.fmt.type = SPECTRA_PL_SUM;
	extract_pl_rates(pk,&rate);

	ptime = pk->spin;
	if(lasttime != ptime || last_step!= rate.min_nrg[0]){
		fprintf(fp,"\n` (%3d)   ",rate.es);
		for(i=0;i<n;i++)
			fprintf(fp," %3.0f",(rate.min_nrg[i]+rate.max_nrg[i])/2.);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",rate.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",rate.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	last_step = rate.min_nrg[0];
	return(1);
}

#endif


