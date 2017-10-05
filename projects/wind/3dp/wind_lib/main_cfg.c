


#include "main_cfg.h"
#include "wind_pk.h"

#include <string.h>  /* for memcmp */


int initialize_main_open(MCFG *cfg);
int initialize_main_foil(MCFG *cfg);
int initialize_main_thick(MCFG *cfg);


#define  GEOM_OPEN  .3
#define  GEOM_FOIL  .3


MCFG *get_MCFG(double time)
{
	static MCFG Mcfg;        
	static uchar  last_data[MCONFIG_SIZE];   
	static packet *pk;
	static int series;
	static int different =1;
	static packet_selector pks;
	Mconfig old_cfg;

	SET_PKS_BY_LASTT(pks, time,M_CFG_ID);

	Mcfg.time = time;

	Mcfg.spin_period = SPIN_PERIOD;   /* default; this must be made more dynamic */
	Mcfg.temperature1_2 = 10.;   /* default */
	Mcfg.temperature3   = 10.;   /* default */
/*
	Mcfg.open_geom = GEOM_OPEN;
	Mcfg.foil_geom = GEOM_FOIL;
*/
	pk = get_packet(&pks);

	if(pk && !(pk->quality & (~pkquality)))
		different = memcmp(last_data,pk->data,MCONFIG_SIZE);
	if(different){
		old_cfg = Mcfg.norm_cfg;
		decom_mconfig(pk,&Mcfg.norm_cfg);
		if(Mcfg.norm_cfg.valid == 1){
			if(pk && !(pk->quality & (~pkquality)))
				memcpy(last_data,pk->data,MCONFIG_SIZE);
			initialize_main_foil(&Mcfg);
			initialize_main_open(&Mcfg);
			initialize_main_thick(&Mcfg);
			different = 0;
			Mcfg.valid++;
		}
		else
			Mcfg.norm_cfg = old_cfg;
	}


	return(&Mcfg);
}


static float rnergs_3d_F_min[6][14];
static float rnergs_3d_F_max[6][14];
static float rnergs_3d_F_eff[6][7];

static float rnergs_spect_F_min[6][32];
static float rnergs_spect_F_max[6][32];
static float rnergs_spect_F_eff[6][16];



initialize_main_foil(MCFG *cfg)

{

	int i,j,d;

      static float f_threshold_slope[6]   =  {1.285,1.591,1.291,1.447,1.334,1.565};
      static float f_threshold_offset[6]  =  {7.51,9.92,7.057,6.914,6.491,8.61};

      static float f_adc_slope[6]  = {3.0622,3.0791,2.9867,3.0896,2.9774,3.0180};
      static float f_adc_offset[6] = {-.15,6.93,3.38,1.53,.63,8.14};

      static int f5_3dbin_lut[8][7] = 
	 {8,15,26,44,75,128,208,
          3,6,9,12,13,14,15,
          20,29,38,47,50,53,56,
          59,68,77,86,89,92,95,
          98,107,116,125,128,131,134,
          137,146,155,164,167,170,173,
          176,185,194,203,206,209,212,
          218,227,236,245,248,251,254};
/*
      static int f1_3dbin_lut[8][7] =   f5_3dbin_lut[8][7];  
      static int f4_3dbin_lut[8][7] =   f5_3dbin_lut[8][7];
*/
      static int f3_3dbin_lut[8][7] = 
	 {7,14,25,43,75,128,208,
          2,5,8,11,13,14,15,
          17,26,35,44,50,53,56,
          56,65,74,83,89,92,95,
          95,104,113,122,128,131,134,
          134,143,152,161,167,170,173,
          173,182,191,200,206,209,212,
          215,224,233,242,248,251,254};

      static int f6_3dbin_lut[8][7] = 
	 {6,13,24,42,75,128,208,
          1,4,7,10,13,14,15,
          14,23,32,41,50,53,56,
          53,62,71,80,89,92,95,
          92,101,110,119,128,131,134,
          131,140,149,158,167,170,173,
          170,179,188,197,206,209,212,
          212,221,230,239,248,251,254};
/*
      static int f2_3dbin_lut[8][7] =   f6_3dbin_lut[8][7];
*/
      static int f_adc_lut[8][16] = 
	 {6,7,8,13,14,15,24,25,26,42,43,44,75,128,208,9999,
          1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,9999,
          14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,9999,
          53,56,59,62,65,68,71,74,77,80,83,86,89,92,95,9999,
          92,95,98,101,104,107,110,113,116,119,122,125,128,131,134,9999,
          131,134,137,140,143,146,149,152,155,158,161,164,167,170,173,9999,
          170,173,176,179,182,185,188,191,194,197,200,203,206,209,212,9999,
          212,215,218,221,224,227,230,233,236,239,242,245,248,251,254,9999};

	static float f_coeff[2][5] = {.226,1.415e-2,-1.45e-4,6.266e-7,-9.55e-10,
				      1.755,-4.715e-3,3.15e-6};	

	Mconfig c;
	c = cfg->norm_cfg;

	rnergs_3d_F_min[0][0] = (float)c.sst_thrf1 * f_threshold_slope[0] + f_threshold_offset[0];
	rnergs_3d_F_min[1][0] = (float)c.sst_thrf2 * f_threshold_slope[1] + f_threshold_offset[1];
	rnergs_3d_F_min[2][0] = (float)c.sst_thrf3 * f_threshold_slope[2] + f_threshold_offset[2];
	rnergs_3d_F_min[3][0] = (float)c.sst_thrf4 * f_threshold_slope[3] + f_threshold_offset[3];
	rnergs_3d_F_min[4][0] = (float)c.sst_thrf5 * f_threshold_slope[4] + f_threshold_offset[4];
	rnergs_3d_F_min[5][0] = (float)c.sst_thrf6 * f_threshold_slope[5] + f_threshold_offset[5];

	j = c.sst_f_lut;

		for (i=1;i<7;i++) {
	rnergs_3d_F_min[0][i] = f5_3dbin_lut[j][i-1] * f_adc_slope[0] + f_adc_offset[0];
	rnergs_3d_F_min[1][i] = f6_3dbin_lut[j][i-1] * f_adc_slope[1] + f_adc_offset[1];
	rnergs_3d_F_min[2][i] = f3_3dbin_lut[j][i-1] * f_adc_slope[2] + f_adc_offset[2];
	rnergs_3d_F_min[3][i] = f5_3dbin_lut[j][i-1] * f_adc_slope[3] + f_adc_offset[3];
	rnergs_3d_F_min[4][i] = f5_3dbin_lut[j][i-1] * f_adc_slope[4] + f_adc_offset[4];
	rnergs_3d_F_min[5][i] = f6_3dbin_lut[j][i-1] * f_adc_slope[5] + f_adc_offset[5];
	}
		for (i=0;i<7;i++) {
	rnergs_3d_F_max[0][i] = f5_3dbin_lut[j][i] * f_adc_slope[0] + f_adc_offset[0];
	rnergs_3d_F_max[1][i] = f6_3dbin_lut[j][i] * f_adc_slope[1] + f_adc_offset[1];
	rnergs_3d_F_max[2][i] = f3_3dbin_lut[j][i] * f_adc_slope[2] + f_adc_offset[2];
	rnergs_3d_F_max[3][i] = f5_3dbin_lut[j][i] * f_adc_slope[3] + f_adc_offset[3];
	rnergs_3d_F_max[4][i] = f5_3dbin_lut[j][i] * f_adc_slope[4] + f_adc_offset[4];
	rnergs_3d_F_max[5][i] = f6_3dbin_lut[j][i] * f_adc_slope[5] + f_adc_offset[5];
		}


	for (i=0;i<6;i++) 
	rnergs_spect_F_min[i][0] = rnergs_3d_F_min[i][0];

	for (d=0;d<6;d++)  {
		for (i=1;i<16;i++) {
	rnergs_spect_F_min[d][i] = f_adc_lut[j][i-1] * f_adc_slope[d] + f_adc_offset[d];
		}
	}
	for (d=0;d<6;d++)  {
		for (i=0;i<16;i++) {
	rnergs_spect_F_max[d][i] = f_adc_lut[j][i]   * f_adc_slope[d] + f_adc_offset[d];
		}
	}
	if (j==0)	{
	for (d=0;d<6;d++)  {
		for (i=7;i<14;i++) {
	rnergs_3d_F_min[d][i] = F_electronic_to_electron_energy (rnergs_3d_F_min[d][i-7]);
	rnergs_3d_F_max[d][i] = F_electronic_to_electron_energy (rnergs_3d_F_max[d][i-7]);
		}
	}
	for (d=0;d<6;d++)  {
		for (i=0;i<7;i++) {
	if (rnergs_3d_F_min[d][i] < (float) 250.)
	rnergs_3d_F_eff[d][i] =  polynom5(&f_coeff[0][0],rnergs_3d_F_min[d][i+7]);
	if (rnergs_3d_F_min[d][i] > (float) 250.)
	rnergs_3d_F_eff[d][i] =  polynom5(&f_coeff[1][0],rnergs_3d_F_min[d][i+7]);
		}
	}
	for (d=0;d<6;d++)  {
		for (i=16;i<32;i++) {
	rnergs_spect_F_min[d][i] = F_electronic_to_electron_energy (rnergs_spect_F_min[d][i-16]);
	rnergs_spect_F_max[d][i] = F_electronic_to_electron_energy (rnergs_spect_F_max[d][i-16]);
		}
	}
	for (d=0;d<6;d++)  {
		for (i=0;i<16;i++) {
	if (rnergs_spect_F_min[d][i] < (float) 250.)
	rnergs_spect_F_eff[d][i] =  polynom5(&f_coeff[0][0],rnergs_spect_F_min[d][i+16]);
	if (rnergs_spect_F_min[d][i] > (float) 250.)
	rnergs_spect_F_eff[d][i] =  polynom5(&f_coeff[1][0],rnergs_spect_F_min[d][i+16]);
		}
	}
	}
	else	{
	for (d=0;d<6;d++)  {
		for (i=7;i<14;i++) {
	rnergs_3d_F_min[d][i] = rnergs_3d_F_min[d][i-7];
	rnergs_3d_F_max[d][i] = rnergs_3d_F_max[d][i-7];
		}
	}
	for (d=0;d<6;d++)  {
		for (i=16;i<32;i++) {
	rnergs_spect_F_min[d][i] = rnergs_spect_F_min[d][i-16];
	rnergs_spect_F_max[d][i] = rnergs_spect_F_max[d][i-16];
		}
	}
	}
	return(1);
}


static float rnergs_3d_O_min[6][18];
static float rnergs_3d_O_max[6][18];

static float rnergs_spect_O_min[6][48];
static float rnergs_spect_O_max[6][48];


initialize_main_open(MCFG *cfg)

{
	int i,j,d;


      static float o_threshold_slope[6]  =  {1.228,1.303,1.353,1.364,1.350,1.234};
      static float o_threshold_offset[6] =  {7.388,6.498,7.168,7.599,6.760,6.960};

      static float o_adc_slope[6]  = {27.753,27.289,27.43,27.484,27.732,27.436};
      static float o_adc_offset[6] = {26.57,34.60,28.80,26.5,29.90,28.3};

	static int o_3dbin_min_lut[8][9] = {0,2,4,7,14,23,48,100,232};
	static int o_3dbin_max_lut[8][9] = {2,4,7,14,23,48,100,220,256};

	 int o_adc_lut[8][24] =
	 {1,2,3,4,5,7,9,11,14,18,23,29,
	  38,48,61,78,100,128,163,208,220,232,244,999};


	Mconfig c;
	c = cfg->norm_cfg;

	for (i=0;i<24;i++)
	{ o_adc_lut[1][i] = i+1;
	  o_adc_lut[3][i] = 58+i*2;
	  o_adc_lut[2][i] = 20+i*2;
	  o_adc_lut[4][i] = 96+i*2;
	  o_adc_lut[5][i] = 134+i*2;
	  o_adc_lut[6][i] = 172+i*2;
	  o_adc_lut[7][i] = 210+i*2;}
	for (j=0;j<8;j++)	 {
	  o_adc_lut[j][23] = 9999;}

	rnergs_3d_O_min[0][0] = (float)c.sst_thro1 * o_threshold_slope[0] + o_threshold_offset[0];
	rnergs_3d_O_min[1][0] = (float)c.sst_thro2 * o_threshold_slope[1] + o_threshold_offset[1];
	rnergs_3d_O_min[2][0] = (float)c.sst_thro3 * o_threshold_slope[2] + o_threshold_offset[2];
	rnergs_3d_O_min[3][0] = (float)c.sst_thro4 * o_threshold_slope[3] + o_threshold_offset[3];
	rnergs_3d_O_min[4][0] = (float)c.sst_thro5 * o_threshold_slope[4] + o_threshold_offset[4];
	rnergs_3d_O_min[5][0] = (float)c.sst_thro6 * o_threshold_slope[5] + o_threshold_offset[5];

	for (i=0;i<6;i++) 
	rnergs_spect_O_min[i][0] = rnergs_3d_O_min[i][0];

	j = c.sst_o_lut;

	for (d=0;d<6;d++) {
		for (i=1;i<9;i++) {
	rnergs_3d_O_min[d][i] = o_3dbin_min_lut[j][i] * o_adc_slope[d] + o_adc_offset[d];
		}
		for (i=0;i<9;i++) {
	rnergs_3d_O_max[d][i] = o_3dbin_max_lut[j][i] * o_adc_slope[d] + o_adc_offset[d];
		}
		for (i=1;i<24;i++) {
	rnergs_spect_O_min[d][i] = o_adc_lut[j][i-1] * o_adc_slope[d] + o_adc_offset[d];
		}
		for (i=0;i<24;i++) {
	rnergs_spect_O_max[d][i] = o_adc_lut[j][i]   * o_adc_slope[d] + o_adc_offset[d];
		}
	}
	if (j==0)	{
		for (i=9;i<18;i++) {
	rnergs_3d_O_min[0][i] = O1_electronic_to_proton_energy (rnergs_3d_O_min[0][i-9]);
	rnergs_3d_O_max[0][i] = O1_electronic_to_proton_energy (rnergs_3d_O_max[0][i-9]);
		}
		for (i=24;i<48;i++) {
	rnergs_spect_O_min[0][i] = O1_electronic_to_proton_energy (rnergs_spect_O_min[0][i-24]);
	rnergs_spect_O_max[0][i] = O1_electronic_to_proton_energy (rnergs_spect_O_max[0][i-24]);
		}
	for (d=1;d<6;d++)  {
		for (i=9;i<18;i++) {
	rnergs_3d_O_min[d][i] = O_electronic_to_proton_energy (rnergs_3d_O_min[d][i-9]);
	rnergs_3d_O_max[d][i] = O_electronic_to_proton_energy (rnergs_3d_O_max[d][i-9]);
		}
	}
	for (d=1;d<6;d++)  {
		for (i=24;i<48;i++) {
	rnergs_spect_O_min[d][i] = O_electronic_to_proton_energy (rnergs_spect_O_min[d][i-24]);
	rnergs_spect_O_max[d][i] = O_electronic_to_proton_energy (rnergs_spect_O_max[d][i-24]);
		}
	}
	}
	else	{
	for (d=0;d<6;d++)  {
		for (i=9;i<18;i++) {
	rnergs_3d_O_min[d][i] = rnergs_3d_O_min[d][i-9];
	rnergs_3d_O_max[d][i] = rnergs_3d_O_max[d][i-9];
		}
	}
	for (d=0;d<6;d++)  {
		for (i=24;i<48;i++) {
	rnergs_spect_O_min[d][i] = rnergs_spect_O_min[d][i-24];
	rnergs_spect_O_max[d][i] = rnergs_spect_O_max[d][i-24];
		}
	}
	}
	return(1);
}

static float rnergs_3d_FT_min[2][7];
static float rnergs_3d_FT_max[2][7];
static float rnergs_3d_FT_eff[2][7];
static float rnergs_spect_FT_min[2][24];
static float rnergs_spect_FT_max[2][24];
static float rnergs_spect_FT_eff[2][24];

static float rnergs_3d_OT_min[2][9];
static float rnergs_3d_OT_max[2][9];
static float rnergs_spect_OT_min[2][24];
static float rnergs_spect_OT_max[2][24];

static float rnergs_spect_T_min[2][24];
static float rnergs_spect_T_max[2][24];


initialize_main_thick(MCFG *cfg)
{
	int i,j,d;

      static float t_threshold_slope[2]  =  {1.442,1.467};
      static float t_threshold_offset[2]  =  {8.868,7.175};

      static float t_adc_slope[6] = {7.937,8.0806,47.538,48.71,38.211,38.844};
      static float t_adc_offset[6] = {33.4,33.68,69.32,43.3,27.6,30.};

      static int ft_3dbin_min_lut[8][7] = 
         {36,48,60,78,102,125,166};

      static int ft_3dbin_max_lut[8][7] = 
         {48,60,78,102,125,166,220};

      static int ot_3dbin_min_lut[8][9] = 
         {6,8,10,13,17,21,125,166,229};

      static int ot_3dbin_max_lut[8][9] = 
         {8,10,13,17,21,36,166,220,256};

	static float ft_coeff[2][5] = {3.49818,-3.980e-2,1.54e-4,-2.356e-7,1.266e-10,
				       2.53851,-4.86291e-3,3.14568e-6,-6.82919e-10};	
	 int o_adc_lut[8][24] =
	 {1,2,3,4,5,7,9,11,14,18,23,29,
	  38,48,61,78,100,128,163,208,220,232,244,999};


       int t_adc_lut[8][24] = 
         {6,8,10,13,17,21,36,42,48,54,60,69,78,90,102,113,
          125,144,166,191,220,229,237,999};
	Mconfig c;
	c = cfg->norm_cfg;

	for (i=0;i<24;i++)
	{ o_adc_lut[1][i] = i+1;
	  o_adc_lut[3][i] = 58+i*2;
	  o_adc_lut[2][i] = 20+i*2;
	  o_adc_lut[4][i] = 96+i*2;
	  o_adc_lut[5][i] = 134+i*2;
	  o_adc_lut[6][i] = 172+i*2;
	  o_adc_lut[7][i] = 210+i*2;}
	for (j=0;j<8;j++)	 {
	  o_adc_lut[j][23] = 9999;}
	for (j=1;j<8;j++){
		for (i=0;i<24;i++){ 
	    t_adc_lut[j][i] = o_adc_lut[j][i];}}


	rnergs_spect_FT_min[0][0] = (float)c.sst_thrt2 * t_threshold_slope[0] + t_threshold_offset[0];
	rnergs_spect_FT_min[0][0] = rnergs_spect_FT_min[0][0] + rnergs_spect_F_min[1][0]; 
	rnergs_spect_FT_min[1][0] = (float)c.sst_thrt6 * t_threshold_slope[1] + t_threshold_offset[1];
	rnergs_spect_FT_min[1][0] = rnergs_spect_FT_min[1][0] + rnergs_spect_F_min[5][0]; 

	rnergs_spect_OT_min[0][0] = (float)c.sst_thrt2 * t_threshold_slope[0] + t_threshold_offset[0];
	rnergs_spect_OT_min[0][0] = rnergs_spect_OT_min[0][0] + rnergs_spect_O_min[1][0]; 
	rnergs_spect_OT_min[1][0] = (float)c.sst_thrt6 * t_threshold_slope[1] + t_threshold_offset[1];
	rnergs_spect_OT_min[1][0] = rnergs_spect_OT_min[1][0] + rnergs_spect_O_min[5][0]; 

	rnergs_spect_T_min[0][0] = (float)c.sst_thrt2 * t_threshold_slope[0] + t_threshold_offset[0];
	rnergs_spect_T_min[1][0] = (float)c.sst_thrt6 * t_threshold_slope[1] + t_threshold_offset[1];

	j = c.sst_t_lut;

	for (d=0;d<2;d++) {
		for (i=0;i<7;i++) {
	rnergs_3d_FT_min[d][i] = ft_3dbin_min_lut[j][i] * t_adc_slope[d] + t_adc_offset[d];
	rnergs_3d_FT_max[d][i] = ft_3dbin_max_lut[j][i] * t_adc_slope[d] + t_adc_offset[d];
		}
	}
	for (d=0;d<2;d++) {
		for (i=0;i<9;i++) {
	rnergs_3d_OT_min[d][i] = ot_3dbin_min_lut[j][i] * t_adc_slope[d+2] + t_adc_offset[d+2];
	rnergs_3d_OT_max[d][i] = ot_3dbin_max_lut[j][i] * t_adc_slope[d+2] + t_adc_offset[d+2];
		}
	}
	for (d=0;d<2;d++) {
		for (i=1;i<24;i++) {
	rnergs_spect_FT_min[d][i] = t_adc_lut[j][i-1] * t_adc_slope[d] + t_adc_offset[d];
	rnergs_spect_OT_min[d][i] = t_adc_lut[j][i-1] * t_adc_slope[d+2] + t_adc_offset[d+2];
	rnergs_spect_T_min[d][i] = t_adc_lut[j][i-1] * t_adc_slope[d+4] + t_adc_offset[d+4];
		}
		for (i=0;i<24;i++) {
	rnergs_spect_FT_max[d][i] = t_adc_lut[j][i]   * t_adc_slope[d] + t_adc_offset[d];
	rnergs_spect_OT_max[d][i] = t_adc_lut[j][i]   * t_adc_slope[d+2] + t_adc_offset[d+2];
	rnergs_spect_T_max[d][i] = t_adc_lut[j][i]   * t_adc_slope[d+4] + t_adc_offset[d+4];
		}
	}
	for (d=0;d<2;d++)  {
		for (i=0;i<7;i++) {
	if ( rnergs_3d_FT_min[d][i] < (float) 600 )
	rnergs_3d_FT_eff[d][i] =  polynom5(&ft_coeff[0][0],rnergs_3d_FT_min[d][i]);
	if (rnergs_3d_FT_min[d][i] > (float) 600 )
	rnergs_3d_FT_eff[d][i] =  polynom5(&ft_coeff[1][0],rnergs_3d_FT_min[d][i]);
		}
	}
	for (d=0;d<2;d++)  {
		for (i=7;i<24;i++) {
	if ( rnergs_spect_FT_min[d][i] < (float) 600 )
	rnergs_spect_FT_eff[d][i] =  polynom5(&ft_coeff[0][0],rnergs_spect_FT_min[d][i]);
	if (rnergs_spect_FT_min[d][i] > (float) 600 )
	rnergs_spect_FT_eff[d][i] =  polynom5(&ft_coeff[1][0],rnergs_spect_FT_min[d][i]);
		}
	}

	return(1);
}



int  get_nrg_3d_O(float y[6][18],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<6;f++) {
			for(e=0;e<18;e++) {
				y[f][e] = 1000.*rnergs_3d_O_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<6;f++) {
			for(e=0;e<18;e++) {
				y[f][e] = 1000.*rnergs_3d_O_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<6;f++) {
			for(e=0;e<18;e++) {
 		y[f][e] = 500.*(rnergs_3d_O_min[f][e]+rnergs_3d_O_max[f][e]);
			}	
		}

	
	return(1);
}

int  get_nrg_spect_O(float y[6][48],int ne,int pos,MCFG *cfg)
{

	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<6;f++) {
			for(e=0;e<48;e++) {
				y[f][e] = 1000.*rnergs_spect_O_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<6;f++) {
			for(e=0;e<48;e++) {
				y[f][e] = 1000.*rnergs_spect_O_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<6;f++) {
			for(e=0;e<48;e++) {
 		y[f][e] = 500.*(rnergs_spect_O_min[f][e]+rnergs_spect_O_max[f][e]);
			}	
		}

	
	return(1);
}



int  get_nrg_3d_F(float y[6][14],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<6;f++) {
			for(e=0;e<14;e++) {
				y[f][e] = 1000.*rnergs_3d_F_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<6;f++) {
			for(e=0;e<14;e++) {
				y[f][e] = 1000.*rnergs_3d_F_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<6;f++) {
			for(e=0;e<14;e++) {
 		y[f][e] = 500.*(rnergs_3d_F_min[f][e]+rnergs_3d_F_max[f][e]);
			}	
		}
	if(pos == SSTEFF)
		for(f=0;f<6;f++) {
			for(e=0;e<7;e++) {
				y[f][e] = rnergs_3d_F_eff[f][e];
			}	
		}


	return(1);
}

int  get_nrg_spect_F(float y[6][32],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<6;f++) {
			for(e=0;e<32;e++) {
				y[f][e] = 1000.*rnergs_spect_F_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<6;f++) {
			for(e=0;e<32;e++) {
				y[f][e] = 1000.*rnergs_spect_F_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<6;f++) {
			for(e=0;e<32;e++) {
 		y[f][e] = 500.*(rnergs_spect_F_min[f][e]+rnergs_spect_F_max[f][e]);
			}	
		}
	if(pos == SSTEFF)
		for(f=0;f<6;f++) {
			for(e=0;e<16;e++) {
				y[f][e] = rnergs_spect_F_eff[f][e];
			}	
		}

	return(1);

}

int  get_nrg_3d_OT(float y[2][9],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<2;f++) {
			for(e=0;e<9;e++) {
				y[f][e] = 1000.*rnergs_3d_OT_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<2;f++) {
			for(e=0;e<9;e++) {
				y[f][e] = 1000.*rnergs_3d_OT_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<2;f++) {
			for(e=0;e<9;e++) {
 		y[f][e] = 500.*(rnergs_3d_OT_min[f][e]+rnergs_3d_OT_max[f][e]);
			}	
		}

	
	return(1);
}

int  get_nrg_spect_OT(float y[2][24],int ne,int pos,MCFG *cfg)
{

	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
				y[f][e] = 1000.*rnergs_spect_OT_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
				y[f][e] = 1000.*rnergs_spect_OT_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
 		y[f][e] = 500.*(rnergs_spect_OT_min[f][e]+rnergs_spect_OT_max[f][e]);
			}	
		}

	
	return(1);
}



int  get_nrg_3d_FT(float y[2][7],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<2;f++) {
			for(e=0;e<7;e++) {
				y[f][e] = 1000.*rnergs_3d_FT_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<2;f++) {
			for(e=0;e<7;e++) {
				y[f][e] = 1000.*rnergs_3d_FT_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<2;f++) {
			for(e=0;e<7;e++) {
 		y[f][e] = 500.*(rnergs_3d_FT_min[f][e]+rnergs_3d_FT_max[f][e]);
			}	
		}
	if(pos == SSTEFF)
		for(f=0;f<2;f++) {
			for(e=0;e<7;e++) {
				y[f][e] = rnergs_3d_FT_eff[f][e];
			}	
		}


	return(1);
}

int  get_nrg_spect_FT(float y[2][24],int ne,int pos,MCFG *cfg)
{


	int e,f;

	if(pos == SSTMIN)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
				y[f][e] = 1000.*rnergs_spect_FT_min[f][e];
			}	
		}
	if(pos == SSTMAX)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
				y[f][e] = 1000.*rnergs_spect_FT_max[f][e];
			}	
		}
	if(pos == SSTMID)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
 		y[f][e] = 500.*(rnergs_spect_FT_min[f][e]+rnergs_spect_FT_max[f][e]);
			}	
		}
	if(pos == SSTEFF)
		for(f=0;f<2;f++) {
			for(e=0;e<24;e++) {
				y[f][e] = rnergs_spect_FT_eff[f][e];
			}	
		}

	return(1);

}

#define C0 6.24
#define C1 .95
#define C2 9.9e-5

float F_electronic_to_electron_energy (float x)

{
	float y;
	y=(C2*x+C1)*x+C0;
	return (y);
}

#define Co10 9.39
#define Co11 .995
#define Co12 5.93e-7

float O1_electronic_to_proton_energy (float x)

{
	float y;
	y=(Co12*x+Co11)*x+Co10;
	return (y);
}

#define Co0 17.33
#define Co1 .993
#define Co2 7.84e-7

float O_electronic_to_proton_energy (float x)

{
	float y;
	y=(Co2*x+Co1)*x+Co0;
	return (y);
}

float polynom5(float *coeff,float x)
{
	float y;
	y=(((coeff[4]*x+coeff[3])*x+coeff[2])*x+coeff[1])*x+coeff[0];
	return(y);
}




