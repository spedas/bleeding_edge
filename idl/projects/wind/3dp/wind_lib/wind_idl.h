#ifndef WIND_IDL_H
#define WIND_IDL_H
/* This is a dummy file that is needed for the makefile utility.  It is never */
/* included in any source code */


#if 0
typedef struct {
	int2   *options;   /*  options[0] is the data type */
	double *time;      /*  time[0]=sample time;  time[1]=integration time */
	int2   *sizes;     /*  0: nphi;   1:ntheta;    2:nenergies;   3:nbins */
	int2   *ptmap;     /*  bin map   [ntheta][nphi]   */
	float  *pt_limits; /*  0: phimin,  1:phimax,   2:thetamin;   3:thetamax */
	float  *data;      /*  counts data     [nbins][nenergies] */
	float  *esteps;    /*  energy steps    [nbins][nenergies] */
	float  *geom;      /*  geometric factors  [nbins] */
	float  *thetas;    /*  theta values  [nbins][nenergies] */
	float  *phis;      /*  phi values  [nbins][nenergies] */
	float  *dtheta;    /* delta theta values  [nbins][nenergies] */
	float  *dphi;      /* delta phi values  [nbins][nenergies] */
	float  *domega;    /* solid angle [nbins] */
} idl_3d_data;
#endif


#endif
