#include "wind_pk.h"


#include "windmisc.h"
#include "pckt_prt.h"   /* for packet_log(); */

#include <stdlib.h>
#include <string.h>

/*  private subroutines: */

packet *store_packet(double time,uint errors,uchar *ds,pklist *list);
void add_packet_to_list(packet *pk,pklist *list);
void make_elm_array();
void list_to_array(pklist *pkl);
uint4 packet_id(uchar *p);
uint2 packet_idtype(uchar *p);
uint2 packet_dsize(uchar *p);
uint2 packet_instseq(uchar *p);
uchar packet_seq(uchar *p);
uchar packet_inst(uchar *p);
void print_packet_summary(FILE *fp);
int packet_type_index(uint4 id);
int pk_time_compare(const void  * p1, const void  *p2);
boolean_t is_sortable(pklist pkl);

int batch_print = 0;

FILE *pckt_log_fp;

static pklist packet_types[]={  /*id          mask     sortable_type  size */
	{"All Unkown Packets" ,INVALID_ID, 0x00000000, B_FALSE,    0 },  /* must be first */
	{"Housekeeping"       ,HKP_ID,     0xffff0000, B_FALSE,    999},
	{"Key Parameters"     ,KPD_ID,     0xffff0000, B_FALSE,    999},
	{"Frame Info"         ,FRM_INFO_ID,0xffff0000, B_FALSE,    999},
	{"EESA Moments"       ,EMOM_ID,    0xfff00000, B_FALSE,    224},
	{"EESA PADs"          ,EHPAD_ID,   0xfff00000, B_FALSE,    248},
	{"EESA 3D (Unknown)"  ,E3D_UNK_ID, 0xfff0f000, B_FALSE,    0 },
	{"EESA 3D (Cut)"      ,E3D_CUT_ID, 0xfff0f000, B_FALSE,    480},
	{"EESA 3D (88 A)"     ,E3D_88_ID,  0xfff0f000, B_FALSE,    495,1320 /*,0x07 */},
	{"EESA 3D Burst"      ,E3D_BRST_ID,0x77f0f000, B_TRUE,     0},
	{"PESA 3D"            ,P3D_ID,     0xfff00000, B_FALSE,    390,1890 /* ,0x07,1 */},
	{"PESA 3D Burst"      ,P3D_BRST_ID,0x77f00000, B_TRUE,     0},
	{"PESA Moments"       ,PMOM_ID,    0xfff00000, B_FALSE,    320},
	{"PESA Snapshot"      ,PLSNAP_ID,  0xffff0000, B_FALSE,    350},
	{"Correlator data"    ,FPC_D_ID,   0x77f00000, B_TRUE,     0},
	{"Correlator slice"   ,FPC_P_ID,   0x77f00000, B_TRUE,     0},
	{"Correlator dump"    ,FPC_DUM_ID, 0x77f00000, B_TRUE,     999},

	{"MAIN CC Mem Dump"   ,M_MEM_ID  ,0xffff0000, B_FALSE,    158},
	{"EESA CC Mem Dump"   ,E_MEM_ID  ,0xffff0000, B_FALSE,    182},
	{"PESA CC Mem Dump"   ,P_MEM_ID  ,0xffff0000, B_FALSE,    158},
	{"MAIN HKP A/D"       ,M_HKP_ID  ,0xffff0000, B_FALSE,    64},
	{"EESA HKP A/D"       ,E_A2D_ID  ,0xffff0000, B_FALSE,    64},
	{"PESA HKP A/D"       ,P_A2D_ID  ,0xffff0000, B_FALSE,    64},
	{"RAM Mem Dump"       ,R_MEM_ID  ,0xffff0000, B_FALSE,    999},
	{"MAIN Config"        ,M_CFG_ID  ,0xffffffff, B_FALSE,    110},
	{"EESA Config"        ,E_CFG_ID  ,0xffffffff, B_FALSE,    144},
	{"PESA Config"        ,P_CFG_ID  ,0xffffffff, B_FALSE,    218},
	{"MAIN Extended Cfg"  ,M_XCFG_ID ,0xffffffff, B_FALSE,    432},
	{"EESA Extended Cfg"  ,E_XCFG_ID ,0xffff0000, B_FALSE,    422},
	{"PESA Extended Cfg"  ,P_XCFG_ID ,0xffffffff, B_FALSE,    999},

	{"SST Flat Rate"      ,S_RATE_ID ,0xffff0000, B_FALSE,    999},
	{"SST R+S 1"          ,S_RATE1_ID,0xffff0000, B_FALSE,    353},
	{"SST R+S Burst"      ,0x34100000,0x77f00000, B_TRUE,     0},
	{"SST R+S 3"          ,0x40100000,0xfff00000, B_FALSE,    353},
	{"SST T-dist Burst"   ,0x34200000,0x77f00000, B_TRUE,     0},
	{"SST T-dist"         ,0x40200000,0xfff00000, B_FALSE,    256},
	{"SST Half spin Burst",0x34300000,0x77f00000, B_TRUE,     0},
	{"SST 3D-O data"      ,0x40400000,0xfff00000, B_FALSE,    0},
	{"SST 3D-F data"      ,0x40500000,0xfff00000, B_FALSE,    0},
	{"SST PAD  data"      ,0x40600000,0xfff00000, B_FALSE,    0},

	{"PESA Spectra"       ,PSPECT_ID ,0xfffd0000, B_FALSE,    71},
	{"PESA PHA"           ,0x28600000,0xffff0000, B_FALSE,    999},
	{"PESA Fast Rate"     ,0x28800000,0xfff00000, B_FALSE,    55},
	{"PESA Burst Dump"    ,0x36200000,0xfff00000, B_TRUE,     55},
	{"PESA Burst Snapshot",0x36800000,0x77f00000, B_TRUE,     0},
	{"EESA Spectra"       ,ESPECT_ID, 0xfffd0000, B_FALSE,    71},
	{"EESA Fast Rate"     ,0x18800000,0xfff00000, B_FALSE,    55},
	{"EESA PHA"           ,E_PHA_ID,  0xfff00000, B_FALSE,    0},
	{"EESA High Burst"    ,EH_BRST_ID,0x77f0f000, B_TRUE,     0},
	{"EESA 3D Merge"      ,E3D_ELM_ID,0x77f0f000, B_TRUE,	   0},
#if 0
	{"Pkt 1201"           ,0x12010000,0xffff0000, B_FALSE,    999},
	{"Pkt 1810"           ,0x18100000,0xffff0000, B_FALSE,    999},
	{"Pkt 2201"           ,0x22010000,0xffff0000, B_FALSE,    999},
	{"Pkt 0201"           ,0x02010000,0xffff0000, B_FALSE,    999},
	{"Pkt 2810"           ,0x28100000,0xffff0000, B_FALSE,    999}
#endif
};

#define NUM_PKT_TYPES (sizeof(packet_types)/sizeof(pklist))


static char *hugemem;     /* starting location of static memory  */
static char *buffptr;     /* current pointer to unused memory  */
static int4 hugememsize;  /* size of memory   */
static int4 memory_left;  /* bytes of memory left */
static int4 series_num;/* counter that is incremented with each new data load */


int initialize_raw_memory(int size,void *buff)
{
	int i;
	pklist *pkl;

	series_num++; /* increment series number so that reloads are detected */
	for(i=0;i<NUM_PKT_TYPES;i++){
		pkl = &packet_types[i];
		pkl->store = 1;
		pkl->print = 1;
		pkl->numtotal = 0;
		pkl->numlist  = 0;
		pkl->numarray = 0;
		pkl->first = pkl->last = pkl->current = NULL;
		if(hugemem && pkl->array)
			free((char *)pkl->array);
		pkl->array = NULL;
	}
#if 0
	if(hugemem){
		free(hugemem);
		hugemem = (char *) malloc(size);
		buff = (void *) hugemem;
	}
	else{
		hugemem = (char*)buff;
	}
#else
        hugemem = (char *)buff;
#endif
	if(hugemem == NULL){
		fprintf(stderr,"Can not allocate %lu bytes\n",(ulong)size);
		hugememsize = memory_left = 0;
		size = 0;
	}
	buffptr = hugemem;
	hugememsize = memory_left = size;
	return(buff ? series_num : 0);	
}

long find_mem_left()
{
	int4 d;
	
	d = memory_left;
	
	return(d);
}
#if 0
int free_unused_memory(int *size,void *buff)
{
	int4 d;
	
	if (memory_left > 0)  {
		d = hugememsize - memory_left;
		realloc((void *)hugemem,d);
		memory_left = 0;
		hugememsize = d;
		buff = (void *)hugemem;
		*size = hugememsize;
	}
	return(0);
}
#else 
  
#endif

int memory_filled()
{
	uint2 size;
	
	size = ((size/sizeof(Align))+1)*sizeof(Align);
	if ((memory_left <= size+3000+PDSIZE) && (!batch_print))
		return(1);
	else 
		return(0);
}

#if 0
int set_print_packet_flag(int n)
{
	if(n>=0 && n<NUM_PKT_TYPES)
		packet_types[n].print = 1;
	return(1);
}
#endif






packet *store_packet(double time,uint errors,uchar *ds,pklist *list)
{                                /* adds packet to end of list */
	packet *pk,*pkp;
	uint2   size,ssize,seq;
	
	if(hugemem==0){
		fprintf(stderr,"Memory has not been initialized!");
		return( (packet *) 0);
	}

	pk = (packet *)buffptr;   /* Alignment guaranteed  */

	pk->time   = time;
	pk->spin   = packet_spin(ds);
	pk->idtype = packet_idtype(ds);
	pk->instseq= packet_instseq(ds);
	pk->dsize  = packet_dsize(ds);
	pk->quality = (errors >> 16);
	pk->errors = errors;

	size = pk->dsize + PDSIZE;                 /* bytes of mem used */
	memcpy( pk->data, ds+8 , pk->dsize ); /* store data after the header */

	size = ((size/sizeof(Align))+1)*sizeof(Align);  /* alignment round up */

/* Provide permanent storage only if space for this packet and    */
/* at least 1 other packet is available                            */
	if(list->store && (memory_left > size+3000+PDSIZE) ){ 
		add_packet_to_list(pk,list);
		buffptr += size;    /* provide permanent storage */
		memory_left -= size;
	}
	else{
		pk->next = pk->prev = 0;   /* safety measure */
	}
	return(list->seqmask ? 0 : pk);
}



int add_packet_routine(uint4 id,Packet_Routine routine)
{
	int index;

	index = packet_type_index(id);
	packet_types[index].pckt_print = routine;
	return(index);    /* Not finished */
}






void add_packet_to_list(packet *pk,pklist *list)
{
	if(list->first ==0)                /* If first packet: */
		list->first = pk;          /* mark as such.    */
	pk->prev = list->last;                
	if(pk->prev)                       /* Set prev packet (if any)  */
		pk->prev->next = pk;       /* pointing to this packet. */
	pk->next = 0;                      /* Adding to end of list. */
	list->last = pk;                   /* Set last member to this packet. */
	list->numlist++;                   /* Increment list counter. */
}

void mark_last_packet_as_suspect(int id)
{
	pklist *list;
	packet *pk;
	
	list = &packet_types[id];
	if((list->first ==0) || (id == 0))
		return;
	pk = list->last;
	pk->quality |= QUALITY_INVALID_NEXTP;
}

/* returns the packet type index for valid packets
/* returns 0 if the packet id is unknown */
/* guaranteed to return a valid index  */ 
int packet_type_index(uint4 id)
{
	packet *pk;
	pklist *pkl;
	int i;

	for(i=NUM_PKT_TYPES-1; i>=0; i--){
		pkl = &packet_types[i];
		if(pkl->id == (id & pkl->idmask) )
			break;
	}
	return(i);
}


int process_packet(double time,uint errors,uchar *ds)
{                      /* returns 0 when given unknown packet type */
	packet *pk;
	pklist *pkl;
	int  i,dsize;
	uint4 id;

	id = packet_id(ds);

	i = packet_type_index(id);
	pkl = &packet_types[i];
	pkl->numtotal++;
	pk = store_packet(time,errors,ds,pkl);
	if(batch_print && pk){            /*  Batch printing routines */
		if(pckt_log_fp)
			packet_log(pckt_log_fp,pk);	
		if(pkl->print && pkl->pckt_print)
			(*(pkl->pckt_print))(pk);   /* print packet if needed */
	}
	return(i);
}






packet *search_for_packet(double time,pklist *pkl)
{    /* looks backward through list to find packet with same or earlier time */
	packet *pk;        /* assumes list is in chronological order */

	if(! pkl->current)
		pkl->current = pkl->last;
	pk = pkl->current;      /*  starts search with last used packet */
	while(pk && pk->next && pk->time < time)
		pk = pk->next;
	while(pk && pk->prev && pk->time > time)
		pk = pk->prev;
	pkl->current = pk;
	return(pk);             /* returns null if no packet is found */
}





#if 0

int number_of_packets(uint4 id,double t1,double t2)
{
	pklist *pkl;
	packet *pk;
	double lt;
	int n = 0;

	pkl = packet_type_ptr(id);
	if(pkl){
		pk = get_next_packet(t1,pkl);
		if(pk) 
			t1 = pk->time;
		while(pk && pk->time <= t2){
			lt = pk->time;
			pk = get_next_packet(pk->time,pkl);
			n++;
		}
		if(n && lt < t2)   /* extrapolate */
			n = n*((t2-t1)/(lt - t1));
	}
	return(n);
}

#else



/*  Returns the number of packets (data samples) with the given id. */
int  number_of_packets(uint4 id,double t1,double t2)
{
	pklist *pkl;
	pkl = packet_type_ptr(id);
	if(pkl)
		return(pkl->numlist);
	else
		return(0);

}
#endif







packet *get_packet_3(double time,PACKET_ID id,int direction)
{
    packet *pk;
    packet_selector pks;

    SET_PKS_BY_TIME(pks,time,id) ;
    pk = get_packet(&pks);
    return(pk);	
}



/* get_packet(packet_selector *pks)
 * double           pks->time: time of packet to get. Ignored if getting by index.
 * long             pks->index:    index of packet to get.  Ignored if getting by time.
 * PACKET_ID        pks->id: PACKET_ID of interest.
 * int              pks->direction:       (-1,0,+1) : (previous,nearest,next). 
 * packet          *pks->lastpk:   gives a hint of where to start search. 
 * int              pks->series:   series identifcation tag (insures that lastpk is valid.
 * SELECTION_METHOD pks->select_by:   select by index or by time.
 * usage: 
 *   if pks->time is greater than 0: 
 *       gets the packet with the given id that has: 
 *           time less than pks->time    (direction <0) 
 *           time nearest to pks->time   (direction =0) 
 *           time greater than pks->time (direction >0) 
 *   if t is 0: 
 *       gets (previous/nearest/next) packet based on value of lastpk 
 * Note:  pks->lastpk and pks->series should be stored as static variables generally 
 */

/* returns the packet pointer  (null if there is no such packet)  */

packet * get_packet(packet_selector *pks) 
{   
	packet *pk;        /* assumes list is in chronological order */
	pklist *pkl;
	int l;
	
	pkl = packet_type_ptr(pks->id);
	if(pkl==0 || pkl->numarray==0)
		return(0);
#if 0 /* temporary test  */
	if(pks->direction <0)
		return(search_for_packet(pks->time,pkl));
#endif


	if(pks->series != series_num || pks->lastpk==0){   /*  reset */
		pks->series = series_num;         /* packet pointer was invalid */
		pks->lastpk = (pks->direction>0) ? pkl->last : pkl->first;
	}

	/* we will select the return packet by index in the array of packets,
	 * or by time */

	switch ( pks->select_by ) {
	case BY_INDEX:

	    /* index in range? */
	    if ( pks->index < 0 || pks->index >= pkl->numarray )
		return (packet *) NULL ;

	    pk = pkl->array[pks->index] ;
	    pks->time = pk->time;
	    break;

	case BY_TIME:

	    if(pks->time ==(double)0.){

		if(pks->direction>0)
		    pks->index ++ ;
		else if(pks->direction<0)
		    pks->index -- ;

		/* index in range? */
		if ( pks->index < 0 || pks->index >= pkl->numarray)
		    return (packet *) NULL ;

		pk = pkl->array[pks->index];
		break;
	    }
	    else{      /* use time value; use pks->index as a starting point */
		int idx;
		if(pks->direction>0) {
			/* make index in range */
			if ( pks->index < 0 || pks->index >= pkl->numarray )
			    pks->index = 0;
			idx = pks->index ;
			for ( ; idx > 0 && (((pkl->array[idx])->time > pks->time) ||
				((pkl->array[idx])->quality & ~pkquality)) ; idx -- ) ;
			for ( ; idx < (pkl->numarray - 1) &&
				(((pkl->array[idx])->time <= pks->time) ||
				((pkl->array[idx])->quality & ~pkquality)) ; idx ++ ) ;
		}
		else{
			/* make index in range */
			if ( pks->index < 0 || pks->index >= pkl->numarray )
			    pks->index = pkl->numarray-1;
			idx = pks->index ;
			for ( ; idx < (pkl->numarray - 1) &&
				(((pkl->array[idx])->time < pks->time) ||
				((pkl->array[idx])->quality & ~pkquality)) ; idx ++ ) ;
			for ( ; idx > 0 && (((pkl->array[idx])->time > pks->time) ||
				((pkl->array[idx])->quality & ~pkquality)) ; idx -- ) ;
		}
		
		pk = pkl->array[idx] ;
		pks->index = idx ;
		pks->time = pk->time ;
	    }

	    break;

	default:
	   return (packet *) NULL ;
	   break;

	}

/* #define PK_DEBUG */
#if defined (PK_DEBUG)
	printf("%s: time: %lf, direction: %d, &packet %lx\n\r",
	       __FILE__, pks->time, pks->direction, pk);
	printf("packet {"
	       "\n\r\ttime:       %lf"
	       "\n\r\tspin:       %hd"
	       "\n\r\tdsize:      %hd"
	       "\n\r\tidtype      %hd"
	       "\n\r\tinstseq:    %hd"
	       "\n\r\tquality:    %hd"
	       "\n\r\tterrors:    %hd"
	       "\n\r\tprev:       %lx"
	       "\n\r\tnext:       %lx"
	       "\n\r\tdata:       \r\n",
	       pk->time, pk->spin, pk->dsize, pk->idtype, pk->instseq,
	       pk->quality,pk->errors, pk->prev, pk->next);
	for ( l=0; l<MAX_PACKET_SIZE ; l++ )
	    printf("%s%2hx", l%16 ? " " : "\n\r\t\t", pk->data[l]);
	printf("\n\r\t}\n\r");
#endif /* defined (PK_DEBUG) */

	pks->lastpk = pk;
	
	return(pk);            /* returns null if no packet is found */
}


int pk_time_compare(const void * v1, const void  *v2)
{
    packet *p1 = *(packet **)v1;
    packet *p2 = *(packet **)v2;

    if (p1->time == p2->time) return (0);
    return (p1->time > p2->time) ? 1 : -1;
	
}

boolean_t is_sortable(pklist pkl)
{
    return (pkl.array && pkl.sortable) ? B_TRUE : B_FALSE;
}

void make_all_list_arrays()
{
	int i;
	
	for(i=0;i<NUM_PKT_TYPES;i++) {
	    if(i != packet_type_index(E3D_ELM_ID))
	    	list_to_array(&packet_types[i]);
	    else
	    	make_elm_array();

	    /* if this is a burst type packet array,
	       sort it by time */
	    
	    if ( is_sortable(packet_types[i])) {
		qsort ((void*)packet_types[i].array,
		       packet_types[i].numarray,
		       sizeof (packet*),
		       pk_time_compare);
	    }
	}
}

#define NUM_MALLOC_AT_ONCE 10

void make_elm_array()
{
	int i,j;
	packet *pk;
	int elements_left = NUM_MALLOC_AT_ONCE;
	int num_mallocs = 1 ;
	uint2 spin = 0xffff;
	pklist *pkl, *elmpkl;
	boolean_t first = B_TRUE ;
	
	elmpkl = &packet_types[packet_type_index(E3D_ELM_ID)];
	
	if(elmpkl->array){
	    /* if memory is already allocated, then just reuse it for efficiency */

	    fprintf(debug,"%s array already malloced!\n",pkl->name);

	    /* there will be a little wasted space in the following, but
	     * it won't be much, so who cares
	     */
	    num_mallocs = elmpkl->numarray % NUM_MALLOC_AT_ONCE ;
	    elements_left = num_mallocs * NUM_MALLOC_AT_ONCE ;
	} else {

	    /* We don't know how many array elements we need at first, so
	     * we will use a scheme that mallocs NUM_MALLOC_AT_ONCE elements of
	     * the packet array at one time. When we run out of array slots,
	     * realloc some more.
	     */
	
	    elmpkl->array = (packet **)malloc(NUM_MALLOC_AT_ONCE * sizeof(packet *));
	}

	pkl = &packet_types[packet_type_index(E3D_88_ID)];
	
	if(pkl->array){
	    pk = pkl->first ;
	    for(i=0, j=0;i<pkl->numlist && pk;i++,pk=pk->next) {
		if (first || spin != pk->spin) {
		    elmpkl->array[j] = pk;
		    j++;
		    elmpkl->numarray = j;
		    spin = pk->spin ;
		    first = B_FALSE ;

		    /* check to see if we need more array elements, and get 'em if necessary */
		    
		    elements_left -- ;
		    if ( ! elements_left ) {
			num_mallocs ++ ;
			elmpkl->array =
			    (packet **)realloc(elmpkl->array, NUM_MALLOC_AT_ONCE * num_mallocs * sizeof(packet *));
			elements_left =  NUM_MALLOC_AT_ONCE ;
		    }
		}
	    }
	}
	
	first = B_TRUE;
	pkl = &packet_types[packet_type_index(E3D_BRST_ID)];
	
	if(pkl->array){
	    pk = pkl->first ;
	    for(i=0;i<pkl->numlist && pk;i++,pk=pk->next) {
		if (first || spin != pk->spin) {
		    elmpkl->array[j] = pk;
		    j++;
		    elmpkl->numarray = j;
		    spin = pk->spin ;
		    first = B_FALSE ;

		    /* check to see if we need more array elements, and get 'em if necessary */
		    
		    elements_left -- ;
		    if ( ! elements_left ) {
			num_mallocs ++ ;
			elmpkl->array =
			    (packet **)realloc(elmpkl->array, NUM_MALLOC_AT_ONCE * num_mallocs * sizeof(packet *));
			elements_left =  NUM_MALLOC_AT_ONCE ;
		    }
		}
	    }
	 }
}	

/* creates array of pointers to packets */
void list_to_array(pklist *pkl)
{
	packet *pk;
	uint i, j;
	uint2 spin = 0xffff;
	int elements_left = NUM_MALLOC_AT_ONCE;
	int num_mallocs = 1 ;
	boolean_t first = B_TRUE ;

	if (! pkl->numlist)
	    return;
	
	if(pkl->array){
	    /* if memory is already allocated, then just reuse it for efficiency */

	    fprintf(debug,"%s array already malloced!\n",pkl->name);

	    /* there will be a little wasted space in the following, but
	     * it won't be much, so who cares
	     */
	    num_mallocs = pkl->numarray % NUM_MALLOC_AT_ONCE ;
	    elements_left = num_mallocs * NUM_MALLOC_AT_ONCE ;
	} else {

	    /* We don't know how many array elements we need at first, so
	     * we will use a scheme that mallocs NUM_MALLOC_AT_ONCE elements of
	     * the packet array at one time. When we run out of array slots,
	     * realloc some more.
	     */
	
	    pkl->array = (packet **)malloc(NUM_MALLOC_AT_ONCE * sizeof(packet *));
	}

	if(pkl->array){
	    pk = pkl->first ;
	    for(i=0, j=0;i<pkl->numlist && pk;i++,pk=pk->next) {
		if (first || spin != pk->spin) {
		    pkl->array[j] = pk;
		    j++;
		    pkl->numarray = j;
		    spin = pk->spin ;
		    first = B_FALSE ;

		    /* check to see if we need more array elements, and get 'em if necessary */
		    
		    elements_left -- ;
		    if ( ! elements_left ) {
			num_mallocs ++ ;
			pkl->array =
			    (packet **)realloc(pkl->array, NUM_MALLOC_AT_ONCE * num_mallocs * sizeof(packet *));
			elements_left =  NUM_MALLOC_AT_ONCE ;
		    }
		}
	    }
	    if(i<pkl->numlist || pk)   /* this should never occur */
		fprintf(stderr,"Error in producing %s list array\n"
			,pkl->name);
	} else{
		pkl->numarray = 0;
		fprintf(debug,"Unable to malloc memory for %s\n",pkl->name);
	}
}







  /* The following routines can be replaced with macros to increase speed */
uint4 packet_id(uchar *p)
{
	return( ((uint4)p[0]<<24) | ((uint4)p[6]<<16) | (p[7]<<8) | p[1] );
}

uint2 packet_idtype(uchar *p){ return( (p[0]<<8) + p[6] ); }
uint2 packet_size(uchar *p){ return( (p[3] << 8) + p[2] ); } /* packet size */
uint2 packet_dsize(uchar *p){ return( (p[3] << 8) + p[2] - 8 ); } /* packet data size */
uint2 packet_spin(uchar *p){ return( (p[5] << 8) + p[4] );  }
uint2 packet_instseq(uchar *p){ return( (p[7]<<8) + p[1] ); }
/*uchar packet_seq(uchar *p){ return( p[1] ); }  */
/*uchar packet_inst(uchar *p){ return( p[7] ); } */



/***********  THE REMAINDER OF THIS FILE DEALS WITH PRINTING PACKETS *****/




/*------------------------------------------------------------------------------
|				  PACKET_TYPE_PTR()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function returns a pointer to the requested packet type structure.  The |
| structure pointed to contains all information and data associated with that  | | packet.								       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| id_type		input:  requested packet id/type hex value	       |
|									       |
| RETURN								       |
| ------								       |
| pkt_ptr		pointer to packet type structure		       |
|									       |
| AUTHOR								       |							       | ------								       |
| Todd H. Kermit, Space Sciences Laboratory, U.C. Berkeley		       |
|									       |	------------------------------------------------------------------------------*/

pklist* packet_type_ptr(uint4 id)
{
	return( &packet_types[packet_type_index( id )] );
}
	
#if 0
pklist* packet_type_ptr(uint4 id)
    {

    pklist* ptr = packet_types;				/* pkt struct pointer */
    int4 i;						/* generic counter    */
    int4 n_types = NUM_PKT_TYPES;			/* number of pkt types*/

									      /*
    Search for requested packet type
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    for (i = 0; i < n_types; i++)
	{
	if (ptr->id == id)
	    break;
	ptr++;
	}

									      /*
    Return NULL pointer if packet type not found
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			      */

    if (i == n_types)
	return((pklist*) NULL);

									      /*
    Done
    ~~~~								      */

    return(ptr);

    }
#endif



#if 0
#include <math.h>

/*------------------------------------------------------------------------------
|			        GET_PACKET_INDEX()			       |
|------------------------------------------------------------------------------|
|									       |
| PURPOSE								       |
| -------								       |
| This function determines the packet index associated with input time for the |
| input packet type.							       |
|									       |
| NOTES									       |
| -----									       |
| A binary search is used to locate the time.				       |
|									       |
| ARGUMENTS								       |
| ---------								       |
| id_type		input:  requested packet id/type hex value	       |
| time			input:  requested time				       |
|									       |
| RETURN								       |
| ------								       |
| indx			index number of packet containing requested time       |
|									       |
| AUTHOR								       |							       | ------								       |
| Todd H. Kermit, Space Sciences Laboratory, U.C. Berkeley		       |
|									       |	------------------------------------------------------------------------------*/

int4 get_packet_index(uint4 id, double time)
    {
    packet** pkt;					/* pointer to packets */
    pklist* ptr;					/* pkt struct pointer */
    double val;						/* current value      */
    int4 indx;						/* index              */
    int4 indx1;						/* lower index        */
    int4 indx2;						/* upper index        */

									      /*
    Search for requested packet type
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					      */

    if ((ptr = packet_type_ptr(id)) == NULL)
	return(ERROR);

									      /*
    Initialize indices -- handle single point, if necessary
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		      */

    indx1 = 0;
    indx2 = ptr->numarray - 1;

    if (indx1 == indx2)
	return(indx1);

									      /*
    Assign pointer to packets
    ~~~~~~~~~~~~~~~~~~~~~~~~~						      */

    pkt = ptr->array;    

									      /*
    Locate lower and upper indices using binary search
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			      */

    while ((indx2 - indx1) > 1)
	{
	indx = (indx1 + indx2) / 2;
	val = pkt[indx]->time;
	if (val == time)
	    {
	    indx1 = indx;
	    break;
	    }
	else if (val < time)
	    indx1 = indx;
	else if (val > time)
	    indx2 = indx;
	}

									      /*
    Determine which index number is closest
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~				      */

    if (fabs(pkt[indx1]->time - time) < 
	fabs(pkt[indx2]->time - time))
	indx = indx1;
    else
	indx = indx2;
	
									      /*
    Done
    ~~~~								      */

    return(indx);

    }



#endif


void print_packet_summary(FILE *fp)
{
	int i;
	pklist *pkl;
	fprintf(fp," # Description:           ID    Obs Stored\n");
	for(i=0;i<NUM_PKT_TYPES;i++){
		pkl = &packet_types[i];
		fprintf(fp,"%2d %-20s: %04X %5u %5u",i,pkl->name, pkl->id>>16,pkl->numtotal,pkl->numlist);
		if(pkl->first)
			fprintf(fp," %s ",time_to_YMDHMS(pkl->first->time));
		if(pkl->last)
			fprintf(fp," %s ",time_to_YMDHMS(pkl->last->time));
		fprintf(fp,"\n");
/*		print_list( pkl );  */
	}
}



