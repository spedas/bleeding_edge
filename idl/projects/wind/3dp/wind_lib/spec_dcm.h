#include "wind_pk.h"



	
enum spectra_t {      /*  ESA spectra data types  */
	SPECTRA_INVALID,
	SPECTRA_EH,
	SPECTRA_EL,
	SPECTRA_PH,
	SPECTRA_PL_1,
	SPECTRA_PL_2,
	SPECTRA_PL_SUM,
	SPECTRA_PL_DIF
};




typedef struct {
	int type;
	int nrg_units;
	int flux_units;
	int x_error;
	int y_error;
} spectra_format;

typedef struct {
   /*  INPUT:   */
	spectra_format fmt;  /* units etc. */
   /*  OUTPUT   */
	double time;
	double delta_t;        /* typically 3 or 6 seconds */
	double min_nrg[14];    /* limits */
	double max_nrg[14];    /* limits */
	double flux[14];
	int es;         /* value 0-176 specifying the sweep number */
} spectra_14;


typedef struct {
   /*  INPUT:   */
	spectra_format fmt;  /* units etc. */
   /*  OUTPUT:   */
	double time;
	double delta_t;        /* typically 3 or 6 seconds */
	double min_nrg[30];    /* limits */
	double max_nrg[30];    /* limits */
	double flux[30];   /* flux   */
	uint2  spin;
	uint2  auto_step;       /* auto_step number (if non-zero) */
} spectra_30;




/******* function prototypes:   ******/


/* Gets next spectra (for each analyzer) with a time greater   */
/* than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pesal_spectra(packet_selector *pks, spectra_14 *spec);
int get_next_pesah_spectra(packet_selector *pks, spectra_30 *spec);

/* Gets next EESA LOW spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesal_spectra(packet_selector *pks, spectra_30 *spec);

/* Gets next EESA HIGH spectra with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesah_spectra(packet_selector *pks, spectra_30 *spec);



/*  returns the number of pesa (low or high) spectra between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pesa_spectra_samples(double t1,double t2);


/*  returns the number of eesa (low or high) spectra between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_eesa_spectra_samples(double t1,double t2);


/******  function prototypes   These are not general use functions:  *****/


int extract_eh_spectra(packet *pk,spectra_30 *spec);
int extract_el_spectra(packet *pk,spectra_30 *spec);
int extract_ph_spectra(packet *pk,spectra_30 *spec);
int extract_pl_spectra(packet *pk,spectra_14 *spec);


/*  Printing routines from spec_prt.c */


int print_eesa_spectra(packet *pk);
int print_pesa_spectra(packet *pk);

/*int print_eesah_spectra(packet *pk); */
/*int print_eesal_spectra(packet *pk); */
/*int print_pesah_spectra(packet *pk); */
/*int print_pesal_spectra(packet *pk); */

