#include "pckt_prt.h"
#include "brst_dcm.h"

#include "windmisc.h"


int packet_log(FILE *fp, packet *pk)
{
	static uint packet_number;
	static uint last_frame;
	char *str;

	if(fp==0)
		return(0);
	str = time_to_YMDHMS(pk->time);
	if(pk->idtype == HKP_ID>>16){
		fprintf(fp,"`Frame: %d\n",pk->data[1]);
		fprintf(fp,"`     UT    Spin  idtype   instseq    size    #   Time\n");
	}
	fprintf(fp,"%s  %04x  %04x  %04x  %4d  %6d\n",str,
	   pk->spin,pk->idtype,pk->instseq,
	   pk->dsize,packet_number);
	packet_number++;
	return(1);
}



FILE *unknown_pk_fp;

int print_unknown_packet(packet *pk)
{
	FILE *fp;
	if(unknown_pk_fp==0)
		return(0);
	fp = unknown_pk_fp;
	print_packet_header(fp,pk);
	fprintf(fp,"  %02x  %02x", pk->idtype>>8,  pk->instseq & 0xff);
	fprintf(fp,"  %02x  %02x", (pk->dsize+8) & 0xffu, (pk->dsize+8u) >> 8);
	fprintf(fp,"  %02x  %02x", pk->spin & 0xff,  pk->spin >> 8);
	fprintf(fp,"  %02x  %02x\n", pk->idtype & 0xff,  pk->instseq >> 8);
	print_packet_data(fp,pk,16,2);
	return(1);
}





int print_generic_packet(FILE *fp,packet *pk,int ncol)
{
	packet decomp;
	if(fp==0)
		return(0);
	print_packet_header(fp,pk);
	if(ncol){
/*		print_packet_data(fp,pk,ncol,2); */
		if(decompress_burst_packet(&decomp,pk)){
			fprintf(fp,"Uncompressed size:%d\n",decomp.dsize);
		}
		print_packet_header(fp,&decomp);
		print_packet_data(fp,&decomp,ncol,2);
	}
	return(1);
}


void print_packet_header(FILE *fp,packet *pk)
{	
	char *str;

	if(fp==0)
		return;
	str = time_to_YMDHMS(pk->time);
	fprintf(fp,"%10ld 0x%04x 0x%04x  0x%04x  %4d   %s\n",(long)pk->time,
	  pk->spin,pk->idtype,pk->instseq,pk->dsize,str);
}

void print_packet_data(FILE *fp,packet *pk,int nc,int format)
{
	int i,d;
	char *fmt;
	static char *fmts[4] = { " %3d", " %3u", "  %02x" , " %02x" };
	if(fp==0)
		return;
	fmt = fmts[format & 3];
	for(i=0;i<(int)pk->dsize;i++){
		if(format !=0) d = (uchar)(pk->data[i]);
		else d = (schar)(pk->data[i]);
		fprintf(fp,fmt,d);
		if(i%nc==nc-1) fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
}


#if 0

int print_list_array(pklist *list)
{
	packet **a;
	uint4  i,n;
	int (*print_routine)(packet *pk);

	a = list->array;
	n = list->numarray;
	print_routine = list->pckt_print;
	if(print_routine == 0)
		print_routine = print_generic_packet;
	if(a)
		for(i=0;i<n;i++)
			(*(print_routine))(a[i]);
	return(list->numarray);
}



int print_list(pklist *list)
{
	packet *pk;
	int (*print_routine)(packet *pk);

	pk = list->first;
	print_routine = list->pckt_print;
	if(print_routine == 0)
		print_routine = print_generic_packet;

	while(pk){
		(*(print_routine))(pk);
		pk = pk->next;
	}
	return(list->numlist);
}

#endif


