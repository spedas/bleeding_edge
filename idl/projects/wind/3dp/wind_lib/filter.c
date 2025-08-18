#include "filter.h"

#include "wind_pk.h"
#include "windmisc.h"
#include "ecfg_dcm.h"

#include <memory.h>
#include <math.h>
#include <string.h>

/* #define DEBUG */
#define ROBUST

/*
    This program is designed as a front end filter for WIND data 
    files.   The source files can be either "RAW" or "HKP" type, 
    and can handle RAW files that include the thermister values. 
    It can be easily modified to accomodate the (assumed) 
    final format of the data files from Goddard. 
           Written by Davin Larson   1-10-94. 

  -   Modified to accept all data formats 
*/

int pkquality = 0;
double cur_spin_period = 3.0;

static file_info data_file;

#define NASA_HDR_LEN		  300		/* NASA record header length  */
#define NASA_REC_LEN		12800		/* NASA record length	      */
#define NASA_CLOCK_OFFSET	   12		/* NASA SC clock offset value */
#define NASA_ATC_OFFSET		   20		/* NASA ATC clock offset value*/
#define NASA_MODE_OFFSET   	   44		/* NASA file mode offset value*/
#define LZ_FILL_ERROR_POS     	   36		
#define LZ_SYNC_ERROR_POS 	   40
#define LZ_MINOR_QUAL_POS	   48	

#define MAX_KPDBYTES   33
#define MAX_HKPBYTES   54
#define MAX_THMBYTES   4

#define MAX_RECORDSIZE  12800

static uchar    recbuff[MAX_RECORDSIZE];

static uchar    sci_3dp[12400];           /* 3DP science data  (packet data) */
static uchar    hkp_3dp[MAX_HKPBYTES];    /* 3DP house keeping data          */
static uchar    kpd_3dp[MAX_KPDBYTES];    /* 3DP key parameters data         */
static uchar    thm_3dp[MAX_THMBYTES];    /* 3DP Thermister values           */
static uchar    qual_sc[12400];		  /* Quality of science data         */

static struct t0_speriod {
    double 	t0;
    double 	speriod;
    boolean_t 	set;
    double 	frame_spin;
} t0_speriod_array [16];


/*Declare private functions */
/*~~~~~~~~~~~~~~~~~~~~~~~~~ */
 
 double spin_time(uchar *pk,int2 phase,frameinfo *frame);
 uint   sort_frame(uchar *fptr,uint2 *byte_shift,frameinfo *frame);
  int   get_byte_map(uchar byte_map[],int spc_mode,int file_type);
  int   btype_sci_mode(uint u);
  int   btype_man_mode(uint u);
  int   sort_packets(uint2 *byte_shift,frameinfo *frame);
  int   do_packet(uchar *pk,frameinfo *frame,uchar *firstq);
 void   set_spc_mode(uchar *record,frameinfo *frame);
 void   set_frame_time(uchar *record,file_info *file,frameinfo *frm);
 void   set_spin_time(frameinfo *frame);
 void   make_hkp_packet(frameinfo *frame);
 void   make_kpd_packet(frameinfo *frame);
 void   make_frame_info_packet(frameinfo *frame);
 void   hkptlm(FILE *fp);
 void   determine_file_type(FILE *fp,file_info *file);
 int    gse_header_size(char *hdr,int n);
 int    load_data_file(char *filename,double *t1,double *t2);
 int   spc_telem_rate(int spc_mode);
 int   correct_gse_frame_time(double last_t,double *t,int last_rate,int rate);

int inst_telem_mode(uchar c);
int  set_telem_errors(uchar *recbuff,frameinfo *frm);
void fill_frame_telem_info(struct frameinfo_def *frm);


static double atc_clock(uchar*);			/* ATC time conversion*/
static double spacecraft_clock(uchar*);			/* spacecraft time    */
static double seconds_since_year(int4, int4, int4, 	/* time conversion    */
				 double);

#include "date.h"

int load_all_data_files(char *mastfilename,double begin, double end, int buffsize, void *buffptr)
{	
	int err;
	err = load_all_data_files_p(mastfilename,&begin,&end,buffsize,buffptr);
	return(err);
}


int load_all_data_files_p(char *mastfilename,double *begin, double *end, int buffsize, void *buffptr)
{
	FILE *mfp;
	char buff[300];
	char date1[30];
	char date2[30];
	char fname[300];
	double file_begin_time;
	double file_end_time;
	double t1,t2;
	long mem_left;
	int status,n;

		
	if(buffsize){
		fprintf(stdout,"Wind Data Extraction Library. (compiled: %s)\r\n", compile_date);
		init_decomp19_8();
		init_decomp12_8();
		initialize_raw_memory(buffsize,buffptr);
	}
	
	mfp = fopen(mastfilename,"r");
	if(mfp==0){
		fprintf(stdout,"File %s not found\r\n", mastfilename);
		return(0);
	}
	else{
		fprintf(stdout,"Using %s as the data source.\r\n",mastfilename);
	}

	while(fgets(buff,300,mfp)){
		sscanf(buff,"%s %s %s",date1,date2,fname);
		if(buff[0]=='#' || fname[0]=='#') 
			continue;             /* comment line */
		file_begin_time = YMDHMS_to_time(date1);
		file_end_time   = YMDHMS_to_time(date2);
		if(file_end_time < *begin)          /* skip early files */
			continue;
		if(file_begin_time > *end)          /* break after last file */
			continue;
		if(*begin==*end){
			t1 = file_begin_time;
			t2 = file_end_time;
		}
		else{
			t1 = *begin;
			t2 = *end;
		}
		status = load_data_file(fname,&t1,&t2);
		if (status == -1)
			break;
	}
	if(*begin ==0){                    /* load only last file */
		*begin = file_begin_time;
		if(*end >0 && *end < 72.*3600.)
			*end += file_begin_time;
		else
			*end   = file_end_time;
		status = load_data_file(fname,begin,end);	
	}
	fprintf(stdout,"Done with file input.\r\n");
	fclose(mfp);

	make_all_list_arrays();
	
	mem_left = find_mem_left();
#if 0
(Free the memory where it is malloced)
	free_unused_memory(&buffsize,buffptr);
#endif
	return(mem_left);
}


#if 1
int determine_3dpfile_times(char *filename,double *begin_time,double *end_time)
{
	FILE *fp;
	int n;
	file_info file;
	frameinfo frame;

	fp = fopen(filename,"rb");
	if(fp==0){
		fprintf(stderr,"File %s not found!\n",filename);
		return(0);
	}

	determine_file_type(fp,&file); /* file pointer left at beginning of 1st rec */
	
	if(file.file_type == FILE_INVALID){
		fclose(fp);
		fprintf(stderr,"File %s is not a WIND-3DP data file!\n",
filename);
		return(0);
	}
	if(file.file_type == FILE_GSE_HKP){
		fclose(fp);
		return(0);    /* housekeeping files no longer supported */
	}
	if(file.file_type == FILE_MASTER){
		char s[360];
		char date1[30],date2[30],name[300];
		n = 0;
		while( fgets(s,300,fp) ){
			if(s[0] == '#')
				continue;
			sscanf(s,"%s %s %s",date1,date2,name);
			if(n++ == 0)
				*begin_time = YMDHMS_to_time(date1);
			*end_time = YMDHMS_to_time(date2);
		}
		fclose(fp);
		return(file.file_type);    /* master file */
	}
	       /* determine time of first frame */
	n=fread((char*)recbuff,1,file.rcd_size,fp);
	frame.time = 0;
	set_frame_time(recbuff,&file,&frame);
	*begin_time = frame.time;

		/* determine time of last frame */
	fseek(fp,-(long)file.rcd_size,SEEK_END);  /* set to last record */
	n=fread((char*)recbuff,1,file.rcd_size,fp);
	frame.time = 0;
	set_frame_time(recbuff,&file,&frame);
	*end_time = frame.time;
	
	fclose(fp);
	return(file.file_type);
}
#endif

	



int load_data_file(char *filename,double *t1,double *t2)
{
	FILE *fp;
	double start_time=0;
	int n, m, memcheck=0;
	static frameinfo frame;
	static uint2 byte_shift;   /* determines the byte offset in sci_3dp */
	uint4 bad_frame_code;

	bad_frame_code = ERROR_DIFFERENT_MODES | ERROR_BAD_FRAME_SPIN;

	fp = fopen(filename,"rb");
	if(fp==0){
		fprintf(stdout,"File %s not found!\r\n",filename);
	}
	if(fp)
		fprintf(debug,"Loading file %s...\r\n",filename);
	else
		return(0);

	determine_file_type(fp,&data_file);
	
	if(data_file.file_type == FILE_INVALID){
		fclose(fp);
		return(0);
	}
	if(data_file.file_type == FILE_GSE_HKP){
		fclose(fp);
		return(0);    /* housekeeping files no longer supported */
	}
	if(data_file.file_type == FILE_MASTER){
/*		char s[360]; */
/*		char date1[30],date2[30],name[300]; */
/*		if(fgets(s,300,fp)) */
/*			sscanf(s,"%s %s %s",date1,date2,name); */
/*		else */
/*			name[0] = 0; */
		fclose(fp);
		load_all_data_files_p(filename,t1,t2,0,0);
		return(1);
	}
	
	while((n=fread((char*)recbuff,1,data_file.rcd_size,fp))
                                                   ==data_file.rcd_size){
		frame.errors = 0;
		frame.good = frame.bad = frame.ugly = 0;
		
		for(m=0;m<MAX_TELEM_TYPES;m++)
			frame.telem[m] = 0;

#if 0
		frame.main_telem = frame.eesa_telem = 0;
		frame.pesa_telem = frame.fpc_telem = 0;
#endif
		frame.npkts = 0;
		frame.nsci = frame.nhkp = frame.nkpd = frame.nthm = 0;
		frame.main_packet_types = frame.eesa_packet_types = 0;
		frame.pesa_packet_types = 0;

		set_frame_time(recbuff,&data_file,&frame);
			/* Check time limits */
		if(frame.time < *t1 -100.)       /* not efficient but o.k. */
			continue;
		if(frame.time > *t2 +100.)
			break;
		if(start_time==0)
			start_time = frame.time;

		if (frame.errors & ERROR_MODE_INVALID){
			frame.spin = frame.phase = 0;
			frame.dspin = 0.;
			frame.seq = 0;
			byte_shift = 0;
		}
		else{
			sort_frame(recbuff+data_file.hdr_size, &byte_shift,
				&frame);
			if(inst_telem_mode(hkp_3dp[0]) != frame.spc_mode)
				frame.errors |= ERROR_DIFFERENT_MODES;
			set_telem_errors(recbuff,&frame);
			set_spin_time(&frame);

				/* Store the data in memory.....  */
			if(!(frame.errors & bad_frame_code)){
				sort_packets(&byte_shift,&frame);
				if(!(frame.errors & ERROR_TELEM)){
					make_hkp_packet(&frame); 
					make_kpd_packet(&frame);
				}
			}
		}
		fill_frame_telem_info(&frame);
		make_frame_info_packet(&frame);
		memcheck = memory_filled();
		if (memcheck)  {
			fprintf(debug,"%s : Memory buffer filled.\r\n", 
                             time_to_YMDHMS(frame.time));
			break;
		}
		frame.counter++;
	}
	if(n)
		fprintf(debug,"File incompletely loaded.\r\n");

	fclose(fp);
	*t1 = start_time;
	*t2 = frame.time;

	return(memcheck ? -1 : data_file.file_type);	
}







int set_telem_errors(uchar *recbuff,frameinfo *frm)
{
	if(data_file.file_type == FILE_NASA_LZ){
		frm->num_fill_bytes  = str_to_int4(recbuff + LZ_FILL_ERROR_POS);
		frm->num_sync_errors = str_to_int4(recbuff + LZ_SYNC_ERROR_POS);
		if(frm->num_fill_bytes)
			frm->errors |= ERROR_FILL_BYTES;
		if(frm->num_sync_errors)
			frm->errors |= ERROR_FRAME_SYNC;
	}
	
	return(0);
}






#ifdef DEBUG
#include "frame_prt.h"
#endif


/*----------------------------------------------------------------------------*/

 
   /* byte types used in the sort frame routine */
#define SPCT  0x10
#define P3DP  0x20
#define OTHR  0x30

#define THM   0x01
#define SCI   0x02
#define HKP   0x03
#define KPD   0x04

/****************************************************************************
The sort_frame routine takes a pointer to a raw frame of data and sorts
the bytes into several different byte arrays:  
	sci_3dp   (science packets)
	hkp_3dp   (housekeeping data)
	kpd_3dp   (keyparameter data)
	thm_3dp   (thermistor data)
Fill bytes (if any) are discarded.
***************************************************************************/
uint sort_frame(uchar *fptr,uint2 *byte_shift,frameinfo *frame)
{
	unsigned int  b;
	unsigned char *bptr,*sptr,*hptr,*kptr,*tptr,*qptr;
	static uchar byte_map[MAX_RECORDSIZE];  /* used for sorting */
	static int l_spc_mode,l_file_type;
	static int nbytes;
	int i,mframe_size;
	
	if(frame->errors & ERROR_FRAME_GAP)
		*byte_shift = 0;
	bptr = fptr;
	sptr = sci_3dp + *byte_shift;
	hptr = hkp_3dp;
	kptr = kpd_3dp;
	tptr = thm_3dp;
	qptr = qual_sc + *byte_shift;
	
	if(l_spc_mode != frame->spc_mode || l_file_type != data_file.file_type){
#ifdef DEBUG
		fprintf(debug,"`%s  New mode:%s\n", time_to_YMDHMS(frame->time), spc_mode_str(frame->spc_mode));
#endif
		l_spc_mode = frame->spc_mode;
		l_file_type = data_file.file_type;
		nbytes = get_byte_map(byte_map,frame->spc_mode, data_file.file_type);	
		frame->nbytes = nbytes;
	}
	
	for (i=0; i<250; i++)
		frame->minor_frame_quality[i] = *(recbuff +
			LZ_MINOR_QUAL_POS + i);
	mframe_size = nbytes/250;
	
	for(b=0;b<nbytes;b++){
		switch(byte_map[b]){
			case(P3DP | SCI):
				*sptr++ = *bptr++;
				if (frame->minor_frame_quality[b/mframe_size])
					*qptr++ = 1;
				else
					*qptr++ = 0;
				break;
			case(P3DP | HKP):  *hptr++ = *bptr++;  break;
			case(P3DP | KPD):  *kptr++ = *bptr++;  break;
			case(P3DP | THM):  *tptr++ = *bptr++;  break;
			default:  bptr++;  break;      /* other data */
		}
	}
	frame->nsci = (sptr - sci_3dp) - *byte_shift;
	frame->nhkp = hptr - hkp_3dp;
	frame->nkpd = kptr - kpd_3dp;
	frame->nthm = tptr - thm_3dp;
	return(bptr - fptr);
}





/****************************************************************************
This routine will create a byte map to be used by the sort_frame routine.
It only needs to be called once at start-up or when the spacecraft mode or
file_type changes.
***************************************************************************/
int get_byte_map(uchar byte_map[],int spc_mode,int file_type)
{                            
	uint u,b,sf,n;
	uchar btype;

	n = 0;
	for(sf=0;sf<250;sf++){
		for(b=0;b<256;b++){
			u = (sf<<8) + b;
			if(n>=MAX_RECORDSIZE){
				fprintf(stderr,"Byte map overflow\n");
				return(0);
			}
			switch(spc_mode){
				case SPC_MODE_SCI1x:
				case SPC_MODE_CON1x:
				case SPC_MODE_SCI2x:
				case SPC_MODE_CON2x:
					btype = btype_sci_mode(u);
					break;
				case SPC_MODE_MAN1x:
				case SPC_MODE_MAN2x:
					btype = btype_man_mode(u);
					break;
				default:
					return(0);
			}
			switch(file_type){
				case FILE_GSE_RAW:  
				case FILE_GSE_ENG:  
					if((btype & 0x0f) == THM )
						break;  /* No thermister byte */
				case FILE_GSE_THERM:
				case FILE_GSE_FLT: 
					if((btype & 0xf0) == P3DP )
						byte_map[n++] = btype;
					break;
				case FILE_NASA_LZ:   /*  NASA level 0 file */
				case FILE_NRT_LZ:    /*  NASA level 0 file */
					if((b>=17&&b<=19)||(btype&0xf0)== P3DP)
						byte_map[n++] = btype;
					break;
				default:
					return(0);
			}
		}
	}
	return(n);
}




/*   Returns the byte type in science mode */
btype_sci_mode(unsigned int u)   /* 0 <= u < 64000 */
{
	unsigned int subframe;
	unsigned int byte;
	unsigned int mod;

	subframe = u >> 8;      /*  u/256  */
	byte     = u & 0xff;    /*  u%256  */
	if(byte > 20){                          /*  science data */
		if((byte & 0x03)==3 && byte <= 207 ){    /*  3DP  data  */
			if(u<=35)           /* first four bytes are hkp */
				return(P3DP | HKP);
			if(u<=167)           /* Next 33 bytes are KPD  */
				return(P3DP | KPD);
			else
				return(P3DP | SCI);
		}
		else                      /*  other people's science data */
			return(OTHR);
	}
	if(byte <= 16)                         /*  spacecraft data */
		return(SPCT);
	mod = subframe%10;
	if(byte==17){
		if(mod == 6 || mod==9)
			return(P3DP | HKP);
		else
			return(OTHR | HKP);
	}
	if(byte ==18){
		if(subframe==26 || subframe==36 || subframe==46 || subframe==56)
			return(P3DP | THM);
		else
			return(OTHR | HKP);
	}
	if(byte == 19){
		if(mod== 1 || mod==3 || mod==5 || mod==7)
			return(P3DP | SCI);
		else
			return(OTHR | SCI);
	}
	if(byte == 20)
		return(OTHR | SCI);
	return(0);    /* this line should never be encountered */
}



/* Returns the byte type for manueveur mode */
btype_man_mode(unsigned int u)   /* 0 <= u < 64000 */
{
	unsigned int subframe;
	unsigned int byte;
	unsigned int mod;

	subframe = u >> 8;      /*  u/256  */
	byte     = u & 0xff;    /*  u%256  */
	if(byte > 32){                                       /*  science data */
		if((byte%8==3 || byte%16==7) && byte <= 207 ){   /*  3DP  data  */
			if(u<=51)           /* first four bytes are hkp */ 
				return(P3DP | HKP);
			if(u<=203)           /* Next 29 bytes are KPD */
				return(P3DP | KPD);
			else
				return(P3DP | SCI);
		}
		else                               /*  other people's science data */
			return(OTHR);
	}
	if(byte <= 16)                         /*  spacecraft data */
		return(SPCT);
	mod      = subframe%10;
	if(byte==17){
		if(mod == 6 || mod==9)
			return(P3DP | HKP);
		else
			return(OTHR | HKP);
	}
	if(byte ==18){
		if(subframe==26 || subframe==36 || subframe==46 || subframe==56)
			return(P3DP | THM);
		else
			return(OTHR | HKP);
	}
	if(byte == 19){
		if(mod== 1 || mod==3 || mod==5 || mod==7)
			return(P3DP | SCI);
		else
			return(OTHR | SCI);
	}
	if(byte == 20)
		return(OTHR | SCI);
	return(0);    /* this line should never be encountered */
}



/****************************************************************************
sort_packets() will run through the sci_3dp character array and determine the
beginning of each new packet.  It will then pass a pointer to the packet
stream to the routine do_packet().
Error checking is performed here.  A count of errors and types of errors are
saved in the structure "frame". 
All of the important quantities are stored in the structure "frame".
*****************************************************************************/
int sort_packets(uint2 *byte_shift,frameinfo *frame)
{                    /* This routine assumes that sci_3dp[] */
                     /* and sci_hkp[] are currently filled  */
	uchar *ptr,*firstq,*qptr;
	uchar last_seqp1;  /* last sequence number plus 1 */
	int d,size,type=0;
	static int last_type=0;

	frame->good = frame->bad = frame->ugly = frame->npkts = 0;
#if 0
	frame->main_telem = frame->pesa_telem = 0;
	frame->eesa_telem = frame->fpc_telem = 0;
#endif
	for(d=0;d<MAX_TELEM_TYPES;d++)
		frame->telem[d] = 0;

	last_seqp1      = ((int)frame->seq + 1) %256;
	frame->seq       = hkp_3dp[1];   
	frame->offset    = (hkp_3dp[3]<<8) | hkp_3dp[2];  

	if(frame->seq != last_seqp1){
		frame->errors |= ERROR_NON_CONSEC_FRAMES;
#ifdef DEBUG
		fprintf(debug,"`%s  Non-consecutive frames.\n",  time_to_YMDHMS(frame->time));
#endif
	}
	else if(*byte_shift){
		size = packet_size(sci_3dp);
		if(size == *byte_shift+frame->offset){ /* sync ok  */
			firstq = memchr(qual_sc,1,size);
			type = do_packet(sci_3dp,frame,firstq); /*  salvage packet */
			if(type){
				if(!firstq) {
					frame->good += size - *byte_shift;
					frame->telem[type] += size;
				}
				else
					frame->bad += size - *byte_shift;
				frame->npkts++;
				last_type = type;
			}
			else{    /* invalid packet type */
				frame->errors |= ERROR_INVALID_PACKET;
			}
		}
		else{
			frame->errors |= ERROR_OFFSET_MISMATCH;
#ifdef DEBUG
			fprintf(debug,"`%s  Offset error  %d + %d != %d.\n", time_to_YMDHMS(frame->time),frame->offset,*byte_shift,size);
#endif
		}
	}

	ptr = sci_3dp + *byte_shift;
	qptr = qual_sc + *byte_shift;
	d = frame->offset;
	while(d < (int)frame->nsci){
		if( ptr[d] ==0 ){
			frame->errors |= ERROR_ZERO_BYTES;  
			frame->bad++;                     /*  count zero bytes */
			d++;
			continue;
		}
		if( ptr[d] <=1 ){              /*  skip any missed telemetry  */
			frame->ugly++;        /*  count unused telemetry bytes */
			d++;
			continue;
		}
		if(d > (int)frame->nsci-8)
			break;                      /* packet header is split */
		size = packet_size(ptr+d);
		if(size<8 || size>508){              /* invalid packet length */
			frame->errors |= ERROR_PACKET_LENGTH; /* set error flag*/
#ifdef DEBUG
			fprintf(debug,"`%s  Invalid packet length of %d bytes\n",time_to_YMDHMS(frame->time), size);
#endif
			frame->bad++;
#ifdef ROBUST
			mark_last_packet_as_suspect(last_type);
			last_type = 0;
			d++;
			continue;
#else
			d = frame->nsci;        /* will force *byte_shift to 0 */
			break;
#endif
		}
		if(d+size < (int)frame->nsci){                   /* complete packet */
			firstq = memchr(qptr+d,1,size);
			type = do_packet(ptr+d,frame,firstq); /* process it */
			if(type){
				size = packet_size(ptr+d); /*size can be fixed*/
				d += size;
				if(!firstq) {
					frame->good += size;
					frame->telem[type] += size;
				}
				else
					frame->bad += size;
				frame->npkts++;
				last_type = type;
			}
			else{
				frame->errors |= ERROR_INVALID_PACKET;
#ifdef DEBUG
				fprintf(debug,"`%s  Invalid packet type %08x\n",time_to_YMDHMS(frame->time),packet_id(ptr+d));
#endif
				frame->bad++;
#ifdef ROBUST
				mark_last_packet_as_suspect(last_type);
				last_type = 0;
				d++;
				continue;
#else
				d += size;
#endif
			}
		}
		else
			break; /*split packet, deal with it on the next frame */
	}

	*byte_shift = frame->nsci-d;  /* number of bytes of partial packet */
	if(*byte_shift > 508){                     
#ifdef DEBUG
		fprintf(debug,"`%s  Frame shift error\n", time_to_YMDHMS(frame->time));
#endif
		frame->errors |= ERROR_FRAME_SHIFT;
		*byte_shift=0;
	}
	memcpy(sci_3dp,ptr+d,*byte_shift); /*copy partial packet to beginning */
	memcpy(qual_sc,qptr+d,*byte_shift);
	frame->good += *byte_shift;               /*  presumably good data */
	return(frame->npkts);
}

#if 0
int do_telem_sort(int type,int size,frameinfo *frame)
{
	switch (type) {
	case 4:
	case 5:
	case 6:
	case 7:
	case 8:
	case 9:
	case 45:
	case 46:
	case 47:
		frame->eesa_telem += size;
		break;
	case 10:
	case 11:
	case 12:
	case 13:
	case 40:
	case 41:
	case 42:
	case 43:
	case 44:
		frame->pesa_telem += size;
		break;
	case 14:
	case 15:
	case 16:
		frame->fpc_telem += size;
		break;
	default:
		frame->main_telem += size;
		break;
	}
	return(0);
}
#endif


/* Determines the real time of a packet and sends it on for processing */
int do_packet(uchar *pk,frameinfo *frame, uchar *firstq)
{
	double time;
	uint4 errors;
	uint2 quality;
	time = spin_time(pk,0,frame);
	errors = frame->errors;
	if (frame->errors & ERROR_FILL_BYTES)
		errors |= (QUALITY_FILL_INFRAME << 16);
	if (firstq)
		errors |= (QUALITY_FILL_INPACKET << 16);
	return(process_packet(time,errors,pk));
}


/* Determines the spacecraft mode (science or manuever) from the file header. */
void set_spc_mode(uchar *record,frameinfo *frame)
{
	int c;

	switch(data_file.file_type){
	case FILE_GSE_RAW: 
	case FILE_GSE_THERM:
	case FILE_GSE_FLT:
	case FILE_GSE_ENG:
		frame->spc_mode=inst_telem_mode(*(record+data_file.hdr_size));
		break;
	case FILE_NASA_LZ:
	case FILE_NRT_LZ:
		c = str_to_int4((uchar*)record+NASA_MODE_OFFSET);
		if( c!=SPC_MODE_SCI1x && c!=SPC_MODE_MAN1x
		 && c!=SPC_MODE_SCI2x && c!=SPC_MODE_MAN2x )
			c = SPC_MODE_INVALID;
		frame->spc_mode = c;
		break;
	default:              /* error */
		frame->spc_mode = SPC_MODE_INVALID;
	}
	if(frame->spc_mode == SPC_MODE_INVALID)
		frame->errors |= ERROR_MODE_INVALID;
/*	if(frame->spc_mode != inst_telem_mode) */
/*		frame->errors |= ERROR_DIFFERENT_MODES; */
}





/* returns Telemetry mode given first HKP byte  */
int inst_telem_mode(uchar c)
{
	switch(c & 0x0B){
		case 1:
			return(SPC_MODE_SCI1x);
		case 2: 
			return(SPC_MODE_MAN1x);
		case 9:
			return(SPC_MODE_SCI2x);
		case 10: 
			return(SPC_MODE_MAN2x);
		default:
			return(SPC_MODE_INVALID);
	}	
}




/*********************************************************************** */
/*  sets the parameters: */
/*	frame->time;   (at begining of frame) */
/*	frame->spc_mode; */
/*      frame->errors;     */
/*  The following is expected to be set already: */
/*	frame->file_type */
/*	frame->time      (from previous frame) */
/*	frame->spc_mode  (from previous frame) */

void set_frame_time(uchar *record,file_info *file,frameinfo *frm)
{
	double last_time,time,dt;
	int    last_rate,rate;
	static float dft[3] = {0., 92, 46.}; 
	
	last_time = frm->time;
	last_rate = spc_telem_rate(frm->spc_mode);
	set_spc_mode(record,frm);
	rate = spc_telem_rate(frm->spc_mode);
	if(rate==0)
		rate = last_rate;   
	
	switch(file->file_type){
	case FILE_GSE_RAW:
	case FILE_GSE_THERM:       
		time = MDYHMS_to_time((char *)(record+9));
			 /* subtract frame duration for old files */
		time -= dft[rate];
		if(correct_gse_frame_time(last_time,&time,last_rate,rate))
			frm->errors |= ERROR_GSE_TIME_CORRECT;
		frm->time = time;
		break;	
	case FILE_GSE_FLT:   /* It is assumed that GMT is recorded */
	case FILE_GSE_ENG:
		time = MDYHMS_to_time((char *)(record+5));
		frm->time = time;  
		break;	
	case FILE_NASA_LZ:    
	case FILE_NRT_LZ:
		frm->time = atc_clock(record + NASA_ATC_OFFSET); 
/*		frm->time = spacecraft_clock(record + NASA_CLOCK_OFFSET); */
		break;
	default:
		fprintf(stderr,"Illegal File type\n");
	}
	dt = frm->time - last_time;
	if(dt > dft[last_rate] + 3. || dt<=0)
		frm->errors |= ERROR_FRAME_GAP;
}



/*  returns the telemetry rate: 0 unknown;   1: 1x;    2: 2x  */
int spc_telem_rate(int spc_mode)
{

	switch(spc_mode){
		case SPC_MODE_SCI1x:
		case SPC_MODE_MAN1x:
		case SPC_MODE_CON1x:
		case SPC_MODE_ENG1x:
			return(1);
		case SPC_MODE_SCI2x:
		case SPC_MODE_MAN2x:
		case SPC_MODE_CON2x:
		case SPC_MODE_ENG2x:
			return(2);
		default:
			return(0);
	}
}



/**************************************************************************
Determines spin number, inst_mode, start time and spin_period from the frame header.
This routine needs work!!!!!
***************************************************************************/
#define TIME_ERR (ERROR_SPIN_ROLLOVER | ERROR_SPIN_RESET | ERROR_BAD_FRAME_SPIN)
void set_spin_time(frameinfo *frame)
{
	double creep;
	double spin_period;
	double fspin_x,fspin;
	static double lastfspin,lasttime;
	static double startspin,starttime;   /* used to compute spin period */
	static int lasterror;
	
/*#define FILTER_DEBUG*/
#if defined(FILTER_DEBUG)

    extern FILE *info_fp;
	if ( info_fp )
	    {
		fprintf(info_fp,"         init vals: ");
		fprintf(info_fp,"%5d ",frame->counter);
		fprintf(info_fp,"%3d %5d %6.4f ",frame->seq, frame->spin, frame->dspin);
		fprintf(info_fp,"%6.4f ",frame->spin_period);
		fprintf(info_fp,"%5d %3d ", frame->good+frame->ugly+frame->bad, frame->npkts);
		fprintf(info_fp,"%4.1lf ",frame->creep);
		fprintf(info_fp,"%4d ",frame->bad);
		fprintf(info_fp,"<%s> ",bit_pattern_o(frame->errors,ERROR_STRING));
		fprintf(info_fp,"\n");
	    }
#endif /* FILTER_DEBUG */

	frame->inst_mode =  hkp_3dp[0];
	frame->spin      = (hkp_3dp[5]<<8) + hkp_3dp[4];
	frame->phase     =  hkp_3dp[7]>>4;
	frame->fspin = frame->spin + (((double)frame->phase)/16.);
	frame->dspin = frame->fspin - lastfspin;
	frame->burst_num = hkp_3dp[20] & 0xf;
	if(frame->dspin < 0)
		frame->dspin = -1.;
	if(frame->dspin >=100)
		frame->dspin = 99.;

	if((frame->time < lasttime)||(frame->time > lasttime+3600.)){  /*reset*/
		lasttime  = 0;
		lastfspin = 0;
		starttime = 0;
		startspin = 0;
		lasterror = 0;
	}
	
/*	frame->spin_period = 3.-.000368; */        /* for Berkeley therm-vac */
	if(frame->spin_period < 2.6 || frame->spin_period > 3.6)
		frame->spin_period = 3.0;                   /* nominal value */


	fspin = frame->fspin;

	if(lasterror & ERROR_BAD_FRAME_SPIN)
		fspin_x = fspin;
	else
		fspin_x = lastfspin + (frame->time-lasttime)/frame->spin_period;

	if(lasttime && fabs(fspin_x - fspin) > 3.){
		if(fabs(fspin_x - fspin - 65536.) < 3.)
			frame->errors |= ERROR_SPIN_ROLLOVER;
		else if((fspin > 0.) && (fspin < 32.))
			frame->errors |= ERROR_SPIN_RESET;
		else{
			frame->errors |= ERROR_BAD_FRAME_SPIN;
			fspin = fspin_x; /* prevents new spin time calculation*/
		}
	}


/* calculate new start time whenever it drifts too much*/

	creep= frame->time - (fspin * frame->spin_period) - frame->spin0_time;
	if((fabs(creep) > .5) && !(frame->errors & ERROR_TELEM)){
		frame->errors |= ERROR_NEW_SPIN0_TIME;
		if( !(frame->errors & TIME_ERR) ){
			spin_period = (frame->time-starttime)/(frame->fspin-startspin);
			if(fabs(spin_period - 3.) < .3)
				frame->spin_period = spin_period;
		}
		frame->spin0_time= frame->time-frame->fspin*frame->spin_period;
		starttime = frame->time;
		startspin = frame->fspin;
	}

	frame->creep= creep;

	lastfspin = frame->fspin;
	lasttime  = frame->time;
	lasterror = frame->errors;

	/* fill array of frame times/spin periods vs burst cntr */

	t0_speriod_array[frame->burst_num].t0 = frame->spin0_time;
	t0_speriod_array[frame->burst_num].speriod = frame->spin_period;
	t0_speriod_array[frame->burst_num].set = B_TRUE;
	t0_speriod_array[frame->burst_num].frame_spin = frame->spin;
if(frame->spin_period != cur_spin_period){
	fprintf(stderr,"frame: %s, Period: %lf\r\n",
		time_to_YMDHMS(frame->time), frame->spin_period);

}

	cur_spin_period = frame->spin_period;

#if defined (SETSPINTIME_DEBUG)
	fprintf(stderr,"frame-t0: %s, -Sping Period: %lf, Burst #: %u\r\n",
		time_to_YMDHMS(frame->spin0_time), frame->spin_period, frame->burst_num);
#endif


}



/*  Determines absolute time from the packet spin counter */ 
double spin_time(uchar *pk,int2 phase,frameinfo *frame)
{
	double fspin,time;
	int4 ps,fs;     /* packet spin number and frame spin number */
	int lowerlim = 300;
	int upperlim = 30;
	int brst_num ;
	double spin0_time ;
	double spin_period ;

	/* decide which t0_speriod_array element to get spin and timing
	 * info from.
	 */
	
	brst_num = frame->burst_num ;
	if(pk[0] & 0x80)  {              /* burst packet */
	    brst_num = pk[6] & 0xf ;
	    if (t0_speriod_array[brst_num].set == B_FALSE) 
		brst_num = frame->burst_num ;
	}

	upperlim = (frame->spc_mode > 4) ? 18 : 33; /*telem rate dependent */
	lowerlim = (frame->inst_mode & 0x04) ? 3000:50; /*burst mode dependent*/
	ps = packet_spin(pk);
	fs = t0_speriod_array[brst_num].frame_spin;

	if(fs < 22000 && ps > 44000)      /* correct roll overs */
		ps -= 65536;
        if(fs > 44000 && ps < 22000)       /* correct roll overs */
                ps += 65536;
#if 0
   	if(ps < fs - lowerlim){
		fprintf(debug,"`%s  Packet spin (%ld) below frame spin (%ld)\n",
		    time_to_YMDHMS(frame->time),ps,fs);
/*		ps = fs;  */
	}
	if(ps > fs + upperlim){
		fprintf(debug,"`%s  Packet spin (%ld) above frame spin (%ld)\n",
		    time_to_YMDHMS(frame->time),ps,fs);
/*		ps = fs;  */
	}
#endif

	fspin = ps + phase/16.;
	spin_period = t0_speriod_array[brst_num].speriod ;
	spin0_time = t0_speriod_array[brst_num].t0 ;
	time = fspin * spin_period + spin0_time;
	    
/*#define SPINTIME_DEBUG*/
#if defined (SPINTIME_DEBUG)
/*	if(pk[0] & 0x80 ) {*/
	if((pk[0]&0x77) == 0x36) {
	    fprintf(stderr,"pk-t0: %s, -SPeriod: %lf, Burst #: %u,"
		    "FSpin %le\r\n",
		    time_to_YMDHMS(spin0_time), spin_period, brst_num,
		    fspin);
	}
#endif
	return(time);	
}

int correct_gse_frame_time(double last_t,double *t,int last_rate,int rate)
{
	static double dft[3] = {45.857756,91.715512, 45.86};
	static int counter;
	int4 n;
	double dt,dtx;
	
	if(counter){            /* this prevents repetitive corrections */
		counter--;
		return(0);
	}
	if(rate == 0)
		rate = last_rate;
	if(rate != last_rate)
		return(0);
	dt = *t - last_t;
	dtx = dft[rate];
	n = dt/dtx;
	dt = last_t + n*dtx - *t;
	if(dt <= 0 && dt> -dtx+2 && n>=1 && n<=15){
		*t += dt;
#ifdef DEBUG
		fprintf(debug,"`%s  Correcting Frame time by %.1f seconds\n", time_to_YMDHMS(*t),dt);
#endif
/*		counter = 1;     */       /* don't correct the next sample  */
		if(dt>.99 || dt <-.99)
			return(1);
	}
	return(0);
}

/* determine telemetry percentages */
void fill_frame_telem_info(struct frameinfo_def *frm)
{
	int nbytes,n;
	nbytes = frm->nbytes;
	if(nbytes==0)
		nbytes = 1;
	for(n=0;n<MAX_TELEM_TYPES;n++)
		frm->telem[n] = frm->telem[n]/nbytes;
#if 0
	frm->main_telem = frm->main_telem / nbytes;
	frm->pesa_telem = frm->pesa_telem / nbytes;
	frm->eesa_telem = frm->eesa_telem / nbytes;
	frm->fpc_telem = frm->fpc_telem / nbytes;
#endif
	frm->used_telem = (float)frm->good / nbytes;
	frm->bad_telem  = (float)frm->bad / nbytes;
	frm->unused_telem = (float)frm->ugly / nbytes;
	frm->lost_telem = (float)frm->lost / nbytes;
}



/* Creates a simulated housekeeping packet */
void make_hkp_packet(frameinfo *frame)
{       /* prepends 8 byte header to housekeeping data and sends it on */
	static uchar buff[8 + MAX_HKPBYTES + MAX_THMBYTES];
	uint size;

	size = 8 + MAX_HKPBYTES + MAX_THMBYTES;
	buff[0] = (uchar)(((uint4)HKP_ID) >>24);
	buff[1] = frame->nhkp;
	buff[2] = size & 0xff;
	buff[3] = size >> 8;
	buff[4] = frame->spin & 0xff;
	buff[5] = frame->spin >> 8;
	buff[6] = (uchar)(((uint4)HKP_ID>>16) & 0xff);
	buff[7] = frame->nthm;
	memcpy(buff+8,hkp_3dp,MAX_HKPBYTES);
	memcpy(buff+8+MAX_HKPBYTES,thm_3dp,MAX_THMBYTES);
	process_packet(frame->time,frame->errors,buff);
}



/* Creates a simulated key parameter packet */
void make_kpd_packet(frameinfo *frame)
{       /* prepends 8 byte header to keyparameter data and sends it on */
	static uchar buff[8 + MAX_KPDBYTES + MAX_THMBYTES];
	uint size;

	size = 8 + MAX_KPDBYTES + MAX_THMBYTES;
	buff[0] = (uchar)(((uint4)KPD_ID) >> 24);
	buff[1] = frame->nkpd;
	buff[3] = size >> 8;
	buff[2] = size & 0xff;
	buff[5] = frame->spin >> 8;
	buff[4] = frame->spin & 0xff;
	buff[6] = (uchar)(((uint4)KPD_ID>>16) & 0xff);
	buff[7] = frame->nthm;
	memcpy(buff+8,kpd_3dp,MAX_KPDBYTES);
	memcpy(buff+8+MAX_KPDBYTES,thm_3dp,MAX_THMBYTES);
	process_packet(frame->time,frame->errors,buff);
}

/* Creates a simulated frame_info packet */
void make_frame_info_packet(frameinfo *frame)
{       /* prepends 8 byte header to frame_info data and sends it on */
	static uchar buff[8 + FRAME_INFO_SIZE];

	buff[0] = (uchar)(((uint4)FRM_INFO_ID) >>24);
	buff[1] = 0;
	buff[2] = (FRAME_INFO_SIZE+8) & 0xff;
	buff[3] = (FRAME_INFO_SIZE+8) >> 8;
	buff[4] = frame->spin & 0xff;
	buff[5] = frame->spin >> 8;
	buff[6] = (uchar)(((uint4)FRM_INFO_ID>>16) & 0xff);
	buff[7] = 0;
	memcpy(buff+8,frame,FRAME_INFO_SIZE);
	process_packet(frame->time,frame->errors,buff);
}


/*****************************************************************************
This subroutine determines file characteristics (hdr_size, rcd_size, etc.)
given a file pointer.  The file is left pointing to the first data record.
*****************************************************************************/
void determine_file_type(FILE *fp,file_info *file)
{
	int n;
	char hdr[300];
	int4 spacecraft_id,instrument_id,record_length;
	char spc_name[5];

	fseek(fp,0l,SEEK_SET);            /* set back to beginning */
	n = fread(hdr,1,300,fp);
	fseek(fp,0l,SEEK_SET);            /* set back to beginning */
#if 0
	if(n==0){
		file->file_type = FILE_INVALID;        /* error */
		return;
	}
#endif
	if(memcmp(hdr,"NEWPKT",6)==0){            /* HKP file */
		file->file_type = FILE_GSE_HKP;
		return;
	}
	if(memcmp(hdr,"NEWFRAME",8)==0){        /* original version gse data */
		file->file_type=FILE_GSE_RAW;
		file->hdr_size = gse_header_size(hdr,300);
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NEWFR+TH",8)==0){  /* raw with thermister values*/
		file->file_type=FILE_GSE_THERM;
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NFRM/",5)==0){
		file->file_type = FILE_GSE_FLT;  /* flight version */
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(memcmp(hdr,"NFNT/",5)==0){
		file->file_type = FILE_GSE_ENG;  /* flight version */
		file->hdr_size = 30;
		file->rcd_size = 12000+file->hdr_size;
		return;
	}
	if(hdr[4]=='-' && hdr[7]=='-' && hdr[10]=='/' && hdr[13]==':' 
                    && hdr[16]==':' && hdr[19]==' '){
		file->file_type = FILE_MASTER;   /* master file  */
		file->hdr_size = 0;
		file->rcd_size = 0;
		return;
	}
	spacecraft_id = str_to_int4((uchar*)hdr);
	instrument_id = str_to_int4((uchar*)hdr+4);
	record_length = str_to_int4((uchar*)hdr+176);
	if(record_length ==0)
		record_length = NASA_REC_LEN;
	memcpy(spc_name,hdr+8,4);  spc_name[4]=0;
	if(spacecraft_id==25 && instrument_id==6) { /* WIND 3DP LZ data file */
		file->file_type = FILE_NASA_LZ;
		file->file_hdr_size = record_length;
		file->hdr_size      = NASA_HDR_LEN;
		file->rcd_size      = record_length;
		fseek(fp, (long) file->rcd_size, SEEK_SET);
		return;
	}
	if(spacecraft_id==0 && instrument_id==0) { /* WIND 3DP NRT data file */
		file->file_type = FILE_NRT_LZ;
		file->file_hdr_size = NASA_REC_LEN;
		file->hdr_size      = NASA_HDR_LEN;
		file->rcd_size      = NASA_REC_LEN;
		fseek(fp, (long) file->rcd_size, SEEK_SET);
		return;
	}
	instrument_id = str_to_int4((uchar*)hdr);
	record_length = str_to_int4((uchar*)hdr+172);
	if(instrument_id==6) { /* WIND 3DP NRT data file */
		file->file_type = FILE_NRT_LZ;
		file->file_hdr_size = NASA_REC_LEN;
		file->hdr_size      = NASA_HDR_LEN;
		file->rcd_size      = NASA_REC_LEN;
		fseek(fp, (long) file->rcd_size, SEEK_SET);
		return;
	}
	file->file_type = FILE_INVALID;
}







/*  Used for GSE files only to determine the frame record header size */  
int gse_header_size(char *hdr,int n)  
{	
	int i,len;

	len = -1;               /* illegal header */
	for(i=0;i<n;i++){
		if(hdr[i]==':' && hdr[i+1]==':'){   /* NEW FORMAT  '::'  */
			len = i+2;
			break;
		}
	}

	if (i>=n){       /* OLD FORMAT HAS HEADER OF 10 OR 20  */
		if (hdr[18] == ':' && (hdr[19]==':' || hdr[19]==' '))
			len = 20; 
		else if (hdr[9] == ':')
			len = 10;
	}
	return(len);
}






/*------------------------------------------------------------------------------
|				SPACECRAFT_CLOCK()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function converts an 8-byte stream to the current data record header    |
| spacecraft clock time value (seconds since midnight).			       |
|									       |
| NOTES									       |
| -----									       |
| The conversion used is described in the "Data Format Control Document", page |
| 3-7 (March 1993).							       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| stream			input:  raw byte stream			       |
|									       |
| RETURN								       |
| ------								       |
| seconds								       |
|									       |
| AUTHOR								       |
| ------								       |
| Todd H. Kermit, January 31 1994					       |
|									       |
------------------------------------------------------------------------------*/

static double spacecraft_clock(uchar* stream)
    {
    double seconds;					/* decimal seconds    */
    uchar buf[8];					/* reverse byte stream*/
    uchar lsb;						/* least signif. byte */
    uchar msb;						/* most  signif. byte */
    uchar xsb;						/* extended byte      */
    int2  i;						/* generic counter    */
    int2  msec;						/* milli-seconds      */
    int2  usec;						/* micro-seconds      */
    int2  usec_tenths;					/* micro-seconds / 10 */
    int2  tjd;						/* trunc. Julian date */
    int4  sec;						/* seconds into day   */

									      /*
    Reverse the byte stream
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    for (i = 0; i < 8; i++)
        buf[i] = stream[7 - i];

									      /*
    Compute time values
    ~~~~~~~~~~~~~~~~~~~							      */

    usec_tenths = (int2) (buf[0] & 0x1f);

    msb  = (buf[1] >> 5) & 0x03;
    lsb  = (buf[1] << 3)  | (buf[0] >> 5);

    usec = (int2) ((msb << 8) + lsb);


    msb  = ((buf[3] << 1) & 0x02) | (buf[2] >> 7);
    lsb  = (buf[2] << 1) | (buf[1] >> 7);

    msec = (int2) ((msb << 8) + lsb);

    xsb  = (buf[5] >> 1) & 0x01;
    msb  = (buf[5] << 7) | (buf[4] >> 1);
    lsb  = (buf[4] << 7) | (buf[3] >> 1);

    sec  = (int4) ((xsb << 16) + (msb << 8) + lsb);

    msb  = (buf[6] >> 2);
    lsb  = (buf[6] << 6) | (buf[5] >> 2);

    tjd  = (int2) ((msb << 8) + lsb);		/* <---- NOT YET IMPLEMENTED  */

									      /*
    Compute decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    seconds = sec + (msec / 1000.) + (usec / 1.e+6) + (usec_tenths / 1.e+7);

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }


#define YEAR_START	1970			/* time zero (00:00:00) year  */


/*------------------------------------------------------------------------------
|				     ATC_CLOCK()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function converts a 16-byte (four 4-byte integers) stream containing the|
| Absolute Time Code (ATC) to time in units of seconds.			       |
|									       |
| NOTES									       |
| -----									       |
| The conversion used is described in the "Data Format Control Document", page |
|   3-8 (March 1993).							       |
| The ATC time is converted to seconds since January 1, 1900 (00:00:00).       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| byte				input:  raw byte stream			       |
|									       |
| RETURN								       |
| ------								       |
| seconds								       |
|									       |
| AUTHOR								       |
| ------								       |
| Todd H. Kermit, February 03 1994					       |
|									       |
------------------------------------------------------------------------------*/

static double atc_clock(uchar* byte)
    {
    double seconds;					/* decimal seconds    */
    int4  day;						/* day of year        */
    int4  msec;						/* milli-seconds      */
    int4  usec;						/* micro-seconds      */
    int4  year;						/* year    	      */

									      /*
    Swap bytes and load time values
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    year = str_to_int4(byte);
    day  = str_to_int4(byte+4);
    msec = str_to_int4(byte+8);
    usec = str_to_int4(byte+12);

    if(year<1970)
	year = 1970;
    if(year>2040)
	year = 2040;
    if(day<1)   day =1;
    if(day>366) day =1;

									      /*
    Compute decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~						      */

    seconds = (double) ((msec / 1000.) + (usec / 1.e+6));

									      /*
    Convert to seconds since January 1, 1900 (00:00:00)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			      */

    seconds = seconds_since_year(YEAR_START, year, day-1, seconds);
          /* edited 9-14-94 to subtract 1 day */

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }

/*------------------------------------------------------------------------------
|			      SECONDS_SINCE_YEAR()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function computes the number of seconds between the input start year at |
| 00:00:00 and the input date/time (year, day-of-year, decimal seconds).       |
|									       |
| NOTES									       |
| -----									       |
| The date notation conforms to ASCII standards.			       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| year0			input:  start year				       |
| year			input:  year					       |
| yday			input:  day of year (0 - 365)			       |
| sec			input:  decimal seconds				       |			       |									       |
| RETURN								       |
| ------								       |
| seconds		total decimal seconds since start year		       |
|									       |
------------------------------------------------------------------------------*/

#define leap(y)	(!((y) % 4) && ((y) % 100) || !((y) % 400) && ((y) % 4000))

static double seconds_since_year(int4 year0, int4 year, int4 yday, double sec)
    {
    double seconds;					/* seconds since year0*/
    uint4 ndays = 0;					/* day number total   */
    int4  iyear = year0;				/* year value	      */

									      /*
    Compute number of days
    ~~~~~~~~~~~~~~~~~~~~~~						      */

    while (iyear < year)
	{
	ndays += (leap(iyear)) ? 366 : 365;
	iyear++;
	}

    ndays += yday;

									      /*
    Compute total decimal seconds
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    seconds = ndays * 86400 + sec;

									      /*
    Done
    ~~~~								      */

    return(seconds);
    }



