#include "hkp_dcm.h"
#include "windmisc.h"


/*---------------------------------------------------------------------------*/

/* public stuff  */

FILE *hkp_main_fp;
FILE *hkp_mvolts_fp;
FILE *hkp_pesa_fp;
FILE *hkp_eesa_fp;
FILE *hkp_temp_fp;
FILE *hkp_log_fp;
extern FILE *hkp_sum_fp;
FILE *hkp_bin_fp;



/*---------------------------------------------------------------------------*/

/*   private structures and subroutines:   */  

typedef struct{
	char inst_mode[9];
/*	char mode[8];  */
	char last_cmd[11];
	char main_status[9];
	char eesa_status[9];
	char pesa_status[9];
	char brst_status[8];
	char errors[33];
} hkpstrings;


int print_hkp_struct_main(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_mvolts(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_pesa(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_eesa(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_temp(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_log(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_sum(FILE *fp, hkpPktStruct *hkp);
int print_hkp_struct_bin(FILE *fp, hkpPktStruct *hkp);
int get_hkp_strings(hkpstrings *str, hkpPktStruct *hkp);




/*---------------------------------------------------------------------------*/

int print_hkp_packet(packet *pk)
{
	static hkpPktStruct hkp;

	if(hkp_main_fp || hkp_mvolts_fp || hkp_pesa_fp || hkp_eesa_fp 
               || hkp_temp_fp || hkp_log_fp || hkp_sum_fp || hkp_bin_fp){
		fill_hkp_struct(pk,&hkp);
		print_hkp_struct_main(hkp_main_fp,&hkp);
		print_hkp_struct_mvolts(hkp_mvolts_fp,&hkp);
		print_hkp_struct_pesa(hkp_pesa_fp,&hkp);
		print_hkp_struct_eesa(hkp_eesa_fp,&hkp);
		print_hkp_struct_temp(hkp_temp_fp,&hkp);
		print_hkp_struct_log(hkp_log_fp,&hkp);
		print_hkp_struct_bin(hkp_bin_fp,&hkp);
		print_hkp_struct_sum(hkp_sum_fp,&hkp);
	}
	return(1);
}


double lt_sum_period;

int print_hkp_struct_bin(FILE *fp, hkpPktStruct *hkp)
{
    static int ns;
    static hkpPktStruct avg;
    static double time0;

    if(fp == 0) return(0);
    if(hkp->valid == 0) return(0);
    if(hkp->time < time0  || hkp->time > time0+lt_sum_period) {
        if(ns && hkp->time >= time0){
            avg.time /= ns;
            avg.fspin /= ns;
            avg.main_p5 /= ns;
            avg.main_m5 /= ns;
            avg.main_p12 /= ns;
            avg.main_m12 /= ns;
            avg.sst_p9 /= ns;
            avg.sst_p5 /= ns;
            avg.sst_m4 /= ns;
            avg.sst_m9 /= ns;
            avg.sst_hv /= ns;
            avg.eesa_p5 /= ns;
            avg.eesa_p12 /= ns;
            avg.eesa_m12 /= ns;
            avg.eesa_mcpl /= ns;
            avg.eesa_mcph /= ns;
            avg.eesa_pmt /= ns;
            avg.eesa_swpl /= ns;
            avg.eesa_swph /= ns;
            avg.pesa_p5 /= ns;
            avg.pesa_p12 /= ns;
            avg.pesa_mcpl /= ns;
            avg.pesa_mcph /= ns;
            avg.pesa_pmt /= ns;
            avg.pesa_swpl /= ns;
            avg.pesa_swph /= ns;
            avg.eesa_temp /= ns;
            avg.pesa_temp /= ns;
            avg.sst1_temp /= ns;
            avg.sst3_temp /= ns;
            
            fwrite(&avg,sizeof(avg),1,fp);  /* store  */
        }
        memset(&avg,0,sizeof(avg));     /* clear memory */
        ns = 0;
    }
    if(1) {
        if(ns == 0){
            avg = *hkp;
            time0 = hkp->time;
        }
        else{
            avg.time += hkp->time;
            avg.fspin += hkp->fspin;
            avg.main_p5 += hkp->main_p5;
            avg.main_m5 += hkp->main_m5;
            avg.main_p12 += hkp->main_p12;
            avg.main_m12 += hkp->main_m12;
            avg.sst_p9 += hkp->sst_p9;
            avg.sst_p5 += hkp->sst_p5;
            avg.sst_m4 += hkp->sst_m4;
            avg.sst_m9 += hkp->sst_m9;
            avg.sst_hv += hkp->sst_hv;
            avg.eesa_p5 += hkp->eesa_p5;
            avg.eesa_p12 += hkp->eesa_p12;
            avg.eesa_m12 += hkp->eesa_m12;
            avg.eesa_mcpl += hkp->eesa_mcpl;
            avg.eesa_mcph += hkp->eesa_mcph;
            avg.eesa_pmt += hkp->eesa_pmt;
            avg.eesa_swpl += hkp->eesa_swpl;
            avg.eesa_swph += hkp->eesa_swph;
            avg.pesa_p5 += hkp->pesa_p5;
            avg.pesa_p12 += hkp->pesa_p12;
            avg.pesa_mcpl += hkp->pesa_mcpl;
            avg.pesa_mcph += hkp->pesa_mcph;
            avg.pesa_pmt += hkp->pesa_pmt;
            avg.pesa_swpl += hkp->pesa_swpl;
            avg.pesa_swph += hkp->pesa_swph;
            avg.eesa_temp += hkp->eesa_temp;
            avg.pesa_temp += hkp->pesa_temp;
            avg.sst1_temp += hkp->sst1_temp;
            avg.sst3_temp += hkp->sst3_temp;
            avg.burst_stat |= hkp->burst_stat;
        }
        ns++;
    }

    return(1);
}



#if 0

int print_hkp_struct_all( FILE *fp, hkpPktStruct *hkp)
{
	
	struct hkpstrings str;

	get_hkp_strings(hkp,&str);

	if(fp==0)
		return(0);

#if 0
242/86  6050/65/0030      3D PLASMA FGSE I&T Rev:4.1        08/21/94 18:49:23   
      S/C            MAIN         EESA          PESA       PKT CNT    %   %TOT  
  Mode: 81       Ver#  45     Ver#  43      Ver#  43        #0  29  87.2  87.2  
  S/1X/E         Stat: 67     Stat: 23      Stat: 23        #1  2    1.2   1.2  
 Frame: 1       LstEr: 67    LstEr: 00     LstEr: 00        #2  2    1.2   1.2  
   Off: 29       Errs: 1      Errs: 0       Errs: 0         #3  0    0.0   0.0  
  Spin: 0005.0  Reset: 1     Reset: 1      Reset: 1         #4  0    0.0   0.0  
 MagAz: 0         +5V: 5.0   +5VBm: 5.0    +5VBm: 5.0       #5  3    6.5   6.5  
 MagEl: 0         -5V: -5.0   +12V: 12.0    +12V: 12.0      #6  2    6.1   6.1  
 Burst: 01       +12V: 12.1   -12V: -12.3   -12V: -12.1     #7  0    0.0   0.0  
 #Cmds: 5        -12V: -12.1  MCPL: 44      MCPL: -88       Packets: 38         
 A0D7000000       +9V: 9.0    MCPH: 0       MCPH: -89         Bytes: 12077      
                  +5V: 5.0     PMT: 59       PMT: 30                            
    STATUS        -5V: -5.0   SWPL: 0       SWPL: 0               EESA    PESA  
Sync: 70          -9V: -9.1   SWPH: 0       SWPH: 0        L0: 0       0        
 Rec:  Raw         HV: 0    TH:23.0  23.4  23.4  23.4      L1: 0       0        
Mode: Sci+Th                                               H0: 0       0        
Mask: FF/F0/00  O6: 0          SST C/SPIN  F2: 0           H1: 0       0        
Seld: 02/20/00  O2: 0        O1: 0         F3: 0          H16: 0       0        
 Pkt: 00/00/00  O3: 0        T2: 0         F4: 0          H17: 0       0        
Time: 0000      O4: 0        T6: 0         F5: 0                                
                O5: 0        F6: 0         F1: 0                                
#endif

    fprintf(fp,"House Keeping Parameters:  %s\n",time_to_YMDHMS(hkp->time));
    fprintf(fp,"   S/C             MAIN        EESA        PESA    \n");
    fprintf(fp,"Mode:%8s   Ver# %02x  Ver# %02x  Ver#%02x\n", 
        str->inst_mode,hkp->main_version, hkp->eesa_version,hkp->pesa_version);
    fprintf(fp,"Frame:%3d   stat: %02x  Ver# %02x  Ver#%02x\n", 
        str->inst_mode,hkp->main_version, hkp->eesa_version,hkp->pesa_version);

}
#endif



int print_hkp_struct_main( FILE *fp, hkpPktStruct *hkp)
{
	int i;
/*	char *fmt; */

	static int lastreset=-1;
	double fspin;
	hkpstrings str;
 
	
	if(fp==0)
		return(0);

	if(lastreset != hkp->main_num_resets){      /* reset */
		fprintf(fp,"\n");	
		fprintf(fp,"`  Time           "); 
		fprintf(fp," Seq"); 
/*		fprintf(fp," fspin  ");
/*		fprintf(fp,"  maz mel "); */
/*		fprintf(fp,"  +5 "); */
/*		fprintf(fp,"   -5 "); */
/*		fprintf(fp,"  +12 "); */
/*		fprintf(fp,"   -12 "); */ 
		fprintf(fp," rsts");
		fprintf(fp," ver");
		fprintf(fp," #com lastcmd  ");
		fprintf(fp," errs lst");
		fprintf(fp,"    STATUS ");
		fprintf(fp,"   BURST-#");
		fprintf(fp,"   mode ");
		fprintf(fp,"\n");
	}

	fspin =  ((double)hkp->spin+(double)hkp->phase)/16.;
/*	fmt = inst_mode_str(hkp->inst_mode); */
	get_hkp_strings(&str, hkp);

	fprintf(fp,"%s ",time_to_YMDHMS(hkp->time));
/*	fprintf(fp,"%9.0f ",hkp->time); */
	fprintf(fp," %3d",hkp->frame_seq);
/*	fprintf(fp," %8.3f",fspin);
/*	fprintf(fp," %4d %3d",hkp->magaz,hkp->magel); */
/*	fprintf(fp," %4.2f",hkp->main_p5); */
/*	fprintf(fp," %5.2f",hkp->main_m5); */
/*	fprintf(fp," %5.2f",hkp->main_p12); */
/*	fprintf(fp," %6.2f",hkp->main_m12); */ 
	fprintf(fp," %3d ",hkp->main_num_resets);
	fprintf(fp," %02x ",hkp->main_version);
	fprintf(fp," %3d %s ",hkp->num_commands,str.last_cmd);
	fprintf(fp," %3d  %02x ",hkp->main_num_errors,hkp->main_last_error);
	fprintf(fp," <%s>",bit_pattern(hkp->main_status,"QBHPESep","        "));
	fprintf(fp," <%s-%2d>",bit_pattern(hkp->main_burst_stat >> 4,"P210",
"    "),
		hkp->main_burst_stat & 0xf);
	fprintf(fp," <%s>",bit_pattern(hkp->inst_mode,"Ex..2BMS","        "));
/*	fprintf(fp," %s",fmt); */
	fprintf(fp,"\n");
	lastreset = hkp->main_num_resets;
	return(1);
}

#include "frame_dcm.h"

int print_hkp_struct_log( FILE *fp, hkpPktStruct *hkp)
{
	int i,n;
	static int init;
	static hkpPktStruct lasthkp;
	hkpstrings str;
 
	if(fp==0)
		return(0);

	get_hkp_strings(&str, hkp);

	if(hkp->errors & ERROR_TELEM){
/*		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
/*		fprintf(fp," 0   Telemetry Errors: <%s>\n\n",str.errors); */ 
		return(0);
	}

	if(! init){
		init = 1;
		lasthkp = *hkp;
		return(0);
	}

	i = 0;

	if(lasthkp.main_version != hkp->main_version){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   MAIN Version: %2x\n",hkp->main_version);
		i |= 1;
	}
	if(lasthkp.pesa_version != hkp->pesa_version){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   PESA Version: %2x\n",hkp->pesa_version);
		i |= 1;
	}
	if(lasthkp.eesa_version != hkp->eesa_version){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   EESA Version: %2x\n",hkp->eesa_version);
		i |= 1;
	}


	if(lasthkp.main_num_resets != hkp->main_num_resets){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   MAIN Reset (%d)\n",hkp->main_num_resets);
		i |= 1;
	}
	if(lasthkp.pesa_num_resets != hkp->pesa_num_resets){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   PESA Reset (%d)\n",hkp->pesa_num_resets);
		i |= 1;
	}
	if(lasthkp.eesa_num_resets != hkp->eesa_num_resets){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 10   EESA Reset (%d)\n",hkp->eesa_num_resets);
		i |= 1;
	}


	if(lasthkp.num_commands != hkp->num_commands){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		n = hkp->num_commands - lasthkp.num_commands;
		if(n<0)
			n+=256;
		fprintf(fp," 10   Command #%d (%d) [%s] \n", 
                    hkp->num_commands, n, str.last_cmd);
		i |= 1;
	}


	if((lasthkp.inst_mode != hkp->inst_mode) &&
		(lasthkp.inst_mode != hkp->inst_mode + 4) &&
		(lasthkp.inst_mode != hkp->inst_mode - 4)){
		fprintf(fp,"!  %s ",time_to_YMDHMS(hkp->time));
		fprintf(fp," 30   New mode: <%s>\n",str.inst_mode);
		i |= 1;
	}

/*	fprintf(fp," <%s>",bit_pattern(hkp->main_status,"QBHPESep","        ")); */
	if(i)
		fprintf(fp,"\n");
	lasthkp = *hkp;
	return(1);
}



int print_hkp_struct_temp( FILE *fp, hkpPktStruct *hkp)
{
	static double lasttime;

	if(fp==0)
		return(0);

	if(hkp->time > lasttime + 93.){
		fprintf(fp,"\n");
		fprintf(fp,"`  Time    "); 
		fprintf(fp," Pesa ");
		fprintf(fp," Eesa ");
		fprintf(fp," SST1 ");
		fprintf(fp," SST3 ");
		fprintf(fp,"\n");
	}
	fprintf(fp,"%9.0f ",hkp->time);
	fprintf(fp," %5.1f",hkp->sst1_temp);
	fprintf(fp," %5.1f",hkp->sst3_temp);
	fprintf(fp," %5.1f",hkp->pesa_temp);
	fprintf(fp," %5.1f",hkp->eesa_temp);
	fprintf(fp," %s",time_to_YMDHMS(hkp->time));
	fprintf(fp,"\n");

	lasttime = hkp->time;
	return(1);
}

int print_hkp_struct_mvolts( FILE *fp, hkpPktStruct *hkp)
{
	int i;
/*	char *fmt; */

	static int lastreset=-1;
	double fspin;

 
	
	if(fp==0)
		return(0);

	if(lastreset != hkp->main_num_resets){      /* reset */
		fprintf(fp,"\n");	
		fprintf(fp,"   Time   "); 
		fprintf(fp," Seq"); 
		fprintf(fp," fspin  ");
		fprintf(fp,"  maz mel ");
		fprintf(fp,"  +5 ");
		fprintf(fp,"   -5 ");
		fprintf(fp,"  +12 ");
		fprintf(fp,"   -12 ");
		fprintf(fp,"  +5 ");
		fprintf(fp,"   -5 ");
		fprintf(fp,"   +9 ");
		fprintf(fp,"    -9 ");
		fprintf(fp," Temp1");
		fprintf(fp," Temp3");
		fprintf(fp,"     Time  ");
		fprintf(fp,"\n");
	}

	fspin =  ((double)hkp->spin+(double)hkp->phase)/16.;
/*	fmt = inst_mode_str(hkp->inst_mode); */

	fprintf(fp,"%9.0f ",hkp->time);
	fprintf(fp," %3d",hkp->frame_seq);
	fprintf(fp," %8.3f",fspin);
	fprintf(fp," %4d %3d",hkp->magaz,hkp->magel);
	fprintf(fp," %4.2f",hkp->main_p5);
	fprintf(fp," %5.2f",hkp->main_m5);
	fprintf(fp," %5.2f",hkp->main_p12);
	fprintf(fp," %6.2f",hkp->main_m12);
	fprintf(fp," %4.2f",hkp->sst_p5);
	fprintf(fp," %5.2f",hkp->sst_m4);
	fprintf(fp," %5.2f",hkp->sst_p9);
	fprintf(fp," %6.2f",hkp->sst_m9);
	fprintf(fp," %5.1f",hkp->sst1_temp);
	fprintf(fp," %5.1f",hkp->sst3_temp);
	fprintf(fp," %s",time_to_YMDHMS(hkp->time));
	fprintf(fp,"\n");
	lastreset = hkp->main_num_resets;
	return(1);
}



int print_hkp_struct_pesa( FILE *fp, hkpPktStruct *hkp)
{
	int i;
/*	char *fmt;  */

	static int lastreset=-1;
	double fspin;


	if(fp==0)
		return(0);

	if(lastreset != hkp->pesa_num_resets){      /* reset */
		fprintf(fp,"\n");	
		fprintf(fp,"   Time   "); 
		fprintf(fp," Seq"); 
/*		fprintf(fp," fspin  ");
/*		fprintf(fp,"  maz mel "); */ 
		fprintf(fp,"  +5 ");
		fprintf(fp,"  +12 ");
		fprintf(fp,"   -12 ");
		fprintf(fp," SwpL ");
		fprintf(fp," SwpH ");
		fprintf(fp," PMT  ");
		fprintf(fp," TempP");
		fprintf(fp," rsts");
		fprintf(fp," ver");
		fprintf(fp," errs lst");
		fprintf(fp,"    STATUS ");
		fprintf(fp,"     Time\n");
	}

	fspin =  ((double)hkp->spin+(double)hkp->phase)/16.;
/*	fmt = inst_mode_str(hkp->inst_mode); */

	fprintf(fp,"%9.0f ",hkp->time);
	fprintf(fp," %3d",hkp->frame_seq);
/*	fprintf(fp," %8.3f",fspin);
/*	fprintf(fp," %4d %3d",hkp->magaz,hkp->magel); */ 
	fprintf(fp," %4.2f",hkp->pesa_p5);
	fprintf(fp," %5.2f",hkp->pesa_p12);
	fprintf(fp," %6.2f",hkp->pesa_m12);
	fprintf(fp," %5.0f",hkp->pesa_swpl);
	fprintf(fp," %5.0f",hkp->pesa_swph);
	fprintf(fp," %5.0f",hkp->pesa_pmt);
	fprintf(fp," %5.1f",hkp->pesa_temp);
	fprintf(fp," %3d ",hkp->pesa_num_resets);
	fprintf(fp," %02x ",hkp->pesa_version);
	fprintf(fp," %3d  %02x ",hkp->pesa_num_errors,hkp->pesa_last_error);
	fprintf(fp," <%s>",bit_pattern(hkp->pesa_status,"QVH...BP","        "));
	fprintf(fp," %s",time_to_YMDHMS(hkp->time));
	fprintf(fp,"\n");
	lastreset = hkp->pesa_num_resets;
	return(1);
}

int print_hkp_struct_eesa( FILE *fp, hkpPktStruct *hkp)
{
	int i;
/*	char *fmt; */

	static int lastreset=-1;
	double fspin;


	if(fp==0)
		return(0);

	if(lastreset != hkp->eesa_num_resets){      /* reset */
		fprintf(fp,"\n");	
		fprintf(fp,"   Time   "); 
/*		fprintf(fp," Seq");
/*		fprintf(fp," fspin  "); */
/*		fprintf(fp,"  maz mel "); */ 
		fprintf(fp,"  +5 ");
		fprintf(fp,"  +12 ");
		fprintf(fp,"   -12 ");
		fprintf(fp," SwpL ");
		fprintf(fp," SwpH ");
		fprintf(fp," PMT  ");
		fprintf(fp," mcpL ");
		fprintf(fp," mcpH ");
	
		fprintf(fp," TempE");
		fprintf(fp," rsts");
		fprintf(fp," ver");
		fprintf(fp," errs lst");
		fprintf(fp,"    STATUS ");
		fprintf(fp,"     Time\n");
	}

	fspin =  ((double)hkp->spin+(double)hkp->phase)/16.;
/*	fmt = inst_mode_str(hkp->inst_mode); */

	fprintf(fp,"%9.0f ",hkp->time);
/*	fprintf(fp," %3d",hkp->frame_seq);
/*	fprintf(fp," %8.3f",fspin); */
/*	fprintf(fp," %4d %3d",hkp->magaz,hkp->magel); */ 
	fprintf(fp," %4.2f",hkp->eesa_p5);
	fprintf(fp," %5.2f",hkp->eesa_p12);
	fprintf(fp," %6.2f",hkp->eesa_m12);
	fprintf(fp," %5.0f",hkp->eesa_swpl);
	fprintf(fp," %5.0f",hkp->eesa_swph);
	fprintf(fp," %5.0f",hkp->eesa_pmt);
	fprintf(fp," %5.0f",hkp->eesa_mcpl);
	fprintf(fp," %5.0f",hkp->eesa_mcph);

	fprintf(fp," %5.1f",hkp->eesa_temp);
	fprintf(fp," %3d ",hkp->eesa_num_resets);
	fprintf(fp," %02x ",hkp->eesa_version);
	fprintf(fp," %3d  %02x ",hkp->eesa_num_errors,hkp->eesa_last_error);
	fprintf(fp," <%s>",bit_pattern(hkp->eesa_status,"QVH...BP","        "));
	fprintf(fp," %s",time_to_YMDHMS(hkp->time));
	fprintf(fp,"\n");
	lastreset = hkp->eesa_num_resets;
	return(1);
}

/* print out housekeeping values to summary file.  Used for near realtime data as alternate to */
/* the GSE. */

int print_hkp_struct_sum(FILE *fp, hkpPktStruct *hkp)
{
    hkpstrings str ;

    if(fp==0)
	return(0);

    get_hkp_strings(&str, hkp);

/*              0         1         2         3         4         5         6          */
/*              01234567890123456789012345678901234567890123456789012345678901234567890*/
    fprintf(fp, "------------------------- WIND 3DP Housekeeping  --------------------------\n");
    fprintf(fp, "                               SPACE CRAFT\n");
    fprintf(fp, "%s", hkp->valid ? "" : "          Data: Not Valid\n");
	if ( hkp->valid )
	    {
		fprintf(fp, "          Time: %s\n"
			"     Inst Mode: '%8s' Science Mode: %-5hx  \n"
			"    Burst Stat: '%4s'\n",
			time_to_YMDHMS(hkp->time), str.inst_mode, hkp->mode, str.brst_status);
		fprintf(fp, "     Data Rate: %-5hd         Frame Seq: %-5hd       Data Offset: %-5hu\n",
			hkp->rate, hkp->frame_seq, hkp->offset);
		fprintf(fp, "          Spin: %-5hu        Spin Phase: %-5hu             FSpin: %-8.2f\n",
			hkp->spin, hkp->phase, hkp->fspin);
		fprintf(fp, " Mag Elevation: %-5hu       Mag Azimuth: %-5hu\n",
			hkp->magel, hkp->magaz);
		fprintf(fp, "   Number Cmds: %-5hu       Errors: '%s'\n",
			hkp->num_commands, str.errors);
		fprintf(fp, "  Last Command: %s\n",
			str.last_cmd);
		fprintf(fp, "             MAIN                     EESA                     PESA\n");
		fprintf(fp, "           Ver# %-4d                Ver# %-4d                Ver# %-4d\n",
			hkp->main_version, hkp->eesa_version, hkp->pesa_version);
		fprintf(fp, "          Stat: '%7s'         Stat: '%8s'         Stat: '%8s'\n",
			str.main_status, str.eesa_status, str.pesa_status);
		fprintf(fp, "     LastError: %-5d         LastError: %-5d         LastError: %-5d\n",
			hkp->main_last_error, hkp->eesa_last_error, hkp->pesa_last_error);
		fprintf(fp, "        Errors: %-5d            Errors: %-5d            Errors: %-5d\n",
			hkp->main_num_errors, hkp->eesa_num_errors, hkp->pesa_num_errors);
		fprintf(fp, "        Resets: %-5d            Resets: %-5d            Resets: %-5d\n",
			hkp->main_num_resets, hkp->eesa_num_resets, hkp->pesa_num_resets);
		fprintf(fp, "           +5V: %-8.1f              BOOM                     BOOM\n",
			hkp->main_p5);
		fprintf(fp, "           -5V: %-8.1f             +5: %-8.1f             +5: %-8.1f\n",
			hkp->main_m5, hkp->eesa_p5, hkp->pesa_p5);
		fprintf(fp, "          +12V: %-8.1f            +12: %-8.1f            +12: %-8.1f\n",
			hkp->main_p12, hkp->eesa_p12, hkp->pesa_p12);
		fprintf(fp, "          -12V: %-8.1f            -12: %-8.1f            -12: %-8.1f\n",
			hkp->main_m12, hkp->eesa_m12, hkp->pesa_m12);
		fprintf(fp, "             SST                   MCPL: %-8.1f           MCPL: %-8.1f\n",
			hkp->eesa_mcpl, hkp->pesa_mcpl);
		fprintf(fp, "           +9V: %-8.1f           MCPH: %-8.1f           MCPH: %-8.1f\n",
			hkp->sst_p9, hkp->eesa_mcph, hkp->pesa_mcph);
		fprintf(fp, "           -9V: %-8.1f            PMT: %-8.1f            PMT: %-8.1f\n",
			hkp->sst_m9, hkp->eesa_pmt, hkp->pesa_pmt);
		fprintf(fp, "           +5V: %-8.1f           SWPL: %-8.1f           SWPL: %-8.1f\n",
			hkp->sst_p5, hkp->eesa_swpl, hkp->pesa_swpl);
		fprintf(fp, "           -5V: %-8.1f           SWPH: %-8.1f           SWPH: %-8.1f\n",
			hkp->sst_m4, hkp->eesa_swph, hkp->pesa_swph);
		fprintf(fp, "            HV: %-8.1f\n",
			hkp->sst_hv);
		fprintf(fp, "        1-Temp: %-8.1f          Sweep: %s              Sweep: %s\n",
			hkp->sst1_temp,
			hkp->eesa_swp ? "High" : "Low ", hkp->pesa_swp ? "High" : "Low ");
		fprintf(fp, "        3-Temp: %-8.1f           Temp: %-8.1f           Temp: %-8.1f\n",
			hkp->sst3_temp, hkp->eesa_temp, hkp->pesa_temp);
	    }    
    return (1);
}


int get_hkp_strings(hkpstrings *str, hkpPktStruct *hkp)
{
	uchar *u;
	sprintf(str->inst_mode,"%8s",bit_pattern(hkp->inst_mode,"Ex..2BMS" ,"    1   "));
	sprintf(str->main_status,"%8s",bit_pattern(hkp->main_status,"QBHPESep" ,"        "));
	sprintf(str->brst_status,"%4s-%2d",bit_pattern(hkp->main_burst_stat >> 4,"P210","    "),
		hkp->main_burst_stat & 0xf);
	u = hkp->lastcmd;
	sprintf(str->last_cmd,"%02x%02x%02x%02x%02x",u[0], u[1], u[2], u[3], u[4]);
	sprintf(str->pesa_status,"%8s" ,bit_pattern(hkp->pesa_status,"QVH...BP" ,"        "));
	sprintf(str->eesa_status,"%8s" ,bit_pattern(hkp->eesa_status,"QVH...BP" ,"        "));
	sprintf(str->errors,"%s" ,bit_pattern_o(hkp->errors,ERROR_STRING));
	return(1);
}



#if 0

char *inst_mode_str(uchar inst_mode)
{
	static char *fmts[16]= { "?1x ","S1x ","M1x ","C1x ",
	                         "?1xB","S1xB","M1xB","C1xB",
	                         "?2x ","S2x ","M2x ","C2x ",
	                         "?2xB","S2xB","M2xB","C2xB"  };

	if(inst_mode/16)
		return("????");
	else
		return(fmts[inst_mode]);
}
#endif

