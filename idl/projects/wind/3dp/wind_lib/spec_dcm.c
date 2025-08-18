#include "spec_dcm.h"

#include "windmisc.h"
#include "eesa_cfg.h"
#include "pesa_cfg.h"






/* Gets next Pesa LOW spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pesal_spectra(packet_selector *pks, spectra_14 *spec)
{
    packet *pk;
    
    pk = get_packet(pks);
    return(extract_pl_spectra(pk,spec));
}




/* Gets next Pesa HIGH spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pesah_spectra(packet_selector *pks, spectra_30 *spec)
{
    packet * pk;
    
    pk = get_packet(pks);
    return(extract_ph_spectra(pk,spec));
}


/*  returns the number of pesa (low or high) spectra between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pesa_spectra_samples(double t1,double t2)
{
	return(number_of_packets(PSPECT_ID,t1,t2));
}




/* Gets next EESA LOW spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesal_spectra(packet_selector *pks, spectra_30 *spec)
{
    packet *pk;
    
    pk = get_packet(pks);
    return(extract_el_spectra(pk,spec));
}


/* Gets next EESA HIGH spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesah_spectra(packet_selector *pks, spectra_30 *spec)
{
    packet *pk;
    
    pk = get_packet(pks);
    return(extract_eh_spectra(pk,spec));
}


/*  returns the number of eesa (low or high) spectra between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_eesa_spectra_samples(double t1,double t2)
{
	return(number_of_packets(ESPECT_ID,t1,t2));
}








extract_eh_spectra(packet *pk,spectra_30 *spec)
{
	int i;
	spectra_format *fmt;
	ECFG  *ecfg;

	if(pk==NULL)
		return(0);

        if(pk->quality & (~pkquality)) {
                spec->time = pk->time;
                return(0);
        }

	ecfg = get_ECFG(pk->time);

	fmt = &spec->fmt;

	spec->time = pk->time;
	spec->delta_t = ecfg->spin_period;

	for(i=0;i<30;i++)
		spec->flux[i] = decomp19_8( pk->data[12+2*i] );

	get_esteps_eh(spec->min_nrg,30,MIN,ecfg);
	get_esteps_eh(spec->max_nrg,30,MAX,ecfg);

	fmt->nrg_units = ENERGY_UNITS;

	return(1);
}


#define AUTO_STEP_VECTOR 0xe43b

extract_el_spectra(packet *pk,spectra_30 *spec)
{
	int i;
	spectra_format *fmt;
	double nrglim[31];
	ECFG *ecfg;

	if(pk==NULL)
		return(0);

        if(pk->quality & (~pkquality)) {
                spec->time = pk->time;
                return(0);
        }

	fmt = &spec->fmt;

	ecfg = get_ECFG(pk->time);

	spec->time = pk->time;
	spec->spin = pk->spin;
	spec->delta_t = ecfg->spin_period;
	if(ecfg->norm_cfg.esa_swp_low == AUTO_STEP_VECTOR){
		i = (uint2)(pk->spin-1)%16;
		spec->auto_step = ecfg->norm_cfg.min_swp_level + i * ecfg->norm_cfg.step_swp_level;
	}
	else{
#if 0
		spec->auto_step = 0;
#else
		i = (uint2)(pk->spin-1)%16;
		spec->auto_step = (0x1060 + i * 2) | 0x8000;
#endif
	}

	get_esteps_el(spec->min_nrg,30,MIN,ecfg);
	get_esteps_el(spec->max_nrg,30,MAX,ecfg);
	fmt->nrg_units = ENERGY_UNITS;

	for(i=0;i<30;i++)
		spec->flux[i] = decomp19_8( pk->data[11+2*i] );

	return(1);
}




extract_ph_spectra(packet *pk,spectra_30 *spec)
{
	int i;
	spectra_format *fmt;
	PCFG *pcfg;

	if(pk==NULL)
		return(0);

        if(pk->quality & (~pkquality)) {
                spec->time = pk->time;
                return(0);
        }

	pcfg = get_PCFG(pk->time);

	fmt = &spec->fmt;

	spec->time = pk->time;
	spec->delta_t = pcfg->spin_period;

	for(i=0;i<30;i++)
		spec->flux[i] = decomp19_8( pk->data[12+2*i] );

	get_esteps_ph(spec->min_nrg,30,MIN,pcfg);
	get_esteps_ph(spec->max_nrg,30,MAX,pcfg);
	fmt->nrg_units = ENERGY_UNITS;

	return(1);
}



extract_pl_spectra(packet *pk,spectra_14 *spec)
{
	int i;
	double z[30];
	spectra_format *fmt;
	PCFG *pcfg;

	if(pk==NULL)
		return(0);
	
        if(pk->quality & (~pkquality)) {
                spec->time = pk->time;
                return(0);
        }

	pcfg = get_PCFG(pk->time);

	fmt = &spec->fmt;

	spec->time = pk->time;
	spec->delta_t = pcfg->spin_period;

	for(i=0;i<30;i++)
		z[i] = decomp19_8( pk->data[11+2*i] );

	for(i=0;i<14;i++){
		switch(fmt->type){
		case SPECTRA_PL_1:
			spec->flux[i] = z[i];
			break;
		case SPECTRA_PL_2:
			spec->flux[i] = z[i+16];
			break;
		case SPECTRA_PL_DIF:
			spec->flux[i] = (z[i]-z[i+16]);
			break;
		case SPECTRA_PL_SUM:
		default:
			spec->flux[i] = (z[i]+z[i+16])/2.;
			break;
		}
	}

	spec->es = pk->instseq>>8;
	get_esteps_pl14(spec->min_nrg,spec->es,MIN,pcfg);
	get_esteps_pl14(spec->max_nrg,spec->es,MAX,pcfg);
	fmt->nrg_units = ENERGY_UNITS;
	return(1);
}




