#ifndef PH_DCM_H
#define PH_DCM_H

#include "winddefs.h"
#include "wind_pk.h"
#include "esteps.h"
#include "pesa_cfg.h"
#include "map_5.h"
#include "map_11b.h"
#include "map_8.h"
#include "map_0.h"
#include "map_22d.h"
#include "map3d.h"


typedef struct {  /* struct for get_ph_mapcode_idl() */
  int4   *options;
  double *time;
  int2   *advance;
  int4   *mapcode;   
  uint2  *idtype;
  uint2  *instseq;
} idl_ph_pk_data;

/*  WARNING  DO NOT CHANGE without changing get_ph?.pro  */
typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[97][15];
	float  dt[97][15];
	int2   valid;	
	int4   spin;
	uchar  shift;
        uint4  index;
	int4   mapcode;
	uchar  double_sweep;
        int2   nenergy;
        int2   nbins;
	uchar  bins[97][15];	
	int2   pt_map[32*24];
	float  flux[97][15];   /* counts,flux,   [t][p][e] */
        float  nrg[97][15];
        float  dnrg[97][15];
        float  phi[97][15];        
        float  dphi[97][15];
        float  theta[97][15];
        float  dtheta[97][15];
        float  bkgrate[97][15];
        float  dvolume[97][15];
        float  ddata[97][15];
	float  domega[97];     /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[97][15];
	float  mag[3];
	float  sc_pot;
}  idl_ph97;
typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[121][15];
	float  dt[121][15];
	int2   valid;	
	uint4  spin;
	uchar  shift;
        int4   index;
	int4   mapcode;
	uchar  double_sweep;
        int2   nenergy;
        int2   nbins;
	uchar  bins[121][15];
	int2   pt_map[32*24];
	float  flux[121][15];  /* counts,flux,   [t][p][e] */
        float  nrg[121][15];
        float  dnrg[121][15];
        float  phi[121][15];        
        float  dphi[121][15];
        float  theta[121][15];
        float  dtheta[121][15];
        float  bkgrate[121][15];
        float  dvolume[121][15];
        float  ddata[121][15];
	float  domega[121];    /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[121][15];
	float  mag[3];
	float  sc_pot;
}  idl_ph121;
typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[56][15];
	float  dt[56][15];
	int2   valid;	
	int4   spin;
	uchar  shift;
        uint4  index;
	int4   mapcode;
	uchar  double_sweep;
        int2   nenergy;
        int2   nbins;
	uchar  bins[56][15];	
	int2   pt_map[32*24];
	float  flux[56][15];   /* counts,flux,   [t][p][e] */
        float  nrg[56][15];
        float  dnrg[56][15];
        float  phi[56][15];        
        float  dphi[56][15];
        float  theta[56][15];
        float  dtheta[56][15];
        float  bkgrate[56][15];
        float  dvolume[56][15];
        float  ddata[56][15];
	float  domega[56];     /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[56][15];
	float  mag[3];
	float  sc_pot;
}  idl_ph56;
typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[65][15];
	float  dt[65][15];
	int2   valid;	
	int4   spin;
	uchar  shift;
        uint4  index;
	int4   mapcode;
	uchar  double_sweep;
        int2   nenergy;
        int2   nbins;
	uchar  bins[65][15];	
	int2   pt_map[32*24];
	float  flux[65][15];   /* counts,flux,   [t][p][e] */
        float  nrg[65][15];
        float  dnrg[65][15];
        float  phi[65][15];        
        float  dphi[65][15];
        float  theta[65][15];
        float  dtheta[65][15];
        float  bkgrate[65][15];
        float  dvolume[65][15];
        float  ddata[65][15];
	float  domega[65];     /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[65][15];
	float  mag[3];
	float  sc_pot;
}  idl_ph65;
typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[88][15];
	float  dt[88][15];
	int2   valid;	
	int4   spin;
	uchar  shift;
        uint4  index;
	int4   mapcode;
	uchar  double_sweep;
        int2   nenergy;
        int2   nbins;
	uchar  bins[88][15];	
	int2   pt_map[32*24];
	float  flux[88][15];   /* counts,flux,   [t][p][e] */
        float  nrg[88][15];
        float  dnrg[88][15];
        float  phi[88][15];        
        float  dphi[88][15];
        float  theta[88][15];
        float  dtheta[88][15];
        float  bkgrate[88][15];
        float  dvolume[88][15];
        float  ddata[88][15];
	float  domega[88];     /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[88][15];
	float  mag[3];
	float  sc_pot;
}  idl_ph88;
typedef struct {  /* ph 97 and 121 bin high res. structure */
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
	double time;           /* sample time */
        double end_time;
        double trange[2];
	double integ_t;        /* integration time typically 3 seconds */
	double delta_t;        /* time between samples */
	float  deadtime[5][30];
	float  dt[5][30];
	int2   valid;	
	int4   spin;
	uchar  shift;
        uint4  index;
	int4   mapcode;
        int2   nenergy;
        int2   nbins;
	uchar  bins[5][30];	
/*	int2   map[32*32];    map is removed because it contains elements
	                      outside of the bin range (5) */
	float  flux[5][30];   /* counts,flux,   [bin][energy] */
        float  nrg[5][30];
        float  dnrg[5][30];
        float  phi[5][30];        
        float  dphi[5][30];
        float  theta[5][30];
        float  dtheta[5][30];
	float  ddata[5][30];
	float  domega[5];     /* solid angle [t][p] */
        uint2  dac_code[30*4]; /* [DAC_TBL_SIZE_PH] */
        float  volts[30*4];
	double mass;
	double geom_factor;
	float  gf[5][30];
	float  mag[3];
	float  sc_pot;
}  idl_ph5;

int get_next_ph97_struct(packet_selector *pks, idl_ph97 *dat);
/*int number_of_ph97_samples(double t1,double t2);*/
int decom_ph97(packet *pk, idl_ph97 *dat);

int get_next_ph121_struct(packet_selector *pks, idl_ph121 *dat);
/*int number_of_ph121_samples(double t1,double t2);*/
int decom_ph121(packet *pk, idl_ph121 *dat);

int get_next_ph5_struct(packet_selector *pks, idl_ph5 *dat);
/*int number_of_ph5_samples(double t1,double t2);*/
int decom_ph5(packet *pk, idl_ph5 *dat);

#endif


