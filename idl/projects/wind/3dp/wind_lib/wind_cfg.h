
struct filter_def {
	int avg;
	int davg;
	uchar n0;
	uchar n1;
	uchar n2;
	uchar offset;
	uchar mult;
	uchar shift;
};



struct eesa_configuration        {
                  uchar inst_config;
                  uchar inst_mode;
                  uint2  icfg_size;
                  nvector init_inst;
                  nvector inst_hk;
                  nvector set_x_hk_mux;
                  nvector get_x_hk_mux;
                  nvector cal_command;
                  nvector esa_swp_select;
                  uint2    sel_sector;
                  nvector esa_swp_high;
                  nvector esa_swp_low;
                  uint2    min_swp_level;
                  uint2    step_swp_level;
                  uint2    step_time;
                  nvector esa_swp_start;
                  nvector esa_pdq_task;
                  nvector dumpf_proc;
                  nvector eos_task0;
                  nvector rate_proc;
                  nvector spec_proc;
                  nvector flux_proc;
                  nvector pha_proc;
                  nvector pha_pckt_maker;
                  nvector sci_init;
                  nvector sci_proc;
                  nvector brst_proc;
                  nvector eos_task1;
                  nvector tlm_task;
                  uint2    esa_default_swp;
                  uchar   esa_hve;
                  uchar   esa_pmt;
                  uchar   esa_mcph;
                  uchar   esa_mcpl;
                  uchar   esa_pha_basech;
                  uchar   esa_pha_chstp;
                  uchar   esa_pha_lvlstp;
                  uchar   esa_pha_mnlvl_low;
                  uchar   esa_pha_mnlvl_high;
                  uchar   fpc_mode_low;
                  uchar   fpc_mode_mid;
                  uchar   fpc_mode_high;
                  uchar   fpc_chnl;
                  uchar   fpc_period;
                  uchar   wave_event;
                  uchar   wave_period;
                  uint2    min_wave_level;
                  struct sweep_def el_sweep;
                  struct sweep_def eh_sweep;
                  nvector init_map_add;
                  nvector acc_3d_add;
                  nvector mk_3d_pkt_add;
                  nvector mk_mom_pkt_add;
                  nvector getb_dir_add;
                  nvector cosb256_add;
                  nvector sinb256_add;
                  nvector init_velw_add;
                  nvector acc_pad_add;
                  nvector mk_pad_pkt_add;
                  nvector cp_bdq_add;
                  nvector cp_stmom_add;
                  nvector cp_emom_add;
                  nvector cp_edens_add;
                  nvector cp_bst_add;
                  nvector filter_ptr;
                  nvector sin_cos_sec_tbl;
                  nvector w_el_tbl;
                  nvector init_corr_add;
                  nvector acc_corr_add;
                  nvector mk_corr_pkt_add;
                  uint2    check_sum;

		double time;
		double e_temp;
};


struct eesa_Xconfiguration {  /* to be copied from rom to ram fixed memory */
	uchar size;
	uchar magic_number;
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
	schar   bth_mult;    /* for conversion from degrees to binary degrees  */
	uchar   misc_bits;
	schar   defl_up_offset;
	schar   defl_dn_offset;
	uchar   pad_shift;
	uchar   defl_b_shift;
	uchar   def_cal_strt;
	uchar   def_cal_step;
	uchar   def_cal_ehdac;
	struct filter_def dens_trig;
	struct filter_def press_trig;
};
#define SCN_SIZE sizeof(struct eesa_Xconfiguration)




typedef struct eesa_configuration Econfig;
typedef struct eesa_Xconfiguration EXconfig;


extern Econfig ecfg;
extern EXconfig excfg;


/********** Function prototypes *********/

/*************************************************************************
set_eesa_configuration...  This routine will determine the eesa instrument
configuration for the given time.  It should be called prior to any routine
that depends upon the instrument configuration.
**************************************************************************/
int set_eesa_configuration(double time);

int print_econfig_packets(int print,int store);






struct pesa_configuration {  
   /* variable space for Jan  */
                  uchar   inst_config;
                  uchar   inst_mode;
                  uint2    icfg_size;
                  nvector  init_inst; 
                  nvector  inst_hk; 
                  nvector  set_x_hk_mux;
                  nvector  get_x_hk_mux;
                  nvector  cal_command;
                  nvector  esa_swp_select;
                  uint2    select_sector;
                  nvector  esa_swp_high;
                  nvector  esa_swp_low;
                  uint2    min_swp_level;
                  uint2    step_swp_level;
                  uint2    step_time;
                  nvector  esa_swp_start;
                  nvector  esa_pdq_task;
                  nvector  dumpf_proc;
                  nvector  brst_proc;
                  nvector  eos_task0;
                  nvector  rate_proc;
                  nvector  spec_proc;
                  nvector  flux_proc;
                  nvector  pha_proc;
                  nvector  quad_proc;
                  nvector  snap_55;
                  nvector  snap_88;
                  nvector  esa_mom_init;
                  nvector  quad_task;
                  nvector  esa_3d_init;
                  nvector  d3_proc;
                  nvector  eos_task1;
                  uint2    esa_default_swp;
                  uchar   esa_hve;
                  uchar   esa_pmt;
                  uchar   esa_mcph;
                  uchar   esa_mcpl;
                  uchar   esa_pha_basech;
                  uchar   esa_pha_chstp;
                  uchar   esa_pha_lvlstp;
                  uchar   esa_pha_mnlvl_low;
                  uchar   esa_pha_mnlvl_high;
                  uchar   fill1;
                  struct  sweep_def pl_sweep;
                  uint2    gs1_pl;
                  uchar   bndry_pt;
                  uchar   fill2;
                  struct  sweep_def ph_sweep;

                  uint4   snap_periods;                
   /*  more code vectors  */
                  nvector  cp_vel_add;
                  nvector  cp_bq2_add;
                  nvector  cp_stmom_add;
                  nvector  cp_adjpmom_add;
                  nvector  cp_densmom_add;
                  nvector  cp_velmom_add;
                  nvector  cp_newst_add;
                  nvector  cp_bst_add;
                  nvector  cp_keyparms;
                  np_uint  w_pl_tbl;     /* pointer to weight table */

#if 0   /*   the following were removed for some unknown reason */
                  nvector  cp_dac_add;
                  nvector  cp_pmom_add;
                  nvector  init_map_add;
                  nvector  make_ph_pack_add;
                  nvector  cp_dac_t_add;
                  nvector  cp_comp16_add;
                  nvector  cph_comp19_add;
#endif

   /*   variables to control sweep and moment calculations for PESAL   */
                  uchar   cbin;         /*  specifies which bin contains the peak             */ 
                  uchar   hysteresis;   /*  specifies hysteresis substep value for sweep      */
                  uchar   N_thresh;     /*  specifies flux threshold for search mode       */     
                  uchar   shiftmask;     /*  insures proper boundaries                         */
                  uchar   proton_cnt;    /*  Max counts needed before triggering alpha moment  */
                  uchar   alpha_step;   /*  # of steps after peak before accumulating alphas  */
                  schar   skip_size;    /*  substeps to skip while in search mode             */
                  uchar   E_step_min;   /*  lowest allowable energy substep                   */
                  uchar   E_step_max;   /*  largest allowable energy substep                  */
                  schar   psmin;
                  schar   psmax;
                  schar   p_hyst;

                  uint2  brst_log_offset; 
                  uchar brst_NV_thresh;  /*  Count rate threshold for burst trigger  */
                  uchar brst_v_n1;       /*  smoothing parameter for dv   */
                  uchar brst_v_n2;       /*  smoothing parameter for vc   */
                  schar brst_v_offset;   /*  threshold level for velocity changes */

                  nvector bld_map_add;
                  nvector burst_shift;
                  nvector accum_shift;
                  np_schar padj;

                  nvector  init_proc[4];  /*  initialization procedures  */
                  uint2     eres_codes[4];
                  uint2     telemetry_modes[8];  /*  telemetry modes  */
                  uint2     int_period[8];       /*  integration period codes. Period= 1<<n */
                  uint2     bts_c_vals;       /* special codes for each of the 4 accum's */

   /*  control variables for PESAH  */
                  uchar A_a_bsize;      /* Buffer size / 64  */
                  uchar A_b_bsize;      /* Buffer size / 64  */
                  uchar B_a_bsize;      /* Buffer size / 64  */
                  uchar B_b_bsize;      /* Buffer size / 64  */
                  uchar tsum_min;       /* starting acc sum  */
                  uchar tsum_max;       /* ending acc sum  */
                  uchar beam_n1;        /* sum averaging parameter */  
                  uchar beam_n2;        /* difference averaging parameter */
                  uchar ph_bst_shft;    /* burst accum shift value */
                  uchar ph_bst_msk;     /* burst accum mask value  */
                  uchar ph_acc_shft;    /* burst accum shift value */
                  uchar ph_acc_msk;     /* burst accum mask value  */
                  uchar bad_nrg;

#if 0   /* not included for some reason */
   /*    Burst trigger control variables  */
                  uchar brst_NV_thresh;  /*  Count rate threshold for burst trigger  */
                  uchar brst_min_spin;   /*  minimum number of spins  */
                  uchar brst_v_thresh;   /*  velocity threshold  */
                  uchar brst_v_n1;       /*  smoothing parameter for dv   */
                  uchar brst_v_n2;       /*  smoothing parameter for vc   */
                  uchar brst_v_mult;     /*  multiplication factors */
                  uchar brst_v_shift;    /*  should be 10 nominally */
                  schar brst_v_offset;   /*  threshold level for velocity changes */
#endif
                  uint2 iconfig_crc;    /* checksum */

		double time;
		double p_temp;
};



typedef struct pesa_configuration Pconfig;

extern struct pesa_configuration pcfg;


/********** Function prototypes *********/
int      set_pesa_configuration(double time);
int      print_pconfig_packets(int print,int store);
