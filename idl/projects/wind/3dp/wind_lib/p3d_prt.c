#include <sys/types.h>
#include "p3d_prt.h"

#include "p3d_dcm.h"
#include "map3d.h"
#include "windmisc.h"
#include "pckt_prt.h"

FILE *el3d_fp;
FILE *eh3d_fp;
FILE *ph3d_fp;

FILE *phb3d_raw_fp;
FILE *ph3d_raw_fp;
FILE *eh3d_raw_fp;
FILE *el3d_raw_fp;

FILE *ph3d_spec_fp;
FILE *eh3d_spec_fp;
FILE *el3d_spec_fp;

FILE *eh3d_bins_fp;
FILE *el3d_bins_fp;
FILE *ph3d_bins_fp;

FILE *eh3d_log_fp;
FILE *el3d_log_fp;
FILE *ph3d_log_fp;
FILE *phb3d_log_fp;

FILE *eh3d_cuts_fp;
FILE *el3d_cuts_fp;
FILE *ph3d_cuts_fp;

FILE *eh3d_omni_fp;
FILE *el3d_omni_fp;
FILE *ph3d_omni_fp;

FILE *el3d_accums_fp;
FILE *eh3d_accums_fp;
FILE *ph3d_accums_fp;

uchar el_blank[MAX3DBINS];
uchar eh_blank[MAX3DBINS];
uchar ph_blank[MAX3DBINS];
int flux_units;


/*#define DEBUG_BAD_MAP*/
#if defined ( DEBUG_BAD_MAP )

const MAX_DECOM_8_19 = 507904 ;

/* routine to print out a map if it's trashed */

int print_if_map_bad (data_map_3d *map )
{
    int a, e, s, offset = 0 ;
    boolean_t bad = B_FALSE ;

    /* check for bad elements in map-> data */
    
    for ( s = 0 ; s < map->nsamples ; s ++ )
	if ( map->data[s] < 0 || map->data[s] > MAX_DECOM_8_19 )
	    bad = B_TRUE ;

    /* if map bad, print it */
    
    if ( bad ) {
	for  ( a = 0 ; a < map->nbins ; a++ ) {
	    printf ("angle bin: %d\n", a) ;
	    for ( e = 0 ; e < map->bin[a].ne ; e ++ ) {
		char ast = ' ';
		if ( map->data[offset] < 0 || map->data[offset] > MAX_DECOM_8_19 )
		    ast = '*' ;
		printf("%7.1e%c%s",map->data[offset], ast, (e+1)%15 ? "": "\n" );
		offset ++ ;
	    }
	}
	return 1 ;
    }
    return 0 ;
}    

#else
#define print_if_map_bad(x) 0
#endif /* defined ( DEBUG_BAD_MAP ) */

int print_ph3d_packet(packet *pk)
{
	static data_map_3d map;

	if(ph3d_fp || ph3d_spec_fp || ph3d_bins_fp || ph3d_cuts_fp || ph3d_omni_fp
	    || ph3d_accums_fp){
		map.flux_units = flux_units;
		decom_map3d(pk,&map);
		if ( print_if_map_bad ( &map ))
		    printf ("in print_eh3d_packet\n");
		if(map.status==0){	
		    print_data_3d_gse(ph3d_fp,&map);
		    print_data_3d_bins(ph3d_bins_fp,&map);
		    print_data_3d_cuts(ph3d_cuts_fp,&map,ph_blank);
		    print_data_3d_omni(ph3d_omni_fp,&map,ph_blank);
		    print_data_3d_spectra(ph3d_spec_fp,&map);
		    print_data_3d_accums(ph3d_accums_fp,&map);
		}
	}
	if(ph3d_raw_fp || ph3d_log_fp){
		print_packet_header(ph3d_log_fp,pk);
		print_packet_header(ph3d_raw_fp,pk);
		print_packet_data(ph3d_raw_fp,pk,15,1);
	}
	return(0);

}


int print_phb3d_packet(packet *pk)
{
	static data_map_3d map;

/*	if(ph3d_fp || ph3d_spec_fp || ph3d_bins_fp || ph3d_cuts_fp || ph3d_omni_fp){
		map.flux_units = flux_units;
		decom_map3d(pk,&map);
		print_data_3d_gse(ph3d_fp,&map);
		print_data_3d_bins(ph3d_bins_fp,&map);
		print_data_3d_cuts(ph3d_cuts_fp,&map,ph_blank);
		print_data_3d_omni(ph3d_omni_fp,&map,ph_blank);
		print_data_3d_spectra(ph3d_spec_fp,&map);
	}*/
	if(phb3d_raw_fp || phb3d_log_fp){
		print_packet_header(phb3d_log_fp,pk);
/*		print_packet_header(phb3d_raw_fp,pk); */
		print_generic_packet(phb3d_raw_fp,pk,15);
	}
	return(0);

}


int print_el3d_packet(packet *pk)
{
	static data_map_3d map;

	if(el3d_fp || el3d_spec_fp || el3d_bins_fp 
                         || el3d_cuts_fp || el3d_omni_fp || el3d_accums_fp){
		map.flux_units = flux_units;
		decom_map3d(pk,&map);
		if ( print_if_map_bad ( &map ))
		    printf ("in print_eh3d_packet\n");
		if(map.status==0){	
			print_data_3d_gse(el3d_fp,&map);
			print_data_3d_bins(el3d_bins_fp,&map);
			print_data_3d_cuts(el3d_cuts_fp,&map,el_blank);
			print_data_3d_omni(el3d_omni_fp,&map,el_blank);
			print_data_3d_spectra(el3d_spec_fp,&map);
			print_data_3d_accums(el3d_accums_fp,&map);
		}
	}
	if(el3d_raw_fp || el3d_log_fp){
		print_packet_header(el3d_log_fp,pk);
		print_packet_header(el3d_raw_fp,pk);
/*		print_packet_data(el3d_raw_fp,pk,15,1); */
		print_generic_packet(el3d_raw_fp,pk,15);
	}
	return(0);

}

int print_elc3d_packet(packet *pk)
{
	static data_map_3d map;

	if(el3d_cuts_fp){
		map.flux_units = flux_units;
		decom_map3d(pk,&map);
		if(map.status==0){	
			print_data_3d_cuts(el3d_cuts_fp,&map,el_blank);
		}
	}
	return(0);

}

int print_eh3d_packet(packet *pk)
{
	static data_map_3d map;

	if(eh3d_fp || eh3d_spec_fp || eh3d_bins_fp || 
                           eh3d_cuts_fp || eh3d_omni_fp || eh3d_accums_fp){
		map.flux_units = flux_units;
		decom_map3d(pk,&map);
		if ( print_if_map_bad ( &map ))
		    printf ("in print_eh3d_packet\n");
		if(map.status==0){	
			print_data_3d_gse(eh3d_fp,&map);
			print_data_3d_bins(eh3d_bins_fp,&map);
			print_data_3d_cuts(eh3d_cuts_fp,&map,eh_blank);
			print_data_3d_omni(eh3d_omni_fp,&map,eh_blank);
			print_data_3d_spectra(eh3d_spec_fp,&map);
			print_data_3d_accums(eh3d_accums_fp,&map);
		}
	}
	if(eh3d_raw_fp || eh3d_log_fp){
		print_packet_header(eh3d_log_fp,pk);
		print_packet_header(eh3d_raw_fp,pk);
		print_packet_data(eh3d_raw_fp,pk,15,1);
	}
	return(0);

}



int print_data_3d_gse(FILE *fp,data_map_3d *Map)
{
	int e,p,t,b,ne,offset;
	float flux;

	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
	fprintf(fp,"%s\n",time_to_YMDHMS(Map->time));
	fprintf(fp,"`flux_units: %d\n",Map->flux_units);

	for(t=0;t<16;t++){
		fprintf(fp,"`");
		for(p=0;p<32;p++)
			fprintf(fp," %3d ",Map->ptmap[t*32+p]);
		fprintf(fp,"\n");
	}

	for(e=0;e<15;e++){
		fprintf(fp,"step %d: %.1f eV\n",e,Map->nrg15[e]);
		for(t=0;t<16;t++){
			for(p=0;p<32;p+=1){
				b = Map->ptmap[t*32+p];
				ne = Map->bin[b].ne;
				offset = Map->bin[b].offset;
				if(ne==15)
					flux = Map->data[offset+e];
				else if(ne==30){
					flux =  Map->data[offset+2*e];
					flux += Map->data[offset+2*e+1];
				}
				else
					flux = -1;
				flux;
				fprintf(fp," %4.0f",flux);
			}
			fprintf(fp,"\n");
		}
		fprintf(fp,"\n");
	}
	return(1);
}	



int print_data_3d_idl(FILE *fp,data_map_3d *Map)
{
	int e,p,t,b,ne,offset;
	float flux;

	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
/*	fprintf(fp,"%s\n",time_to_YMDHMS(Map->time)); */
/*	fprintf(fp,"`flux_units: %d\n",Map->flux_units); */

/*	for(t=0;t<16;t++){ */
/*		fprintf(fp,"`"); */
/*		for(p=0;p<32;p++) */
/*			fprintf(fp," %3d ",Map->ptmap[t*32+p]); */
/*		fprintf(fp,"\n"); */
/*	} */

	for(e=0;e<15;e++){
/*		fprintf(fp,"step %d: %.1f eV\n",e,Map->nrg15[e]); */
		for(t=0;t<16;t++){
			for(p=0;p<32;p+=1){
				b = Map->ptmap[t*32+p];
				ne = Map->bin[b].ne;
				offset = Map->bin[b].offset;
				if(ne==15)
					flux = Map->data[offset+e];
				else if(ne==30){
					flux =  Map->data[offset+2*e];
					flux += Map->data[offset+2*e+1];
				}
				else
					flux = -1;
				flux;
				fprintf(fp," %4.0f",flux);
			}
			fprintf(fp,"\n");
		}
		fprintf(fp,"\n");
	}
	return(1);
}	




int print_data_3d_bins(FILE *fp,data_map_3d *Map)
{
	int e,p,t,b,ne,offset;
	float total,val;

	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
	fprintf(fp,"%s",time_to_YMDHMS(Map->time));
	fprintf(fp,"  Units:%d ",Map->flux_units);
	fprintf(fp,"\n");
/*	fprintf(fp,"nsamples: %d\n",Map->nsamples); */
	fprintf(fp,"shift: %d\n",Map->shift);
	fprintf(fp,"Integration time: %f", Map->integ_t);
	fprintf(fp,"\n");
	for(b=0;b<Map->nbins;b++){
		ne = Map->bin[b].ne;
		offset = Map->bin[b].offset;
		total = 0;
		for(e=0;e<ne;e++){
			val = Map->data[offset+e];
			total += val;
		}

		fprintf(fp,"%3d ",b);
		fprintf(fp,"%4.1f ",Map->bin[b].geom);		
		fprintf(fp,"%6.0f ",total);		
		for(e=0;e<ne;e++){
			val = Map->data[offset+e];
			fprintf(fp," %5.0f",val);
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	return(1);
}	


int print_data_3d_cuts(FILE *fp,data_map_3d *Map,uchar *blank)
{
	int e,p,t,b,ne,offset;
	float total,val;
	double *nrg;

	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
	fprintf(fp,"define tm %s\n",time_to_YMDHMS(Map->time));
	fprintf(fp,"`  Units:%d ",Map->flux_units);
	fprintf(fp,"\n");
/*	fprintf(fp,"`nsamples: %d\n",Map->nsamples); */
	fprintf(fp,"`shift: %d\n",Map->shift);
	fprintf(fp,"`funits: %d\n",Map->flux_units);
	fprintf(fp,"`Integration time: %f", Map->integ_t);
	fprintf(fp,"\n");
	for(b=0;b<Map->nbins;b++){
		if(blank && (blank[b] & 1))
			continue;
		ne = Map->bin[b].ne;
		offset = Map->bin[b].offset;
		if(ne==15)
			nrg = Map->nrg15;
		else
			nrg = Map->nrg30;
		fprintf(fp,"set bin %3d\n",b);
/*		fprintf(fp,"`%4.1f ",Map->bin[b].geom);		 */
		for(e=0;e<ne;e++){
			fprintf(fp,"%5.1f ",nrg[e]);
			val = Map->data[offset+e];
			fprintf(fp," %f",val);
			fprintf(fp,"\n");
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	return(1);
}	


int print_data_3d_omni(FILE *fp,data_map_3d *Map,uchar *blank)
{
	spectra_3d_omni spec;
	int i;

	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
	fprintf(fp,"define tm %s\n",time_to_YMDHMS(Map->time));
	average_p3d_channels(Map,blank,&spec);
	for(i=0;i<15;i++){
		fprintf(fp,"%6.2f  ",(spec.nrg_min[i]+spec.nrg_max[i])/2);
		fprintf(fp,"%6.2f  ",spec.flux[i]);
		fprintf(fp,"\n");
	}
		
	
	fprintf(fp,"\n");
	return(1);			
}


int print_omni_spec(FILE *fp,spectra_3d_omni *spec)
{
	int i;

	if(fp==0)
		return(0);
	fprintf(fp,"%9.0f  ",spec->time);
	for(i=0;i<15;i++){
		fprintf(fp,"%6.1f  ",spec->flux[i]);
	}
	
	fprintf(fp,"\n");
	return(1);			
}


int print_data_3d_spectra(FILE *fp,data_map_3d *Map)
{
	int b,e,i,ne,offset;
	float spectra[15];
	if(fp==0)
		return(0);
	if(Map->status)
		return(0);
	for(e=0;e<15;e++)
		spectra[e] = 0;
	for(b=0;b<Map->nbins;b++){
		ne = Map->bin[b].ne;
		offset = Map->bin[b].offset;
		for(e=0;e<15;e++){
			spectra[e] += Map->data[offset++];
			if(ne==30)
				spectra[e]+= Map->data[offset++];
		}
	}	
	fprintf(fp,"%9.0f ",Map->time);
	for(e=0;e<15;e++)
		fprintf(fp," %4.0f",spectra[e]);
	fprintf(fp,"\n");
	return(1);			
}


/* used for accumulating by number of samples */

/*#define ACCUM_BY_NSAMPLES */
#if defined (ACCUM_BY_NSAMPLES)
const int N_TO_SUM_EL = 64 ;
const int N_TO_SUM_EH = 64 ;
const int N_TO_SUM_PH = 64 ;

#else
/* used for accumulating by a delta T */

extern double lt_sum_period;
#endif

typedef struct amel {
    double time ;
    double integT ;
    int4 numSamples ;
    int4 quality;
    float fill[3] ;  
    float counts [88][15] ;
} accMapEl ;

typedef struct ameh {
    double time ;
    double integT ;
    int4 numSamples ;
    int4 quality;
    float fill[3] ;  
    float counts [88][15] ;
} accMapEh ;

typedef struct amph {
    double time ;
    double integT ;
    int4 numSamples ;
    int4 quality;
    float fill[3] ;  
    float counts [121][15] ;
} accMapPh ;

/* note that this routine assumes all packets for map */
/* have been accumumlated. */

int print_data_3d_accums ( FILE *fp,data_map_3d *map ) 
{
    static initAccumsEl = 1 ;
    static initAccumsEh = 1 ;
    static initAccumsPh = 1 ;
    static accMapEl elAccMap ;
    static accMapEh ehAccMap ;
    static accMapPh phAccMap ;
    static double time0El = 0. ;
    static double time0Eh = 0. ;
    static double time0Ph = 0. ;
    int e,a ; 

    if ( fp == 0 ) 
	return ( 0 ) ;

    if ( print_if_map_bad ( map ) )
	printf("in print_data_3d_accums\n") ;

    /* output accums if number samples reached */

    switch  ( map->inst ) {
    case EESAL_INST:
#if defined ACCUM_BY_NSAMPLES
	if  ( elAccMap.numSamples >= N_TO_SUM_EL )  {
#else	    
	if(time0El && (map->time < time0El  || map->time > time0El+lt_sum_period)) {
	    if(elAccMap.numSamples && map->time >= time0El)
#endif
		fwrite ( &elAccMap, sizeof ( elAccMap ) , 1, fp ) ;
	    initAccumsEl = 1 ;
	}
	break ;
    case EESAH_INST:
#if defined ACCUM_BY_NSAMPLES
	if  ( ehAccMap.numSamples >= N_TO_SUM_EH )  {
#else	    
	if(time0Eh && (map->time < time0Eh  || map->time > time0Eh+lt_sum_period)) {
	    if(ehAccMap.numSamples && map->time >= time0Eh)
#endif
		fwrite ( &ehAccMap, sizeof ( ehAccMap ) , 1, fp ) ;
	    initAccumsEh = 1 ;
	}
	break ;
    case PESAH_INST:
#if defined ACCUM_BY_NSAMPLES
	if  ( phAccMap.numSamples >= N_TO_SUM_PH )  {
#else
	if(time0Ph && (map->time < time0Ph  || map->time > time0Ph+lt_sum_period)) {
	    if(phAccMap.numSamples && map->time >= time0Ph)
#endif
		fwrite ( &phAccMap, sizeof ( phAccMap ) , 1, fp ) ;
	    initAccumsPh = 1 ;
	}
	break ;
    default:
	return (0) ;
    }
	
    /* init accummulations */

    if  ( initAccumsEl )  {
	elAccMap.time = map->time ;
	elAccMap.integT = 0 ;
	elAccMap.numSamples = 0 ;
	for ( a = 0 ; a < 88 ; a++ ) 
	    for ( e = 0 ; e < 15 ; e++ ) 
		elAccMap.counts[a][e] = 0 ;
	elAccMap.quality = 1 ;
	time0El = map->time;
	initAccumsEl = 0 ;
    }
    if  ( initAccumsEh )  {
	ehAccMap.time = map->time ;
	ehAccMap.integT = 0 ;
	ehAccMap.numSamples = 0 ;
	for ( a = 0 ; a < 88 ; a++ ) 
	    for ( e = 0 ; e < 15 ; e++ ) 
		ehAccMap.counts[a][e] = 0 ;
	ehAccMap.quality = 1 ;
	time0Eh = map->time;
	initAccumsEh = 0 ;
    }
    if  ( initAccumsPh )  {
	phAccMap.time = map->time ;
	phAccMap.integT = 0 ;
	phAccMap.numSamples = 0 ;
	for ( a = 0 ; a < 121 ; a++ ) 
	    for ( e = 0 ; e < 15 ; e++ ) 
		phAccMap.counts[a][e] = 0 ;
	phAccMap.quality = 1 ;
	time0Ph = map->time;
	initAccumsPh = 0 ;
    }

    /* accumulate data sum */
    {
	int offset = 0 ;      /* into map->data, will step in order */
	int s ;

	for  ( a = 0 ; a < map->nbins ; a++ ) {
	    for ( e = 0 ; e < 15 ; e ++ ) {
		for ( s = 0 ; s < (map->bin[a].ne/15) ; s ++ ) {
		                   /* inner loop combines the 30 e bins -> 15 e bins */
/*#define DEBUG_BIN_OUT */
#if defined  ( DEBUG_BIN_OUT )
		    printf("a: %d, e: %d, s: %d, offset:%d, ne: %d\r\n",
			    a, e, s, offset, map->bin[b].ne);
#endif /* defined  ( DEBUG_BIN_OUT ) */

		    switch  ( map->inst ) {
		    case EESAL_INST:
			elAccMap.counts[a][e] += map->data[offset] ;
			break;
		    case EESAH_INST:
			ehAccMap.counts[a][e] += map->data[offset] ;
			break;
		    case PESAH_INST:
			phAccMap.counts[a][e] += map->data[offset] ;
			break;
		    }
		    offset ++ ;

		}           /* end of 30 -> 15 bin loop */
	    }           /* end of 15 energies loop */
	}           /* end of angle bin loop */
    }
    /* accumulate integration t and # packet */
    
    switch  ( map->inst ) {
    case EESAL_INST:
	elAccMap.integT += map->integ_t ;
	elAccMap.numSamples ++ ;
	break;
    case EESAH_INST:
	ehAccMap.integT += map->integ_t ;
	ehAccMap.numSamples ++ ;
	break;
    case PESAH_INST:
	phAccMap.integT += map->integ_t ;
	phAccMap.numSamples ++ ;
	break;
    }

#if defined  ( DEBUG_BIN_OUT )

    switch  ( map->inst ) {
    case EESAL_INST:
	printf ( "packet type: EESA LOW, nsumed: %d \n",elAccMap.numSamples ) ;
	for ( a = 0 ; a < 88 ; a++ ) {
	    printf ( "angle bin: %d\n", a);
	    for ( e = 0 ; e < 15 ; e++ ) 
		printf ( "%3.0f%s", elAccMap.counts[a][e],  ( e== ( 15-1 )  ) ?"\n":", " ) ;
	}
	break ;
    case EESAH_INST:
	printf ( "packet type EESA HIGH, nsumed: %d \n",ehAccMap.numSamples ) ;
	for ( a = 0 ; a < 88 ; a++ ) {
	    printf ( "angle bin: %d\n", a);
	    for ( e = 0 ; e < 15 ; e++ ) 
		printf ( "%3.0f%s", ehAccMap.counts[a][e],  ( e== ( 15-1 )  ) ?"\n":", " ) ;
	}
	break ;
    case PESAH_INST:
	printf ( "packet type PESA HIGH, nsumed: %d \n",phAccMap.numSamples ) ;
	for ( a = 0 ; a < 121 ; a++ ) {
	    printf ( "angle bin: %d\n", a);
	    for ( e = 0 ; e < 15 ; e++ ) 
		printf ( "%3.0f%s", phAccMap.counts[a][e],  ( e== ( 15-1 )  ) ?"\n":", " ) ;
	}
	break ;
    }

#endif /* defined DEBUG_BIN_OUT     */

    return ( 1 ) ;
}
