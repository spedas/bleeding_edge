#include "spec_dcm.h"
#include "windmisc.h"
#include "esteps.h"


FILE *elspec_fp;
FILE *ehspec_fp;
FILE *plspec_fp;
FILE *phspec_fp;
FILE *elspec_auto_fp;

int print_eesah_spectra(FILE *fp,packet *pk);
int print_eesal_spectra(FILE *fp,packet *pk);
int print_pesah_spectra(FILE *fp,packet *pk);
int print_pesal_spectra(FILE *fp,packet *pk);
int print_eesal_auto_step(FILE *fp, spectra_30 *spec);


int print_eesa_spectra(packet *pk)
{
	static spectra_30 elspec;

	if(ehspec_fp)
		print_eesah_spectra(ehspec_fp,pk);
	if(elspec_fp)
		print_eesal_spectra(elspec_fp,pk);
	if(elspec_auto_fp){
		extract_el_spectra(pk,&elspec);
		print_eesal_auto_step(elspec_auto_fp,&elspec);
	}
	return(1);
}

int print_pesa_spectra(packet *pk)
{
	if(phspec_fp)
		print_pesah_spectra(phspec_fp,pk);
	if(plspec_fp)
		print_pesal_spectra(plspec_fp,pk);
	return(1);
}



int print_eesah_spectra(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static uint lasttime;
	static spectra_30 spec;

	if(fp==0)
		return(0);
	n = 30;

/*	spec.fmt.nrg_units = ENERGY_UNITS; */
/*	spec.fmt.flux_units = COUNTS_UNITS; */
	extract_eh_spectra(pk,&spec);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n` min:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.min_nrg[i]);
		fprintf(fp,"\n");
		fprintf(fp,"` max:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.max_nrg[i]);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",spec.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",spec.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}


int print_eesal_auto_step(FILE *fp, spectra_30 *spec)
{
	int i,n;
	float total;
	uint step,gain;
	static uint2 laststep;

	if(fp==0)
		return(0);
	if(spec->auto_step == 0)
		return(0);
	n = 30;
	step = spec->auto_step & 0x0fff;
	gain = (spec->auto_step & 0x1000) ? 1 : 0;
	if(step < laststep)
		fprintf(fp,"\n");
	fprintf(fp," %5u ",step);
	total = 0.;
	for(i=0;i<n;i++){
		total += spec->flux[i];
/*		fprintf(fp," %3.0f",spec->flux[i]); */
	}
	fprintf(fp," %6.f ",total);
	fprintf(fp," %s ",time_to_YMDHMS(spec->time));
	fprintf(fp," %u ",gain);
	fprintf(fp," 0x%04x ",spec->spin);
	fprintf(fp,"  %9.f ",spec->time);
	fprintf(fp,"  (%9.f) ",spec->time+8*3600.-33.);
	if(spec->auto_step & 0x8000)
		fprintf(fp,"*");
	fprintf(fp,"\n");
	laststep = step;
	return(1);
}


int print_eesal_spectra(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static uint lasttime;
	static spectra_30 spec;

	if(fp==0)
		return(0);
	n = 30;

	spec.fmt.nrg_units = ENERGY_UNITS;
	spec.fmt.flux_units = COUNTS_UNITS;
	extract_el_spectra(pk,&spec);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n` min:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.min_nrg[i]);
		fprintf(fp,"\n");
		fprintf(fp,"` max:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.max_nrg[i]);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",spec.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",spec.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}



int print_pesah_spectra(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static uint lasttime;
	static spectra_30 spec;

	if(fp==0)
		return(0);
	n = 30;

	spec.fmt.nrg_units = ENERGY_UNITS;
	spec.fmt.flux_units = COUNTS_UNITS;
	extract_ph_spectra(pk,&spec);

	ptime = pk->spin;
	if(lasttime != ptime){
		fprintf(fp,"\n` min:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.min_nrg[i]);
		fprintf(fp,"\n");
		fprintf(fp,"` max:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.max_nrg[i]);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",spec.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",spec.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	return(1);
}



int print_pesal_spectra(FILE *fp, packet *pk)
{
	int i,n;
	uint ptime;
	static spectra_14 spec;
	static uint lasttime;
	static double last_step;

	if(fp==0)
		return(0);
	n = 14;

	spec.fmt.nrg_units = ENERGY_UNITS;
	spec.fmt.flux_units = COUNTS_UNITS;
	spec.fmt.type = SPECTRA_PL_SUM;
	extract_pl_spectra(pk,&spec);

	ptime = pk->spin;
	if(lasttime != ptime || last_step!= spec.min_nrg[0]){
		fprintf(fp,"\n` min:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.min_nrg[i]);
		fprintf(fp,"\n");
		fprintf(fp,"` max:   ");
		for(i=0;i<n;i++)
			fprintf(fp," %4.0f", spec.max_nrg[i]);
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.f ",spec.time);
	for(i=0;i<n;i++)
		fprintf(fp," %3.0f",spec.flux[i]);
	fprintf(fp,"\n");
	lasttime = ptime+1;
	last_step = spec.min_nrg[0];
	return(1);
}



