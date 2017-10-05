;************************************************************************
;+
;*NAME:
;
;	BITLIS       AUG. 28, 1989
;
;*CLASS:
;
;	data display
;
;*CATEGORY:
;
;*PURPOSE:  
;
;	To display bit pattern for byte, integer or longword integer scalars 
;	or vectors.
;
;*CALLING SEQUENCE:
;
;	BITLIS,A,B
;
;*PARAMETERS:
;
;	A   	(REQ) (I) (0,1) (B,I,L)
;		Input scalar or vector 
;
;	B   	(REQ) (O) (1,2) (B)
;		Output vector or array of 0's (off) and 1's (on) representing 
;		bit patterns of input vector A.
;
;*EXAMPLES:
;
;	a = bindgen(5)
;	bitlis,a,b
;	print,b
;	0 0 0 0 0 0 0 0 0
;	1 0 0 0 0 0 0 0 0
;	0 1 0 0 0 0 0 0 0
;	1 1 0 0 0 0 0 0 0
;	0 0 1 0 0 0 0 0 0
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
;    	none
;
;*FILES USED:
;
;	none
;
;*SIDE EFFECTS:
;
;*RESTRICTIONS:
;
;       Input parameter must be scalar or vector and either
;       byte, integer or longword integer data type.
;
;*NOTES:
;
;       When integers are stored in two's complement, the bit pattern
;       for negative numbers will be different than for positive numbers.
;
;*PROCEDURE: 
;
;      Each bit in the input parameter is checked.
;
;      Note that negative integers are stored in twos complement form.
;      Therefore, the left-most bits are ON rather than OFF as they are for 
;      positive numbers. Input the absolute value of A is negative numbers 
;      to avoid this problem. 

;      If the input parameter is a integer vector with N elements, 
;      the output parameter will be an array with 16xN elements, with
;      the first bit status contained in the first column 0, second bit in
;      the second column, etc. A scalar byte value would produce a 8
;      element vector.
;
;      Note when the output parameter is displayed, the bit order will be 
;      opposite that normally used for displaying bit patterns (i.e., 
;      the least significant bit is on the left and the most significant
;      is on the right).
;
;*MODIFICATION HISTORY:
;
;        3/30/93 rwt allow byte data
;	   Dec 1998       removed use of PARCHECK;  incorporated BITTEST code
;
;-
;******************************************************************************
 pro bitlis,a,b

;  check input

 npar = n_params(0)
 if (npar eq 0) then begin
    print,' BITLIS,A,B'
    retall
 endif  ; npar eq 0

;  determine dimension and type of input

 s = size(a)
 type = s(s(0)+1)
 lbit = (type * 8) - 1                     ; type = 1,2,or 3
 dim = s(0)
 if (dim eq 0) then b = bytarr(lbit+1) else b = bytarr(lbit+1,s(1))

;  step through input

 for i=0,lbit do begin

;  yesno -> 1 (true) if bit i is set, 0 (false) otherwise

;    bittest,a,i,yesno
    yesno = ( fix(a) or (not 2^i) ) eq -1 

    if (dim eq 0) then b(i) = yesno 
    if (dim eq 1) then b(i,0:*) = yesno
 endfor  ; i

 return
 end  ; bitlis 
