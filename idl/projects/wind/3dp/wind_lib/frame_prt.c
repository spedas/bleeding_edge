
#include "frame_prt.h"


int print_frame_sum(FILE *fp,struct frameinfo_def *frm);

FILE *info_fp;
FILE *hkp_sum_fp;

int print_frameinfo_packet(packet *pk)
{
	struct frameinfo_def temp;
	if(info_fp || hkp_sum_fp){
		memcpy(&temp,pk->data,FRAME_INFO_SIZE);
		print_frame_struct(info_fp,&temp);
		print_frame_sum(hkp_sum_fp,&temp);
		return(1);
	}
	return(0);
}



int print_frame_struct(FILE *fp,struct frameinfo_def *frm)
{
	static double last_spin0_time;
	static double last_frame_time;
	double dft;
	char *smode;
	static double frame_period[3] = { 100., 92.,46. }; 

	if(fp==0)
		return(0);

	smode = spc_mode_str(frm->spc_mode);
	
	dft = frm->time - last_frame_time;
	last_frame_time = frm->time;
	if(( frm->errors & ERROR_FRAME_GAP) || last_spin0_time==0 ){
		if(dft>999.)
			dft = 999.;
		fprintf(fp,"\n");	
		fprintf(fp,"`   Time           ");
/*		fprintf(fp,"`   Time   "); */
/*		fprintf(fp," dft  "); */
		fprintf(fp," cntr ");
		fprintf(fp,"Seq  spin  dspin ");
		fprintf(fp,"  Per  ");
/*		fprintf(fp," Good   Bad  Ugly  "); */
		fprintf(fp,"  Tot    pks "); 
		fprintf(fp,"Crp ");
		fprintf(fp," Num ");
		fprintf(fp,"  Errors    ");
		fprintf(fp,"      Mode ");
/*		fprintf(fp,"%s",time_to_YMDHMS(frm->spin0_time)); */
		fprintf(fp,"\n");
		last_spin0_time = frm->spin0_time;
	}
#if 1
	fprintf(fp,"%s ",time_to_YMDHMS(frm->time));
#else
	fprintf(fp,"  %9.2f  ",frm->time);
	fprintf(fp,"%5.2f ",dft);
#endif
	fprintf(fp,"%5d ",frm->counter);
	fprintf(fp,"%3d %5d %6.4f ",frm->seq, frm->spin, frm->dspin);
	fprintf(fp,"%6.4f ",frm->spin_period);
/*	fprintf(fp,"%5d %5d %5d ",frm->good, frm->bad, frm->ugly); */
	fprintf(fp,"%5d %3d ", frm->good+frm->ugly+frm->bad, frm->npkts);
	fprintf(fp,"%4.1lf ",frm->creep);
	fprintf(fp,"%4d ",frm->bad);
	fprintf(fp,"<%s> ",bit_pattern_o(frm->errors,ERROR_STRING));
	fprintf(fp,"%s\n",smode);
	return(1);
}


/* print out frame information to summary file.  Used for near realtime data as alternate to */
/* the GSE.  Note that we share the housekeeping file streem. */

int print_frame_sum(FILE *fp,struct frameinfo_def *frm)
{
    if(fp==0)
	return(0);

    
/*              0         1         2         3         4         5         6          */
/*              01234567890123456789012345678901234567890123456789012345678901234567890*/
    fprintf(fp, "------------------------- WIND 3DP frame summary ----------------------\n");
    fprintf(fp, "                            FRAME INFORMATION\n");

    fprintf(fp, "          Time: %s                        Creep: %-8.2lf\n",
	    time_to_YMDHMS(frm->time), frm->creep);
    fprintf(fp, "   Spin Period: %-8.2lf          FSpin: %-8.2lf          DSpin: %-8.2lf\n",
	    frm->spin_period, frm->fspin, frm->dspin);
    fprintf(fp, "     Frame Cnt: %-8u         Errors: %-8u     Numer Pkts: %-5hu\n",
	    frm->counter, frm->errors, frm->npkts);
    fprintf(fp, " Main PktTypes: %-5hx     EESA PktTypes: %-5hx     PESA PktTypes: %-5hx\n",
	    frm->main_packet_types, frm->eesa_packet_types, frm->pesa_packet_types);
    fprintf(fp, "    Fill Bytes: %-5hd       Sync Errors: %-5hd\n",
	    frm->num_fill_bytes, frm->num_sync_errors);
    fprintf(fp, "                           TELEMETRY PERCENTAGES\n");
#if 0
    fprintf(fp, "          Main: %-8.2f           EESA: %-8.2f           PESA: %-8.2f\n",
	    frm->main_telem, frm->eesa_telem, frm->pesa_telem);
    fprintf(fp, "           FPC: %-8.2f           Used: %-8.2f            Bad: %-8.2f\n",
	    frm->fpc_telem, frm->used_telem, frm->bad_telem);
#endif
    fprintf(fp, "	   Used: %-8.2f         Unused: %-8.2f           Lost: %-8.2f\n",
	    frm->used_telem, frm->unused_telem, frm->lost_telem);
    fprintf(fp, "                              DATA STATISTICS\n");
    fprintf(fp, "          Good: %-5hd               Bad: %-5hd              Ugly: %-5hd\n"
	        "          Lost: %-5hd\n",
	    frm->good, frm->bad, frm->ugly, frm->lost);
    fprintf(fp, "       \n\n\n\n");

    return (1);
}



/*****************************************************************************
The following routines are used for printing frame information.  This is very
useful for debugging purposes.
*****************************************************************************/

char *spc_mode_str(int spc_mode)
{
	char *s;
	switch(spc_mode){
		case SPC_MODE_SCI1x:
			s = "S1X";
			break;
		case SPC_MODE_ENG1x:
			s = "E1X";
			break;
		case SPC_MODE_MAN1x:
			s = "M1X";
			break;
		case SPC_MODE_CON1x:
			s = "C1X";
			break;
		case SPC_MODE_SCI2x:
			s = "S2X";
			break;
		case SPC_MODE_ENG2x:
			s = "E2X";
			break;
		case SPC_MODE_MAN2x:
			s = "M2X";
			break;
		case SPC_MODE_CON2x:
			s = "C2X";
			break;
		case SPC_MODE_UNKNOWN:
			s = "UNK";
			break;
		case SPC_MODE_TRANS:
			s = "TRN";
			break;
		default:
			s = "???";
			break;
	}
	return(s);
}



