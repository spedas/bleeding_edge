#include <stdio.h>

#include "sst_prt.h"
#include "sst_dcm.h"
#include "windmisc.h"
#include "brst_dcm.h"
#include "pckt_prt.h"


int fprint_floats(FILE *fp,char *s,float *f,int n);
int print_sst_flat_rate_str(FILE *fp, sst_flat_rate *sst);
int print_sst_0810_cal(FILE *fp, sst_spectra *sst);
int print_sst_spectra_rate_struct(FILE *fp, sst_spectra *sst);
int print_sst_spectra_cond_struct(FILE *fp,sst_spectra *sst);
int print_sst_3d_O_dist(FILE *fp,sst_3d_O_distribution *dist);
int print_sst_3d_F_dist(FILE *fp,sst_3d_F_distribution *dist);
int print_sst_3d_O_accums(FILE *fp,sst_3d_O_distribution *dist);
int print_sst_3d_F_accums(FILE *fp,sst_3d_F_distribution *dist);
int print_sst_t_distribution(FILE *fp,sst_t_distribution *tdist);





/* rates  PRINTING  routines    */

FILE *sst_rate_fp;

int print_sst_rate_packet(packet *pk)
{
	static sst_flat_rate sst_rate;
	if(sst_rate_fp){
		fill_sst_flat_rate_str(pk,&sst_rate);
		print_sst_flat_rate_str(sst_rate_fp,&sst_rate);
		return(1);
	}
	return(0);
}


int print_sst_flat_rate_str(FILE *fp, sst_flat_rate *sst)
{
	int i,j;

	if(fp==0)
		return(0);

	fprintf(fp,"`time:%s\n", time_to_YMDHMS(sst->time));
	for(i=0;i<16;i++){
		fprintf(fp,"%10.2f ",sst->time+i*SPIN_PERIOD/16.);
		for(j=0;j<14;j++)
			fprintf(fp," %5.0f",sst->flux[j][i]);
		fprintf(fp,"\n");
	}
	return(1);
}





/* spectra  PRINTING  routines   */

FILE *s_spec_cond_fp;
FILE *s_spec_rate_fp;
FILE *s_0810_cal_fp;
FILE *s_3410_fp;

int print_sst_spectra_packet(packet *pk)
{
	static sst_spectra sst_spec;

	if(s_spec_cond_fp || s_spec_rate_fp){
		fill_sst_spectra_struct(pk,&sst_spec);
		print_sst_spectra_cond_struct(s_spec_cond_fp,&sst_spec);
		print_sst_spectra_rate_struct(s_spec_rate_fp,&sst_spec);
	}

	return(1);
}

int print_sst_0810_packet(packet *pk)
{
	static sst_spectra sst_spec;

	if(s_0810_cal_fp){
		fill_sst_spectra_struct(pk,&sst_spec);
		print_sst_0810_cal(s_0810_cal_fp,&sst_spec);
	}

	return(1);
}

int print_sst_3410_packet(packet *pk)
{
	static sst_spectra sst_spec;
	packet temp;

	if(s_3410_fp){
		decompress_burst_packet(&temp,pk);
		fill_sst_spectra_struct(&temp,&sst_spec);
/*		print_sst_0810_cal(s_3410_fp,&sst_spec);   */
/*		print_sst_spectra_cond_struct(s_3410_fp,&sst_spec);  */
		print_sst_spectra_rate_struct(s_3410_fp,&sst_spec);
	}

	return(1);
}



int print_sst_0810_cal(FILE *fp, sst_spectra *sst)
{
	int i;

	if(fp==0)
		return(0);

	fprintf(fp,"\n`time:%s  Spin:%u  Az=%u    El=%u\n", time_to_YMDHMS(sst->time),sst->spin, sst->magaz,sst->magel);
	fprint_floats(fp,"Rates:",sst->rates,14);

	fprint_floats(fp,"FT2: ",sst->FT2,24);
	fprint_floats(fp,"OT2: ",sst->OT2,24);
	fprint_floats(fp,"FT6: ",sst->FT6,24);
	fprint_floats(fp,"OT6: ",sst->OT6,24);

	fprint_floats(fp,"F6:   ",sst->F6,16);
	fprint_floats(fp,"F2:   ",sst->F2,16);
	fprint_floats(fp,"F3:   ",sst->F3,16);
	fprint_floats(fp,"F4:   ",sst->F4,16);
	fprint_floats(fp,"F5:   ",sst->F5,16);
	fprint_floats(fp,"F1:   ",sst->F1,16);

	fprint_floats(fp,"O6:   ",sst->O6,24);
	fprint_floats(fp,"O2:   ",sst->O2,24);
	fprint_floats(fp,"O3:   ",sst->O3,24);
	fprint_floats(fp,"O4:   ",sst->O4,24);
	fprint_floats(fp,"O5:   ",sst->O5,24);
	fprint_floats(fp,"O1:   ",sst->O1,24);

	fprintf(fp,"Calib: ");
	for(i=0;i<6;i++)
		fprintf(fp," %02x",sst->calib_control[i]);
	fprintf(fp,"\n");
	return(1);
}


int fprint_floats(FILE *fp,char *s,float *f,int n)
{
	int i;
	fprintf(fp,"%s",s);
	for(i=0;i<n;i++)
		fprintf(fp," %6.0f",f[i]);
	fprintf(fp,"\n");
	return(n);
}





int print_sst_spectra_rate_struct(FILE *fp, sst_spectra *sst)
{
	int i;
	static double lasttime;

	if(fp==0)
		return(0);

	if(sst->time <= lasttime || sst->time > lasttime+200){
		fprintf(fp,"\n`time:%s  Az=%u  El=%u\n",time_to_YMDHMS(sst->time), sst->magaz,sst->magel);
	}
	fprintf(fp,"%9.0f ",sst->time);
	for(i=0;i<14;i++){
		fprintf(fp," %6.0f",sst->rates[i]);
	}
	fprintf(fp,"\n");
	lasttime = sst->time;
	return(1);
}


int print_sst_spectra_cond_struct(FILE *fp,sst_spectra *sst)
{
	int i;
	static double lasttime;

	if(fp==0)
		return(0);

	if(sst->time <= lasttime || sst->time > lasttime+200){
		fprintf(fp,"\n`time:%s  Az=%u  El=%u\n",time_to_YMDHMS(sst->time), sst->magaz,sst->magel);
	        fprintf(fp,"`time     06     02     03     04     05     01     F6     F2     F3     F4     F5     F1\n");
	}
	fprintf(fp,"%9.0f ",sst->time);
	fprintf(fp," %6.0f",sst->O6[0]);
	fprintf(fp," %6.0f",sst->O2[0]);
	fprintf(fp," %6.0f",sst->O3[0]);
	fprintf(fp," %6.0f",sst->O4[0]);
	fprintf(fp," %6.0f",sst->O5[0]);
	fprintf(fp," %6.0f",sst->O1[0]+sst->O1[1]);
	fprintf(fp," %6.0f",sst->F6[0]);
	fprintf(fp," %6.0f",sst->F2[0]);
        fprintf(fp," %6.0f",sst->F3[0]+sst->F3[1]);
        fprintf(fp," %6.0f",sst->F4[0]+sst->F4[1]+sst->F4[2]);
        fprintf(fp," %6.0f",sst->F5[0]+sst->F5[1]+sst->F5[2]);
        fprintf(fp," %6.0f",sst->F1[0]+sst->F1[1]+sst->F1[2]);
	fprintf(fp,"\n");
	lasttime = sst->time;
	return(1);
}



FILE *sst_3d_O_fp;
FILE *sst_3d_F_fp;
FILE *sst_3d_t_fp;
FILE *sst_3d_F_accums_fp;
FILE *sst_3d_O_accums_fp;
FILE *sst_3d_F_burst_fp;
FILE *sst_3d_O_burst_fp;
FILE *sst_3d_T_burst_fp;


int print_sst_343x_O_packet(packet *pk)
{
	static sst_3d_O_distribution dist;
	packet temp;

	if(sst_3d_O_burst_fp){
		decompress_burst_packet(&temp,pk);
		if(fill_sst_3d_O_distribution(&temp,&dist))
		print_sst_3d_O_dist(sst_3d_O_burst_fp,&dist);
	}

	return(1);
}

int print_sst_3d_O_packet(packet *pk)
{
	static sst_3d_O_distribution dist;
	if(sst_3d_O_fp || sst_3d_O_accums_fp){
		fill_sst_3d_O_distribution(pk,&dist);
		print_sst_3d_O_accums(sst_3d_O_accums_fp,&dist);
		print_sst_3d_O_dist(sst_3d_O_fp,&dist);
	}
	return(1);
}

int print_sst_343x_F_packet(packet *pk)
{
	static sst_3d_F_distribution dist;
	packet temp;

	if(sst_3d_F_burst_fp){
		decompress_burst_packet(&temp,pk);
		if(fill_sst_3d_F_distribution(&temp,&dist))
		print_sst_3d_F_dist(sst_3d_F_burst_fp,&dist);
	}

	return(1);
}


int print_sst_3d_F_packet(packet *pk)
{
	int base, spin, seq;

	static sst_3d_F_distribution dist;
	if(sst_3d_F_fp || sst_3d_F_accums_fp){
		fill_sst_3d_F_distribution(pk,&dist);
		print_sst_3d_F_dist(sst_3d_F_fp,&dist);
		print_sst_3d_F_accums(sst_3d_F_accums_fp,&dist);
	}
	return(1);
}


int print_sst_342x_T_packet(packet *pk)
{
	static sst_t_distribution dist;
	packet temp;

	if(sst_3d_T_burst_fp){
		decompress_burst_packet(&temp,pk);
		if(fill_sst_t_distribution(&temp,&dist))
		print_sst_3d_t_dist(sst_3d_T_burst_fp,&dist);
	}

	return(1);
}
int print_sst_3d_t_packet(packet *pk)
{
	static sst_t_distribution tdist;
	if(sst_3d_t_fp){
		fill_sst_t_distribution(pk,&tdist);
		print_sst_3d_t_dist(sst_3d_t_fp,&tdist);
	}
	return(1);
}


int print_sst_3d_O_dist(FILE *fp,sst_3d_O_distribution *dist)
{
	int e,a;

	if(fp==0)
		return(0);
	fprintf(fp,"`Time: %s\n",time_to_YMDHMS(dist->time));
/*	if(dist->valid != 15) */
/*		return(0); */
	for(e=0;e<dist->ne;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<48;a++){
			fprintf(fp," %4.0f",dist->flux[e][a]);
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");

	return(1);
}


int print_sst_3d_F_dist(FILE *fp,sst_3d_F_distribution *dist)
{
	int e,a;

	if(fp==0)
		return(0);
	fprintf(fp,"`Time: %s\n",time_to_YMDHMS(dist->time));
	for(e=0;e<dist->ne;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<48;a++){
			fprintf(fp," %4.0f",dist->flux[e][a]);
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");

	return(1);
}

int print_sst_3d_t_dist(FILE *fp,sst_t_distribution *tdist)
{
	int e,a;

	if(fp==0)
		return(0);
	fprintf(fp,"`Time: %s\n",time_to_YMDHMS(tdist->time));
	for(e=0;e<7;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<8;a++){
			fprintf(fp," %4.0f",tdist->FT2[e][a]);
		}
		fprintf(fp,"\n");
	}
	for(e=0;e<9;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<8;a++){
			fprintf(fp," %4.0f",tdist->OT2[e][a]);
		}
		fprintf(fp,"\n");
	}
	for(e=0;e<7;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<8;a++){
			fprintf(fp," %4.0f",tdist->FT6[e][a]);
		}
		fprintf(fp,"\n");
	}
	for(e=0;e<9;e++){
		fprintf(fp,"%d  ",e);
		for(a=0;a<8;a++){
			fprintf(fp," %4.0f",tdist->OT6[e][a]);
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");

	return(1);
}


/*#define ACCUM_BY_NSAMPLES */
#if defined (ACCUM_BY_NSAMPLES)
const int N_TO_SUM = 64;
#else
extern double lt_sum_period;
#endif

/* print sums of of data samples in binary format */

int print_sst_3d_F_accums(FILE *fp,sst_3d_F_distribution *dist)
{
    int e,a;
    int seq;
    static boolean_t start=B_TRUE;      /* start flag.. look for seq # 0 */
    static int initAccums=1;
    static double time0 = 0.;
    static struct ad {
	double time;
	double integT;
	int4 numSamples;
	int4 quality;
	float fill[3];  
	float counts [48][7];
    } accumDist;
	
    seq = dist->seqn;
    if(fp==0)
	return(0);
    if (start && (seq !=0))
	return (0);
    else if (start)   {
	time0 = dist->time;     /* set first time */
	start = B_FALSE;
    }

    /* output accums if number samples reached */

#if defined (ACCUM_BY_NSAMPLES)
    if (accumDist.numSamples >= N_TO_SUM && !seq) {
#else
    if(dist->time < time0  || dist->time > time0+lt_sum_period && !seq) {
	if(accumDist.numSamples && dist->time >= time0)
#endif
	    fwrite(&accumDist, sizeof(accumDist), 1, fp);
	initAccums = 1;
    }
	
    /* init accummulations */

    if (initAccums) {
	accumDist.time = dist->time;
	accumDist.integT = 0;
	accumDist.numSamples = 0;
	for(e=0;e<7;e++)
	    for(a=0;a<48;a++)
		accumDist.counts[a][e] = 0;
	accumDist.quality = 1;
	time0=dist->time;
	initAccums = 0;
    }

    /* accumulate sum */

    for(e=0;e<dist->ne;e++)
	for(a=0;a<48;a++)
	    accumDist.counts[a][e] += dist->flux[e][a];
    accumDist.integT += dist->integ_t;
    accumDist.numSamples ++;

/*#define DEBUG_BIN_OUT */
#if defined (DEBUG_BIN_OUT)
    static int lastSeq;
    printf("nsumed: %d, seq: %d %c\n",accumDist.numSamples, seq, lastSeq == (seq-1) ? ' ':'*');
    lastSeq = seq;
/*    for(e=0;e<dist->ne;e++) */
/*	for(a=0;a<48;a++) */
/*	    printf("%5.0f%s", accumDist.counts[a][e], (a==(48-1))?"\n":", "); */
#endif /* defined DEBUG_BIN_OUT     */

    return(1);
}

/* print sums of of data samples in binary format */

int print_sst_3d_O_accums(FILE *fp,sst_3d_O_distribution *dist)
{
    int e,a;
    int seq;
    static boolean_t start=B_TRUE;      /* start flag.. look for seq # 0 */
    static initAccums=1;
    static double time0 = 0.;
    static struct ad {
	double time;
	double integT;
	int4 numSamples;
	int4 quality;
	float fill[3];  
	float counts [48][9];
    } accumDist;
	
    seq = dist->seqn;
    if(fp==0)
	return(0);
    if (start && (seq !=0))
	return (0);
    else if (start)  {
	time0 = dist->time;     /* set first time */
	start = B_FALSE;
    }
	
    /* output accums if number samples reached */

#if defined (ACCUM_BY_NSAMPLES)
    if (accumDist.numSamples >= N_TO_SUM && !seq) {
#else
    if(dist->time < time0  || dist->time > time0+lt_sum_period && !seq) {
	if(accumDist.numSamples && dist->time >= time0)
#endif
	    fwrite(&accumDist, sizeof(accumDist), 1, fp);
	initAccums = 1;
    }

    /* init accummulations */

    if (initAccums) {
	accumDist.time = dist->time;
	accumDist.integT = 0;
	accumDist.numSamples = 0;
	for(e=0;e<9;e++)
	    for(a=0;a<48;a++)
		accumDist.counts[a][e] = 0;
	accumDist.quality = 1;
	time0=dist->time;
	initAccums = 0;
    }

    /* accumulate sum */

    for(e=0;e<dist->ne;e++)
	for(a=0;a<48;a++)
	    accumDist.counts[a][e] += dist->flux[e][a];
    accumDist.integT += dist->integ_t;
    accumDist.numSamples ++;

/*#define DEBUG_BIN_OUT */
#if defined (DEBUG_BIN_OUT)
    static int lastSeq;
    printf("nsumed: %d, seq: %d %c\n",accumDist.numSamples, seq, lastSeq == (seq-1) ? ' ':'*');
    lastSeq = seq;
/*    for(e=0;e<dist->ne;e++) */
/*	for(a=0;a<48;a++) */
/*	    printf("%5.0f%s", accumDist.counts[a][e], (a==(48-1))?"\n":", "); */
#endif /* defined DEBUG_BIN_OUT     */

    return(1);
}











