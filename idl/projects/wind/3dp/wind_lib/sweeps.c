#include "sweeps.h"


	
 /*                            KA_EH, KA_EL, KA_PH, KA_PL, KA_DEF      */
static double k_analyser[5] = { 6.42 , 6.42,  6.42 , 6.42 ,  0.0   };

static double offst_coeff[5][2][3] = {
/*                   High gain                 low gain                 */
/* eesah */      -20.737  , 0.0   , 0.0   ,    43.743  , 0.0   , 0.0   ,
/* eesal */      -60.658  , 0.0   , 0.0   ,    38.23 , -.5452  , 0.0   ,
/* pesah */       29.021  , 0.0   , 0.0   ,    87.87   , 0.0   , 0.0   ,
/* pesal */       32.90   , 0.0   , 0.0   ,    93.05   , 0.0   , 0.0   ,
/* deflt */        0.0    , 0.0   , 0.0   ,     0.0    , 0.0   , 0.0   };

static double slope_coeff[5][2][3] = {
/*                   High gain                 low gain                 */
/* eesah */       1.22012 , 0.0   , 0.0   ,  0.0729336 , 0.0   , 0.0   ,
/* eesal */       0.399661, 0.0   , 0.0   ,  0.0516865  , 0.0   , 0.0   ,
/* pesah */       1.22694 , 0.0   , 0.0   ,  0.0799144 , 0.0   , 0.0   ,
/* pesal */       1.22331 , 0.0   , 0.0   ,  0.0793421 , 0.0   , 0.0   ,
/* deflt */       1.48699 , 0.0   , 0.0   ,  1.48699  , 0.0   , 0.0   
};

#if 0
/* eesah */       0.81959 , 0.0   , 0.0   ,  13.71111 , 0.0   , 0.0   ,
/* eesal */       2.50212 , 0.0   , 0.0   ,  19.3474  , 0.0   , 0.0   ,
/* pesah */       0.81504 , 0.0   , 0.0   ,  12.5134  , 0.0   , 0.0   ,
/* pesal */       0.81745 , 0.0   , 0.0   ,  12.60364 , 0.0   , 0.0   ,
/* deflt */       0.6725  , 0.0   , 0.0   ,   0.6725  , 0.0   , 0.0   
#endif

int initialize_cal_coeff(int inst,double temp,sweep_cal *cal)
/* using instrument number and temperature; computes cal coeffecients */
{
	switch(inst){
		case EH:
			cal->inst_name = "Eesa High";  break;
		case EL:
			cal->inst_name = "Eesa Low";  break;
		case PH:
			cal->inst_name = "Pesa High";  break;
		case PL:
			cal->inst_name = "Pesa Low";  break;
		case DF:
			cal->inst_name = "Deflectors";  break;
		default:
			return(0);
	}

	cal->temperature = temp;
	cal->inst_num = inst;
	cal->offset_high = polynom3(&offst_coeff[inst][0][0],temp);
	cal->offset_low  = polynom3(&offst_coeff[inst][1][0],temp);
	cal->slope_high =  polynom3(&slope_coeff[inst][0][0],temp);
	cal->slope_low  =  polynom3(&slope_coeff[inst][1][0],temp);
	cal->k_analyser =  k_analyser[inst];
/*	cal->geom_factor = geom_factor[inst]; */

	return(1);
}


double polynom3(double *coeff,double x)
/*evaluates 3rd order polynomial */
{
	double d;
	d = (coeff[2] * x + coeff[1]) * x + coeff[0];
	return(d);
}




void compute_dac_table( sweep_def *par,uint2 *tbl,uint2 n)
{
	uint4 le;
	int i;
	uint2 e1;      /*  high,low gain energy values */

	le = (uint4)par->start_E << 16;
	for(i=0;i<(int)n;i++){
		e1 = (uint2)(le>>16);
		if(e1 < par->gs2)                    /* low gain  */
			tbl[i] = (uint2)( (((((le>>12)*par->m2)>>15)+par->s2)>>4)
			         | 0x1000);
		else                                /* high gain */
			tbl[i] = ((uint2)(e1+par->s1)>>4);        /* divide by 16 */
		le = lumult_lu_ui(le,par->k_sw);
	}
}



uint4 lumult_lu_ui(uint4 l,uint2 ui)
  /* 32 x 16 bit multiply (unsigned)     returns:  Product/2^16  */
{
	uint2 l1;
	uint2 l2;
	uint4 p;

	l1 = (uint2)(l >> 16);       /*  high order  */
	l2 = (uint2)(l & 0xffff);    /*  low  order  */
	p = (uint4)l1*ui + (((uint4)l2*ui)>>16); 
	return(p);
}





double dac_to_voltage(uint2 dac,sweep_cal *cal)
{
	double v;
	uint2 gain;
	gain = dac & 0x1000;

	if(dac & 0x1000)     /*  low gain  */
		v = ((dac & 0x0fffu) - cal->offset_low ) * cal->slope_low;
	else
		v = ((dac & 0x0fffu) - cal->offset_high) * cal->slope_high;
	return(v);
}


double dac_to_energy(uint2 dac,sweep_cal *cal)
{
	return( cal->k_analyser * dac_to_voltage(dac,cal) );

}


