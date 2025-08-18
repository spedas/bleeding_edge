#ifndef ECFG_DCM_H
#define ECFG_DCM_H

#include "winddefs.h"
#include "wind_pk.h"




struct eesa_configuration_data        {
	double time1;   /* starting limit of validity */
	double time2;   /* ending   limit of validity */
	double e_temp;
	int  valid;
	uchar inst_config;
	uchar inst_mode;
	uint2  icfg_size;
	nvector esa_swp_high;
	nvector esa_swp_low;
	uchar    mcph;
	uchar    mcpl;
	uint2    min_swp_level;
	uint2    step_swp_level;
	uint2    step_time;
	sweep_def el_sweep;
	sweep_def eh_sweep;
	nvector cp_emom_add;    /* vector that computes on board moments */
};

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        double time;           /* sample time */
        int4   index;
        int2   valid;
        uchar  data[142];
} ecfg_data;

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        double time;           /* sample time */
        int4   index;
        int2   valid;
        uchar  data[264];
} excfg_data;

struct eesa_Xconfiguration_data {  
	double time1;   /* starting limit of validity */
	double time2;   /* ending   limit of validity */
	double e_temp;
	int  valid;

	uchar p_blank[32];         /* blanking array for pads and 3d  */

	uchar t_blank[40];         /* blanking array for pads and 3d  */

	uchar arc_cos_def1[17];     /* definition of arc_cos table */
	uchar arc_cos_def2[17];     /* definition of arc_cos table */

	uint4 eres[4];              /*  energy res codes */

	nvector map_proc[4];        
	uchar  eres_code[4];

	uint2  tmode_codes[6*8];

	uchar msc1format[6];
	uchar bsizeformat[6];
	uchar shftvarformat[6];
	uchar shftmskformat[6];
	int2  def_up_def[6];
	int2  def_dn_def[6];

	uint2    bph_offset;  /* rotation value for Bph  */
	uchar   bth_offset;  /*  typically 90 */
	schar   bth_mult;  /* for conversion from degrees to binary degrees  */
	uchar   misc_bits;
	schar   defl_up_offset;
	schar   defl_dn_offset;
	uchar   pad_shift;
	uchar   defl_b_shift;
	uchar   def_cal_strt;
	uchar   def_cal_step;
	uchar   def_cal_ehdac;
};
#define SCN_SIZE sizeof(struct eesa_Xconfiguration)

typedef struct eesa_configuration_data Econfig;
typedef struct eesa_Xconfiguration_data EXconfig;


extern uchar default_excfg_data[];
extern uchar default_ecfg_data[];

#define ECONFIG_SIZE 144
#define EXCONFIG_SIZE 422






/********** Function prototypes *********/



int decom_econfig(packet *pk,Econfig *vp); /*decomutates normal config packets*/
int decom_exconfig(packet *pk,EXconfig *vp); /* decoms extended config packets*/



#endif
