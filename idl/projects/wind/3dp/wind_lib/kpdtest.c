

/* This is a test program for the Key Parameter Data  */
/* usage:                                             */
/* kpdtest filename          */ 
/* where filename is an ascii file with raw kp data  */
/* this is a VERY crude program please forgive the data entry */

#include "kpd_dcm.h"
#include "eesa_cfg.h"
#include "pesa_cfg.h"

#include "pmom_prt.h"  /* for printing */
#include "emom_prt.h"  /* for printing */
#include "windmisc.h"      /* for YMDHMS_to_time() */

main(int argc,char *argv[])
{
	FILE *fp;
	char buffer[300],*p;
	uchar data[33];
	int d,i;
	kpd_struct kpd;
	double time;
	double spin;
	ECFG *ecfg;
	PCFG *pcfg;

	ecfg = get_ECFG(0.);
	pcfg = get_PCFG(0.);

	if (argc==1)
		fprintf(stderr,"usage: %s inp_file\n", argv[0]);

	fp = fopen(argv[1],"r");
	if(fp==0)
		return(1);
	while(fgets(buffer,300,fp)){
		time = YMDHMS_to_time(buffer);
		spin = 0;
		p = buffer+20;              /*  this is a very poor method!! */
/*		printf(p); */
		for(i=0;i<33;i++){
			sscanf(p,"%x",&d);
			p+=3;
			data[i]=d;
		}
		unpack_to_kpd_def(data,time,spin,&kpd,ecfg,pcfg);
		print_emom_phys(stdout,&kpd.Emom);
/*		print_pmom_phys(stdout,&kpd.Pmom); */

	}
	return(0);
}


/* DUMMY routines for testing: */
packet *get_packet(double, unsigned int, int, packet_def*, int*)
{
	return(NULL);
}

int number_of_packets(unsigned int, double, double)
{
	return(0);
}

int print_generic_packet(FILE*, packet_def*, int)
{
	return(0);
}

