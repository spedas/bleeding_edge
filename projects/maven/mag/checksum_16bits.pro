;***************************************************************************** 
;+
;*NAME:
;
;	CHECKSUM_16BITS
;
;*PURPOSE:
;
;	Calculate a 16 bit checksum.  Also converts 2 bytes into hexidecimal.
;
;*CALLING SEQUENCE:
;
;	checksum_16bits,byte_buff,hex_string,/rfc1071,/debug,/complement,
;          /lastbitzero
;
;*PARAMETERS:
;
;	byte_buff	(input) (array) (integer)
;		The array of values to be used to determine the checksum.
;
;	hex_string (output) (scalar) (string)
;	        The hexidecimal checksum value.
;
;	rfc1071 (input) (keyword) (integer)
;		When set, the RFC1071 formula is followed which 
;		includes wrap during addition.
;		http://www.faqs.org/rfcs/rfc1071.html
;		When only 2 bytes are supplied in input, this has
;		no meaning since no addition is done.
;
;	debug	(input) (keyword) (integer)
;		Set for debug output.
;
;	lastbitzero (input) (keyword) (integer)
;	        Last bit is zero for the calculated checksum value.
;               This is needed for data that is from the MAVEN MAG instruments
;		(without processing thr the PFP).
;
;*EXAMPLES:
;
;	2 bytes examples
;
;	   temp = [248b, 95b]
;          checksum_16bits,temp,hex_string & print,hex_string
;	   F85F
;
;	   temp = [0b, 0b]
;	   checksum_16bits,temp,hex_string & print,hex_string
;	   0000
;
;	   temp = [77b, 239b]
;	   checksum_16bits,temp,hex_string & print,hex_string
;	   4DEF
;
;	   temp = [77b, 239b]
;	   checksum_16bits,temp,hex_string & print,hex_string,/lastbitzero
;	   4DEE
;
;
;	addition example
;
;	   temp = [69b, 0b, 0b, 52b, 0b, 0b, 64b, 0b, 255b, 17b,  $
;	           192b, 168b, 1b, 7b, 192b, 168b, 1b, 1b]
;
;	without rfc1071
;
;	   checksum_16bits,temp,hex_string & print,hex_string
;	   079D
;
;	with rfc1071
;
;	   checksum_16bits,temp,hex_string,/rfc1071 & print,hex_string
;	   07A0
;
;
;	another addition example
;
;	   temp = [69b, 0b, 0b, 52b, 0b, 0b, 64b, 0b, 255b, 17b,  $
;	           248b, 95b, 192b, 168b, 1b, 7b, 192b, 168b, 1b, 1b]
;
;	without rfc1071
;
;	   checksum_16bits,temp,hex_string & print,hex_string
;	   FFFC
;
;	with rfc1071
;
;	   checksum_16bits,temp,hex_string,/rfc1071 & print,hex_string
;	   FFFF
;
;*SYSTEM VARIABLES USED:
;
;	none
;
;*INTERACTIVE INPUT:
;
;	none
;
;*SUBROUTINES CALLED:
;
;	none
;
;*FILES USED:
;
;	none
;
;*SIDE EFFECTS:
;
;
;*RESTRICTIONS:
;
;	Input must be in multiples of 2 bytes (16 bits).
;
;*NOTES:
;
;*PROCEDURE:
;
;	Confirm multiple of 2 bytes.
;
;	Split bytes into bits.  Reverse bits.
;	Reformat to 16 bit array.
;
;	If more than 2 bytes
;	   Add bits.  Calculate remainder in base 2.  If RFC1071 
;	   keyword is set, wrap carry.  
;
;	Determine hexidecimal value and return.
;
;*MODIFICATION HISTORY:
;
;	14 Dec 2009  PJL  wrote
;	15 Dec 2009  PJL  changed 2 byte case to use same convert to 
;			  hexidecimal logic;  added examples
;	 8 Dec 2010  PJL  add returning the bit value of the checksum
;       16 Dec 2010  PJL  addeed complement keyword to obtain one's 
;                         complement checksum
;	11 Dec 2013  PJL  lastbitzero keyword added
;
;-
;******************************************************************************
 pro checksum_16bits,byte_buff,hex_string,bit_value,rfc1071=rfc1071,   $
        debug=debug,complement=complement,lastbitzero=lastbitzero

;  default for retall

 hex_string = ''

;  correct number of input parameters?

 if ( (n_params(0) ne 2) and (n_params(0) ne 3) ) then begin
    print,'checksum_16bits,byte_buff,hex_string,bit_value,/rfc1071,' +   $
       '/debug,/complement'
    print,'ACTION: retall'
    retall
 endif  ; n_parmas(0)

;  if needed for one's complement calculations

 ffff = [1, 1, 1, 1, 1, 1, 1, 1]

;  is debug keyword set?

 if (keyword_set(debug)) then debug = 1 else debug = 0

;  is input byte buffer and array with a  multiple of 2 number of elements?

 buff_size = size(byte_buff)
 if (debug) then print,'buff_size: ',buff_size
 if (buff_size[0] eq 1) then begin
    n_elements = buff_size[1]
    if ((n_elements mod 2) ne 0) then begin
       print,'Input byte buffer size is not a multiple of 2'
       print,'ACTION: retall'
       retall
    endif  ; (n_elements mod 2) ne 0
 endif else begin
    print,'Input bute buffer not an array.'
    print,'ACTION: retall'
    retall
 endelse  ; buff_size[0] eq 1
 if (debug) then print,'byte_buff = ',byte_buff

; split out the bits

 bitlis,byte_buff,bit_array
 if (debug) then print,'bit_array = ',bit_array

;  if what one's complement, keyword should be set

 if (keyword_set(complement)) then begin
    new_bit_array = bytarr(8,n_elements)
    for i=0,n_elements-1 do new_bit_array[*,i] = ffff - bit_array[*,i]
    bit_array = new_bit_array
 endif  ; keyword_set(complement)

; reverse the order of the bits

 rev_bit_array = reverse(bit_array)
 if (debug) then print,'rev_bit_array = ',rev_bit_array

; reformat the bits from an 8 by N to an 16 by N/2

 bit_array_16 = reform(rev_bit_array,16,n_elements/2)
 if (debug) then print,'bit_array_16 = ',bit_array_16

;  setup arrays - check and sum

 size_check = 16
 check = intarr(size_check)

;  if more than 2 bytes

 if (n_elements gt 2) then begin
    sum_16 = intarr(16)

;  sum the bits for each of the 16 location

    for i=0,15 do sum_16[i] = total(bit_array_16[i,*])
    if (debug) then print,'sum_16 = ',sum_16

;  for elements 15 through 1

    for i=15,1,-1 do begin 

;  modulus of 2

       check[i] = sum_16[i] mod 2 

;  carry to the previous index

       sum_16[i-1] = sum_16[i-1] + sum_16[i]/2 
    endfor  ; i

;  handle index 0 separately

    check[0] = sum_16[0] mod 2 
    if (debug) then print,'check = ',check

;  if rfc1071 keyword set

    if (keyword_set(rfc1071)) then begin

;  carry the division result from index 0 to index 15

       check[15] = check[15] + sum_16[0]/2

;  run through indices again

       sum_16 = check
       if (debug) then print,'rfc sum_16 = ',sum_16

;  for elements 15 through 1

       for i=15,1,-1 do begin 

;  modulus of 2

          check[i] = sum_16[i] mod 2 

;  carry to the previous index

          sum_16[i-1] = sum_16[i-1] + sum_16[i]/2 
       endfor  ; i

;  handle index 0 separately

       check[0] = sum_16[0] mod 2 
       if (debug) then print,'rfc check = ',check
    endif  ;  keyword_set(rfc1071)
 endif else check = bit_array_16

 bit_value = check
 if (keyword_set(lastbitzero)) then check[size_check-1] = 0

;  calculate hexidecimal

 for i=0,3 do begin
    value = check[i*4]*8 + check[i*4+1]*4 + check[i*4+2]*2 + check[i*4+3]
    if (debug) then print,'value = ',value
    case (value) of
       10: hex_string = hex_string + 'A'
       11: hex_string = hex_string + 'B'
       12: hex_string = hex_string + 'C'
       13: hex_string = hex_string + 'D'
       14: hex_string = hex_string + 'E'
       15: hex_string = hex_string + 'F'
       else: hex_string = hex_string + strtrim(value,2)
    endcase  ; value
 endfor ; i

 return
 end  ; checkum_16bits
