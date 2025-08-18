;+
; NAME:
;       thm_fit_fgm_crosscheck.pro
;
; Purpose:
;       Load a day's worth of FIT, FGE, and FGL data, and produce packet
;       by packet offset estimates by cross-correlating spin fits and 
;       waveforms.
; CATEGORY:
;       THEMIS-SOC
; CALLING SEQUENCE:
;      pro thm_fit_fgm_crosscheck,date=date,probe=probe
; INPUTS:
; 
;
; OUTPUTS:
;       
;  Verbose diagnostic output + final summary
;
; KEYWORDS:
;
; COMMENTS: This function will probably die horribly if time
;  values are not monotonic.
;
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
;-

function thm_fit_fgm_err,vals1,vals2,lag_array
nsteps=n_elements(lag_array)
retvals=dblarr(nsteps)
for i=0,nsteps-1 do begin
   lag=lag_array[i]
   nvals=n_elements(vals1)-abs(lag)
   sse=0.0D
   abslag=abs(lag)
   if lag LE 0 then begin
      for j=0,nvals-1 do begin
          sse = sse + (vals2[j]-vals1[j+abslag])*(vals2[j]-vals1[j+abslag])
      endfor
   endif else begin
      for j=0,nvals-1 do begin
          sse = sse + (vals2[j+abslag]-vals1[j])*(vals2[j+abslag]-vals1[j])
      endfor
   endelse
   retvals[i]=sse/nvals
endfor
return, retvals
end

pro thm_fit_fgm_crosscheck, start_date=date, days=days, probe=probe

; Set timespan
timespan,date,days,/day

; Load L1 fit and support data

thm_load_fit,probe=probe,level=1,/get_supp

; Calculate fit b_total

get_data,'th'+probe+'_fgs',data=fit_dat
fgs_btotal=sqrt(total(fit_dat.Y * fit_dat.Y, 2))
store_data,'th'+probe+'_fgs_btotal',data={x:fit_dat.x, y:fgs_btotal}

; Get last sample time
n=n_elements(fit_dat.x)
t_last=fit_dat.x[n-1] + 0.5

; Look for overlaps and repeated timestamps

ts_diffs=fit_dat.x[1:n-1]-fit_dat.x[0:n-2]

gap_ind=where(ts_diffs GT 5.5,global_gap_count)
dup_ind=where(ts_diffs LT 0.1,global_dup_count)

; The gap and dup counts will be printed at the end of the report.

; Get packet boundaries

get_data,'tha_fit_hed',data=d
original_fit_times=d.x
original_pkt_count=n_elements(d.x)

pkt_times=[d.x,t_last]
pkt_count=n_elements(pkt_times)-1

; Load FGE and FGL using L2 data

thm_load_fgm,probe=probe,level=2,datatype='fge fgl fge_btotal fgl_btotal'

get_data,'th'+probe+'_fge_btotal',data=fge_dat
get_data,'th'+probe+'_fgl_btotal',data=fgl_dat

fge_flag=intarr(pkt_count)
fgl_flag=intarr(pkt_count)
fge_lag=intarr(pkt_count)
fgl_lag=intarr(pkt_count)
fge_offset=intarr(pkt_count)
fgl_offset=intarr(pkt_count)
pkt_status_before=intarr(pkt_count)
pkt_status_after=intarr(pkt_count)
pkt_spinphase=fltarr(pkt_count)

thm_load_state,probe=probe,/get_supp
smp=spinmodel_get_ptr(probe,use_eclipse_correction=0)
smp->interp_t,time=d.x,spinphase=pkt_spinphase

status_codes=['first','gap', 'dup', 'ok', 'last']
pkt_status_before[*]=3
pkt_status_after[*]=3

pkt_status_before[0]=0
pkt_status_after[pkt_count-1]=4


for i=0, pkt_count-1 do begin
   print,"next packet:",time_string(pkt_times[i]), ' spinphase: ',pkt_spinphase[i]
   ts=pkt_times[i]
   te=pkt_times[i+1]
   fit_ind=where((fit_dat.x GE ts) AND (fit_dat.x LT te), fit_count)
   if (fit_count GT 0) then begin
      fit_times=fit_dat.x[fit_ind]
      ; Trim range to observed times in case of missing fit packet
      obs_trange=minmax(fit_times)
      ts=obs_trange[0]
      te=obs_trange[1]
   endif

   if (i GE 1) then begin
      ; check for gaps and dupes
      first_fit_ind=fit_ind[0]
      nearby_times=fit_dat.x[first_fit_ind-5:first_fit_ind+1]
      nearby_diffs=nearby_times[1:6]-nearby_times[0:5]
      dup_ind=where(nearby_diffs LT 1.0,dup_count)
      gap_ind=where(nearby_diffs GT 5.5 ,gap_count)
      if (dup_count GT 0) then begin
        pkt_status_before[i]=2
        pkt_status_after[i-1]=2 
      endif
      if (gap_count GT 0) then begin
        pkt_status_before[i]=1
        pkt_status_after[i-1]=1 
      endif
   endif

    
   fge_ind=where((fge_dat.x GE ts) AND (fge_dat.x LT te), fge_count);
   fgl_ind=where((fgl_dat.x GE ts) AND (fgl_dat.x LT te), fgl_count);
   print,"fit_count: ",fit_count," fge_count: ",fge_count," fgl_count: ",fgl_count
   skip=1
   if (fge_count GT 0) then begin
      fge_flag[i]=1
      skip=0
   endif
   if (fgl_count GT 0) then begin
      fgl_flag[i]=1
      skip=0
   endif
   if (fit_count EQ 0) then begin
      skip=1
      fge_flag[i]=0
      fgl_flag[i]=0
   endif
   
   if (skip eq 0) then begin
      fit_vals=fgs_btotal[fit_ind]
      if (fge_count GT 0) then begin
         fge_times=fge_dat.x[fge_ind]
         fge_vals=fge_dat.y[fge_ind]
         fge_tr=minmax(fge_times)
         fge_ts=fge_tr[0]
         fge_te=fge_tr[1]
         if ( ((fge_ts - ts) GT 3.0) OR ((te - fge_te) GT 3.0)) then begin
            print,"Incomplete FGE coverage"
            fge_flag[i] = 0
         endif else begin
            print, "Calculating FGE overlap"
            ; So now we have fit_times and fit_vals for this packet,
            ; and fge_times and fge_vals with sufficient overlap
            ; to generate a correction. 
            ; Now interpolate the FGE vals to the FIT times.
            interpol_vals=interpol(fge_vals,fge_times,fit_times)
            lag_vector=[-2,-1,0,1,2]
            result=c_correlate(fit_vals,interpol_vals,lag_vector)
            max_corr=max(result,index)
            max_offset=lag_vector[index]
            print,'corr result: ',result
            print,'best offset: ',max_offset
            result_sse=thm_fit_fgm_err(fit_vals,interpol_vals,lag_vector)
            min_sse=min(result_sse,index_sse)
            min_offset=lag_vector[index_sse]
            print,'sse result: ',result_sse
            print,'best offset: ',min_offset
            fge_offset[i]=min_offset
            ;plot,fit_times,fit_vals,psym=2
            ;oplot,fit_times,interpol_vals
         endelse
      endif else begin
         print,"No overlap for FGE"
      endelse

      ; Now do FGL
      if (fgl_count GT 0) then begin
         fgl_times=fgl_dat.x[fgl_ind]
         fgl_vals=fgl_dat.y[fgl_ind]
         fgl_tr=minmax(fgl_times)
         fgl_ts=fgl_tr[0]
         fgl_te=fgl_tr[1]
         if ( ((fgl_ts - ts) GT 3.0) OR ((te - fgl_te) GT 3.0)) then begin
            print,"Incomplete FGL coverage"
            fgl_flag[i] = 0
         endif else begin
            print, "Calculating FGL overlap"
            ; So now we have fit_times and fit_vals for this packet,
            ; and fgl_times and fgl_vals with sufficient overlap
            ; to generate a correction. 
            ; Now interpolate the FGL vals to the FIT times.
            interpol_vals=interpol(fgl_vals,fgl_times,fit_times)
            lag_vector=[-2,-1,0,1,2]
            result=c_correlate(fit_vals,interpol_vals,lag_vector)
            max_corr=max(result,index)
            max_offset=lag_vector[index]
            print,'correlation result: ',result
            print,'best offset: ',max_offset
            result_sse=thm_fit_fgm_err(fit_vals,interpol_vals,lag_vector)
            min_sse=min(result_sse,index_sse)
            min_offset=lag_vector[index_sse]
            print,'sse result: ',result_sse
            print,'best offset: ',min_offset
            fgl_offset[i]=min_offset
         endelse
      endif else begin
         print,"No overlap for FGL"
      endelse


   endif
endfor

; Summarize

fge_pkt_ind=where(fge_flag NE 0,fge_pkt_count)
if (fge_pkt_count GT 0) then begin
    fge_good_offset=fge_offset[fge_pkt_ind] 
    fge_zero_ind=where(fge_good_offset EQ 0,fge_zero_count)
    fge_good_pct=100.0*fge_zero_count/fge_pkt_count
    print,'FGE comparison: '
    print,fge_pkt_count,' packets compared ',fge_zero_count,' no-offset',fge_good_pct,'%'
    print,'Packets with nonzero offset compared to FGE'
    for i=0,pkt_count-1 do begin
       if (fge_offset[i] NE 0) then begin
          print,time_string(original_fit_times[i]), ' offset(spins): ', fge_offset[i], ' spinphase: ', pkt_spinphase[i], ' status_before: ',status_codes[pkt_status_before[i]], ' status_after: ',status_codes[pkt_status_after[i]]
       endif
    endfor
    
endif

fgl_pkt_ind=where(fgl_flag NE 0,fgl_pkt_count)
if (fgl_pkt_count GT 0) then begin
    fgl_good_offset=fgl_offset[fgl_pkt_ind] 
    fgl_zero_ind=where(fgl_good_offset EQ 0,fgl_zero_count)
    fgl_good_pct=100.0*fgl_zero_count/fgl_pkt_count
    print,'FGL comparison: '
    print,fgl_pkt_count,' packets compared ',fgl_zero_count,' no-offset',fgl_good_pct,'%'
    print,'Packets with nonzero offset compared to FGL'
    for i=0,pkt_count-1 do begin
       if (fgl_offset[i] NE 0) then begin
          print,time_string(original_fit_times[i]), ' offset(spins): ', fgl_offset[i], ' spinphase: ', pkt_spinphase[i], ' status_before: ',status_codes[pkt_status_before[i]], ' status_after: ',status_codes[pkt_status_after[i]]
       endif
    endfor
endif

print,'total gap count: ',global_gap_count
print,'total dup count: ',global_dup_count

print,'FGE comparison: '
print,fge_pkt_count,' packets compared ',fge_zero_count,' no-offset',fge_good_pct,'%'
print,'FGL comparison: '
print,fgl_pkt_count,' packets compared ',fgl_zero_count,' no-offset',fgl_good_pct,'%'

end
