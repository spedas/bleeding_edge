#include "wind_pk.h"



	
enum rates_t {      /*  ESA rates data types  */
	RATES_INVALID,
	RATES_EH,
	RATES_EL,
	RATES_PH,
	RATES_PL_1,
	RATES_PL_2,
	RATES_PL_SUM,
	RATES_PL_DIF
};




typedef struct {
	int type;
	int nrg_units;
	int flux_units;
	int x_error;
	int y_error;
} rates_format;

typedef struct {
   /*  INPUT:   */
	rates_format fmt;  /* units etc. */
   /*  OUTPUT   */
	double time;
	double delta_t;        /* typically 3 or 6 seconds */
	double min_nrg[14];    /* limits */
	double max_nrg[14];    /* limits */
	double flux[14];
	int es;         /* value 0-176 specifying the sweep number */
} rates_14;


typedef struct {
   /*  INPUT:   */
	rates_format fmt;  /* units etc. */
   /*  OUTPUT:   */
	double time;
	double delta_t;        /* typically 3 or 6 seconds */
	double min_nrg[30];    /* limits */
	double max_nrg[30];    /* limits */
	double flux[30];   /* flux   */
} rates_30;




/******* function prototypes:   ******/


/* Gets next rates (for each analyzer) with a time greater   */
/* than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pesal_rates(double time, rates_14 *spec);
int get_next_pesah_rates(double time, rates_30 *spec);

/* Gets next EESA LOW rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesal_rates(double time, rates_30 *spec);

/* Gets next EESA HIGH rates with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_eesah_rates(double time, rates_30 *spec);



/*  returns the number of pesa (low or high) rates between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pesa_rates_samples(double t1,double t2);


/*  returns the number of eesa (low or high) rates between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_eesa_rates_samples(double t1,double t2);


/******  function prototypes   These are not general use functions:  *****/


extract_eh_rates(packet *pk,rates_30 *spec);
extract_el_rates(packet *pk,rates_30 *spec);
extract_ph_rates(packet *pk,rates_30 *spec);
extract_pl_rates(packet *pk,rates_14 *spec);


/*  Printing routines from spec_prt.c */


int print_eesa_rates(packet *pk);
int print_pesa_rates(packet *pk);

int print_eesah_rates(packet *pk);
int print_eesal_rates(packet *pk);
int print_pesah_rates(packet *pk);
int print_pesal_rates(packet *pk);

