#include "pads_dcm.h"
#include "pads_prt.h"
#include "windmisc.h"
#include "pckt_prt.h"



FILE *pads_fp;
FILE *pads_raw_fp;
FILE *pads_log_fp;
FILE *pads_spec_fp;

int print_pads_packet(packet *pk)
{
	static PADdata pad;
	
	if(pads_fp || pads_spec_fp){
		pads_decom(pk,&pad);
		print_pad_structure(pads_fp,&pad);
		print_pad_spectra(pads_spec_fp,&pad);
	}
	if(pads_raw_fp || pads_log_fp){
		print_packet_header(pads_log_fp,pk);
		print_generic_packet(pads_raw_fp,pk,15);
	}
	return(0);
}

int print_pad_spectra(FILE *fp,PADdata *pad)
{
	int e,a,ne;
	double f;
	if(fp==0)
		return(0);
	ne = pad->num_energies;
	fprintf(fp,"%9.0f ",pad->time1);
	for(e=0;e<ne;e++){
		f = 0;
		for(a=0;a<pad->num_angles;a++){
			f += pad->flux[a*ne+e];
		}
		fprintf(fp," %5.0f",f);
	}
	fprintf(fp,"\n");
	return(1);
}


int print_pad_structure(FILE *fp,PADdata *pad)
{
	int e,a,n,ne,na,ns;
	double ta,nrg,flx;

	if(fp==0)
		return(0);

	fprintf(fp,"\n`%s - ",time_to_YMDHMS(pad->time1));
	fprintf(fp,"%s   ",time_to_YMDHMS(pad->time2));
	fprintf(fp,"  %d-%d  ",pad->t_start,pad->t_stop);
	fprintf(fp,"\n");
	
	ne = pad->num_energies;
	na = pad->num_angles;
	ns = pad->num_samples;

	fprintf(fp,"`       ");
	for(a=0;a<na;a++)
		fprintf(fp," %5g",pad->angles[a]);
	fprintf(fp,"\n");
	for(e=0;e<ne;e++){
		nrg = pad->energies[e];
		fprintf(fp,"%5.0f ",nrg);
		for(a=0;a<na;a++){
			flx = pad->flux[a*ne+e];
			fprintf(fp," %5g",flx);
		}
		fprintf(fp,"\n");
	}
#if 1
	fprintf(fp,"` area:");
	ta = 0;
	for(a=0;a<na;a++){
		fprintf(fp," %5g",pad->area[a]);
		ta += pad->area[a];
	}
	fprintf(fp,"\n`total area: %4f\n",ta);
#endif
#if 0
	for(n=0;n< ns;n++){
		fprintf(fp,"`bth=%3d  bph=%3d \n",bdir[2*a+1],bdir[2*a]);
	}
	fprintf(fp,"\n");
#endif
	return(1);
}






#if 0

print_c_tables(FILE *fp)
{	
	int i;
	for(i=0;i<11*10;i++){
		fprintf(fp," %5d,",w_el[i]);
		if(i%10 ==9)
			fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	for(i=0;i<65;i++){
		fprintf(fp," %5d,",cos_[i]);
		if(i%8 ==7)
			fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	fprintf(fp,"\n");
	for(i=0;i<48;i++){
		fprintf(fp," %6d,",sin_cos_sec[i]);
		if(i%8 ==7)
			fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
}

print_asm_tables(FILE *fp)
{	
	int i;
	fprintf(fp,"\ttitle\twel.tbl\n");
	fprintf(fp,"w_el");
	for(i=0;i<11*10;i++){
		if(i%5 ==0)
			fprintf(fp,"\tdw\t");
		fprintf(fp,"  %05xh",w_el[i]);
		if(i%5 ==4)
			fprintf(fp,"\n");
		else
			fprintf(fp,",");
	}
	fprintf(fp,"\n");
	fprintf(fp,"cos_");
	for(i=0;i<65;i++){
		if(i%8 ==0)
			fprintf(fp,"\tdw\t");
		fprintf(fp,"  %05xh",cos_[i]);
		if(i%8 ==7)
			fprintf(fp,"\n");
		else
			fprintf(fp,",");
	}
	fprintf(fp,"\n");
	fprintf(fp,"sin_cos_sec");
	for(i=0;i<48;i++){
		if(i%8 ==0)
			fprintf(fp,"\tdw\t");
		fprintf(fp,"  %05xh",sin_cos_sec[i]);
		if(i%8 ==7)
			fprintf(fp,"\n");
		else
			fprintf(fp,",");
	}
	fprintf(fp,"nesteps	db	0,0,15,30\n");
	fprintf(fp,"tstrt	db	0,16,16,32\n");
	fprintf(fp,"tstop	db	16,32,40,40\n");
	fprintf(fp,"nthta	db	16,24,24,24\n");
	fprintf(fp,"\n");
}


print_rom_arrays(FILE *fp)
{
	int i,t,n,sib,cib,max,cpa,tmax,min,tmin,imax,imin;
	fprintf(fp,"`   cos_\n");
	for(i=0;i<65;i++)
		fprintf(fp,"%2d  %3d \n",i,cos_gr[i]);
	fprintf(fp,"`   sin_sec cos_sec\n");
	for(i=0;i<24;i++)
		fprintf(fp,"%2d  %6d  %6d \n",i,sin_sec[i],cos_sec[i]);
	max = -1000;
	min = 1000;
#if 0
	for(t=0;t<=128;t++){
		mis.current_bth = t;
		init_pad_arrays();
		for(i=0;i<24;i++){
#if NEW
#if NBITS16
			cpa = (( (long)sinib[i] * cos_gr[0] + 16383) >> 15) + cosib[i];   
#else
			cpa = ((sinib[i] * cos_gr[0] + 63) >> 7) + cosib[i];   
#endif
#else
			cpa = (sinib[i] * cos_gr[0])/128 + cosib[i];
#endif
			if(cpa>max){ max=cpa;  tmax=t; imax=i; }
			if(cpa<min){ min=cpa;  tmin=t; imin=i; }
#if NEW
			cpa = ((sinib[i] * -cos_gr[0] + 63) >> 7) + cosib[i];
#else
			cpa = (sinib[i] * -cos_gr[0])/128 + cosib[i];
#endif
			if(cpa>max){ max=cpa;  tmax=t; imax=i; }
			if(cpa<min){ min=cpa;  tmin=t; imin=i; }
		}
	}
	fprintf(fp,"`cpamax=%3d at t=%d, i=%d    cpamin=%4d at t=%d, i=%d \n",max,tmax,imax,min,tmin,imin);
#endif
}


uchar cpamapth,cpamapph;
uchar cpamap[40][32];

print_cpamap(FILE *fp)
{
	int p,t;
	uchar m;
	fprintf(fp,"`th=%d , ph=%d\n",cpamapth,cpamapph);
	for(t=0;t<40;t++){
		m = 0;
		for(p=0;p<32;p++)
			m |= cpamap[t][p];
		if(m==0)
			continue;
		fprintf(fp,"%2d ",t);
		for(p=0;p<32;p++){
			if(m=cpamap[t][p])
				fprintf(fp," %3d",m);
			else
				fprintf(fp,"    ");
			cpamap[t][p] = 0;
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
}



#define T_SCALE 32767.499
#define S_SCALE 32640.
#define C_SCALE (S_SCALE*T_SCALE/32768.)


init_rom_arrays()
{
	int i,n;
	double ac;
	int flag=0;
	for(i=0;i<65;i++){
		cos_gr[i] = floor( T_SCALE * cos(2.*PI*i/256.) +.5 );
/*		if(cos_[i] != cos_gr[i]){ */
/*			flag |=1; */
/*			cos_[i] = cos_gr[i]; */
/*		} */
	}
	for(i=0;i<24;i++){
		cos_sec[i] = floor( C_SCALE * cos(PI/180.*th_e[i]) +.5 );
		sin_sec[i] = floor( S_SCALE * sin(PI/180.*th_e[i]) +.5 );	
/*		if(sin_cos_sec[2*i] != sin_sec[i]){ */
/*			flag |=2; */
/*			sin_cos_sec[2*i] = sin_sec[i]; */
/*		} */
/*		if(sin_cos_sec[2*i+1] != cos_sec[i]){ */
/*			flag |=4; */
/*			sin_cos_sec[2*i+1] = cos_sec[i]; */
/*		} */
	}
/*	flag |= init_w_el(w_el); */
/*	if(flag){ */
/*		err_out("\007 Rom Error!"); */
/*		print_c_tables(nfile("welc.tbl")); */
/*		print_asm_tables(nfile("wel.tbl")); */
/*	} */
/*	if(flag & 1) */
/*		err_out("COS_ table is incorrect!  It has been changed"); */
/*	if(flag & 2) */
/*		err_out("SIN_SEC table is incorrect!  It has been changed"); */
/*	if(flag & 4) */
/*		err_out("COS_SEC table is incorrect!  It has been changed"); */
/*	if(flag & 8) */
/*		err_out("W_EL table is incorrect!  It has been changed"); */
}


char *fstring5(char *s,double x)
{
	char *f;
	int e;
	if(x==0){
		sprintf(s,"%6.4f",0.);
		return( s );
	}
	e = floor( log10(x) );
	if(e<-3 || e>5){
		sprintf(s,"%3.1fe%-2d",x/pow((double)e,10.),e);
		return(s);
	}
	f="%6.4f";
	if(e==1)    f="%6.3f";
	if(e==2)    f="%6.2f";
	if(e==3)    f="%6.1f";
	if(e==4)    f="%6.0f";
	if(e==5)    f="%6f";
	sprintf(s,f,x);
	return(s);	
}

#endif
