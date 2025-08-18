;***************************************************************************** 
;+
;*NAME:
;
;	decom_2s_complement
;
;*PURPOSE:
;
;	Decom 2 bytes into a long integer via 2's complement.
;
;*CALLING SEQUENCE:
;
;	decom_2s_complement,buff,value
;
;*PARAMETERS:
;
;	buff (required) (input) (array) (byte)
;	   An array of 2 bytes in order as read from file.
;
;	value (required) (output) (scalar) (longwod integer)
;	   The calculated value.
;
;*EXAMPLES:
;
;	decom_2s_complement,buff,value
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
;	none
;
;*RESTRICTIONS:
;
;	Only for use with 2 bytes
;
;*NOTES:
;
;
;*PROCEDURE:
;
;	- Check inputs
;	- Bytes to bits
;	- calculate value
;
;*MODIFICATION HISTORY:
;
;	26 Jul 2010       wrote
;       29 Jul 2010       generalized the code
;        3 Aug 2010       RCS
;
;-
;******************************************************************************
 pro decom_2s_complement,buff,value

;  check input parameters

 if (n_params(0) ne 2) then begin
    print,'decom_2s_complement,buff,value'
    retall
 endif  ;  n_params(0) ne 2
 
 buffsize = size(buff)
 if ( (buffsize[0] ne 1) or (buffsize[1] ne 2) ) then begin
    print,'decom_2s_complement: buff incorrect size'
    retall
 endif  ; (buffsize[0] ne 1) or (buffsize[1] ne 2)

;  used for calculation

 two_array_16_2 = [ 1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L,   $
                    256L, 512L, 1024L, 2048L, 4096L, 8192L, 16384L, 32768L ]

;  bytes to bits

 temp = reverse(buff)
 bitlis,temp,bit_array

;  calculate value

; if (bit_array[15] eq 0) then   $
;    value = long(total(bit_array[0:14] * two_array_16_2[0:14]))   $
; else   $
;    value = -1L * ( two_array_16_2[15] -   $
;                   (long(total(bit_array[0:14] * two_array_16_2[0:14]))) )
    value = ( -1L *  two_array_16_2[15] * bit_array[15] ) +   $
            ( long(total(bit_array[0:14] * two_array_16_2[0:14])) )

;stop
 return
 end   ; decom_2s_complement
