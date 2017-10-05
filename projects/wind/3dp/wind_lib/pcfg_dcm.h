#ifndef PCFG_DCM_H
#define PCFG_DCM_H

#include "winddefs.h"
#include "wind_pk.h"

/*
typedef uint2 nvector;
typedef uint2 np_uint;
typedef uint2 np_schar; -- already defined in winddefs.h .. jpr  3/95 */


struct pesa_configuration {  
  double    time1;
  double    time2;
  double    p_temp;
  int       valid;
  uchar     inst_config;
  uchar     inst_mode;
  uint2     icfg_size;
  nvector   esa_swp_select; /* added by fvm */
  uint2     select_sector;  /* added by fvm */
  nvector   esa_swp_high;
  nvector   esa_swp_low;
  uint2     min_swp_level;
  uint2     step_swp_level;
  uint2     step_time;
  uchar     esa_mcph;       /* added by fvm */
  uchar     esa_mcpl;       /* added by fvm */
  uchar     esa_pha_basech; /* added by fvm */
  sweep_def pl_sweep;
  uint2     gs1_pl;
  uchar     bndry_pt;
/*uchar     fill2;   */
  sweep_def ph_sweep;
  
  int4	    snap_periods;
  uint2     cp_vel_add;
  uint2     cp_bq2_add;
  uint2     cp_stmom_add;
  uint2     cp_adjpmom_add;
  uint2     cp_densmom_add;
  uint2     cp_velmom_add;
  uint2     cp_newst_add;
  uint2     cp_bst_add;
  uint2     cp_keyparms;
  uint2     w_pl_tbl;
    
/* variables to control sweep and moment calculations for PESAL               */
  uchar     cbin;         /* specifies which bin contains the peak            */ 
  uchar     hysteresis;   /* specifies hysteresis substep value for sweep     */
  uchar     N_thresh;     /* specifies flux threshold for search mode         */     
  uchar     shiftmask;    /* insures proper boundaries                        */
  uchar     proton_cnt;   /* Max counts needed before triggering alpha moment */
  uchar     alpha_step;   /* # of steps after peak before accumulating alphas */
  schar     skip_size;    /* substeps to skip while in search mode            */
  uchar     E_step_min;   /* lowest allowable energy substep                  */
  uchar     E_step_max;   /* largest allowable energy substep                 */
  schar     psmin;
  schar     psmax;
  schar     p_hyst;
  
  uint2     brst_log_offset;
  uchar     brst_NV_thresh;  /* Count rate threshold for burst trigger */
  uchar     brst_v_n1;       /* smoothing parameter for dv             */
  uchar     brst_v_n2;       /* smoothing parameter for vc             */
  schar     brst_v_offset;   /* threshold level for velocity changes   */
  
  uint2     bld_map_add;
  uint2     burst_shift;
  uint2     accum_shift;
  uint2     padj;
  
  uint2     init_proc[4];
  uint2     eres_codes[4];
  uint2     telemetry_modes[8];
  uint2     int_period[8];
  nvector   bts_c_val;       /* special codes, 4 accums */
  
  uchar     A_a_bsize;
  uchar     A_b_bsize;
  uchar     B_a_bsize;
  uchar     B_b_bsize;
  
  uchar     tsum_min;
  uchar     tsum_max;
  uchar     beam_n1;
  uchar     beam_n2;
  uchar     ph_bst_shft;
  uchar     ph_bst_msk;
  uchar     ph_acc_shft;
  uchar     ph_acc_msk;
  uchar     bad_nrg;
  uint2     iconfig_crc;
  
};

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        double time;           /* sample time */
        int4   index;
        int2   valid;
	uchar  data[218];
} pcfg_data;

typedef struct pesa_configuration Pconfig;

/* extern struct pesa_configuration pcfg;  */

extern uchar default_pcfg_data[];
#define PCONFIG_SIZE 218


/********** Function prototypes *********/

int decom_pconfig(packet *pk,Pconfig *pc);

int set_pesa_configuration(double time);


#endif
