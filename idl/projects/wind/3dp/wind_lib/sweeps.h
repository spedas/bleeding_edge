#ifndef SWEEPS_H
#define SWEEPS_H

#include "winddefs.h"
#include "defs.h"

#include <stdio.h>

enum  { EH, EL, PH, PL, DF };   /* don't change the order */

struct sweep_calibration_def {
	int    inst_num;
	char   *inst_name;
	double temperature;
	double slope_high;
	double offset_high;
	double slope_low;
	double offset_low;
	double k_analyser;
/*	double geom_factor; */
	sweep_def sweep_par;
};
typedef struct sweep_calibration_def sweep_cal;

double dac_to_voltage(uint2 dac,sweep_cal *cal);
double dac_to_energy(uint2 dac,sweep_cal *cal);
int initialize_cal_coeff(int inst,double temp,sweep_cal *cal);
void print_dac_table(FILE *fp,sweep_cal *cal,uint2 *tbl,int n);
void compute_dac_table( sweep_def *par,uint2 *tbl,uint2 n);
double polynom3(double *coeff,double x);

uint4 lumult_lu_ui(uint4 l,uint2 ui);
  /* 32 x 16 bit multiply (unsigned)     returns:  Product/2^16  */



#endif
