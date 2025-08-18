#include "ecfg_dcm.h"
#include "mem_dcm.h"
#include "windmisc.h"
#include "sweep_prt.h"

#include "string.h"

FILE *eesa_xcfg_fp;
FILE *excfg_par_fp;

FILE *eesa_cfg_fp;
FILE *ecfg_par_fp;
FILE *eesa_sweep_par_fp;

FILE *elswp_fp;
FILE *ehswp_fp;
FILE *eesa_cscb_fp;
extern FILE *hkp_log_fp;


/***** Function Prototypes  ****/

int print_econfig_log(FILE *fp,Econfig *vp);
int print_eesa_sweep_values(FILE *fp,Econfig *vartemp);
int print_excfg_param(FILE *fp,packet *pk);
int print_ecfg_changes(FILE *fp,packet *pk,uchar *last_data);
int print_excfg_changes(FILE *fp,packet *pk,uchar *last_data);




/*  STANDARD print routines...  */

int print_eesa_cscb_packet(packet *pk)
{
	if(eesa_cscb_fp==0)
		return(0);
	fprintf(eesa_cscb_fp,"%s\n",time_to_YMDHMS(pk->time));
	print_data_changes(eesa_cscb_fp,pk->data,pk->data,0xb6);
	return(0);
}

/*  This routine is called whenever an eesa normal configuration packet is
    encountered.  */
int print_econfig_packet(packet *pk)
{
	Econfig ec;
	static uchar last_data[ECONFIG_SIZE];
	char chgstr[50];
	static int first = 1;
	int different= 0;
	int i;

	if((check_econfig_pk_validity(pk)) && (hkp_log_fp || ecfg_par_fp || 
		eesa_cfg_fp || eesa_sweep_par_fp)){
		if(first)
			memcpy(last_data,default_ecfg_data,ECONFIG_SIZE);
		decom_econfig(pk,&ec);
		different = memcmp(pk->data,last_data,ECONFIG_SIZE);
/*		print_econfig_log(hkp_log_fp,&ec); */
		if(different || first){
			print_ecfg_changes(eesa_cfg_fp,pk,last_data);
			print_eesa_sweep_values(eesa_sweep_par_fp,&ec);
			print_ecfg_param(ecfg_par_fp,pk);
		}
		if(different && !first && hkp_log_fp){
			sprintf(chgstr,"!  %s  12   EESA change: ",time_to_YMDHMS(pk->time));
			init_parameters(eesa_cfg_par);
			print_param_changes(hkp_log_fp,eesa_cfg_par,
				0x0000, pk->data, last_data, pk->dsize,
				chgstr);
		}
		memcpy(last_data,pk->data,ECONFIG_SIZE);
		first = 0;
	}
#if 1
	if(elswp_fp){
		static int lvalid;
		ECFG *ecfg;
		ecfg = get_ECFG(pk->time);
		if(lvalid != ecfg->valid)
			print_sweep_el(elswp_fp,ecfg);
		lvalid = ecfg->valid;
	}
	if(ehswp_fp){
		static int lvalid;
		ECFG *ecfg;
		ecfg = get_ECFG(pk->time);
		if(lvalid != ecfg->valid)
			print_sweep_eh(ehswp_fp,ecfg);
		lvalid = ecfg->valid;
	}
#endif

	return(different);
}







/*  This routine is called whenever an eesa extended configuration packet is
    encountered.  */

int print_exconfig_packet(packet *pk)
{
	EXconfig ec;
	static uchar last_data[EXCONFIG_SIZE];
	static int first = 1;
	char chgstr[50];
	int different= 0;
	int i;

	if(excfg_par_fp || eesa_xcfg_fp || hkp_log_fp){
		if(first)
			memcpy(last_data,default_excfg_data,EXCONFIG_SIZE);
		decom_exconfig(pk,&ec);
		different = memcmp(pk->data,last_data,0xed);
		if(different || first)
			print_excfg_changes(eesa_xcfg_fp,pk,last_data);
		if(different || first)
			print_excfg_param(excfg_par_fp,pk);
		if (different && !first){
			sprintf(chgstr,"!  %s  12   EESAX change: ",time_to_YMDHMS(pk->time));
			init_parameters(eesa_mem_par);
			print_param_changes(hkp_log_fp,eesa_mem_par,
				0x017c, pk->data, last_data, pk->dsize,
				chgstr);
		}
		memcpy(last_data,pk->data,EXCONFIG_SIZE);
		first = 0;
	}

	return(different);
}




/**** Misc. print routines ******/



int print_econfig_log(FILE *fp,Econfig *vp)
{
	static Econfig lastecfg;
	static int init;
	int i;

	if(! init){
		init = 1;
		lastecfg = *vp;
		return(0);
	}

	if(fp==0)
		return(0);
	i = 0;
/*  EESA Low parameters: */
	if(lastecfg.mcpl != vp->mcpl){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   MCPL %d KP!\n",vp->mcpl);
		i |= 1;
	}
	if(lastecfg.el_sweep.start_E != vp->el_sweep.start_E){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_START_E %d KP!\n",vp->el_sweep.start_E);
		i |= 1;
	}
	if(lastecfg.el_sweep.k_sw != vp->el_sweep.k_sw){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_K_SW %d  KP!\n",vp->el_sweep.k_sw);
		i |= 1;
	}
	if(lastecfg.el_sweep.s1 != vp->el_sweep.s1){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_S1 %d  KP!\n",vp->el_sweep.s1);
		i |= 1;
	}
	if(lastecfg.el_sweep.s2 != vp->el_sweep.s2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_S2 %d  KP!\n",vp->el_sweep.s2);
		i |= 1;
	}
	if(lastecfg.el_sweep.m2 != vp->el_sweep.m2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_M2 %d  KP!\n",vp->el_sweep.m2);
		i |= 1;
	}
	if(lastecfg.el_sweep.gs2 != vp->el_sweep.gs2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EL_GS2 %d  KP!\n",vp->el_sweep.gs2);
		i |= 1;
	}
/*  EESA High parameters: */
	if(lastecfg.mcph != vp->mcph){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   MCPH %d KP!\n",vp->mcph);
		i |= 1;
	}
	if(lastecfg.eh_sweep.start_E != vp->eh_sweep.start_E){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_START_E %d KP!\n",vp->eh_sweep.start_E);
		i |= 1;
	}
	if(lastecfg.eh_sweep.k_sw != vp->eh_sweep.k_sw){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_K_SW %d  KP!\n",vp->eh_sweep.k_sw);
		i |= 1;
	}
	if(lastecfg.eh_sweep.s1 != vp->eh_sweep.s1){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_S1 %d  KP!\n",vp->eh_sweep.s1);
		i |= 1;
	}
	if(lastecfg.eh_sweep.s2 != vp->eh_sweep.s2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_S2 %d  KP!\n",vp->eh_sweep.s2);
		i |= 1;
	}
	if(lastecfg.eh_sweep.m2 != vp->eh_sweep.m2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_M2 %d  KP!\n",vp->eh_sweep.m2);
		i |= 1;
	}
	if(lastecfg.eh_sweep.gs2 != vp->eh_sweep.gs2){
		fprintf(fp,"!  %s ",time_to_YMDHMS(vp->time1));
		fprintf(fp," 10   EH_GS2 %d  KP!\n",vp->eh_sweep.gs2);
		i |= 1;
	}
	if(i){
		fprintf(fp,"\n");
		lastecfg = *vp;
	}
}


int print_ecfg_changes(FILE *fp,packet *pk,uchar *last_data)
{
	if(fp==0)
		return(0);

	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
/*	if(different)
/*		fprintf(fp,"Warning! EESA config has changed!!!\n"); */ 
	print_data_changes(fp,pk->data,last_data, pk->dsize);
	return(1);
}



int print_eesa_sweep_values(FILE *fp,Econfig *vp)
{

	if(fp==0)
		return(0);
	fprintf(fp,"Time: %s\n",time_to_YMDHMS(vp->time1));
	fprintf(fp,"EESAL:");
	fprintf(fp,"  %s %04X","start_E",vp->el_sweep.start_E);
	fprintf(fp,"  %s %04X","k_sw",vp->el_sweep.k_sw);
	fprintf(fp,"  %s %04X","s1",vp->el_sweep.s1);
	fprintf(fp,"  %s %04X","s2",vp->el_sweep.s2);
	fprintf(fp,"  %s %04X","m2",vp->el_sweep.m2);
	fprintf(fp,"  %s %04X\n","gs2",vp->el_sweep.gs2);
	fprintf(fp,"EESAH:");
	fprintf(fp,"  %s %04X","start_E",vp->eh_sweep.start_E);
	fprintf(fp,"  %s %04X","k_sw",vp->eh_sweep.k_sw);
	fprintf(fp,"  %s %04X","s1",vp->eh_sweep.s1);
	fprintf(fp,"  %s %04X","s2",vp->eh_sweep.s2);
	fprintf(fp,"  %s %04X","m2",vp->eh_sweep.m2);
	fprintf(fp,"  %s %04X\n","gs2",vp->eh_sweep.gs2);
	fprintf(fp,"\n");
	return(1);
}




int print_excfg_changes(FILE *fp,packet *pk,uchar *last_data)
{
	static int initialized;

	if(fp==0)
		return(0);

	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
/*	if(different)
		fprintf(fp,"Warning! EESA extended config has changed!!!\n"); */
	print_data_changes(fp,pk->data,last_data, pk->dsize);
	return(1);
}

int print_ecfg_param(FILE *fp,packet *pk)
{
	if(fp==0)
		return(0);
	init_parameters(eesa_cfg_par);
	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
	print_params(fp,eesa_cfg_par, 0x0000, pk->data, pk->dsize);
	fprintf(fp,"\n");
	return(1);
}

int print_excfg_param(FILE *fp,packet *pk)
{
	if(fp==0)
		return(0);
	init_parameters(eesa_mem_par);
	fprintf(fp,"%s\n",time_to_YMDHMS(pk->time));
	print_params(fp,eesa_mem_par, 0x017c, pk->data, pk->dsize);
	fprintf(fp,"\n");
	return(1);
}



