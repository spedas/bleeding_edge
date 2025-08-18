#include "emom_prt.h"

#include "pckt_prt.h"
#include "emom_dcm.h"

#include "windmisc.h"

#include <stdio.h>
#include <math.h>



/* private functions: */
int exsign(uchar c);



FILE *emom_fp;
FILE *emom_raw_fp;
FILE *emom_rraw_fp;


/*   print eesa moment output files  */
int print_emom_packet(packet *pk)
{
	int i;
	eesa_mom_data Emom[16];

	if(emom_fp || emom_raw_fp)
		emom_decom(pk,Emom);
	if(emom_raw_fp)
		for(i=0;i<16;i++)
			print_emom_raw(emom_raw_fp,&Emom[i]);
	if(emom_fp)
		for(i=0;i<16;i++)
			print_emom_phys(emom_fp,&Emom[i]);
	if(emom_rraw_fp)
		print_generic_packet(emom_rraw_fp,pk,11);
	return(1);
}


/*  output physical quantities to a file */
void print_emom_phys(FILE *fp,eesa_mom_data *E)
{
	double vt2;
	emomdata *D;
	if(fp==NULL)
		return;
	if(E->gap){
		fprintf(fp,"\n`  Time          N      Vx     Vy     Vz     T    Vt   \n");
	}
	D = &E->dist;
	vt2= (D->vv[0][0] + D->vv[1][1] + D->vv[2][2]) /3.;
	fprintf(fp,"%10.1f ",E->time);
	fprintf(fp," %7.4g",D->dens);
	fprintf(fp," %6.2f %6.2f %6.2f",D->v[0],D->v[1],D->v[2]);
	fprintf(fp," %6.3f ",D->temp);
	fprintf(fp," %6.1f",sqrt(vt2));
	if(vt2 == 0.)
		vt2=1.;
	fprintf(fp," %6.3f %6.3f %6.3f",D->vv[0][0]/vt2, D->vv[1][1]/vt2, D->vv[2][2]/vt2);
	fprintf(fp," %6.3f %6.3f %6.3f",D->vv[0][1]/vt2, D->vv[0][2]/vt2, D->vv[1][2]/vt2);
	fprintf(fp,"\n");
}



#define NSHIFT 1000

/*  output raw quantities to a file  */
void print_emom_raw(FILE *fp,eesa_mom_data *emom)
{
	int mode=1;
	char expv,expq,expp;
	char *sp;
	comp_eesa_mom *mom;

	if(fp==NULL)
		return;
	if(emom->gap){
		fprintf(fp,"\nTime          c0  c1  c2  c3  c4  c5  c6  c7  c8  c9\n");
	}
	mom = &emom->cmom;
	fprintf(fp,"%10.1f ",emom->time);
	expv=0;
	if(mom->c1 & 0x40)   expv |= 0x04;
	if(mom->c2 & 0x40)   expv |= 0x02;
	if(mom->c3 & 0x40)   expv |= 0x01;
	if(mom->c0 & 0x2000) expv |= 0x08;
	expq=0;
	if(mom->c10 & 0x40)   expq |= 0x04;
	if(mom->c11 & 0x40)   expq |= 0x02;
	if(mom->c12 & 0x40)   expq |= 0x01;
	if(mom->c0  & 0x4000) expq |= 0x08;
	expp=0;
	if(mom->c7 & 0x80)   expp |= 0x04;
	if(mom->c8 & 0x80)   expp |= 0x02;
	if(mom->c9 & 0x80)   expp |= 0x01;
	if(mom->c0 & 0x1000) expp |= 0x08;
	sp = NSHIFT ? " " : "     ";
	if(mode){
		fprintf(fp,"%s %4d",sp,mom->c0 & 0x0fff);
		fprintf(fp,"%s %2d",sp,exsign(mom->c1 & 0xbf));
		fprintf(fp,"%s %2d",sp,exsign(mom->c2 & 0xbf));
		fprintf(fp,"%s %2d",sp,exsign(mom->c3 & 0xbf));
		fprintf(fp,"%s %2d",sp,exsign(mom->c4));
		fprintf(fp,"%s %2d",sp,exsign(mom->c5));
		fprintf(fp,"%s %2d",sp,exsign(mom->c6));
		fprintf(fp,"%s %2d",sp,mom->c7 & 0x7f);
		fprintf(fp,"%s %2d",sp,mom->c8 & 0x7f);
		fprintf(fp,"%s %2d",sp,mom->c9 & 0x7f);
		fprintf(fp,"%s %2d",sp,exsign(mom->c10 & 0xbf));
		fprintf(fp,"%s %2d",sp,exsign(mom->c11 & 0xbf));
		fprintf(fp,"%s %2d",sp,exsign(mom->c12 & 0xbf));
		fprintf(fp," %d ",mom->c0>>15);
		fprintf(fp," %2d  %2d  %2d\n",expv,expp,expq);
	}
	else{
		fprintf(fp,"%s %04x",sp,mom->c0);
		fprintf(fp,"%s   %02x",sp,mom->c1 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c2 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c3 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c4 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c5 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c6 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c7 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c8 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c9 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c10 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c11 & 0xff);
		fprintf(fp,"%s   %02x",sp,mom->c12 & 0xff);
		fprintf(fp,"\n");
	}
}

int exsign(uchar c)
{
	if( c & 0x80 ) return( -(c & 0x7f) );
	else return(c);
}


/* the following are unused printing routines  */


#if 0
void print_e_moments(FILE *fp,double time,uint spin,eesa_mom *mom)
{
	if(fp==NULL) return;
	fprintf(fp,"%10.1f 0x%04x",time,spin);
#if NSHIFT
	fprintf(fp," %5ld",mom->m0 / NSHIFT);
	fprintf(fp," %5ld",mom->m1 / NSHIFT);
	fprintf(fp," %5ld",mom->m2 / NSHIFT);
	fprintf(fp," %5ld",mom->m3 / NSHIFT);
	fprintf(fp," %5ld",mom->m4 / NSHIFT);
	fprintf(fp," %5ld",mom->m5 / NSHIFT);
	fprintf(fp," %5ld",mom->m6 / NSHIFT);
	fprintf(fp," %5ld",mom->m7 / NSHIFT);
	fprintf(fp," %5ld",mom->m8 / NSHIFT);
	fprintf(fp," %5ld",mom->m9 / NSHIFT);
	fprintf(fp," %5ld",mom->m10 / NSHIFT);
	fprintf(fp," %5ld",mom->m11 / NSHIFT);
	fprintf(fp," %5ld",mom->m12 / NSHIFT);
#else
	fprintf(fp," %9ld",mom->m0);
	fprintf(fp," %9ld",mom->m1);
	fprintf(fp," %9ld",mom->m2);
	fprintf(fp," %9ld",mom->m3);
	fprintf(fp," %9ld",mom->m4);
	fprintf(fp," %9ld",mom->m5);
	fprintf(fp," %9ld",mom->m6);
	fprintf(fp," %9ld",mom->m7);
	fprintf(fp," %9ld",mom->m8);
	fprintf(fp," %9ld",mom->m9);
	fprintf(fp," %9ld",mom->m10);
	fprintf(fp," %9ld",mom->m11);
	fprintf(fp," %9ld",mom->m12);
#endif
	fprintf(fp,"\n");
}
#endif

#if 0
void print_raw_hex(FILE *fp,double time,uint spin,uchar *uc,int n)
{
	int i;
	if(fp==NULL) return;
	fprintf(fp,"%10.1f 0x%04x ",time,spin);
	for(i=0;i<n;i++)
		fprintf(fp," %02x",uc[i]);
	fprintf(fp,"\n");
}
#endif
