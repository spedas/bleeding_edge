;+
;
; Procedure: thm_cal_fgm_spintone_removal
;   
; Purpose:
;   Tool to remove spintone from spinplane component FGM high resolution data
;   by dynamical adaption and subtraction of bias field offsets
; 
; Inputs:
;   Time:    vector of time values
;   Data_in:   corresponding spinplane component data, SSL x or y component
;   Datatype: string  'fgl', 'fge' or 'fgh'
;   
; Outputs: 
;   data_out:   corrected data vector
;   offset:     removed offset data vector
;   fulloffset: vector of all offset determinations (for validation)
; 
; Author: Ferdinand Plaschke (2009-10-15)
;         Replace AMOEBA with DFPMIN, Ferdinand Plaschke (2008-10-16)
; 
; Minor modifications by Patrick Cruce(2009-10-15) for TDAS
;           1. Rename with thm prefix
;           2. Standardize documentation.
;           3. Replace print with dprint.
; 
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-07-30 17:39:29 -0700 (Thu, 30 Jul 2015) $
;$LastChangedRevision: 18324 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_cal_fgm_spintone_removal.pro $
;-


;Helper Function.  (Main Routine Below)
function fitfunct_cosplus, P

; Fit-function for spin plane component SSL data.
;
; y = (A + B * x) * cos(omega * (x - x0)) + C
; P[0]: A
; P[1]: B
; P[2]: omega
; P[3]: x0
; P[4]: C

common fitfunct, y, x
fit_y = (P[0] + P[1] * x) * cos(P[2] * (x - P[3])) + P[4]
return, total((fit_y - y)^2) / n_elements(y)
end

function fitfunct_diff_cosplus, P

; Derivative of fit-function:
; y = (A + B * x) * cos(omega * (x - x0)) + C
; with
; P[0]: A
; P[1]: B
; P[2]: omega
; P[3]: x0
; P[4]: C

common fitfunct, y, x
partx0  = (x - P[3])
part1 = cos(P[2] * partx0)
part1b  = sin(P[2] * partx0)
partab  = (P[0] + P[1] * x)
part2 = 2.D * (partab * part1 + P[4] - y) / double(n_elements(y))
dda1  = part2 * part1
dda = total(dda1)
ddb = total(x * dda1)
ddomega1  = part2 * partab * part1b
ddomega = total(- ddomega1 * partx0)
ddx0  = total(ddomega1 * P[2])
ddc = total(part2)
return, [dda, ddb, ddomega, ddx0, ddc]
end

pro thm_cal_fgm_spintone_removal, time, data_in, data_out, datatype, offset=offset, fulloffset=fulloffset

; Program for spintone removal of spinplane component
; FGM high resolution data (FGL, FGE, FGH)

offset		= replicate(0.D, n_elements(time))	; vector of offset values, initialized
fulloffset	= replicate(0.D, n_elements(time))

srt	= 0.2D		; sigma residuum threshold in nT
mbs	= 3.5D * 60.D	; minimum block shift time: 3.5 min in seconds
mig	= 60.D * 60.D	; maximum gap time in interval

case datatype of
'fgl':	begin
		sp		= 0.25D		; sampling period
		spp		= 10L		; lower limit samples per period
		mbl		= 15.D * 60.D	; max block length: 15 min in seconds
		minodets	= 120L		; minimum number of offset determinations
		ost		= 1.D		; offset standard deviation threshold (nT)
	end
'fge':	begin
		sp		= 0.125D	; sampling period
		spp		= 20L		; lower limit samples per period
		mbl		= 15.D * 60.D	; max block length: 15 min in seconds
		minodets	= 120L		; minimum number of offset determinations
		ost		= 1.D		; offset standard deviation threshold (nT)
	end
'fgh':	begin
		sp		= 0.0078125D	; sampling period
		spp		= 320L		; lower limit samples per period
		mbl		= 5.D * 60.D	; max block length: 5 min in seconds
		minodets	= 40L		; minimum number of offset determinations
		ost		= 1.D / sqrt(3.D)	; offset standard deviation threshold (nT)
	end
endcase

;generalize for any sampling period
; for example, if sp=1/16, spp=40
if (n_elements(time) gt 2) then begin
  sp = Double(time[1]-time[0])
  spp = Long(2.5/sp)
endif

;ost	= sqrt(10.D) / sqrt(double(spp))	; offset standard deviation threshold

; cut data_in into segments
in_ib	= where((time - shift(time, 1) gt mig) or (time - shift(time, 1) lt 0.D))	; index: interval begin
in_ie	= where((time - shift(time, -1) lt -mig) or (time - shift(time, -1) gt 0.D))	; index: interval end
n_int	= n_elements(in_ib)		; number of intervals

dprint, dlevel=4, 'Offset correction: ' + string(n_int, format='(-I0)') + ' intervals'
for i_int = 0L, n_int - 1L do begin
	
	; compute offsets
	n_samples	= in_ie(i_int) - in_ib(i_int) + 1L	; number of samples in interval
	n_potoff	= n_samples / spp	; number of potential offset determinations in interval
	
	; check if there are sufficient periods
	if (n_potoff lt minodets) then continue
	
	; initialize offset vector
	raw_off		= dblarr(n_potoff)
	raw_off_time	= dblarr(n_potoff)
	
	; define common block for AMOEBA fitting procedure
	common fitfunct, per_data, time_dummy
	
	dprint, dlevel=4, '  Fitting data of ' + string(n_potoff, format='(-I0)') + ' spin periods in interval ' + string(i_int + 1L, format='(-I0)'), format='(A,$)'
	
	; Error handling for DFPMIN
  catch, error_status
  if error_status ne 0 then goto, next_i_potoff
	
	for i_potoff = 0L, n_potoff - 1L do begin
			
		; period data and time
		per_data	= data_in(in_ib(i_int) + i_potoff * spp:in_ib(i_int) + i_potoff * spp + spp - 1L)
		per_time	= time(in_ib(i_int) + i_potoff * spp:in_ib(i_int) + i_potoff * spp + spp - 1L)
		time_dummy	= dindgen(spp)

		; check if there are continuous data in period
		if (max(per_time) - min(per_time) lt sp * (double(spp) - 0.5D)) then begin
		
			per_data_max	= max(per_data, in_per_data_max, subscript_min=in_per_data_min, min=per_data_min)
			
			fit_param 	= [double(per_data_max - per_data_min) / 2.D, $
          				0.D, $
          				!DPI / double(abs(in_per_data_max - in_per_data_min)), $
          				double(in_per_data_max), $
          				mean([per_data_max, per_data_min])]
			
			if product(finite([fit_param, per_data, per_time])) then begin
      				dfpmin, fit_param, 1.0E-8, fmin, 'fitfunct_cosplus', 'fitfunct_diff_cosplus', /double
     
      				; check if fit is OK
      				if product(finite([fit_param, fmin])) then if (sqrt(fmin) le srt) then begin
        
        				raw_off(i_potoff) = fit_param(4)
	        			raw_off_time(i_potoff)  = mean(per_time)
      
      				endif
			endif
		  	
		endif
		next_i_potoff:
	endfor
	
  ; cancel error handler
  catch, /cancel
	dprint, dlevel=4, ' - done'
		
	in_raw	= where((raw_off_time ne 0.D) and finite(raw_off_time) and finite(raw_off))
	n_raw	= n_elements(in_raw)
	
	; check if there are sufficient offsets remaining
	if (n_raw ge minodets) then begin
			
		raw_off		= raw_off(in_raw)
		raw_off_time	= raw_off_time(in_raw)
		
		; initialize offset medians
		med_off		= dblarr(n_raw)
		med_off_time	= dblarr(n_raw)
		med_quality	= dblarr(n_raw)	; stddev / sqrt(number of contributing offsets)
		med_status	= intarr(n_raw)	; status flag: 0:criteria not met, 1:good offset
			
		in_rf	= 0L
		for i_raw = minodets / 4L - 1L, n_raw - 1L do begin
			
			; select offsets in block
			if (raw_off_time(i_raw) - raw_off_time(in_rf) gt mbl) then begin
				in_med	= where(raw_off_time(in_rf:i_raw) gt raw_off_time(i_raw) - mbl)
				in_rf	+= min(in_med)
			endif
			n_in_med	= n_elements(in_med)
			if (n_in_med ge minodets / 4L) then begin
				
				med_off(i_raw)		= median(raw_off(in_rf:i_raw))
				med_off_time(i_raw)	= mean(raw_off_time(in_rf:i_raw))
				med_stddev		= stddev(raw_off(in_rf:i_raw))
				med_quality(i_raw)	= med_stddev / sqrt(double(n_in_med))
				med_status(i_raw)	= fix((med_stddev le ost) * (n_in_med ge minodets))
			
			endif
			
		endfor
		
		in_med = where((med_off_time ne 0.D) and finite(med_off) and finite(med_off_time) and finite(med_quality) and finite(med_status))
		if (in_med(0) ne -1) then begin
		
			med_off		= med_off(in_med)
			med_off_time	= med_off_time(in_med)
			med_quality	= med_quality(in_med)
			med_status	= med_status(in_med)
			n_med		= n_elements(in_med)
				
			; use only good offsets for correction
			in_status1	= where(med_status eq 1)
			if (in_status1(0) ne -1) then begin
			
				n_status1	= n_elements(in_status1)
				in_status1	= in_status1(sort(med_quality(in_status1)))
				
				in_status0	= lindgen(n_med)
				in_status0	= in_status0(sort(med_quality(in_status0)))
				
				; initialize final offset values
				fin_off		= 0.D
				fin_off_time	= 0.D
				
				in_in1	= dindgen(n_status1)
				repeat begin
				
					fin_off		= [fin_off, med_off(in_status1(0))]
					fin_off_time	= [fin_off_time, med_off_time(in_status1(0))]
					
					in_in1	= where(abs(med_off_time(in_status1) - med_off_time(in_status1(0))) gt mbs)
					in_in0	= where(abs(med_off_time(in_status0) - med_off_time(in_status1(0))) gt mbs)
					
					if (in_in1(0) ne -1) then begin
						in_status1	= in_status1(in_in1)
						in_status0	= in_status0(in_in0)
					endif else if (in_in0(0) ne -1) then in_status0 = in_status0(in_in0)
					
				endrep until (in_in1(0) eq -1)
				
				fin_off		= fin_off(1:*)
				fin_off_time	= fin_off_time(1:*)
				in_sort		= sort(fin_off_time)
				fin_off		= fin_off(in_sort)
				fin_off_time	= fin_off_time(in_sort)
				
				dprint, dlevel=4, '    -> Valid Offsets: ' + string(n_elements(fin_off), format='(-I0)')
				
				; for data correction
				in_fi	= where(time le min(fin_off_time, in_fin_off_min)) > in_ib(i_int)
				in_li	= where(time ge max(fin_off_time, in_fin_off_max)) < in_ie(i_int)

				in_fi	= in_fi(uniq(in_fi, sort(in_fi)))
				in_li	= in_li(uniq(in_li, sort(in_li)))

				n_fi	= n_elements(in_fi)
				n_li	= n_elements(in_li)
				
				offset(in_fi)	= replicate(fin_off(in_fin_off_min), n_fi)
				offset(in_li)	= replicate(fin_off(in_fin_off_max), n_li)
				if (n_elements(fin_off) gt 1L) then offset(max(in_fi) + 1L:min(in_li) - 1L) = interpol(fin_off, fin_off_time, time(max(in_fi) + 1L:min(in_li) - 1L))
				
				if (in_in0(0) ne -1) then repeat begin
				
					fin_off		= [fin_off, med_off(in_status0(0))]
					fin_off_time	= [fin_off_time, med_off_time(in_status0(0))]
					
					in_in0	= where(abs(med_off_time(in_status0) - med_off_time(in_status0(0))) gt mbs)
					
					if (in_in0(0) ne -1) then in_status0	= in_status0(in_in0)
					
				endrep until (in_in0(0) eq -1)
				
				in_sort		= sort(fin_off_time)
				fin_off		= fin_off(in_sort)
				fin_off_time	= fin_off_time(in_sort)
				
				in_fi	= where(time le min(fin_off_time, in_fin_off_min)) > in_ib(i_int)
				in_li	= where(time ge max(fin_off_time, in_fin_off_max)) < in_ie(i_int)
				
				in_fi	= in_fi(uniq(in_fi, sort(in_fi)))
				in_li	= in_li(uniq(in_li, sort(in_li)))

				n_fi	= n_elements(in_fi)
				n_li	= n_elements(in_li)
				
				fulloffset(in_fi)	= replicate(fin_off(in_fin_off_min), n_fi)
				fulloffset(in_li)	= replicate(fin_off(in_fin_off_max), n_li)
				if (n_elements(fin_off) gt 1L) then fulloffset(max(in_fi) + 1L:min(in_li) - 1L) = interpol(fin_off, fin_off_time, time(max(in_fi) + 1L:min(in_li) - 1L))
				
			endif
		endif
	endif
endfor

data_out	= data_in - offset

return
end
