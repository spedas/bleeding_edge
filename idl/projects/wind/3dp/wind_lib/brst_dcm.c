#include "brst_dcm.h"

#define MAXBYTES MAX_PACKET_SIZE

int nibble_decomp(uchar u[MAXBYTES],uchar c[MAXBYTES],int size);
int byte_decomp(uchar u[MAXBYTES],uchar c[MAXBYTES],int size);
uchar msbit(uchar xbyte);

/*------------------------------------------------------------------------------ */
  
/*  burst decompression routine  */

int decompress_burst_packet(packet *uncomp,packet *comp)
{

	int dsize;
	int retval;
	*uncomp = *comp;

	retval = 0;
	if(comp->idtype & 0x8000){
		if(comp->idtype & 0x0800){
			dsize = nibble_decomp(uncomp->data,comp->data, comp->dsize);
			retval = 1;
		}
		else{
			dsize = byte_decomp(uncomp->data,comp->data, comp->dsize);
			retval = 2;
		}
		uncomp->dsize = dsize;
		uncomp->idtype &= ~0x8000;  /* reset compression bit */
		while(dsize<MAXBYTES)
			uncomp->data[dsize++] = 0;
	}
	return(retval);
}






/*------------------------------------------------------------------------------
|				byte_decomp()
|-------------------------------------------------------------------------------
|
| PURPOSE
| -------
| Perform byte decompression on burst data.
|
| ARGUMENTS
| ---------
| u			output: array of uncompressed data
| c			input:  array of compressed data
| size			input:  number of elements in input array
|
| RETURN
| ------
| n			number of elements in output array
|
------------------------------------------------------------------------------*/

int byte_decomp(uchar u[MAXBYTES], uchar c[MAXBYTES], int size)
    {
    uchar byte1;				/* current raw byte */
    uchar byte2;				/* next raw byte */
    uchar temp1;				/* hold current byte */
    uchar temp2;				/* hold next byte */
    int ibit  = 7;				/* current bit position */
    int ibyte = 0;				/* byte counter */
    int n = 0;					/* number of uncompressed values */

    /* Check size of input array and handle special cases */

    switch (size)
        {
	case 0:  return(0);
		 break;
	case 1:  u[0] = msbit(c[0]) ? c[0] & 0x7f : 0;
		 return(1);
		 break;
	default: break;
	}

    if (size > MAXBYTES) return(0);

    /* Read the first 2 bytes */

    byte1 = *c++;
    byte2 = *c++;
    ibyte++;
    
    /* Loop through compressed burst data */

    while (ibyte < size)
	{

	/* Check size of output array */

	if (n >= MAXBYTES-1)
		return(0);

	/* Read in next byte, if necessary */

        if (ibit < 0)
	    {
	    byte2 = *c++;
	    ibit = 7;
	    ibyte++;
            }

	/* Check most significant bit and perform appropriate decompression */

	if (msbit(byte1))
	    {
	    u[n++] = (byte1 << 1) | msbit(byte2);
	    temp1  = (byte2 << 1);
	    temp2  = *c++; 
	    byte1  = temp1 | (temp2 >> ibit);
	    byte2  = temp2 << (8 - ibit); 
	    ibit--;
	    ibyte++;
	    }

	else
	    {
	    u[n++] = 0;
	    byte1  = (byte1 << 1) | msbit(byte2);
	    byte2 <<= 1;
	    ibit--;
	    }
	}

    /* Done */

    return(n);
    }

/*------------------------------------------------------------------------------
|				nibble_decomp()
|-------------------------------------------------------------------------------
|
| PURPOSE
| -------
| Perform nibble decompression on burst data. 
|
| ARGUMENTS
| ---------
| u			output: array of uncompressed data
| c			input:  array of compressed data
| size			input:  number of elements in input array
|
| RETURN
| ------
| n			number of elements in output array
|
------------------------------------------------------------------------------*/

int nibble_decomp(uchar u[MAXBYTES], uchar c[MAXBYTES], int size)
    {
    uchar bit5;					/* current 5 bits */
    uchar bit8;					/* next 8 bits */
    uchar temp;					/* byte holder */
    int outtemp;				/* output bytes from nibbles */
    int nbit;					/* number of bits in bit8 */
    int rbit;					/* bits remaining in stream */
    int n = 0;					/* number of uncompressed values */
    int nNibs = 0;				/* number of uncompressed nibbles */

    /* Check size of array and handle special cases */

    switch (size)
        {
	case 0:  return(0);
		 break;
	case 1:  u[0] = msbit(c[0]) ? (c[0] >> 3) & 0x0f : 0;
		 return(1);
		 break;
	default: break;
	}

    if (size > MAXBYTES) return(0);

    /* Read the first byte and initialize */

    bit5 = (*c) >> 3;
    bit8 = (*c) << 5;
    c++;
    nbit = 3;
    rbit = size * 8;
    
    /* Loop through compressed burst data */

    while (rbit)
	{

	/* Check size of output array */

	if (n >= MAXBYTES-1)
		return(0);

	/* Check most significant bit and perform appropriate decompression */

	if (msbit(bit5 << 3))
	    {
	    if ( nNibs % 2 ) 
		outtemp = outtemp | bit5 & 0x0f;     /* odd nibbles */
	    else
		outtemp = (bit5 & 0x0f) << 4;        /* even nibbles */
	    nNibs ++ ;
	    
	    bit5 = 0x00;
	    if (nbit < 5)
		{
		temp = *c++;
		bit5 = (bit8 >> 3) | (temp >> (nbit + 3));
		bit8 = temp << (5 - nbit);
		nbit += 3;
		}
	    else
		{
		bit5 = bit8 >> 3;
		bit8 = bit8 << 5;
		nbit -= 5;
		}
	    rbit -= 5;
	    }
	else
	    {
	    if ( nNibs % 2 ) 
		outtemp = outtemp | 0;     /* odd nibbles */
	    else
		outtemp = 0;               /* even nibbles */
	    nNibs ++ ;

	    if (nbit <= 0)
		{
		bit8 = *c++;
		nbit = 8;
		}
	    bit5  = (bit5 << 1) | msbit(bit8);
	    bit8 <<= 1;
	    nbit--;
	    rbit--;
	    }
	if ( nNibs && ! (nNibs % 2) )
	    u[n++] = outtemp;
        }

    /* load into the output, any remaining odd nibble */

    if ( nNibs % 2 )
	u[n] = outtemp;

    /* Done */

    return(n);
    }

/*------------------------------------------------------------------------------
|				    msbit()
|-------------------------------------------------------------------------------
|
| PURPOSE
| -------
| Check the value of most significant bit of an unsigned character byte.
|
| ARGUMENTS
| ---------
| byte1			input:  single byte value
|
| RETURN
| ------
| Value of most significant bit.
|
------------------------------------------------------------------------------*/

uchar msbit(uchar byte1)
    {
    return ((byte1 >> 7) && 0x01);
    }

    
