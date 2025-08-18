
;+
;Procedure:
;  spd_slice2d_add_line
;
;
;Purpose:
;  Adds one or more contour lines at specified values to a 2D slice plot.
;  This can be useful for notating the data in different units than 
;  those used for the original plot (e.g. adding a contour line
;  representing N counts to a phase space density plot).
;
;
;Calling Sequence:
;  spd_slice2d_add_line, slice, value  [...]
;
;    -accepts valid keywords to IDL CONTOUR procedure
;
;
;Example Usage:
;
;  ;add line at one count
;    spd_slice2d_plot, slice_psd
;    spd_slice2d_add_line, slice_counts, 1
;
;  ;add colored, dotted lines at 1, 5, and 10 counts
;    spd_slice2d_plot, slice_psd
;    spd_slice2d_add_line, slice_counts, [1,5,10], c_linestype=1, c_colors= [60,170,230]
;
;
;Input:
;  slice:  slice structure returnd by spd_slice2d
;  value:  value to draw contour at (default=1)
;  
;  see IDL documentation for CONTOUR procedure keywords
;
;
;Output:
;  none, draws to current plot window
;
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-17 18:50:32 -0700 (Tue, 17 May 2016) $
;$LastChangedRevision: 21102 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/plotting/spd_slice2d_add_line.pro $
;-

pro spd_slice2d_add_line, slice, value, _extra=_extra

  compile_opt idl2, hidden

if ~is_struct(slice) then return

levels = 1d
c_thick = 2
c_linestyle = 2 ;dashed

if is_num(value) then levels=value

;keywords called here are superceded by _extra
contour, slice.data, $
         slice.xgrid, $
         slice.ygrid, $
         levels=levels, $
         xstyle=1+4, $  ;suppress axes
         ystyle=1+4, $  ;
         /overplot, $
         /isotropic, $
         /closed, $
         /follow, $   ;label value of contour  
         /downhill, $   ;annotate downhill direction
         c_thick=c_thick, $
         c_linestyle=c_linestyle, $
         _extra=_extra

end