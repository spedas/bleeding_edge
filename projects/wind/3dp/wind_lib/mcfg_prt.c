#include "mcfg_prt.h"
#include "windmisc.h"
#include "mcfg_dcm.h"

#include <string.h>


FILE *main_cfg_fp;
FILE *main_cscb_fp;

int print_main_cscb_packet(packet *pk)
{
	if(main_cscb_fp==0)
		return(0);
	fprintf(main_cscb_fp,"%s\n",time_to_YMDHMS(pk->time));
	print_data_changes(main_cscb_fp,pk->data,pk->data,158);
	return(0);
}

int print_mconfig_packet(packet *pk)
{
	Mconfig mc;
	static uchar last_data[MCONFIG_SIZE];
	static int initialized;
	
	int different;
	int i;

/*	if(pk->dsize != MCONFIG_SIZE) */
/*		return(0); */

	if(! initialized)
		memcpy(last_data,current_main_config_data,MCONFIG_SIZE);
	
	decom_mconfig(pk,&mc);
	if (mc.valid == 1)
		different = memcmp(last_data,pk->data,MCONFIG_SIZE-16);
	else
		different = 0;

	if(different || !initialized){
		if(main_cfg_fp){
			fprintf(main_cfg_fp,"%s\n",time_to_YMDHMS(pk->time));
			if(different)
				fprintf(main_cfg_fp,"Warning! Main config has changed!!!\n");
			print_data_changes(main_cfg_fp,pk->data,last_data, pk->dsize);
		}
	}
	initialized++;
	memcpy(last_data,pk->data,MCONFIG_SIZE);
	return(different);
}

