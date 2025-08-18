;+
;
;spd_ui_draw_object method: niceNum
;
;Function adapted from Graphics Gems:
;Heckbert, Paul S., Nice Numbers for Graph Labels, Graphics Gems, p. 61-63, code: p. 657-659
;It identifies the closest "nice" number
;Nice being a number j * 10 ^ n where j = 1,2,5,10 and n = any integer
;
;Inputs:
;  n(double):  The number for which the nearest nicenum is being found
;  
;  floor(optional,boolean keyword): The routine picks the nearest nicenum below n
;  
;  ceil(optional,boolean keyword): The routine picks the nearest nicenum above n
;  
;  factors(optional, array of numeric types): rather than using 1,2,5,10, pass an array
;                                      of alternate values. Common inputs are
;                                      [1,2,3,4,5,6,7,8,9,10], or [1,2,3,6,10]
;                                      
;  bias(optional,long): Some sets of factors may entail looking at the first 2 or D
;                       digits of the nearest nicenum, rather than just the first. 
;                       If this is the case, this argument should be set to instruct
;                       this algorithm to look at 2 digits.  For example, if 
;                       factors = dindgen(101), bias should be 1, if factors = dindgen(1001)
;                       bias should be 2. The default is 0
;  Outputs:                     
;    factor_index(long): this returns an index into the factor_array indicating which
;                        factor actually got selected.  For example: If nicenum = 2, then 
;                        factor_index = 1
;  
;  Returns: 
;     The nicenum that was found
;  
;NOTES:
;  Default behavior is to find the nearest nicenum above or below N, but the algorithm from
;  graphics gems could only approximate this somewhat roughly.  So instead, two calls one
;  with /floor and one with /ceil is made by the calling routine and the called decides
;  which result is closest.
  
;
;factor_index:  The index of the factor that will be used for the result.(ie different j's)
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__nicenum.pro $
;-


function spd_ui_draw_object::niceNum,n,floor=floor,ceil=ceil,factors=factors,bias=bias,factor_index=factor_index

  compile_opt idl2,hidden

  ;factors = dindgen(100)+1
 ; factors = [1,2,5,10]

  ;this input used to determine the values that
  ;the leading digit(s) should snap to 
  if ~keyword_set(factors) then begin
    factors = [1,2,3,4,5,6,7,8,9,10]
  endif
  
  ;If the algorithm should consider more than 1 digit
  ;This value should grow(bias = 1 => 2 digits considered)
  if ~keyword_set(bias) then begin
    bias = 0
  endif

  exponent = floor(alog10(n))
  
  f = n/(10D^(exponent-bias))
  
  ;For each variant of the operation,
  ;it loops through and finds the "nearest" factor
  ;Then puts the output at the correct order of magnitude.
  ;This could probably be vectorized, but I don't think
  ;that it is taking a lot of runtime.
  
  ;this version performs a floored operation
  
  if keyword_set(floor) then begin
    for i = 0,n_elements(factors)-1 do begin
  
      if i eq n_elements(factors)-1 || $
         f lt factors[i+1] then begin
        nf = factors[i]
        break
      endif 
      
    endfor
  endif else if keyword_set(ceil) then begin
    for i = 0,n_elements(factors)-1 do begin
  
      if  i eq n_elements(factors)-1 || $
          f le factors[i] then begin
          
        nf = factors[i]
        break
      endif 
    
    endfor
  
  endif else begin
  
    for i = 0,n_elements(factors)-1 do begin
    
      if  i eq n_elements(factors)-1 || $
          f lt (factors[i] + factors[i+1])/2D then begin
            
        nf = factors[i]
        break
      endif
       
    endfor
    
  endelse

  factor_index = i
 
  return, nf*(10D^(exponent-bias))

end
