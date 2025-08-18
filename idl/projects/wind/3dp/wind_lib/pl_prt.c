#include "pl_prt.h"
#include "pl_dcm.h"
#include "windmisc.h"
#include "pckt_prt.h"
#include "brst_dcm.h"

#include <stdio.h>


FILE *plsnap5x5_fp;
FILE *plsnap5x5_cut_fp;
FILE *plsnap5x5_raw_fp;
FILE *plsnap8x8_fp;
FILE *plsnap8x8_raw_fp;
FILE *plsnap8x8_draw_fp;


print_plsnap5x5_packet(packet *pk)
{
	static pl_snap_55 pldata;

	if(plsnap5x5_fp || plsnap5x5_cut_fp){
		decom_pl_snapshot_5x5(pk,&pldata);
		print_plsnap5x5(plsnap5x5_fp,&pldata);
		print_plsnap5x5_cut(plsnap5x5_cut_fp,&pldata);
	}
	if(plsnap5x5_raw_fp)
		print_generic_packet(plsnap5x5_raw_fp,pk,16);

	return(1);
}

print_plsnap5x5_cut(FILE *fp,pl_snap_55 *pldata)
{
	int p,t,e;
	double tflux,f,nrg,dnrg;

	if(fp==0 || pldata==0)
		return(0);

	fprintf(fp,"\n`%s",time_to_YMDHMS(pldata->time));

	for(e=0;e<14;e++){
		tflux = 0;
		for(t=0; t<5; t++){
			for(p=0; p<5; p++){
					tflux += pldata->flux[t][p][e];
			}
		}
		nrg = pldata->nrg[0][0][e];
		dnrg = pldata->dnrg[0][0][e];
		
		fprintf(fp," %5.0f",nrg);
		fprintf(fp," %3.0f",tflux);
		fprintf(fp," %5.0f",dnrg);
		fprintf(fp,"\n");
	}
	return(1);
}


print_plsnap5x5(FILE *fp,pl_snap_55 *pldata)
{
	int p,t,e;
	double tflux,f,nrg;

	if(fp==0 || pldata==0)
		return(0);

	fprintf(fp,"\n`%s",time_to_YMDHMS(pldata->time));

	fprintf(fp,"   ");
	for(p=0; p<16; p++)
		fprintf(fp," %2d ",p);
	fprintf(fp,"\n");

	for(t=0; t<16; t++){
		fprintf(fp,"%2d",t);
		for(p=0; p<16; p++){
			tflux = 0;
			for(e=0;e<14;e++)
				tflux += pldata->flux[t][p][e];
			fprintf(fp," %3.0f",tflux);
		}
		fprintf(fp,"\n");
	}
	for(e=0;e<14;e++){
		nrg = pldata->nrg[0][0][e];
		fprintf(fp," %4.0f",nrg);
	}
	fprintf(fp,"\n");
	for(e=0;e<14;e++){
		f = 0;
		for(p=0;p<5;p++)
			for(t=0;t<5;t++)
				f += pldata->flux[t][p][e];
		fprintf(fp," %4.0f",f);
	}
	fprintf(fp,"\n");
	return(1);
}



print_plsnap8x8_packet(packet *pk)    /*  printing burst packets */
{
	static pl_snap_8x8 pldata;
	packet temp;

	if(plsnap8x8_fp){
		decom_pl_snapshot_8x8(pk,&pldata);
		print_plsnap8x8(plsnap8x8_fp,&pldata);
	}
	if(plsnap8x8_raw_fp)
		print_generic_packet(plsnap8x8_raw_fp,pk,16);

	if(plsnap8x8_draw_fp){
		decompress_burst_packet(&temp,pk);
		print_generic_packet(plsnap8x8_draw_fp,&temp,16);
	}

	return(1);
}

print_plsnap8x8(FILE *fp,pl_snap_8x8 *pldata)
{
	int p,t,e;
	double tflux,f,nrg;

	if(fp==0 || pldata==0 || pldata->valid==0)
		return(0);

	fprintf(fp,"\n`%s",time_to_YMDHMS(pldata->time));

	fprintf(fp,"   ");
	for(p=0; p<16; p++)
		fprintf(fp," %2d ",p);
	fprintf(fp,"\n");

	for(t=0; t<16; t++){
		fprintf(fp,"%2d",t);
		for(p=0; p<16; p++){
			tflux = 0;
			for(e=0;e<14;e++)
				tflux += pldata->flux[t][p][e];
			fprintf(fp," %3.0f",tflux);
		}
		fprintf(fp,"\n");
	}
	for(e=0;e<14;e++){
		nrg = pldata->nrg[0][0][e];
		fprintf(fp," %4.0f",nrg);
	}
	fprintf(fp,"\n");
	for(e=0;e<14;e++){
		f = 0;
		for(p=0;p<8;p++)
			for(t=0;t<8;t++)
				f += pldata->flux[t][p][e];
		fprintf(fp," %4.0f",f);
	}
	fprintf(fp,"\n");
	return(1);
}

