#include "pcfg_prt.h"
#include "mem_dcm.h"

#include "windmisc.h"
#include "pesa_cfg.h"
#include "sweep_prt.h"

#include <string.h>
#include <stdio.h>

/* *********************    Printing routines:  ******************** */


int print_pcfg_changes(FILE *fp,packet *pk,uchar *last_data);
int print_pconfig_log(FILE *fp,Pconfig *pc);


FILE *pesa_cfg_fp;
FILE *pesa_cfg_raw_fp;
FILE *pesa_par_fp;
FILE *plswp_fp;
FILE *phswp_fp;
extern FILE *hkp_log_fp;

int print_pconfig_packet(packet *pk)
{
	Pconfig pc;
	static uchar last_data[PCONFIG_SIZE];
	static int first = 1;
	char chgstr[50];
	int different= 0;
	int i;
	
        set_PCFG(pk);   /* sets the pesa configuration */

	if(pesa_cfg_fp || hkp_log_fp || pesa_par_fp){
		if(first)
			memcpy(last_data,default_pcfg_data,PCONFIG_SIZE);
		decom_pconfig(pk,&pc);
		if (pc.valid == 1) {
		different = memcmp(pk->data,last_data,PCONFIG_SIZE);
/*		print_pconfig_log(hkp_log_fp,&pc); */
		if (different || first){
			print_pcfg_changes(pesa_cfg_fp,pk,last_data);
			print_pcfg_param(pesa_par_fp,pk);
		}
		if (different && !first && hkp_log_fp){
			sprintf(chgstr,"!  %s  12   PESA change: ",time_to_YMDHMS(pk->time));
			init_parameters(pesa_mem_par);
			print_param_changes(hkp_log_fp,pesa_mem_par,
				0x0000, pk->data, last_data, pk->dsize,
				chgstr);
		}
		first = 0;
		memcpy(last_data,pk->data,PCONFIG_SIZE);
		}
	}
#if 1
	if(plswp_fp){
		static int lvalid;
		PCFG *pcfg;
		pcfg = get_PCFG(pk->time);
		if(lvalid != pcfg->valid)
			print_sweep_pl(plswp_fp,pcfg);
		lvalid = pcfg->valid;
	}
	if(phswp_fp){
		static int lvalid;
		PCFG *pcfg;
		pcfg = get_PCFG(pk->time);
		if(lvalid != pcfg->valid)
			print_sweep_ph(phswp_fp,pcfg);
		lvalid = pcfg->valid;
	}
#endif
	return(different);
}




int print_pconfig_log(FILE *fp,Pconfig *pc)
{
	static Pconfig lastpcfg;
	static int init;
	int i;

	if(! init){
		init = 1;
		lastpcfg = *pc;
		return(0);
	}

	if(fp==0)
		return(0);

	i = 0;
/*  PESA Low parameters: */
	if(lastpcfg.pl_sweep.start_E != pc->pl_sweep.start_E){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_START_E %d KP!\n",pc->pl_sweep.start_E);
		i |= 1;
	}
	if(lastpcfg.pl_sweep.k_sw != pc->pl_sweep.k_sw){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_K_SW %d  KP!\n",pc->pl_sweep.k_sw);
		i |= 1;
	}
	if(lastpcfg.pl_sweep.s1 != pc->pl_sweep.s1){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_S1 %d  KP!\n",pc->pl_sweep.s1);
		i |= 1;
	}
	if(lastpcfg.pl_sweep.s2 != pc->pl_sweep.s2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_S2 %d  KP!\n",pc->pl_sweep.s2);
		i |= 1;
	}
	if(lastpcfg.pl_sweep.m2 != pc->pl_sweep.m2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_M2 %d  KP!\n",pc->pl_sweep.m2);
		i |= 1;
	}
	if(lastpcfg.pl_sweep.gs2 != pc->pl_sweep.gs2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PL_GS2 %d  KP!\n",pc->pl_sweep.gs2);
		i |= 1;
	}
/*  PESA High parameters: */
	if(lastpcfg.ph_sweep.start_E != pc->ph_sweep.start_E){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_START_E %d KP!\n",pc->ph_sweep.start_E);
		i |= 1;
	}
	if(lastpcfg.ph_sweep.k_sw != pc->ph_sweep.k_sw){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_K_SW %d  KP!\n",pc->ph_sweep.k_sw);
		i |= 1;
	}
	if(lastpcfg.ph_sweep.s1 != pc->ph_sweep.s1){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_S1 %d  KP!\n",pc->ph_sweep.s1);
		i |= 1;
	}
	if(lastpcfg.ph_sweep.s2 != pc->ph_sweep.s2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_S2 %d  KP!\n",pc->ph_sweep.s2);
		i |= 1;
	}
	if(lastpcfg.ph_sweep.m2 != pc->ph_sweep.m2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_M2 %d  KP!\n",pc->ph_sweep.m2);
		i |= 1;
	}
	if(lastpcfg.ph_sweep.gs2 != pc->ph_sweep.gs2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(pc->time1));
		fprintf(fp," 10  PH_GS2 %d  KP!\n",pc->ph_sweep.gs2);
		i |= 1;
	}
	if(i){
		fprintf(fp,"\n");
		lastpcfg = *pc;
	}
	return(1);
}

print_pcfg_changes(FILE *fp,packet *pk,uchar *last_data)
{
	if(fp==0)
		return(0);
	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
	print_data_changes(fp,pk->data,last_data, pk->dsize);
	return(1);
}

int print_pcfg_param(FILE *fp,packet *pk)
{
	if(fp==0)
		return(0);
	init_parameters(pesa_mem_par);
	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
	print_params(fp,pesa_mem_par, 0x0000, pk->data, pk->dsize);
	fprintf(fp,"\n");
	return(1);
}

