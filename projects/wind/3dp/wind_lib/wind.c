#include "frame_dcm.h"
#include "filter.h"

/*  Print routine prototypes:  */
#include "fpc_prt.h"
#include "emom_prt.h"
#include "pmom_prt.h"
#include "pads_prt.h"
#include "sst_prt.h"
#include "p3d_prt.h"
#include "frame_prt.h"
#include "hkp_prt.h"
#include "pckt_prt.h"
#include "pl_prt.h"
#include "sst_prt.h"
#include "spec_prt.h"
#include "kpd_prt.h"

#include "pcfg_prt.h"
#include "ecfg_prt.h"
#include "mcfg_prt.h"

#include "eAtoD_dcm.h"
#include "pAtoD_dcm.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int print_all_packets();
void test_plt_routines();
int test_hkp_routine();
void test_get_routines();

int file_commands(char *filename);
int search_cmd(char **strptr,char *cmds[]);
int open_print_file(char *ptype);
int misc_commands(char *cmd_string);
int process_command(char *cmd_string);
int flux_unit_string(char *cmd_string);

char *output_directory="";


main(int argc,char *argv[])
{
	char buffer[200];
	int i;
	for(i=1;i<argc;i++)
		file_commands(argv[i]);

	/* run interactively here */
	while(1){
		printf(">");
		gets(buffer);
		process_command(buffer);
	}

}




#define isterm(c)  ((c)==0 || isspace(c))

search_cmd(char **strptr,char *cmds[])
         /* matches strings; returning the number */
         /* and setting *strptr to the next word */
{
	int cmdnum,i,j,c;
	char *s,*p;

	while(isspace(**strptr))
		(*strptr)++;
	for(cmdnum=0;cmds[cmdnum] && *cmds[cmdnum];cmdnum++){
		for(p=cmds[cmdnum],s = *strptr; !isterm(*p) 
		        && tolower(*p)==tolower(*s);p++,s++)
				;
		if(isterm(*p) && isterm(*s)){
			while( isspace(*s) )
				s++;
			*strptr = s;
			return(cmdnum+1);
		}
	}
	return(0);
}


FILE *summary_fp;


typedef struct  {
	char *name   ;   FILE **fp; 
} print_list_struct;


print_list_struct print_file_list[] = {
	"unknown"  	,&unknown_pk_fp ,
	"pckt_log"   	,&pckt_log_fp   ,
	"summary"   	,&summary_fp    ,
	"elswp"   	,&elswp_fp 	,
	"ehswp"   	,&ehswp_fp 	,
	"plswp"   	,&plswp_fp 	,
	"phswp"   	,&phswp_fp 	,
	"pcfg"   	,&pesa_cfg_fp   ,
	"pcfg_par"	,&pesa_par_fp	,
	"mcfg"   	,&main_cfg_fp   ,
	"ecfg"   	,&eesa_cfg_fp   ,
	"ecfg_par"	,&ecfg_par_fp	,
	"excfg"   	,&eesa_xcfg_fp  ,
	"excfg_par"   	,&excfg_par_fp  ,
	"hkp_log"   	,&hkp_log_fp   ,
	"hkp_temp"   	,&hkp_temp_fp   ,
	"hkp_main"   	,&hkp_main_fp   ,
	"hkp_mvolts" 	,&hkp_mvolts_fp ,
	"hkp_eesa"   	,&hkp_eesa_fp   ,
	"hkp_pesa"	,&hkp_pesa_fp	,
	"hkp_smry"	,&hkp_sum_fp	,
	"hkp_accums"	,&hkp_bin_fp	,
	"eAtoD"   	,&eAtoD_fp	,
	"pAtoD"   	,&pAtoD_fp	,
	"kpd_raw"    	,&kpd_raw_fp	,
	"ekpd"    	,&ekpd_fp	,
	"pkpd"    	,&pkpd_fp	,
	"ekpd_raw"    	,&ekpd_raw_fp	,
	"pkpd_raw"    	,&pkpd_raw_fp	,
	"info"    	,&info_fp	,
	"emom"    	,&emom_fp	,
	"emom_raw"    	,&emom_raw_fp	,
	"emom_rraw"    	,&emom_rraw_fp	,
	"pmom"    	,&pmom_fp	,
	"pmom_raw"    	,&pmom_raw_fp	,
	"pmom_binary"   ,&pmom_binary_fp,
	"pmom_brst"    	,&pmom_brst_fp	,
	"elspec_auto"  	,&elspec_auto_fp,
	"el_spect"    	,&elspec_fp	,
	"eh_spect"    	,&ehspec_fp	,
	"pl_spect"    	,&plspec_fp	,
	"ph_spect"    	,&phspec_fp	,
	"pad"    	,&pads_fp	,
	"pad_spec"    	,&pads_spec_fp	,
	"pad_raw"    	,&pads_raw_fp	,
	"pad_log"    	,&pads_log_fp	,
	"plsnap5x5"    	,&plsnap5x5_fp	,
	"plsnap5x5_cut" ,&plsnap5x5_cut_fp	,
	"plsnap5x5_raw"	,&plsnap5x5_raw_fp	,
	"plsnap8x8"    	,&plsnap8x8_fp	,
	"plsnap8x8_raw"	,&plsnap8x8_raw_fp	,
	"plsnap8x8_draw",&plsnap8x8_draw_fp	,
	"ph3d"    	,&ph3d_fp	,
	"ph3d_raw"    	,&ph3d_raw_fp	,
	"phb3d_raw"    	,&phb3d_raw_fp	,
	"ph3d_log"    	,&ph3d_log_fp	,
	"phb3d_log"    	,&phb3d_log_fp	,
	"ph3d_spec"    	,&ph3d_spec_fp	,
	"ph3d_bins"    	,&ph3d_bins_fp	,
	"ph3d_cuts"    	,&ph3d_cuts_fp	,
	"ph3d_omni"    	,&ph3d_omni_fp	,
	"el3d"    	,&el3d_fp	,
	"el3d_raw"    	,&el3d_raw_fp	,
	"el3d_log"    	,&el3d_log_fp	,
	"el3d_spec"    	,&el3d_spec_fp	,
	"el3d_bins"    	,&el3d_bins_fp	,
	"el3d_cuts"    	,&el3d_cuts_fp	,
	"el3d_omni"    	,&el3d_omni_fp	,
	"eh3d"    	,&eh3d_fp	,
	"eh3d_raw"    	,&eh3d_raw_fp	,
	"eh3d_spec"    	,&eh3d_spec_fp	,
	"eh3d_bins"    	,&eh3d_bins_fp	,
	"eh3d_log"    	,&eh3d_log_fp	,
	"eh3d_cuts"    	,&eh3d_cuts_fp	,
	"eh3d_omni"    	,&eh3d_omni_fp	,
	"sst_rate"      ,&sst_rate_fp	,
	"sst_spectra"	,&s_spec_cond_fp,
	"sst_sprate" 	,&s_spec_rate_fp,
	"sst_0810_cal" 	,&s_0810_cal_fp, 
	"sst_3410" 	,&s_3410_fp, 
	"sst_3d_O" 	,&sst_3d_O_fp,   
	"sst_3d_F" 	,&sst_3d_F_fp,   
	"sst_343o"      ,&sst_3d_O_burst_fp,   
	"sst_343f"      ,&sst_3d_F_burst_fp,   
	"sst_342x"      ,&sst_3d_T_burst_fp,   
	"sst_3d_t" 	,&sst_3d_t_fp,   
	"sst_3d_O_accums",&sst_3d_O_accums_fp,
	"sst_3d_F_accums",&sst_3d_F_accums_fp,
	"mem_dump" 	,&memory_dump_fp,
	"epar_dump" 	,&eesa_dump_fp, 
	"main_cscb"	,&main_cscb_fp, 
	"eesa_cscb"	,&eesa_cscb_fp, 
	"fpc_dump_raw" 	,&fpc_dump_raw_fp,   
	"fpc_dump" 	,&fpc_dump_fp,   
	"fpc_xcorr_raw"	,&fpc_xcorr_raw_fp,   
	"fpc_xcorr" 	,&fpc_xcorr_fp,   
	"fpc_slice_raw"	,&fpc_slice_raw_fp,   
	"fpc_slice" 	,&fpc_slice_fp,   
	"el3d_accums"	,&el3d_accums_fp,
	"eh3d_accums"	,&eh3d_accums_fp,
	"ph3d_accums"	,&ph3d_accums_fp
};
#define NUM_PRINT_LIST (sizeof(print_file_list)/sizeof(print_list_struct))

static double ref_time;
static int nrg_units;


int set_esa_blank(char *cmdstr)
{
	char *cmds[] = {"el","eh","ph",""};
	int n,b,val,b1,b2;
	uchar *e_blank[] = { NULL, el_blank, eh_blank, ph_blank };
	uchar *blank;

	n = search_cmd(&cmdstr,cmds);
	blank = e_blank[n];
	if(!blank)
		return(0);
	b = MAX3DBINS;
	val = -1;
	sscanf(cmdstr,"%d %d",&b2,&val);
	if(b2>=MAX3DBINS){
		b2 = MAX3DBINS;
		b = 0;
	}
	else
		b = b2;
	do{
		blank[b] = (val==-1) ? !blank[b] : val;
		b++;
	}while(b<b2);

	return(1);
}


int dump_type(char *cmdstr)
{
	int dt,fmt,exppk;
	data_map_3d map;
	double time;
	FILE *fp;
	char buffer[200];
	uchar *blank;
	static packet_selector pks;

	static char *dtypes[] = {"el","ph","eh","elb","" };
	static char *formats[] = {"3d","spec","cuts","bins","omni","idl",""};
	dt = search_cmd(&cmdstr,dtypes);
	fmt = search_cmd(&cmdstr,formats);

	map.flux_units = flux_units;
	map.nrg_units = nrg_units;
	time = ref_time;
	if(dt==0 || fmt==0)
		return(0);

	SET_PKS_BY_TIME(pks,time,0) ;
	switch(dt){
	case 1:
	    pks.id = E3D_BRST_ID;
	    blank = el_blank;
	    exppk = 3;
	    break;
	case 2:	
	    pks.id = P3D_ID;
	    blank = ph_blank;
	    exppk = 4;
	    break;
	case 3:
	    pks.id = E3D_UNK_ID;
	    blank = eh_blank;
	    exppk = 3;
	    break;
	case 4:
	    pks.id = E3D_BRST_ID;
	    blank = el_blank;
	    exppk = 3;
	    break;
	default:
	    return(0);
	}
	get_next_p3d(&pks,&map,exppk);


	if(*cmdstr=='*'){
		cmdstr = time_to_YMDHMS(map.time)+1;
		cmdstr[8] = '.';
	}

	sprintf(buffer,"%s%s_%s.%s",output_directory,dtypes[dt-1], formats[fmt-1],cmdstr);

	fp = fopen(buffer,"w");
	switch(fmt){
	case 1:
		print_data_3d_gse(fp,&map);
		break;
	case 2:
		print_data_3d_spectra(fp,&map);
		break;
	case 3:
		print_data_3d_cuts(fp,&map,blank);
		break;
	case 4:
		print_data_3d_bins(fp,&map);
		break;
	case 5:
		print_data_3d_omni(fp,&map,blank);
		break;
	case 6:
		print_data_3d_idl(fp,&map);
		break;
	default:
		;
	}
	if(fp)
		fclose(fp);

	return(1);
}



get_sdt_interface(char *cmd)
{
	int n;
	FILE *fp;
	char filename[300];
	double t;
	static char *types[]={"pl5x5","sst_3dO","sst_3dF","eh_omni","pl8x8",""};
	char *type;

	n = search_cmd(&cmd,types);
	if(n==0){
		printf("the following are recognized:\n");
		while(*types[n]){
			printf("%-10s ",types[n]);
			if(n%6==5)
				printf("\n");
			n++;
		}
		printf("\n");
		return(0);
	}
	sprintf(filename,"%s%s",output_directory,types[n-1]);
	fp = fopen(filename,"w");
	if(fp==0)
		return(0);

	{
	    uint2 validmask;
	    switch(n){
	    case 1:    /* pl5x5 */
		{
		    packet_selector pks;
		    pl_snap_55 snap;
		    n = number_of_plsnap55_samples(0.,1e12);	
		    printf("%d samples\n",n);
		    t = 1.;  /* first sample */
		    SET_PKS_BY_TIME(pks,t,PLSNAP_ID);
		    while(get_next_plsnap55_struct(&pks,&snap)==1){
			print_plsnap5x5(fp,&snap);
			t = 0.;
		    }
		}
		break;;
	    case 2:   /* sst_3dO */
		{
		    sst_3d_O_distribution dist;
		    packet_selector pks;
		    n = number_of_sst_3d_O_samples(0.,1e12);
		    printf("%d samples\n",n);
		    t = 1.;    /* first sample */
		    SET_PKS_BY_TIME(pks,t,S_3D_O_ID);
		    while(get_next_sst_3d_O_str(&pks,&dist, 0, &validmask)==1){
			print_sst_3d_O_dist(fp,&dist);
			t = 0.;
		    }
		}
		break;;
	    case 3:   /* sst_3dF */
		{
		    sst_3d_F_distribution distrib;
		    packet_selector pks;
		    n = number_of_sst_3d_F_samples(0.,1e12);
		    printf("%d samples\n",n);
		    t = 1.;    /* first sample */
		    SET_PKS_BY_TIME(pks,t,S_3D_F_ID);
		    while(get_next_sst_3d_F_str(&pks,&distrib, 0, &validmask)==1){
			print_sst_3d_F_dist(fp,&distrib);
			t = 0.;
		    }
		}
		break;;
	    case 4:   /* eh_omni */
		{
		    spectra_3d_omni spec;
		    n = number_of_eh_omni_samples(0.,1e12);
		    printf("%d samples\n",n);
		    t = 1.;    /* first sample */
		    while(get_next_eh_omni_spec(t,&spec)==1){
			print_omni_spec(fp,&spec);
			t = 0.;
		    }
		}
		break;;
	    case 5:   /* pl8x8 */
		{
		    pl_snap_8x8 snap88;
		    static packet_selector pks;
		    n = number_of_plsnap88_samples(0.,1e12);
		    printf("%d samples\n",n);
		    t = 1.;    /* first sample */
		    SET_PKS_BY_TIME(pks,t,P_SNAP_BST_ID);
		    while(get_next_plsnap88_struct(&pks,&snap88)==1){
			print_plsnap8x8(fp,&snap88);
			t = 0.;
		    }
		}
		break;;

	    }
	}
	fclose(fp);
	return(1);
}




int open_print_file(char *ptype)
{
	int i;
	print_list_struct *pls;
	FILE *fp;
	char buf[300];
	
	print_all_packets();

	for(i=0;i<NUM_PRINT_LIST;i++){
		pls = &print_file_list[i];
		if(strcmp(ptype,pls->name)==0){
			if(pls->fp==0){
				printf("FP not initialized!\n");
				return(0);
			}
			if(*(pls->fp)){
				printf("File already opened!  Changing...\n");
				fclose(*(pls->fp));
			}
			sprintf(buf,"%s%s",output_directory, pls->name);
			fp = fopen(buf,"w");
			if(fp==0)
				printf("Unable to open file %s\n",buf);
			*(pls->fp) = fp;
			batch_print =1;
			return(1);
		}
	}
	printf("The following types are valid:");
	for(i=0;i<NUM_PRINT_LIST;i++){
		if(i%6==0) printf("\n");
		printf("%-12s ",print_file_list[i].name);
	}
	printf("\n");
	
	return(0);
}




close_all_dump_files()
{
	int i;
	print_list_struct *pls;
	
	print_all_packets();

	for(i=0;i<NUM_PRINT_LIST;i++){
		pls = &print_file_list[i];
		if(*(pls->fp)){
			fclose(*(pls->fp));
			*(pls->fp) = 0;
		}
	}
	return(0);
}




int file_commands(char *filename)
{
	FILE *fp;
	char buffer[200];
	char *p;
	int  i;
	static int level;

	fp = fopen(filename,"r");
	if(fp){
		level++;
		while(fgets(buffer,sizeof(buffer),fp)){
			if(p = strchr(buffer,'\n'))
				*p = 0;
			for(i=0;i<level;i++)
				printf("  ");
			printf("%s> %s\n",filename,buffer);
			process_command(buffer);
		}
		fclose(fp);
		level--;
	}
	else 
		printf("Unable to open file %s\n",filename);
	return(level);
}


int standard_commands(char *cmd_string)
{
	int n;
	static char *cmds[] = {"file","exit","" };
	n = search_cmd(&cmd_string,cmds);
	switch(n){
	case 1:  /* file */
		file_commands(cmd_string);
		break;
	case 2:  /* exit */
		exit(0);
		break;
	}
	return(n);
}


int misc_commands(char *cmd_string)
{
	int n;
	static char *cmds[] = {
		"print", "mastfile", "load", "begintime","endtime",
                "outputdir","memsize","reftime","flux_units","nrg_units",
		"blank","dump","close","get","deltat","ltperiod","help","" };

	static char mastfilename[81];
	static double begin_time,end_time;
	static double delta_time=24.;
	static char *bigmem;
	static int  memsize = 24 * 1024 * 1024;
	char  *s;
	static char * dump_string;
	print_list_struct *pls;
	extern double lt_sum_period;

	n = search_cmd(&cmd_string,cmds);
	switch(n){
	case 1:  /* print */
		open_print_file(cmd_string);
		break;
	case 2:  /* mastfile */
		strncpy(mastfilename,cmd_string,80);
		break;
	case 3:  /* load  */
		if(end_time < begin_time){         /*  process 1 day of data  */
			if(end_time <= 0)
				end_time = delta_time*3600.;
			end_time += begin_time;
		}
/*		printf("Loading data from:%s   ",time_to_YMDHMS(begin_time)); */
/*		printf("to:%s\n",time_to_YMDHMS(end_time)); */
		if(*mastfilename==0 && (s = getenv("WIND_DATA")))
			strncpy(mastfilename,s,80);
		if(*mastfilename==0 && (s = getenv("WIND_DATA_DIR")))
			sprintf(mastfilename,"%s/%s",s,"wi_lz_3dp_files");
		if(*mastfilename==0)
			strncpy(mastfilename,"mastfile",80);
		if(bigmem==0)
			bigmem = (char *) malloc(memsize);
		load_all_data_files(mastfilename,begin_time,end_time,
                           memsize,bigmem);
		if(summary_fp)
			print_packet_summary(summary_fp);
		ref_time = begin_time;
	case 13:
		close_all_dump_files();
		break;
	case 4:  /* begin time */
		begin_time = YMDHMS_to_time(cmd_string);
		break;
	case 5:  /* endtime */
		end_time = YMDHMS_to_time(cmd_string);
		break;
	case 6:  /* output */
		output_directory = strdup(cmd_string); /* small mem leak */
		break;
	case 7:  /* memsize */
		memsize = 1024 * 1024 * atoi(cmd_string);
		break;
	case 8:  /* reftime */
		ref_time = YMDHMS_to_time(cmd_string);
		break;
	case 9:  /* flux_units */
		flux_units = flux_unit_string(cmd_string);
		break;
	case 10:  /* nrg_units */
		nrg_units = atoi(cmd_string);
		break;
	case 11:  /* blank  */
		set_esa_blank(cmd_string);
		break;
	case 12: /* dump */
		dump_string = strdup(cmd_string);
		dump_type(cmd_string);
		break;
	case 14:  /* get */
		get_sdt_interface(cmd_string);
		break;
	case 15:  /* delta_time */
		delta_time = atof(cmd_string);
		break;
	case 16:  /* longterm time */
		lt_sum_period = atof(cmd_string);
		break;
	case 17:  /* help */
		{
		    char *flux_units_str[] = {"Default","Raw","Energy","Velocity","Angle",
					      "Cos Angle", "Counts", "NCounts", "Rate",
					      "EFlux", "Flux", "DistF"};
		    int i;
		    boolean_t first = B_TRUE;
		    double et;
		    
		    printf("Commands:\n\n");   /* be sure to add standard command list here*/
		    printf("%12s, %12s","file", "exit");
		    for (i=2 ; strlen(cmds[i-2]) ; i ++)
			printf("%s%12s", i%5? ", ":"\n", cmds[i-2]);
		    printf("\n\n");

		    printf("Settings:\n");
		    for(i=0;i<NUM_PRINT_LIST;i++){
			pls = &print_file_list[i];
			if(*(pls->fp)){
			    if (first)
				printf("\n  Print files:\n");
			    printf("    %-15s\n", pls->name);
			    first = B_FALSE;
			}
		    }
		    printf("\n");

		    if (strlen(mastfilename)) 
			printf("  Mastfile:         %s\n", mastfilename);
		    else
			printf("  Mastfile:         default\n");
		    if (strlen(output_directory)) 
			printf("  Output Directory: %s\n", output_directory);
		    else
			printf("  Output Directory: ./\n");
		    printf("  Begin Time:       %s\n", time_to_YMDHMS(begin_time));
		    et=end_time;
		    if(et < begin_time){   /* if end time not set, use deltat*/
			if(et <= 0) et = delta_time*3600.;
			et += begin_time;
		    }
		    printf("  End Time:         %s\n", time_to_YMDHMS(et));
		    printf("  Reference Time:   %s\n", time_to_YMDHMS(ref_time));	        
		    printf("  Memory Size:      %d Megabytes \n", memsize/(1024*1024));
		    printf("  Flux Units:       %s\n",flux_units_str[flux_units]);
		    printf("  Energy Units:     %d\n", nrg_units);
		    printf("  Longterm Period:  %.1lf Seconds\n", lt_sum_period);

		    printf("  Blanked Channels:  (25 Across-> )\n"
			   "    Eesa Low:");
		    for (i=0; i < MAX3DBINS; i ++)
			printf("%s%d", i%25? ", ":"\n    ", el_blank[i]);
		    printf("\n    Eesa High:");
		    for (i=0; i < MAX3DBINS; i ++)
			printf("%s%d", i%25? ", ":"\n    ", eh_blank[i]);
		    printf("\n    Peas High:");
		    for (i=0; i < MAX3DBINS; i ++)
			printf("%s%d", i%25? ", ":"\n    ", ph_blank[i]);
		    printf("\n");
		}
		break;
	}
	return(n);		
}



int flux_unit_string(char *cmd_string)
{
	int n;
	static char *cmds[] = {
                "counts","rate","eflux","flux","distf","" };

	n = search_cmd(&cmd_string,cmds);
	switch(n){
	case 1:  return(COUNTS_UNITS);
	case 2:  return(RATE_UNITS);
	case 3:  return(EFLUX_UNITS);
	case 4:  return(FLUX_UNITS);
	case 5:  return(DISTF_UNITS);
	default: return(DEFAULT_UNITS);
	}	
}



int process_command(char *cmd_string)
{
	if(*cmd_string == '#')             return(1);   /* comment */
	if(*cmd_string == 0)               return(1);   /* empty line */
	if(misc_commands(cmd_string)) 	   return(1);
	if(standard_commands(cmd_string))  return(1);
	else{
		fprintf(stderr,"Huh?\n");		
		 return(0);
	}
}




#if 0

void test_get_routines()
{
	test_hkp_routine();
}


int test_hkp_routine()
{
	hkpPktStruct hkp;
	int n;
	static packet_selector pks= PKS_BY_TIME_DEC (1.) (HKP_ID);

	hkp.time = 0;
	n=0;
	printf("%3d\n",number_of_hkp_samples(0.,1e10));
	while( get_next_hkp_struct(&pks,&hkp) ){
		printf("%3d  %s  %.4f\n",n,time_to_YMDHMS(hkp.time),hkp.fspin);
		n++;
	}
	printf("%3d\n",number_of_hkp_samples(0.,hkp.time));

	return(n);
}
#endif





int print_all_packets()
{

/*	debug = nfile("info"); */     /* opens debugging file */ 
/*	debug = stderr; */

        set_PCFG(0);  /* initialize pesa configuration. */

	add_packet_routine(E_A2D_ID,   print_eAtoD_packet);
	add_packet_routine(P_A2D_ID,   print_pAtoD_packet);
	add_packet_routine(P3D_BRST_ID,print_phb3d_packet);
	add_packet_routine(P3D_ID,     print_ph3d_packet);
	add_packet_routine(E3D_88_ID,  print_el3d_packet);
	add_packet_routine(E3D_UNK_ID, print_eh3d_packet);
	add_packet_routine(S_RATE_ID,  print_sst_rate_packet);
	add_packet_routine(S_RATE3_ID, print_sst_spectra_packet);
	add_packet_routine(S_RATE1_ID, print_sst_0810_packet);
	add_packet_routine(S_RS_BST_ID,print_sst_3410_packet);
	add_packet_routine(S_3D_O_ID,  print_sst_3d_O_packet);
	add_packet_routine(S_3D_F_ID,  print_sst_3d_F_packet);
	add_packet_routine(S_HS_BST_ID,print_sst_343x_O_packet);
	add_packet_routine(S_HS_BST_ID,print_sst_343x_F_packet);
	add_packet_routine(S_TBRST_ID, print_sst_342x_T_packet);
	add_packet_routine(S_T_DST_ID, print_sst_3d_t_packet);
	add_packet_routine(R_MEM_ID,   print_memory_dump_packet);
	add_packet_routine(M_MEM_ID,   print_main_cscb_packet);
	add_packet_routine(E_MEM_ID,   print_eesa_cscb_packet);
	add_packet_routine(INVALID_ID, print_unknown_packet);
	add_packet_routine(M_CFG_ID,   print_mconfig_packet);
	add_packet_routine(E_CFG_ID,   print_econfig_packet);
	add_packet_routine(E_XCFG_ID,  print_exconfig_packet);
	add_packet_routine(P_CFG_ID,   print_pconfig_packet);
	add_packet_routine(HKP_ID,     print_hkp_packet);
	add_packet_routine(KPD_ID,     print_kpd_packet);
	add_packet_routine(FRM_INFO_ID,print_frameinfo_packet);
	add_packet_routine(PSPECT_ID,  print_pesa_spectra);
	add_packet_routine(ESPECT_ID,  print_eesa_spectra);
	add_packet_routine(EMOM_ID,    print_emom_packet);
	add_packet_routine(PMOM_ID,    print_pmom_packet);
	add_packet_routine(EHPAD_ID,   print_pads_packet);
	add_packet_routine(PLSNAP_ID,  print_plsnap5x5_packet);
	add_packet_routine(P_SNAP_BST_ID,  print_plsnap8x8_packet);
	add_packet_routine(FPC_DUM_ID, print_fpc_dump_packet);
	add_packet_routine(FPC_D_ID,   print_fpc_xcorr_packet);
	add_packet_routine(FPC_P_ID,   print_fpc_slice_packet);
	add_packet_routine(E3D_CUT_ID, print_elc3d_packet);

	return(1);
	
}



