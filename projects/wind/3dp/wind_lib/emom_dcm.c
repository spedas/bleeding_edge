#include "emom_dcm.h"

#include "windmisc.h"
#include "ecfg_dcm.h"
#include "esteps.h"
#include <math.h>



/* private functions: */
void make_cmom_struct( comp_eesa_mom *cmom,uchar *d);
void decompress_eesa_mom(comp_eesa_mom *cmom, eesa_mom *mom);


/* Gets next emom structure with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_emom_struct(packet_selector * pks, eesa_mom_data Emom[16])
{
	static packet *pk;
	pk = get_packet(pks);
	return( emom_decom(pk,Emom) );
}


/*  returns the number of electron moment samples between time t1 and t2  */
/*  Note:  there are 16 samples per packet  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_emom_struct_samples(double t1,double t2)
{
	return(16*number_of_packets(EMOM_ID,t1,t2));
}


#if 1
int emom_to_idl(int argc,void *argv[])
{
	eesa_mom_data Emom[16],*E;
	int i,n,ns,size;
        packet_selector pks;

	if(argc == 0)
		return( number_of_emom_struct_samples( 0.,1e12) );
	if(argc != 3){
		printf("Incorrect number of arguments\r\n");
		return(0);
	}

        ns    = * ((int4 *)argv[0]);
        size =  * ((int4 *)argv[1]);
        if(size != sizeof(eesa_mom_data)){
            printf("Incorrect stucture size.  Aborting.\r\n");
            return(0);
        }

        E = (eesa_mom_data *)argv[2];
	
	for(n = 0;n<ns/16;n++){
        	SET_PKS_BY_INDEX(pks,n,EMOM_ID);
        
		get_next_emom_struct(&pks,Emom);
		for(i=0;i<16;i++){
			*E++ = Emom[i];
		}
	}
        return(n);
}
#endif


int fill_emom_data(emom_fill_str ptr)
{
	eesa_mom_data Emom[16];
	double t;
	int i, j;
	int n;
	static packet_selector pks;

	n = 0;

	SET_PKS_BY_INDEX(pks,0.,EMOM_ID);
	while(1){
		get_next_emom_struct(&pks,Emom);
		if(n >= ptr.num_samples)
			break;
		for(i=0;i<16;i++){
			if(n >= ptr.num_samples)
				break;
			if(ptr.time)  *(ptr.time++) = Emom[i].time;
			if(ptr.dens)  *(ptr.dens++) = Emom[i].dist.dens;
			if(ptr.temp)  *ptr.temp++ = Emom[i].dist.temp;
			if(ptr.Vx)    *ptr.Vx++   = Emom[i].dist.v[0];
			if(ptr.Vy)    *ptr.Vy++   = Emom[i].dist.v[1];
			if(ptr.Vz)    *ptr.Vz++   = Emom[i].dist.v[2];
			if(ptr.Pe)
			    {
				ptr.Pe[n]                   = Emom[i].dist.vv[0][0];
				ptr.Pe[ptr.num_samples*1+n] = Emom[i].dist.vv[1][1];
				ptr.Pe[ptr.num_samples*2+n] = Emom[i].dist.vv[2][2];
				ptr.Pe[ptr.num_samples*3+n] = Emom[i].dist.vv[0][1];
				ptr.Pe[ptr.num_samples*4+n] = Emom[i].dist.vv[0][2];
				ptr.Pe[ptr.num_samples*5+n] = Emom[i].dist.vv[1][2];
			    }
			if(ptr.Qe)    
			    for (j=0;j<3;j++)
				ptr.Qe[ptr.num_samples*j+n] = Emom[i].dist.q[j];
			n++;
		}
		t = 0;
		pks.index++;
	}
	return(n);
}









/**************************************************************************
Decomutates all 16 spins of one eesa moment packet.
	Returns 0 on error.
	Returns 1 if successful.
****************************************************************************/
int emom_decom(packet *pk,eesa_mom_data Emom[16])
{
	int i,j,k,gap;
	static uint2 spin;
	double time;
	uint newp=0;
	ECFG *cfg;       /* instrument configuration */

	if(pk==0){
		for(i=0;i<16;i++)
			Emom[i].valid =0;
		return(0);
	}

	if(pk->quality & (~pkquality)) {
		for(i=0;i<16;i++){
			Emom[i].valid =0;
			Emom[i].time =pk->time;
			Emom[i].dist.dens = NaN;
			Emom[i].dist.temp = NaN;
			for(j=0;j<3;j++) {
				Emom[i].dist.v[j] = NaN;
				Emom[i].dist.q[j] = NaN;
				for(k=0;k<3;k++)
					Emom[i].dist.vv[j][k] = NaN;

			}
		}
		return(0);
	}
	
	if(pk->idtype != 0x5040){
		err_out("Invalid EMOM Packet ID");
		return(0);      /* Not EESA MOMENT data    */
	}

	cfg = get_ECFG(pk->time);

	gap = 0;
	if(spin != pk->spin)
		gap = 1;
	spin = pk->spin;
	time = pk->time;

	for(i=0;i<16; i++){
		make_cmom_struct(&Emom[i].cmom,pk->data + i*14);
		Emom[i].spin = spin;
		Emom[i].time = time;
		Emom[i].gap = gap;
		Emom[i].dist.charge = 0;    /* default */
		calc_emom_param(&Emom[i],cfg);
		gap = 0;
		spin++;
		time += cfg->spin_period;
	}
	return(1);
}





/* Takes as input a byte stream and returns a compressed eesa moment structure*/
void make_cmom_struct(comp_eesa_mom *cmom,uchar *d)
{
	cmom->c0 = str_to_uint2(d);
	cmom->c1 = (schar)d[2];
	cmom->c2 = (schar)d[3];
	cmom->c3 = (schar)d[4];
	cmom->c4 = (schar)d[5];
	cmom->c5 = (schar)d[6];
	cmom->c6 = (schar)d[7];
	cmom->c7 = (uchar)d[8];
	cmom->c8 = (uchar)d[9];
	cmom->c9 = (uchar)d[10];
	cmom->c10 = (schar)d[11];
	cmom->c11 = (schar)d[12];
	cmom->c12 = (schar)d[13];
}




/* Takes 8-bit compressed quantities (cmom) and returns 32 bit uncompressed
numbers */
void decompress_eesa_mom(comp_eesa_mom *cmom,eesa_mom *mom)
{

	int exp;
	mom->m0 = decompress(cmom->c0 & 0x0fff,8) << 11; /* incomplete  */
	
	exp = 0;
	if(cmom->c1 & 0x40)   exp |= 0x04;
	if(cmom->c2 & 0x40)   exp |= 0x02;
	if(cmom->c3 & 0x40)   exp |= 0x01;
	if(cmom->c0 & 0x2000) exp |= 0x08;
	mom->m1 =  (long)(cmom->c1 & 0x3f) << (25-15+exp);
	mom->m2 =  (long)(cmom->c2 & 0x3f) << (25-15+exp);
	mom->m3 =  (long)(cmom->c3 & 0x3f) << (25-15+exp);
	if(cmom->c1 & 0x80) mom->m1 = -mom->m1;
	if(cmom->c2 & 0x80) mom->m2 = -mom->m2;
	if(cmom->c3 & 0x80) mom->m3 = -mom->m3;

	exp = 0;
	if(cmom->c7 & 0x80)   exp |= 0x04;
	if(cmom->c8 & 0x80)   exp |= 0x02;
	if(cmom->c9 & 0x80)   exp |= 0x01;
	if(cmom->c0 & 0x1000) exp |= 0x08;
	mom->m4 =  (long)(cmom->c4 & 0x7f) << (24-15+exp);
	mom->m5 =  (long)(cmom->c5 & 0x7f) << (24-15+exp);
	mom->m6 =  (long)(cmom->c6 & 0x7f) << (24-15+exp);
	mom->m7 =  (long)(cmom->c7 & 0x7f) << (24-15+exp);
	mom->m8 =  (long)(cmom->c8 & 0x7f) << (24-15+exp);
	mom->m9 =  (long)(cmom->c9 & 0x7f) << (24-15+exp);
	if(cmom->c4 & 0x80) mom->m4 = -mom->m4;
	if(cmom->c5 & 0x80) mom->m5 = -mom->m5;
	if(cmom->c6 & 0x80) mom->m6 = -mom->m6;

	exp = 0;
	if(cmom->c10 & 0x40)   exp |= 0x04;
	if(cmom->c11 & 0x40)   exp |= 0x02;
	if(cmom->c12 & 0x40)   exp |= 0x01;
	if(cmom->c0 & 0x4000) exp |= 0x08;
	mom->m10 =  (long)(cmom->c10 & 0x3f) << (25-15+exp);
	mom->m11 =  (long)(cmom->c11 & 0x3f) << (25-15+exp);
	mom->m12 =  (long)(cmom->c12 & 0x3f) << (25-15+exp);
	if(cmom->c10 & 0x80) mom->m10 = -mom->m10;
	if(cmom->c11 & 0x80) mom->m11 = -mom->m11;
	if(cmom->c12 & 0x80) mom->m12 = -mom->m12;

	if(cmom->c0 & 0x8000) mom->overflow =1;
	else mom->overflow = 0;
}


#define MAX_NORM_VEL 65535.
#define WS1  199500.
#define WS2  184000.
#define WS3  241000.



/*   WARNING!!!! geometric factor definitions have been changed!   */
/*   These calculations are NOT correct!!!!   */


/***************************************************************************
Calculates physical parameters of Density, solar wind velocity, pressure 
tensor  and heat flux.  Returns 0 on error.  Returns 1 if successful.  Assumes
the compressed moments and time are already stored in the structure Emom.
  INPUT: cmom, ECFG structure
  output: dist  (set valid flag as well!)
	Returns 0 on error.
	Returns 1 on success.
****************************************************************************/
int calc_emom_param(eesa_mom_data *Emom,ECFG *cfg)
{
	double dx,vel_0,vel_n;
	double Vs1,Vs2,Vs3,Vs4;
	double G;
	int    valid;
	eesa_mom mom;            /* temporary decompressed values */
/*	double energies[15];  */
	emomdata *P;             /* contains the physical quantities */
	int step1,step2;  /*   energy steps of interest */

	double el_geom;
	double spin_period;
	double *energies;       /* pointer to 15 energy steps */

	el_geom = cfg->el_geom;
	spin_period = cfg->spin_period;
	energies = cfg->elnrg15.mid;   /* middle of each energy step */	

	step1 = 5;     /* the actual value (0-14) should not matter */
	step2 = 12;    /* the actual value (0-14) should not matter */
	dx = log( energies[step1]/energies[step2] ) / (step2-step1);

	vel_0 = sqrt(2.*energies[0]/MASS_E)*1e5;       /* cm/sec */
	vel_n = sqrt(2.*energies[14]/MASS_E)*1e5;  

	G = el_geom * (spin_period/32./16.) * 22.5 * 2 / 4.1943e6;

	Vs1 = MAX_NORM_VEL * vel_n;
/* The previous value should be changed so that it is not sensitive to the
   calibrations at low energy steps */
	Vs2 = MAX_NORM_VEL;
	Vs3 = MAX_NORM_VEL / vel_0;
	Vs4 = MAX_NORM_VEL / vel_0 / vel_0;

	decompress_eesa_mom(&Emom->cmom,&mom); /* intermediate decom*/
	P = &Emom->dist;
	if(P->charge ==0){ P->charge = -1;  P->mass = MASS_E; }

	P->dens = mom.m0 * dx /(G*Vs1*WS1);  /* 1/cc */
	valid = 1;
	if(mom.m0==0){  valid = 0;  P->dens = 1.;  }

	P->v[0] = mom.m1 * dx /(G*Vs2*WS2) /1e5 / P->dens;   /* km/sec */
	P->v[1] = mom.m2 * dx /(G*Vs2*WS2) /1e5 / P->dens;   /* km/sec */
	P->v[2] = mom.m3 * dx /(G*Vs2*WS2) /1e5 / P->dens;   /* km/sec */

	P->vv[0][1] = P->vv[1][0] = mom.m4 * dx /(G*Vs3*WS3) /1e10 /P->dens;
	P->vv[0][2] = P->vv[2][0] = mom.m5 * dx /(G*Vs3*WS3) /1e10 /P->dens;
	P->vv[1][2] = P->vv[2][1] = mom.m6 * dx /(G*Vs3*WS3) /1e10 /P->dens;
	P->vv[0][0] = mom.m7 * dx /(G*Vs3*WS3) /1e10 /P->dens;
	P->vv[1][1] = mom.m8 * dx /(G*Vs3*WS3) /1e10 /P->dens;
	P->vv[2][2] = mom.m9 * dx /(G*Vs3*WS3) /1e10 /P->dens;

/* Special Note for heat flux:
/* The documentation maybe incomplete for definitions of heat flux */
/* moments.  There maybe a factor of 2^n that must be included; n=? */ 

	P->q[0] = mom.m10 * dx /(G*Vs4*WS2) /1e15 /P->dens;
	P->q[1] = mom.m11 * dx /(G*Vs4*WS2) /1e15 /P->dens;
	P->q[2] = mom.m12 * dx /(G*Vs4*WS2) /1e15 /P->dens;

 /* Temperature is added late; this is a quick kluge */
	P->temp = (P->vv[0][0] + P->vv[1][1] + P->vv[2][2])*P->mass/3.;

	if(mom.overflow) P->dens *= 8;
	if(valid == 0)
		P->dens = 0.;
/* rotate to (near) GSE coordinates: */
	P->v[0] = - P->v[0];     
        P->v[2] = - P->v[2];
        P->vv[0][1] = P->vv[1][0] =  - P->vv[0][1];       
        P->vv[0][2] = P->vv[2][0] =  - P->vv[0][2];   
	P->q[0] = - P->q[0];
	P->q[2] = - P->q[2];     



	Emom->valid = valid;
	return(1);
}




