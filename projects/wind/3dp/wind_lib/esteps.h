#ifndef ESTEPS_H
#define ESTEPS_H

#if 0
#include "ecfg_dcm.h"
#include "pcfg_dcm.h"
#endif

#include "sweeps.h"

#include "winddefs.h"

#define DAC_TBL_SIZE_PH 120
#define DAC_TBL_SIZE_EH 120
#define DAC_TBL_SIZE_EL 120
#define DAC_TBL_SIZE_PL 232
#define OVERLAP 56

enum {
	DEFAULT_UNITS,
	RAW_UNITS,

	ENERGY_UNITS,
	VELOCITY_UNITS,

	ANGLE_UNITS,
	COS_ANG_UNITS,

	COUNTS_UNITS,
	NCOUNTS_UNITS,
	RATE_UNITS,
	EFLUX_UNITS,
	FLUX_UNITS,
	DISTF_UNITS
};

enum {
	MIDDLE,
	MAX,
	MIN,
	WIDTH
};


struct units_format_str {
	int nrg;
	int ang;
	int flx;
};
typedef struct units_format_str  units_format;

struct energy_step30_def {
	double temp;             /* temperature  */
	double mid[30];          /* middle energy */
	double wid[30];          /* energy 1/2 width */
	double upper[30];        /* upper limit */
	double lower[30];        /* lower limit */
	double unc[30];          /* Uncertainty in middle energy */
};
typedef struct energy_step30_def energy_step30;

struct energy_step15_def {
	double temp;             /* temperature  */
	double mid[15];          /* middle energy */
	double wid[15];          /* energy half width */
	double upper[15];        /* upper limit */
	double lower[15];        /* lower limit */
	double unc[15];          /* Uncertainty in middle energy */
};
typedef struct energy_step15_def energy_step15;

struct energy_steppl_def {    /* special case for pesa low  */
	double temp;              /* temperature  */
	double mid[DAC_TBL_SIZE_PL-3];          /* middle */
	double wid[DAC_TBL_SIZE_PL-3];          /* half width */
	double upper[DAC_TBL_SIZE_PL-3];        /* upper limit */
	double lower[DAC_TBL_SIZE_PL-3];        /* lower limit */
	double unc[DAC_TBL_SIZE_PL-3];          /* Uncertainty in middle */
};
typedef struct energy_steppl_def energy_steppl;




/*********** Function prototypes *************/


/***** This routine will initialize all the esa energy arrays  *****/

void init_estep30_array(energy_step30 *nrg30,uint2 *dactable,sweep_cal *cal);
void init_estep15_array(energy_step15 *nrg15,energy_step30 *nrg30);
void init_esteppl_array2(energy_steppl *plnrg,uint2 *dactable,sweep_cal *cal,
	uint2 bndry);





int convert_units(int n,double *nrg,float *counts,
                  double T,double dth,double geom,int flux_units);

#endif
