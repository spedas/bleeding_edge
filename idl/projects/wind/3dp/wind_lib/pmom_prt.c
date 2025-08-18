#include "pmom_prt.h"

#include <stdio.h>  /* may not be needed  */
#include <string.h>

#include "winddefs.h"
/*#include "wind_dcm.h" */
#include "pcfg_dcm.h"
#include "esteps.h"
#include "pmom_dcm.h"
#include "windmisc.h"
#include "matrix.h"


#include <math.h>



/********* Private structures **********/

struct start_val {
	uchar e_start;
	schar p_start;
};



int print_pmom_binary(FILE *fp,pesa_mom_data *P,int n,int navg);




FILE *pmom_fp;
FILE *pmom_raw_fp;
FILE *amom_fp;
FILE *amom_raw_fp;
FILE *pmom_brst_fp;
FILE *pmom_binary_fp;

/************************************************************************
Given a pointer to a pesa moment packet, this routine will decomutate it.
and then produce ascii output files. 
**************************************************************************/
print_pmom_packet(packet *pk)
{
	int i;
	pesa_mom_data Pmom[16]; /* reconstructed Proton moments */
	pesa_mom_data Amom[16]; /* reconstructed Alpha moments  */

	if((pk->idtype & 0xf0f0) != 0x6040)  return(0); /*not pesa moment data*/
	
	if(pmom_fp || pmom_raw_fp || amom_fp || amom_raw_fp || pmom_brst_fp
             || pmom_binary_fp)
		pmom_decom(pk,Pmom,Amom);

	print_pmom_binary(pmom_binary_fp,Pmom,16,256);

	if(pmom_brst_fp){   /* proton burst trigger */
		for(i=0;i<16;i++)
			print_pmom_brst(pmom_brst_fp,Pmom+i);
	}

	if(pmom_raw_fp){   /* protons raw units */
		for(i=0;i<16;i++)
			print_pmom_raw(pmom_raw_fp,Pmom+i);
	}

	if(pmom_fp){   /* protons normal units */
		for(i=0;i<16;i++)
			print_pmom_phys(pmom_fp,&Pmom[i]);
	}

	if(amom_raw_fp){   /* alphas raw units */
		for(i=0;i<16;i++)
			print_pmom_raw(amom_raw_fp,Amom+i);
	}

	if(amom_fp){   /* alphas normal units */
		for(i=0;i<16;i++)
			print_pmom_phys(amom_fp,&Amom[i]);
	}


	return(1);
}


typedef struct {
      double time;
      double dtime;
      int2 quality;
      int2 nsamples;
      int4 counter;
      int4 dummy;
/*      float  mag[3]; */    /* not used yet */ 
      float  density; 
      float  veloc[3];
      float  temp;
   } pmom_binary_rec;




int print_pmom_binary(FILE *fp,pesa_mom_data *P,int n,int navg)
{
   static pmom_binary_rec rec;
   int i,c,j;

   if(fp ==0)  return(0);

   for(i=0;i<n;i++){
      if(rec.counter % navg == 0) {
          c = rec.counter;
          memset(&rec,0,sizeof(pmom_binary_rec));
          rec.counter = c;
          rec.time = P[i].time;
      }
      if(P[i].valid)  {
          rec.dtime += SPIN_PERIOD;
          rec.quality = 1;
          rec.nsamples++;
          rec.density += P[i].dist.dens;
          for(j=0;j<3;j++)
               rec.veloc[j] += P[i].dist.v[j];
          rec.temp += P[i].dist.temp;
      }
      if(rec.counter % navg == navg-1) {
          if(rec.nsamples) {
             rec.density = rec.density/rec.nsamples;
             for(j=0;j<3;j++) 
                rec.veloc[j] = rec.veloc[j]/rec.nsamples;
             rec.temp  = rec.temp/rec.nsamples;
             fwrite(&rec,sizeof(pmom_binary_rec),1,fp);
          }
      }
      rec.counter++;
   }
   return(1);
}





void print_pmom_brst(FILE *fp, pesa_mom_data *P)
{
	uint e0;
	uint vc;
	comp_pesa_mom c;

	if(fp==0)
		return;
#if 1
	if(P->gap){
		fprintf(fp,"`  Time   ");
		fprintf(fp,"  E_s ");
		fprintf(fp," nv  ");
		fprintf(fp," v ");
		fprintf(fp," vc ");
		fprintf(fp," spin ");
		fprintf(fp,"\n");
	} 
#endif
	c = P->cmom;
	vc = P->Vc;
	e0 = 0;
	fprintf(fp,"%10.0f ",P->time);
	fprintf(fp," %3d",P->E_s);
	fprintf(fp," %3d",c.c0);
	fprintf(fp," %3d",c.c1);
	fprintf(fp," %3d",vc);
	fprintf(fp," %5d ",P->spin);
/*	fprintf(fp," %3d ",P->burst_trig); */
	fprintf(fp," %s",time_to_YMDHMS(P->time));
	fprintf(fp,"\n");
}



void print_pmom_raw(FILE *fp, pesa_mom_data *P)
{
	uint e0;
	uint vc;
	comp_pesa_mom c;
	
	if(fp==0)
		return;
	if(P->gap){
		fprintf(fp,"\n`%s\n",time_to_YMDHMS(P->time));
		fprintf(fp,"`Time       spin ");
/*		fprintf(fp," brst");  */
		fprintf(fp," vc E_s  ps   c0  c1   c2   c3 ");
		fprintf(fp,"  c4   c5   c6  c7  c8  c9  exp\n");
	} 
	c = P->cmom;
	vc = P->Vc;
	e0 = 0;
	if(c.c7 & 0x80) e0 |= 1;
	if(c.c8 & 0x80) e0 |= 2;
	if(c.c9 & 0x80) e0 |= 4;
	fprintf(fp,"%10.0f %2d",P->time,P->spin);
/*	fprintf(fp," %3d",P->burst_trig);  */
	fprintf(fp," %3d %3d %3d  %3u %3u %4d %4d",vc,P->E_s,P->ps,c.c0,c.c1, c.c2,c.c3);
	fprintf(fp," %4d %4d %4d %3u %3u %3u %2d",c.c4,c.c5,c.c6,c.c7 & 0x7f, c.c8 & 0x7f,c.c9 &0x7f,e0);
/*	fprintf(fp,"  %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x", c.c0&0xff, c.c1&0xff, c.c2&0xff,c.c3&0xff,c.c4&0xff,c.c5&0xff, c.c6&0xff,c.c7&0xff,c.c8&0xff,c.c9&0xff);  */
	fprintf(fp," %s",time_to_YMDHMS(P->time));
	fprintf(fp,"\n");
}




void print_pmom_phys(FILE *fp, pesa_mom_data *P)
{  
	double V,th,ph;
	double dV,dth,dph;
	int E_s;
	pmomdata *H;
	
	if(fp==0)
		return;
	if(P->gap){
		fprintf(fp,"\n`%s\n",time_to_YMDHMS(P->time));
		fprintf(fp,"`  Time       Dens   Vel     Phi   Theta   dV    dPhi  dTheta  Emin  Emax\n");
	}
	H = &(P->dist);
	V = sqrt(H->v[0]*H->v[0] + H->v[1]*H->v[1] + H->v[2]*H->v[2]);
	dV = sqrt(H->vv[0][0]);
	if(V != 0){
		th = 180./PI*asin(H->v[2] / V);
		ph = 180./PI*asin(H->v[1] / V);
		dph = 180./PI*sqrt(H->vv[1][1])/V;
		dth = 180./PI*sqrt(H->vv[2][2])/V;
	}
	else
		th = ph = dth = dph = 0.;
	E_s = P->E_s;
	fprintf(fp,"%10.1f ",P->time,P->spin);
/*	fprintf(fp," %.0f",H->mass/MASS_P/H->charge);*/
	fprintf(fp," %7.4f",H->dens);
	fprintf(fp," %6.2f %6.2f %6.2f",V,ph,th);
	fprintf(fp," %6.2f %6.2f %6.2f",dV,dph,dth );
/*	fprintf(fp," %5.2f %5.2f %5.2f",H->vv[0][1],H->vv[0][2],H->vv[1][2]);*/
	fprintf(fp," %5.0f %5.0f",P->E_min,P->E_max);
	fprintf(fp,"\n");
}





/********************  old routines ********************/


#if 0
#if FLT
void print_moments(pesa_mom *mom,comp_pesa_mom *comp)
{
	int i;
	printf("         E_start= %3d p_start= %2x \n",mis.e_start,mis.p_start);
	printf("mom[0] = %10.0lf\n",mom->m0);
	printf("mom[1] = %10.0lf\n",mom->m1);
	printf("mom[2] = %10.0lf\n",mom->m2);
	printf("mom[3] = %10.0lf\n",mom->m3);
	printf("mom[4] = %10.0lf\n",mom->m4);
	printf("mom[5] = %10.0lf\n",mom->m5);
	printf("mom[6] = %10.0lf\n",mom->m6);
	printf("mom[7] = %10.0lf\n",mom->m7);
	printf("mom[8] = %10.0lf\n",mom->m8);
	printf("mom[9] = %10.0lf\n",mom->m9);
}
#else
void print_moments(pesa_mom *mom,comp_pesa_mom *comp)
{
/*	int i;
	printf("         e_start= %3d p_start= %2x \n",mis.e_start,mis.p_start); */
	printf("mom[0] = %10lu = %08lX = %6u = %2x = %4d\n",mom->m0,mom->m0,(uint)(mom->m0>>16),comp->c0&0xFF,(uchar)comp->c0);
	printf("mom[1] = %10lu = %08lX = %6u = %2x = %4d\n",mom->m1,mom->m1,(uint)(mom->m1>>16),comp->c1&0xFF,(uchar)comp->c1);
	printf("mom[2] = %10ld = %08lX = %6d = %2x = %4d\n",mom->m2,mom->m2, (int)(mom->m2>>16),comp->c2&0xFF,(schar)comp->c2);
	printf("mom[3] = %10ld = %08lX = %6d = %2x = %4d\n",mom->m3,mom->m3, (int)(mom->m3>>16),comp->c3&0xFF,(schar)comp->c3);
	printf("mom[4] = %10ld = %08lX = %6d = %2x = %4d\n",mom->m4,mom->m4, (int)(mom->m4>>16),comp->c4&0xFF,(schar)comp->c4);
	printf("mom[5] = %10ld = %08lX = %6d = %2x = %4d\n",mom->m5,mom->m5, (int)(mom->m5>>16),comp->c5&0xFF,(schar)comp->c5);
	printf("mom[6] = %10ld = %08lX = %6d = %2x = %4d\n",mom->m6,mom->m6, (int)(mom->m6>>16),comp->c6&0xFF,(schar)comp->c6);
	printf("mom[7] = %10lu = %08lX = %6u = %2x = %4d\n",mom->m7,mom->m7,(uint)(mom->m7>>16),comp->c7&0xFF,(uchar)(comp->c7 & 0x7f) );
	printf("mom[8] = %10lu = %08lX = %6u = %2x = %4d\n",mom->m8,mom->m8,(uint)(mom->m8>>16),comp->c8&0xFF,(uchar)(comp->c8 & 0x7f) );
	printf("mom[9] = %10lu = %08lX = %6u = %2x = %4d\n",mom->m9,mom->m9,(uint)(mom->m9>>16),comp->c9&0xFF,(uchar)(comp->c9 & 0x7f) );
}
#endif
#endif

