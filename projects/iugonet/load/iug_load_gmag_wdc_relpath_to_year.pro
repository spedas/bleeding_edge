;+
;Function: IUG_LOAD_GMAG_WDC_RELPATH_TO_YEAR
;function iug_load_gmag_wdc_relpath_to_year
;
;Purpose:
;  get year from data path string
;
;Notes:
;  This procedure is called from load procedures for WDC format data,
;  'iug_load_gmag_wdc*' provided by WDC Kyoto.
;
;
;Written by:  Daiki Yoshida,  Aug 2010
;Updated by:  Daiki Yoshida,  Sep 14, 2010
;
;-

function iug_load_gmag_wdc_relpath_to_year, relpath, sname
  year_str = 0
  segm = strsplit(relpath, "/", /extract)

  if strlowcase(sname) eq 'sym' $
     or strlowcase(sname) eq 'asy' $
     or strlowcase(sname) eq 'ae' $
     or strlowcase(sname) eq 'dst' then begin

     for i = 0l, size(segm,/n_elements) -1 do begin
        if segm[i] eq 'index' then begin
           year_str = segm[i+2]
           break
        endif
     endfor

  endif else begin

     for i = 0l, size(segm,/n_elements) -1 do begin
        if segm[i] eq strlowcase(sname) then begin
           year_str = segm[i+1]
           break
        endif
     endfor

  endelse

  return, year_str
end