#include "pcfg_dcm.h"

#include "wind_pk.h"
#include "esteps.h"
#include "map3d.h"

#include "windmisc.h"   /* for debugging  */
#include "pckt_prt.h"

#include <string.h>    /* for memcpy() */
#include <stdio.h>



uchar default_pcfg_data[]= {
0x03,0x0f,0x6c,0x00,0xb9,0xe0,0x8e,0xe1,0xe7,0xe1,0xf0,0xe1,0x0c,0xe2,0x68,0xe2,
0x83,0x03,0x0c,0xe3,0x31,0xe3,0x00,0x02,0x80,0x00,0x00,0x00,0x41,0xe5,0xde,0xe8,
0x8e,0xea,0x39,0xeb,0x39,0xea,0x75,0xeb,0x4c,0xeb,0x97,0xeb,0xdc,0xc7,0xb9,0xde,
0x0f,0xdf,0x5a,0xdf,0x3e,0xc0,0x45,0xb0,0x34,0xd0,0x2a,0xd7,0x11,0xda,0x00,0x00,
0x1c,0x92,0xa5,0xa4,0x00,0x01,0x01,0x00,0x00,0x00,0xa8,0x61,0x18,0xf6,0x0a,0x02,
0xc1,0x05,0x2b,0x7b,0x16,0x01,0x3d,0x10,0x30,0x00,0xef,0xfd,0x30,0xf2,0x10,0x02,
0xdf,0x05,0xe0,0x7a,0x50,0x00,0x34,0x40,0x24,0x33,0xb2,0xbd,0x9d,0xc0,0x23,0xc2,
0x5c,0xb6,0xd5,0xc0,0x4b,0xbe,0x50,0xb4,0xb0,0xf2,0x86,0xbd,0x33,0xc4,0x5e,0x00,
0x0a,0x00,0x02,0x02,0x2c,0x00,0xb0,0x00,0x08,0x20,0xe8,0x03,0x0f,0x08,0x05,0xff,
0x58,0xd1,0x94,0xdc,0x4d,0xdc,0x74,0xdd,0xfe,0xd4,0xa4,0xd4,0xbb,0xd6,0xec,0xd5,
0x6f,0x66,0x6f,0x66,0x6f,0x66,0x6f,0x66,0x33,0x00,0x33,0x00,0x33,0x00,0x33,0x00,
0x33,0x11,0x33,0x11,0x33,0x11,0x33,0x11,0x00,0x55,0x00,0x55,0x00,0x55,0x00,0x55,
0x00,0x44,0x00,0x44,0x00,0x55,0x00,0x44,0xdd,0xee,0x80,0x80,0x40,0x40,0x02,0x0d,
0x02,0x00,0x00,0x1f,0x00,0x1f,0x21,0x00,0x36,0xb3
};

/* #define PCONFIG_SIZE sizeof(default_pcfg_data) */
#define PCONFIG_SIZE 218







/**************************************************************
The following routine will decomutate selected elements of a
PESA configuration packet.  The routine does NOT currently
fill in all elements.
***************************************************************/
int decom_pconfig(packet *pk,Pconfig *pc)
{
	uchar *s;
	int i,j;
	uint2 crc0=0x100;

	if(pk==0){           /* use default setup */
		pc->time1 = pc->time2 = 0;
		s = default_pcfg_data;
	}
	else{
		pc->time1 = pk->time;
		if(pk->next)
			pc->time2 = pk->next->time;
		else
			pc->time2 = pk->time;
		s = pk->data;
	}

	pc->inst_config = s[0];
	pc->inst_mode   = s[1];
	pc->icfg_size   = s[2];

  	pc->esa_swp_select = str_to_uint2( s + 0x0E );
  	pc->select_sector  = str_to_uint2( s + 0x10 );
	pc->esa_swp_high   = str_to_uint2( s + 0x12 );
	pc->esa_swp_low    = str_to_uint2( s + 0x14 );
	pc->min_swp_level  = str_to_uint2( s + 0x16 );
	pc->step_swp_level = str_to_uint2( s + 0x18 );
	pc->step_time      = str_to_uint2( s + 0x1A );

  	pc->esa_mcph         = s[0x42];
 	pc->esa_mcpl         = s[0x43];
 	pc->esa_pha_basech   = str_to_uint2(s + 0x44);
	pc->pl_sweep.start_E = str_to_uint2(s + 0x4a);
	pc->pl_sweep.k_sw    = str_to_uint2(s + 0x4c);
	pc->pl_sweep.s1      = str_to_int2(s + 0x4e);
	pc->pl_sweep.s2      = str_to_int2(s + 0x50);
	pc->pl_sweep.m2      = str_to_uint2(s + 0x52);
	pc->pl_sweep.gs2     = str_to_uint2(s + 0x54);
	pc->gs1_pl           = str_to_uint2(s + 0x56);
	pc->bndry_pt         = *(s + 0x58);

	pc->ph_sweep.start_E = str_to_uint2(s + 0x5a);
	pc->ph_sweep.k_sw    = str_to_uint2(s + 0x5c);
	pc->ph_sweep.s1      = str_to_int2(s + 0x5e);
	pc->ph_sweep.s2      = str_to_int2(s + 0x60);
	pc->ph_sweep.m2      = str_to_uint2(s + 0x62);
	pc->ph_sweep.gs2     = str_to_uint2(s + 0x64);
	
	pc->snap_periods	= str_to_int4(s + 0x66);
	pc->cp_vel_add		= str_to_uint2(s + 0x66 + 0x04);
	pc->cp_bq2_add		= str_to_uint2(s + 0x66 + 0x06);
	pc->cp_stmom_add	= str_to_uint2(s + 0x66 + 0x08);
	pc->cp_adjpmom_add	= str_to_uint2(s + 0x66 + 0x0a);
	pc->cp_densmom_add	= str_to_uint2(s + 0x66 + 0x0c);
	pc->cp_velmom_add	= str_to_uint2(s + 0x66 + 0x0e);
	pc->cp_newst_add	= str_to_uint2(s + 0x66 + 0x10);
	pc->cp_bst_add		= str_to_uint2(s + 0x66 + 0x12);
	pc->cp_keyparms		= str_to_uint2(s + 0x66 + 0x14);
	pc->w_pl_tbl		= str_to_uint2(s + 0x66 + 0x16);

	pc->cbin       = s[0x7e];
	pc->hysteresis = s[0x7f];
	pc->N_thresh   = s[0x80];
	pc->shiftmask  = s[0x81];
	pc->proton_cnt = s[0x82];
	pc->alpha_step = s[0x83];
	pc->skip_size  = s[0x84];
	pc->E_step_min = s[0x85];
	pc->E_step_max = s[0x86];
	pc->psmin      = s[0x87];
	pc->psmax      = s[0x88];
	pc->p_hyst     = s[0x89];

	pc->brst_log_offset= str_to_uint2(s + 0x66 + 0x24);
	pc->brst_NV_thresh = s[0x8c];
	pc->brst_v_n1      = s[0x8d];
	pc->brst_v_n2      = s[0x8e];
	pc->brst_v_offset  = s[0x8f];
	
	pc->bld_map_add		= str_to_uint2(s + 0x66 + 0x2a);
	pc->burst_shift		= str_to_uint2(s + 0x66 + 0x2c);
	pc->accum_shift		= str_to_uint2(s + 0x66 + 0x2e);
	pc->padj		= str_to_uint2(s + 0x66 + 0x30);
	
	pc->init_proc[0] = str_to_uint2(s + 0x98);
	pc->init_proc[1] = str_to_uint2(s + 0x9a);
	pc->init_proc[2] = str_to_uint2(s + 0x9c);
	pc->init_proc[3] = str_to_uint2(s + 0x9e);
	pc->eres_codes[0] = str_to_uint2(s + 0x66 + 0x3a);
	pc->eres_codes[1] = str_to_uint2(s + 0x66 + 0x3c);
	pc->eres_codes[2] = str_to_uint2(s + 0x66 + 0x3e);
	pc->eres_codes[3] = str_to_uint2(s + 0x66 + 0x40);
	pc->telemetry_modes[0] = str_to_uint2(s + 0x66 + 0x42);
	pc->telemetry_modes[1] = str_to_uint2(s + 0x66 + 0x44);
	pc->telemetry_modes[2] = str_to_uint2(s + 0x66 + 0x46);
	pc->telemetry_modes[3] = str_to_uint2(s + 0x66 + 0x48);
	pc->telemetry_modes[4] = str_to_uint2(s + 0x66 + 0x4a);
	pc->telemetry_modes[5] = str_to_uint2(s + 0x66 + 0x4c);
	pc->telemetry_modes[6] = str_to_uint2(s + 0x66 + 0x4e);
	pc->telemetry_modes[7] = str_to_uint2(s + 0x66 + 0x50);
	pc->int_period[0] = str_to_uint2(s + 0x66 + 0x52);
	pc->int_period[1] = str_to_uint2(s + 0x66 + 0x54);
	pc->int_period[2] = str_to_uint2(s + 0x66 + 0x56);
	pc->int_period[3] = str_to_uint2(s + 0x66 + 0x58);
	pc->int_period[4] = str_to_uint2(s + 0x66 + 0x5a);
	pc->int_period[5] = str_to_uint2(s + 0x66 + 0x5c);
	pc->int_period[6] = str_to_uint2(s + 0x66 + 0x5e);
	pc->int_period[7] = str_to_uint2(s + 0x66 + 0x60);
 	pc->bts_c_val = str_to_uint2(s + 0xc8);
 	
 	pc->A_a_bsize = s[0x66 + 0x64];
 	pc->A_b_bsize = s[0x66 + 0x65];
  	pc->B_a_bsize = s[0x66 + 0x66];
	pc->B_b_bsize = s[0x66 + 0x67];
	
	pc->tsum_min	= s[0x66 + 0x68];
	pc->tsum_max	= s[0x66 + 0x69];
	pc->beam_n1	= s[0x66 + 0x6a];
	pc->beam_n2	= s[0x66 + 0x6b];
	pc->ph_bst_shft	= s[0x66 + 0x6c];
	pc->ph_bst_msk	= s[0x66 + 0x6d];
	pc->ph_acc_shft	= s[0x66 + 0x6e];
	pc->ph_acc_msk	= s[0x66 + 0x6f];
	pc->bad_nrg	= s[0x66 + 0x70];
	pc->iconfig_crc = str_to_uint2(s + 0x66 + 0x72);
	
	for(i=0;i<0x66+0x72;i+=2)
		crc0 += str_to_uint2(s + i);
	
	if(pc->iconfig_crc == crc0)
		pc->valid = 1;
	else {
		pc->valid = 0;
		printf("PESA Config Checksum Error at %s: expected %x: received %x\r\n",
			time_to_YMDHMS(pk->time),crc0,pc->iconfig_crc);
	}

	return(1);                  
}

int4 pcfg_to_idl(int argc,void *argv[])
{
        pcfg_data *pcfg;
        Pconfig pc;
        int4 size,advance,index,*options,ok,i;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        packet *pk;

        if(argc == 0)
                return( number_of_packets(P_CFG_ID, 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        pcfg = (pcfg_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(P_CFG_ID,size,time);
            return(ok);
        }

        if(size != sizeof(pcfg_data)){
            printf("Incorrect structure size %d (should be %d).  Aborting.\r\n",size,sizeof(pcfg_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,P_CFG_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_LASTT(pks,time[0],P_CFG_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,P_CFG_ID) ;
        }
	
	pk = get_packet(&pks);
	pcfg->time = pk->time;
	pcfg->index = pks.index;
	
	for (i=0; i<218; i++)
		pcfg->data[i] = pk->data[i];
	
	decom_pconfig(pk,&pc);
	
	pcfg->valid = pc.valid;

        return(1);

}

