;+
; NAME: PDQPLOT
;
;
;
; PURPOSE: to make quick line plots of quantities in FA_FIELDS
;          structures, mostly for debugging purposes.
;
; CALLING SEQUENCE: pdqplot,DATA
;
; INPUTS: DATA is a structure which has a TIME tag and some COMP*
; tags. The data in the COMP tags will be plotted vs. the TIME tags.
;
; SIDE EFFECTS: plot(s) appear in the default window. The plot(s) will
; begin from time = 0, defined as the earliest time in DATA. 
;
; EXAMPLE: v14 = get_fa_fields('V1-V4_S',/all)
;          pdqplot,v14
;
; MODIFICATION HISTORY: written pdq, 16-July-1996 by Bill Peria
;
;-
pro pdqplot,data

if (idl_type(data) ne 'structure') then begin
    message,'need a data structure!',/continue
    return
endif

tags = strlowcase(tag_names(data))
ntags = n_elements(tags)

reqtags = ['time','valid']
if missing_tags(data,reqtags) gt 0 then begin
    message,'required tags are missing...OOPS!',/continue
    return
endif

if not data.valid then begin
    message,' Data is not valid!',/continue
    return
endif

tags = strlowcase(tag_names(data))
ntags = n_elements(tags)
data_tag_spots = where(strmid(tags,0,4) eq 'comp',ndts)
if ndts le 0 then begin
    message,'no component tags in input structure!',/continue
    return
endif

stchk = where(tags eq 'start_time',nst)
if nst gt 0 then begin
    start_time = data.start_time
endif else begin
    start_time = double(min(data.time))
endelse

uchk = where(tags eq 'units_name',nu)
if nu le 0 then begin
    units = 'RAW'
endif else begin
    units = data.units_name
endelse

nchk = where(tags eq 'data_name',nn)
if nn le 0 then begin
    name = 'UNKNOWN'
endif else begin
    name = data.data_name
endelse

pmulti_old = !p.multi

!p.multi = [0,1,ndts,0,0]

time = float(data.time - start_time)
for i=0,ndts-1 do begin
    plot,time,data.(data_tag_spots(i)),title =name+' from ' + $
      ''+time_to_str(start_time,/msec),/ynozero, $
      xstyle = 1,xtitle='seconds',ytitle=units
endfor

!p.multi = pmulti_old

return
end


