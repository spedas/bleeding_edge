#include "fpc_prt.h"
#include "fpc_dcm.h"
#include "pckt_prt.h"
#include "windmisc.h"


FILE *fpc_dump_raw_fp;
FILE *fpc_dump_fp;
FILE *fpc_xcorr_raw_fp;
FILE *fpc_xcorr_fp;
FILE *fpc_slice_raw_fp;
FILE *fpc_slice_fp;


print_fpc_dump_packet(packet *pk)
{
	fpc_dump_str fpc;

	if(fpc_dump_raw_fp)
		print_generic_packet(fpc_dump_raw_fp,pk,15);

	if(fpc_dump_fp){
		fpc_dump_decom(pk,&fpc);
		print_fpc_dump(fpc_dump_fp,&fpc);
	}	
	
	return(0);
}


print_fpc_xcorr_packet(packet *pk)
{
	static fpc_xcorr_str fpc;
	static double lasttime;
	static long lastdate;
	long date;
	char *str;
	static long count;

	if(fpc_xcorr_raw_fp){
/*		print_generic_packet(fpc_xcorr_raw_fp,pk,16);  */
/*   	        print_packet_header(fpc_xcorr_raw_fp,pk);  */
		date = (long)pk->time/86400;
		str = time_to_YMDHMS(pk->time);
		if(date != lastdate) {
		    fprintf(fpc_xcorr_raw_fp,"\n%s ",str);
		    count=0;
		}
		count++;
		fprintf(fpc_xcorr_raw_fp,"*");
		lastdate=date;
   	}
	if(fpc_xcorr_fp){
		if(fpc.valid && fpc.spin != pk->spin){
			fprintf(fpc_xcorr_fp,"Missing Packets!\n");
			print_fpc_xcorr(fpc_xcorr_fp,&fpc);
		}
		fpc_xcorr_decom(pk,&fpc);
		if(fpc.valid == 0xff){
			print_fpc_xcorr(fpc_xcorr_fp,&fpc);
			fpc_clear(&fpc);
		}
	}

	return(0);
}


print_fpc_slice_packet(packet *pk)
{
	if(fpc_slice_raw_fp)
/*		print_generic_packet(fpc_slice_raw_fp,pk,15); */
   	     print_packet_header(fpc_xcorr_raw_fp,pk);

	return(0);
}



print_fpc_xcorr(FILE *fp,fpc_xcorr_str *fpc)
{
	int e,c;
	fprintf(fp,"%s\n",time_to_YMDHMS(fpc->time));
	fprintf(fp,"Spin=%04xh  E=%d   Th=%d  Phi=%d code=%02x Valid=%02xh\n", 
             fpc->spin,fpc->E_step,fpc->Bq_th,fpc->Bq_ph,fpc->code,fpc->valid);
	fprintf(fp,"Flag W_ad  time_total\n");
	for(e=0;e<8;e++){
		fprintf(fp,"%5u ",fpc->time_total[e]);
	}
	fprintf(fp,"\n");
	fprintf(fp,"Time    t3   s3   c3   t2   s2   c2   t1   s1   c1   t0   s0   c0  freq sint cost  Wpow\n");
	for(e=0;e<8*16;e++){
		if(e%16 == 0)
			fprintf(fp,"\n");
		fprintf(fp,"%5.3f ",fpc->sample_time[e]);
		for(c=3;c>=0;c--){
			fprintf(fp,"%4f ",fpc->total[c][e]);
			fprintf(fp,"%4f ",fpc->sin_c[c][e]);
			fprintf(fp,"%4f ",fpc->cos_c[c][e]);
		}
		fprintf(fp,"%4f ",fpc->freq[e]);
		fprintf(fp,"%4f ",fpc->sint[e]);
		fprintf(fp,"%4f ",fpc->cost[e]);
		fprintf(fp,"%5f ",fpc->wave_power[e]);
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");

	return(0);
}


print_fpc_dump(FILE *fp,fpc_dump_str *fpc)
{
	int e,c;
	fprintf(fp,"%s\n",time_to_YMDHMS(fpc->time));
	fprintf(fp,"Spin=%04xh  sweep=%2d  burstn=%2d  channel=%2d ",
           fpc->spin,fpc->sweepnum,fpc->burstnum,fpc->channel);
	fprintf(fp," Code=%02x%02x%02x\n",
           fpc->code[0],fpc->code[1],fpc->code[2]);
	for(e=0;e<15;e++){
		for(c=0;c<16;c++){
			fprintf(fp,"%5u ",fpc->counters[c][e]);
		}
		fprintf(fp,"\n");
	} 
	fprintf(fp,"\n");
	return(1);
}



