#include "kpd_prt.h"
#include "kpd_dcm.h"
#include "pmom_prt.h"
#include "emom_prt.h"
#include "windmisc.h"

#include <stdio.h>


FILE *ekpd_fp;
FILE *pkpd_fp;
FILE *ekpd_raw_fp;
FILE *pkpd_raw_fp;
FILE *kpd_raw_fp;

int print_kpd_raw(FILE *fp,packet *pk);

int print_kpd_packet(packet *pk)
{
	static kpd_struct kpd;
	if(kpd_raw_fp || ekpd_fp || pkpd_fp || ekpd_raw_fp || pkpd_raw_fp){
		kpd_decom(pk,&kpd);
		print_kpd_raw(kpd_raw_fp,pk);
		print_emom_raw(ekpd_raw_fp,&kpd.Emom);
		print_pmom_raw(pkpd_raw_fp,&kpd.Pmom);
		print_emom_phys(ekpd_fp,&kpd.Emom);
		print_pmom_phys(pkpd_fp,&kpd.Pmom);
	}

	return(1);
}



print_kpd_raw(FILE *fp,packet *pk)
{
	int i;
	if(fp==0)
		return(0);
	fprintf(fp,"%s ",time_to_YMDHMS(pk->time));
	for(i=0;i<(int)pk->dsize;i++)
		fprintf(fp," %02x",pk->data[i]);
	fprintf(fp,"\n");
	return(1);
}






