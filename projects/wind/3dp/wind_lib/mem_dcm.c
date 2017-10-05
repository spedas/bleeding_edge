#include "mem_dcm.h"
#include "wind_pk.h"
#include "pckt_prt.h"
#include "windmisc.h"

#include <stdio.h>


FILE *memory_dump_fp;
FILE *eesa_dump_fp;

Parameter_Location eesa_cfg_par[] = {
	{"inst_config"	, 0x01, 'b', 0x0000 },
	{"inst_mode"  	, 0x01, 'b', 0,1 },
	{"icfg_size"	, 0x02, 'w' },
	{"init_inst"	, 0x02, 'w' },
	{"inst_hk"	, 0x02, 'w' },
	{"set_x_hk_mux"	, 0x02, 'w' },
	{"get_x_hk_mux" , 0x02, 'w' },
	{"cal_command"	, 0x02, 'w' },
	{"esa_swp_select"	, 0x02, 'w'},
	{"selection sector"	, 0x02, 'w'},
	{"esa_swp_high"	, 0x02, 'w'},
	{"esa_swp_low"	, 0x02, 'w'},
	{"min_swp_level", 0x02, 'w'},
	{"step_swp_level"	, 0x02, 'w'},
	{"step_time"	, 0x02, 'w'},
	{"esa_swp_start", 0x02, 'w'},
	{"esa_pdq_task"	, 0x02, 'w'},
	{"dumpf_proc"	, 0x02, 'w'},
	{"eos_task0"	, 0x02, 'w'},
	{"rate_proc"	, 0x02, 'w'},
	{"spec_proc"	, 0x02, 'w'},
	{"flux_proc"	, 0x02, 'w'},
	{"pha_proc"	, 0x02, 'w'},
	{"pha_pkt_maker", 0x02, 'w'},
	{"sci_init"	, 0x02, 'w'},
	{"sci_proc"	, 0x02, 'w'},
	{"brst_proc"	, 0x02, 'w'},
	{"eos_task1"	, 0x02, 'w'},
	{"tlm_task"	, 0x02, 'w'},
	{"esa_default_swp"	, 0x02, 'w'},
	{"esa_hve"	, 0x01, 'b'},
	{"esa_pmt"	, 0x01, 'b'},
	{"esa_mcph"	, 0x01, 'b'},
	{"esa_mcpl"	, 0x01, 'b'},
	{"esa_pha_basech"	, 0x01, 'b'},
	{"esa_pha_chstp", 0x01, 'b'},
	{"esa_pha_lvlstp"	, 0x01, 'b'},
	{"esa_pha_mnlvl", 0x02, 'w'},
	{"fpc_mode"	, 0x03, 'b'},
	{"fpc_chnl"	, 0x01, 'b'},
	{"fpc_period"	, 0x01, 'b'},
	{"wave_event"	, 0x01, 'b'},
	{"wave_period"	, 0x01, 'b'},
	{"min_wave_level"	, 0x02, 'w'},
	{"startd_e_l"	, 0x02, 'w' },
	{"kd_sw_l"	, 0x02, 'w' },
	{"s1d_l"	, 0x02, 'w' },
	{"s2d_l"	, 0x02, 'w' },
	{"m2d_l"	, 0x02, 'w' },
	{"gs2_l"	, 0x02, 'w' },
	{"startd_e_h"	, 0x02, 'w' },
	{"kd_sw_h"	, 0x02, 'w' },
	{"s1d_h"	, 0x02, 'w' },
	{"s2d_h"	, 0x02, 'w' },
	{"m2d_h"	, 0x02, 'w' },
	{"gs2_h"	, 0x02, 'w' },
	{"init_map_add"	, 0x02, 'w' },
	{"acc_3d_add"	, 0x02, 'w' },
	{"mk_3d_pkt_add", 0x02, 'w' },
	{"mk_mom_pkt_add"	, 0x02, 'w' },
	{"getb_dir_add"	, 0x02, 'w' },
	{"cosb256_add"	, 0x02, 'w' },
	{"sinb256_add"	, 0x02, 'w' },
	{"init_velw_add", 0x02, 'w' },
	{"acc_pad_add"	, 0x02, 'w' },
	{"mk_pad_pkt_add"	, 0x02, 'w' },
	{"cp_bdq_add"	, 0x02, 'w' },
	{"cp_stmom_add"	, 0x02, 'w' },
	{"cp_emom_add"	, 0x02, 'w' },
	{"cp_edens_add"	, 0x02, 'w' },
	{"cp_bst_add"	, 0x02, 'w' },
	{"filter_ptr"	, 0x02, 'w' },
	{"sin_cos_sec_tbl"	, 0x02, 'w' },
	{"w_el_tbl"	, 0x02, 'w' },
	{"init_corr_add", 0x02, 'w' },
	{"acc_corr_add"	, 0x02, 'w' },
	{"mk_corr_pkt_add"	, 0x02, 'w',0,1},
	
{0}   /* Must be last line */
};


Parameter_Location eesa_mem_par[] = {
	{"p_blank",     0x20,  'b', 0x017c },
	{"low_blank"  , 0x10  },
	{"high_blank"  ,0x18  },
	{"acos1"       ,0x11  },
	{"acos2"       ,0x11  },
	{"map0"        ,0x02 ,'w'  },
	{"map1"        ,0x02 ,'w'  },
	{"map2"        ,0x02 ,'w'  },
	{"map3"        ,0x02 ,'w'  },
	{"eres"        ,0x04 ,'b'},
	{"tmode a0"    ,0x10 ,'b' },
	{"tmode a1"    ,0x10 , },
	{"tmode a2"    ,0x10 , },
	{"tmode a3"    ,0x10 , },
	{"tmode a4"    ,0x10 , },
	{"tmode a5"    ,0x10 , },
	{"mscformat"   ,0x06 ,'b' },
	{"bsize"       ,0x06 ,'b' },
	{"shft"        ,0x06  },
	{"mask"        ,0x06  },
	{"bph_offset"  ,0x02 ,'w'  },
	{"bth_offset"  ,0x01 ,'b'},
	{"bth_mult"    ,0x01 ,'b'},

/*	{"mis"      ,   0x1c,  'b', 0x02e5 },      /* suspect address !!!!! */
	{"moment_a0",   0x20,  'b', 0x0320 },
	{"moment_a1",   0x20  },
	{"eesah_a2",    0x20  },
	{"eesah_a3",    0x20  },
	{"esacut_a4",   0x20  },
	{"esacut_a5",   0x20  },
	{"corr_a6",     0x20  },
	{"P1_map",      0x00,  'w', 0xd000 },
	{"Sp 0",        0x30 },
	{"Sp 1",        0x30 },
	{"Sp 2",        0x30 },
	{"Sp 3",        0x30 },
	{"Sp 4",        0x30 },
	{"Sp 5",        0x30 },
	{"Sp 6",        0x30 },
	{"Sp 7",        0x30 },
	{"Sp 8",        0x30 },
	{"Sp 9",        0x30 },
	{"Sp 10",        0x30 },
	{"Sp 11",        0x30 },
	{"Sp 12",        0x30 },
	{"Sp 13",       0x30 },
	{"Sp 14",       0x30 },
	{"Sp 15",       0x30 },
	{"Sp 16",       0x30 },
	{"Sp 17",       0x30 },
	{"Sp 18",       0x30 },
	{"Sp 19",       0x30 },
	{"Sp 20",       0x30 },
	{"Sp 21",       0x30 },
	{"Sp 22",       0x30 },
	{"Sp 23",       0x30 },
	{"Sp 24",       0x30 },
	{"Sp 25",       0x30 },
	{"Sp 26",       0x30 },
	{"Sp 27",       0x30 },
	{"Sp 28",       0x30 },
	{"Sp 29",       0x30 },
	{"Sp 30",       0x30 },
	{"Sp 31",       0x30 },
	{"P2_map",     0x00,  'w', 0xd600 },
	{"Sp 0",       0x30 },
	{"Sp 1",       0x30 },
	{"Sp 2",       0x30 },
	{"Sp 3",       0x30 },
	{"Sp 4",       0x30 },
	{"Sp 5",       0x30 },
	{"Sp 6",       0x30 },
	{"Sp 7",       0x30 },
	{"Sp 8",       0x30 },
	{"Sp 9",       0x30 },
	{"Sp 10",       0x30 },
	{"Sp 11",       0x30 },
	{"Sp 12",       0x30 },
	{"Sp 13",       0x30 },
	{"Sp 14",       0x30 },
	{"Sp 15",       0x30 },
	{"Sp 16",       0x30 },
	{"Sp 17",       0x30 },
	{"Sp 18",       0x30 },
	{"Sp 19",       0x30 },
	{"Sp 20",       0x30 },
	{"Sp 21",       0x30 },
	{"Sp 22",       0x30 },
	{"Sp 23",       0x30 },
	{"Sp 24",       0x30 },
	{"Sp 25",       0x30 },
	{"Sp 26",       0x30 },
	{"Sp 27",       0x30 },
	{"Sp 28",       0x30 },
	{"Sp 29",       0x30 },
	{"Sp 30",       0x30 },
	{"Sp 31",       0x30 },
	{"M1_map",     0x00,  'w', 0xee00 },
	{"Sp 0",       0x20 },
	{"Sp 1",       0x20 },
	{"Sp 2",       0x20 },
	{"Sp 3",       0x20 },
	{"Sp 4",       0x20 },
	{"Sp 5",       0x20 },
	{"Sp 6",       0x20 },
	{"Sp 7",       0x20 },
	{"Sp 8",       0x20 },
	{"Sp 9",       0x20 },
	{"Sp 10",       0x20 },
	{"Sp 11",       0x20 },
	{"Sp 12",       0x20 },
	{"Sp 13",       0x20 },
	{"Sp 14",       0x20 },
	{"Sp 15",       0x20 },
	{"Sp 16",       0x20 },
	{"Sp 17",       0x20 },
	{"Sp 18",       0x20 },
	{"Sp 19",       0x20 },
	{"Sp 20",       0x20 },
	{"Sp 21",       0x20 },
	{"Sp 22",       0x20 },
	{"Sp 23",       0x20 },
	{"Sp 24",       0x20 },
	{"Sp 25",       0x20 },
	{"Sp 26",       0x20 },
	{"Sp 27",       0x20 },
	{"Sp 28",       0x20 },
	{"Sp 29",       0x20 },
	{"Sp 30",       0x20 },
	{"Sp 31",       0x20 },
	{"P1 buffer",   0x00 , 'w',  0x8000 },
	{"Bin 0",       0x1e,     },
	{"Bin 1",       0x1e,     },
	{"Bin 2",       0x1e,     },
	{"Bin 3",       0x1e,     },
	{"Bin 4",       0x1e,     },
	{"Bin 5",       0x1e,     },
	{"Bin 6",       0x1e,     },
	{"Bin 7",       0x1e,     },
	{"Bin 8",       0x1e,     },
	{"Bin 9",       0x1e,     },
	{"Bin 10",       0x1e,     },
	{"Bin 11",       0x1e,     },
	{"Bin 12",       0x1e,     },
	{"Bin 13",       0x1e,     },
	{"Bin 14",       0x1e,     },
	{"Bin 15",       0x1e,     },
	{"Bin 16",       0x1e,     },
	{"Bin 17",       0x1e,     },
	{"Bin 18",       0x1e,     },
	{"Bin 19",       0x1e,     },
	{"Bin 20",       0x1e,     },
	{"Bin 21",       0x1e,     },
	{"Bin 22",       0x1e,     },
	{"Bin 23",       0x1e,     },
	{"Bin 24",       0x1e,     },
	{"Bin 25",       0x1e,     },
	{"Bin 26",       0x1e,     },
	{"Bin 27",       0x1e,     },
	{"Bin 28",       0x1e,     },
	{"Bin 29",       0x1e,     },
	{"Bin 30",       0x1e,     },
	{"Bin 31",       0x1e,     },
	{"Bin 32",       0x1e,     },
	{"Bin 33",       0x1e,     },
	{"Bin 34",       0x1e,     },
	{"Bin 35",       0x1e,     },
	{"Bin 36",       0x1e,     },
	{"Bin 37",       0x1e,     },
	{"Bin 38",       0x1e,     },
	{"Bin 39",       0x1e,     },
	{"Bin 40",       0x1e,     },
	{"Bin 41",       0x1e,     },
	{"Bin 42",       0x1e,     },
	{"Bin 43",       0x1e,     },
	{"Bin 44",       0x1e,     },
	{"Bin 45",       0x1e,     },
	{"Bin 46",       0x1e,     },
	{"Bin 47",       0x1e,     },
	{"Bin 48",       0x1e,     },
	{"P2 buffer",   0x00 , 'w',  0x9500 },
	{"Bin 0",       0x1e,     },
	{"Bin 1",       0x1e,     },
	{"Bin 2",       0x1e,     },
	{"Bin 3",       0x1e,     },
	{"Bin 4",       0x1e,     },
	{"Bin 5",       0x1e,     },
	{"Bin 6",       0x1e,     },
	{"Bin 7",       0x1e,     },
	{"Bin 8",       0x1e,     },
	{"Bin 9",       0x1e,     },
	{"Bin 10",       0x1e,     },
	{"Bin 11",       0x1e,     },
	{"Bin 12",       0x1e,     },
	{"Bin 13",       0x1e,     },
	{"Bin 14",       0x1e,     },
	{"Bin 15",       0x1e,     },
	{"Bin 16",       0x1e,     },
	{"Bin 17",       0x1e,     },
	{"Bin 18",       0x1e,     },
	{"Bin 19",       0x1e,     },
	{"Bin 20",       0x1e,     },
	{"Bin 21",       0x1e,     },
	{"Bin 22",       0x1e,     },
	{"Bin 23",       0x1e,     },
	{"Bin 24",       0x1e,     },
	{"Bin 25",       0x1e,     },
	{"Bin 26",       0x1e,     },
	{"Bin 27",       0x1e,     },
	{"Bin 28",       0x1e,     },
	{"Bin 29",       0x1e,     },
	{"Bin 30",       0x1e,     },
	{"Bin 31",       0x1e,     },
	{"Bin 32",       0x1e,     },
	{"Bin 33",       0x1e,     },
	{"Bin 34",       0x1e,     },
	{"Bin 35",       0x1e,     },
	{"Bin 36",       0x1e,     },
	{"Bin 37",       0x1e,     },
	{"Bin 38",       0x1e,     },
	{"Bin 39",       0x1e,     },
	{"Bin 40",       0x1e,     },
	{"Bin 41",       0x1e,     },
	{"Bin 42",       0x1e,     },
	{"Bin 43",       0x1e,     },
	{"Bin 44",       0x1e,     },
	{"Bin 45",       0x1e,     },
	{"Bin 46",       0x1e,     },
	{"Bin 47",       0x1e,     },
	{"Bin 48",       0x1e,     },

	{ 0 },                        /* must be last line */
};

Parameter_Location pesa_mem_par[] = {
	{"inst_config",		0x01, 'b', 0x0000 },
	{"inst_mode",		0x01, 'b'},
	{"icfg_size",		0x02, 'w'},
	{"init_inst",		0x02, 'w'},
	{"inst_hk",		0x02, 'w'},
	{"set_x_hk_mux",	0x02, 'w'},
	{"get_x_hk_mux",	0x02, 'w'},
	{"cal_command",		0x02, 'w'},
	{"esa_swp_select",	0x02, 'w'},
	{"select_sector",	0x02, 'w'},
	{"esa_swp_high",	0x02, 'w'},
	{"esa_swp_low",		0x02, 'w'},
	{"min_swp_level",	0x02, 'w'},
	{"step_swp_level",	0x02, 'w'},
	{"step_time",		0x02, 'w'},
	{"esa_swp_start",	0x02, 'w'},
	{"esa_pdq_task",	0x02, 'w'},
	{"dumpf_proc",		0x02, 'w'},
	{"brst_proc",		0x02, 'w'},
	{"eos_task0",		0x02, 'w'},
	{"rate_proc",		0x02, 'w'},
	{"spec_proc",		0x02, 'w'},
	{"flux_proc",		0x02, 'w'},
	{"pha_proc",		0x02, 'w'},
	{"quad_proc",		0x02, 'w'},
	{"snap_55",		0x02, 'w'},
	{"snap_88",		0x02, 'w'},
	{"esa_mom_init",	0x02, 'w'},
	{"quad_task",		0x02, 'w'},
	{"esa_3d_init",		0x02, 'w'},
	{"d3_proc",		0x02, 'w'},
	{"eos_task1",		0x02, 'w'},
	{"esa_default_swp",	0x02, 'w'},
	{"esa_hve",		0x01, 'b'},
	{"esa_pmt",		0x01, 'b'},
	{"esa_mcph",		0x01, 'b'},
	{"esa_mcpl",		0x01, 'b'},
	{"esa_pha_basech",	0x01, 'b'},
	{"esa_pha_chstp",	0x01, 'b'},
	{"esa_pha_lvlstp",	0x01, 'b'},
	{"esa_pha_mnlvl",	0x02, 'w'},
	{"startd_e_pl",		0x02, 'w', 0x004a},
	{"kd_sw_pl",		0x02, 'w'},
	{"s1d_pl",		0x02, 'w'},
	{"s2r_pl",		0x02, 'w'},
	{"m2d_pl",		0x02, 'w'},
	{"gs2_pl",		0x02, 'w'},
	{"gs1_pl",		0x02, 'w'},
	{"bndry_pt",		0x01, 'b'},
	{"startd_e_ph",		0x02, 'w', 0x005a},
	{"kd_sw_ph",		0x02, 'w'},
	{"s1d_ph",		0x02, 'w'},
	{"s2d_ph",		0x02, 'w'},
	{"m2d_ph",		0x02, 'w'},
	{"gs2_ph",		0x02, 'w'},
	{"snap_periods",	0x04, },
	{"cp_vel_add",		0x02, 'w'},
	{"cp_bq2_add",		0x02, 'w'},
	{"cp_stmom_add",	0x02, 'w'},
	{"cp_adjpmom_add",	0x02, 'w'},
	{"cp_densmom_add",	0x02, 'w'},
	{"cp_velmom_add",	0x02, 'w'},
	{"cp_newst_add",	0x02, 'w'},
	{"cp_bst_add",		0x02, 'w'},
	{"cp_keyparms",		0x02, 'w'},
	{"w_pl_tbl",		0x02, 'w'},
	{"cbin",		0x01, 'b'},
	{"hysteresis",		0x01, 'b'},
	{"N_thresh",		0x01, 'b'},
	{"shiftmask",		0x01, 'b'},
	{"proton_cnt",		0x01, 'b'},
	{"alpha_step",		0x01, 'b'},
	{"skip_size",		0x01, 'b'},
	{"E_step_min",		0x01, 'b'},
	{"E_step_max",		0x01, 'b'},
	{"psmin",		0x01, 'b'},
	{"psmax",		0x01, 'b'},
	{"p_hyst",		0x01, 'b'},
	{"brst_log_offset",	0x02, 'w'},
	{"brst_NV_thresh",	0x01, 'b'},
	{"brst_v_n1",		0x01, 'b'},
	{"brst_v_n2",		0x01, 'b'},
	{"brst_v_offset",	0x01, 'b'},
	{"bld_map_add",		0x02, 'w'},
	{"burst_shift",		0x02, 'w'},
	{"accum_shift",		0x02, 'w'},
	{"padj",		0x02, 'w'},
	{"init_proc 0",		0x02, 'w'},
	{"init_proc 1",		0x02, 'w'},
	{"init_proc 2",		0x02, 'w'},
	{"init_proc 3",		0x02, 'w'},
	{"eres_code 0",		0x02, 'w'},
	{"eres_code 1",		0x02, 'w'},
	{"eres_code 2",		0x02, 'w'},
	{"eres_code 3",		0x02, 'w'},
	{"telemetry_mode 0",	0x02, 'w'},
	{"telemetry_mode 1",	0x02, 'w'},
	{"telemetry_mode 2",	0x02, 'w'},
	{"telemetry_mode 3",	0x02, 'w'},
	{"telemetry_mode 4",	0x02, 'w'},
	{"telemetry_mode 5",	0x02, 'w'},
	{"telemetry_mode 6",	0x02, 'w'},
	{"telemetry_mode 7",	0x02, 'w'},
	{"int_period 0",	0x02, 'w'},
	{"int_period 1",	0x02, 'w'},
	{"int_period 2",	0x02, 'w'},
	{"int_period 3",	0x02, 'w'},
	{"int_period 4",	0x02, 'w'},
	{"int_period 5",	0x02, 'w'},
	{"int_period 6",	0x02, 'w'},
	{"int_period 7",	0x02, 'w'},
	{"bts_c_vals",		0x02, 'w'},
	{"A_a_bsize",		0x01, 'b'},
	{"A_b_bsize",		0x01, 'b'},
	{"B_a_bsize",		0x01, 'b'},
	{"B_b_bsize",		0x01, 'b'},
	{"tsum_min",		0x01, 'b'},
	{"tsum_max",		0x01, 'b'},
	{"beam_n1",		0x01, 'b'},
	{"beam_n2",		0x01, 'b'},
	{"ph_bst_shift",	0x01, 'b'},
	{"ph_bst_msk",		0x01, 'b'},
	{"ph_acc_shft",		0x01, 'b'},
	{"ph_acc_msk",		0x01, 'b'},
	{"bad_nrg",		0x01, 'b'},
	{ 0 },                        /* must be last line */
};

#define NUM_EESA_PARAM (sizeof(eesa_par)/sizeof(Parameter_Location))

static int param_init;





int print_memory_dump_packet(packet *pk)
{
	print_block_memory(memory_dump_fp,pk);
	print_eparam_memory(eesa_dump_fp,pk);	
	return(0);
}



int init_parameters(Parameter_Location par[])
{
	int i;
	Parameter_Location last;
	last = par[0];
	for(i=1;par[i].name;i++){
		if(par[i].loc == 0)
			par[i].loc = last.loc + last.size;
		if(par[i].type ==0)
			par[i].type = last.type;
		last = par[i];
	}		
	return(1);
}



int print_eparam_memory(FILE *fp,packet *pk)
{
	uint2 location;
	uchar *d;
	int n;
	if(fp==0)
		return(0);
	if(param_init == 0){
		param_init = 1;
		init_parameters(eesa_mem_par);
	}
	location = str_to_uint2(pk->data);
	fprintf(fp,"%s    Locations %04x - %04x\n",time_to_YMDHMS(pk->time), location,location+256-1);
	n = print_params(fp,eesa_mem_par,location,pk->data + 2,256);
	return(n);
}


int print_params(FILE *fp,Parameter_Location par[],uint2 loc,uchar *d,int ndata)
{
	int i,n,j,k;
	int f1,f2,f3,f4;
	uint2 v;
	char buff[10];
	
	n = 0;
	for(i=0;i<3000;i++){
		if(par[i].name ==0)
			break;
#if 1
		f1 = (par[i].loc <  (uint2)(loc+ndata));
		f4 = ((uint2)(par[i].loc+par[i].size) > loc);
		if(f1 && f4){
			fprintf(fp,"%-20s %04x  ",par[i].name,par[i].loc);
			if(par[i].type =='b' || par[i].type ==0){
				n=par[i].size;
				k = par[i].loc - loc;
				for(j=0;j<n;j++){
					if(k>=0 && k<ndata)
						sprintf(buff," %02x",*(d+k));
					else
						sprintf(buff,"   ");
					fputs(buff,fp);
					k++;
				}
			}
			else{
				n=par[i].size;
				k = par[i].loc - loc;
				for(j=0;j<n;j+=2){
					if(k>=0 && k<ndata){
						v = str_to_uint2(d+k);
						sprintf(buff," %04x",v);
					}
					else
						sprintf(buff,"     ");
					fputs(buff,fp);
					k+=2;
				}
			}
			fprintf(fp,"\n");
		}
#else
		f1 = (par[i].loc <  loc+ndata);
		f2 = (par[i].loc >= loc);
		f3 = (par[i].loc+par[i].size < loc+ndata);
		f4 = (par[i].loc+par[i].size >= loc);
		if(f1 && f2 && f3 && f4){   /* fully contained in data */
			fprintf(fp,"%-10s %04x  ",par[i].name,par[i].loc);
			if(par[i].type =='b' || par[i].type ==0){
				n=par[i].size;
				for(j=0;j<n;j++)
		 			fprintf(fp," %02x",*(d+par[i].loc-loc+j));
			}
			else{
				n=par[i].size;
				for(j=0;j<n;j+=2){
					v = str_to_uint2(d+par[i].loc-loc+j);
					fprintf(fp," %04x",v);
				}
			}
			fprintf(fp,"\n");
		}
		else if((f1 && f2) || (f3 && f4))
			fprintf(fp,"%-10s  (incomplete)\n",par[i].name);
#endif
			
			
	}

	return(n);
}

int print_param_changes(FILE *fp,Parameter_Location par[],uint2 loc,uchar *d,
	uchar *od,int ndata,char *chgstr)
{
	int i,n,j,k,ii=0;
	int f1,f2,f3,f4;
	uint2 v;
	char buff[10];
	char obuff[10];
	
	if (!fp)
		return(0);
	
	n = 0;
	memset(buff,0,10);
	memset(obuff,0,10);
	for(i=0;i<3000;i++){
		if(par[i].name ==0)
			break;
		f1 = (par[i].loc <  (uint2)(loc+ndata));
		f4 = ((uint2)(par[i].loc+par[i].size) > loc);
		if(f1 && f4){
			if(par[i].type =='b' || par[i].type ==0){
				n=par[i].size;
				k = par[i].loc - loc;
				for(j=0;j<n;j++){
					if(k>=0 && k<ndata) {
						sprintf(obuff," %02x", *(od+k));
						sprintf(buff," %02x",*(d+k));
					}
					else {
						sprintf(obuff,"   ");
						sprintf(buff,"   ");
					}
					k++;
				}
			}
			else{
				n=par[i].size;
				k = par[i].loc - loc;
				for(j=0;j<n;j+=2){
					if(k>=0 && k<ndata){
						v = str_to_uint2(od+k);
						sprintf(obuff," %04x",v);
						v = str_to_uint2(d+k);
						sprintf(buff," %04x",v);
					}
					else {
						sprintf(obuff,"     ");
						sprintf(buff,"     ");
					}
					k+=2;
				}
			}
		}
		if((strcmp(buff,obuff) != 0) && (par[i].ig_change != 1)) {
			fprintf(fp,"%s%-20s ",chgstr,par[i].name);
			fputs(obuff,fp);
			fputs(buff,fp);
			fprintf(fp,"\n");
			ii = 1;
		}
			
	}
	if(ii==1)
		fprintf(fp,"\n");
	return(n);
}





int print_block_memory(FILE *fp,packet *pk)
{
	uchar *d;
	uint2 loc;
	int i,j;

	if(fp==0)
		return(0);
	print_packet_header(fp,pk);
	d = pk->data;
	loc = str_to_uint2(d);
	d++;
	d++;
	fprintf(fp,"Location: %04x\n",loc);
	for(i=0;i<16;i++){
		for(j=0;j<16;j++)
			fprintf(fp,"%02x ",*d++);
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	return(1);
}



