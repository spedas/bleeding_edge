
;Procedure:
;  spd_slice2d_get_support
;
;Purpose:
;  Retreive user specified support data for spd_slice2d.
;  This routine abstracts the tast of checking if input is
;  undfined, an array, or a tplot variable. 
;
;Calling Sequence:
;  spd_slice2d_get_support, input, trange, output=output [,/matrix]
;
;Input:
;  input: input variable to be checked
;  trange: two element time range
;  matrix: Flag specifying that the data is a 3x3 matrix, otherwise a 3-vector is assumed.
;          If input is a tplot variable and multiple samples exist within the time range
;          then the sample closest to the center will be returned. 
;
;Output:
;  output: undefined - if input is undefined
;          3-vector/3x3 matrix - if input is 3-vector/3x3 matrix
;                              - if input is a valid tplot variable that covers the time range
;          NaN - otherwise 
;
;Notes:
;  -If the specified tplot variables has no points in the time range then 
;   a linear interpolation will be attempted to return a value at the center
;   of the time range.  This will not occur for matrices.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-13 17:46:11 -0700 (Fri, 13 May 2016) $
;$LastChangedRevision: 21085 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_get_support.pro $
;-

pro spd_slice2d_get_support, input, trange, matrix=matrix, output=output

    compile_opt idl2, hidden


if undefined(input) then return

dim = keyword_set(matrix) ? [3,3] : [3]

if is_num(input) && array_equal( size(input,/dim), dim ) then begin
  
  output = double(input)
    
endif else begin

  output = double(spd_tplot_average(input, trange, center=keyword_set(matrix)))

endelse 


end