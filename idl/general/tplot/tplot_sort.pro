;+
;PROCEDURE:  tplot_sort,name
;PURPOSE: 
;   Sorts tplot data by time (or x).
;INPUT:
;   name: name of tplot variable to be sorted.
;KEYWORDS:  
;
;CREATED BY:    Peter Schroeder
;LAST MODIFICATION:     %W% %E%
; $LastChangedBy: lbwilsoniii_desk $
; $LastChangedDate: 2018-01-31 11:56:42 -0800 (Wed, 31 Jan 2018) $
; $LastChangedRevision: 24612 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_sort.pro $
;
;-

pro tplot_sort,name

indx = find_handle(name)

sepname = str_sep(name,'.')

if (n_elements(sepname) eq 1) then begin
;if n_elements(sepname) eq 1 then begin
	get_data,name,ptr=pdata
;	test = (size(pdata,/type) ne 10)
	test = (size(pdata,/type) ne 8)
	if (test[0]) then return  ;;  Not a time-varying data quantity --> exit
	str_element,pdata,'X',foo,success=ok
	if ok then begin
;	  PRINT,'sorting TPLOT handle:  '+name[0]
		newind = sort(*(pdata.x))
		*(pdata.x) = (*(pdata.x))[newind]
;		*(pdata.x) = (*(pdata.x))(newind)
;		if ndimen(*(pdata.y)) eq 1 then $
;			*(pdata.y) = (*(pdata.y))(newind) else $
;			*(pdata.y) = (*(pdata.y))(newind,*)
		yndim = ndimen(*(pdata.y))
		if (yndim[0] eq 1) then begin
			*(pdata.y) = (*(pdata.y))[newind]
		endif else if (yndim[0] eq 2) then begin
			*(pdata.y) = (*(pdata.y))[newind,*]
		endif else if yndim[0] eq 3 then begin
				*(pdata.y) = (*(pdata.y))[newind,*,*]
		endif else if yndim[0] eq 4 then begin
        *(pdata.y) = (*(pdata.y))[newind,*,*,*]
		endif
;		if vok then if ndimen(*(pdata.v)) eq 2 then $
;			*(pdata.v) = (*(pdata.v))(newind,*)
		str_element,pdata,'V',foo,success=vok
		if vok then if (ndimen(*(pdata.v)) eq 2) then $
			*(pdata.v) = (*(pdata.v))[newind,*]
		;;  Need to account for V1 and V2, if present
		str_element,pdata,'V1',foo,success=v1ok
		str_element,pdata,'V2',foo,success=v2ok
		if (v1ok[0] and v2ok[0]) then begin
			test = (ndimen(*(pdata.v1)) eq 2) and (ndimen(*(pdata.v2)) eq 2)
			if (test[0]) then begin
				;;  Dimensions are okay --> sort
				*(pdata.v1) = (*(pdata.v1))[newind,*]
				*(pdata.v2) = (*(pdata.v2))[newind,*]
			endif
		endif
		str_element,pdata,'V3',foo,success=v3ok
		if v3ok eq 1 then begin
       *(pdata.v3) = (*(pdata.v3))[newind,*]
		endif
		;;  Need to account for DY, if present
		str_element,pdata,'DY',foo,success=vok
		if (vok[0]) then begin
			test = (ndimen(*(pdata.dy)) eq yndim[0])
			if (test[0]) then begin
				case yndim[0] of
					1 : *(pdata.dy) = (*(pdata.dy))[newind]
					2 : *(pdata.dy) = (*(pdata.dy))[newind,*]
					3 : *(pdata.dy) = (*(pdata.dy))[newind,*,*]
					4 : *(pdata.dy) = (*(pdata.dy))[newind,*,*,*]
					else :  ;;  Do nothing --> can't handle 5D arrays currently
				endcase
			endif
		endif
	endif else begin
;			newind = sort(*(pdata.time))
;			tags = tag_names_r(pdata)
;		for i = 0,n_elements(tags)-1 do begin
;			str_element,pdata,tags(i),thisfoo
;			if ndimen(*(thisfoo)) eq 1 then $
;				*(thisfoo) = (*(thisfoo))(newind) else $
;				*(thisfoo) = (*(thisfoo))(newind,*)
		str_element,pdata,'TIME',foo,success=ok
		if ok then begin
			if (size(pdata.time,/type) eq 10) then begin  ;;  make sure pointer-type
				if (ptr_valid(pdata.time)) then begin     ;;  make sure pointer is valid
					newind = sort(*(pdata.time))
					tags = tag_names_r(pdata)
					for i=0l, n_elements(tags) - 1l do begin
						str_element,pdata,tags[i],thisfoo
						if (size(thisfoo,/type) eq 10) then begin  ;;  make sure pointer-type
							if (ndimen(*(thisfoo)) eq 1) then $
								*(thisfoo) = (*(thisfoo))[newind] else $
								*(thisfoo) = (*(thisfoo))[newind,*]
						endif
					endfor
				endif
			endif
		endif
	endelse
;endif else tplot_sort,sepname(0)
endif else tplot_sort,sepname[0]

return
end