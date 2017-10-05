;+
;spd_ui_draw_object method: indexMagic
;
;This function returns indices of all the data values greater(or less) 
;than the index limit + 1(or -1).  It is vectorized, so
;that it will work quickly even if there is a lot of data. 
;
;Inputs:
;  Data(2-dimensional array of data points any numeric type):
;     The values that will be modified dims = MxN
;  Idx(array of indices): an M element array of indices 
;     that specify the limit.  All indices greater(or less) than
;     this index + 1 in a particular column will be returned  
;  Less(boolean keyword):  If set, indicates that indices less than
;                    index - 1 should be returned
;                    
;Outputs: 
;  All the indices that fit the limit critereon, -1 if no values found.
;  
;NOTES:
; 1.  This is used in y-clipping spectrograms.  We want there to be a small amount
;  of margin on spectrograms to prevent any blank from showing up at the edge
;  of plots, but we don't want to render the whole data set because performance
;  would suffer a precipitous drop.
;  
;2. Each element of data[i,*] should be sorted in descending order.
;
;3. This is quite tricky to do without looping, hence the magic.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__indexmagic.pro $
;-
function spd_ui_draw_object::indexMagic,data,idx,less=less

  compile_opt idl2,hidden
  
  ;if we have 1 offending value, it is swallowed by the margin
  ;any more than that, and there is a chance that we'll need
  ;to NaN-clip
  if n_elements(idx) gt 1 then begin

    ;turn the 1-d indices into pairs of 2-d indices
    idx2 = array_indices(data,idx)
    
    ;sort on x-value
    ;This is the central trick. A side effect of a stable sort
    ;on pre-sorted inputs, is that the values for each individual
    ;x-will now be sorted.  Because IDL:'sort' is not stable, 'bsort'
    ;must be used by this algorithm
    srt2 = bsort(idx2[0,*])
    
    ;now reorder indices in order of ascending x indices
    idx2 = idx2[*,srt2]
    
    ;this block identifies all the indicies that are not the minimum(or max) in a column
    if keyword_set(less) then begin
      idx3 = where((shift(idx2[0,*],1)-idx2[0,*]) eq 0,c)
    endif else begin
      idx3 = where((shift(idx2[0,*],-1)-idx2[0,*]) eq 0,c)
    endelse
    
    ;if any exist we return our magic indexes
    if c gt 0 then begin
   
      return,idx2[*,idx3]
  
    endif
    
  endif
  
  return,-1

end
