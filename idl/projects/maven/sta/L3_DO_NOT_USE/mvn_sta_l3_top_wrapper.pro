;+
;Wrapper for CMF testing only: routine to produce preliminary STATIC L3 density tplot save files, using the latest mvn_sta_l3_top routine.
;Files should be checked to make sure everything looks good.
;
;INPUTS:
;date1, date2: strings, 'yyyy-mm-dd', date range to look at, inclusive, meaning that data for days date1 and date2 are included.
;              if not set, use the pcase keyword to select hardcoded time ranges. pcase is for CMF testing and will be removed
;              eventually.
;
;pcase: date ranges to look at. See code for time ranges. Will be removed eventually.
;
;KEYWORDS:
;Set /batchspice if running a large batch job over many days. In this case, mvn_spice_kernels(/load) is run once at the very start
;   over the full date range, rather than on each individual day.
;
;Set /qualc to use Mike Chaffins qualcolors (CMF default).
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/DensityProcessing/mvn_sta_pro_den_wrapper.pro
;-
;

pro mvn_sta_l3_top_wrapper, date1, date2, tmpdir=tmpdir, pcase=pcase, batchspice=batchspice, qualc=qualc



  ;These are hard coded time ranges for CMF testing - can be removed eventually
  if keyword_set(pcase) then begin
    case pcase of
      '1' : begin
              date1 = '2019-04-01' ;dayside
              date2 = '2019-05-31'
            end
      '2' : begin
              date1 = '2016-07-01'  ;nightside
              date2 = '2016-08-31'
            end

     

    endcase
  endif  ;pcase

  time1 = time_double(date1)
  time2 = time_double(date2)

  ndays = floor((time2-time1)/86400d)+1l  ;need the plus one to get inclusive date1 to date2

  success_array = fltarr(ndays)

  ;Get SPICE:
  timespan, date1, ndays
  if keyword_set(batchspice) then begin
      kk=mvn_spice_kernels(/load)
      indspice = 0  ;do not load SPICE for each individual date
  endif else indspice = 1  ;do load SPICE for each individual date

  for dd = 0l, ndays-1l do begin
      dateTMP = time_string(time1 + (86400d*dd), precision=-3)
  
      store_data, '*', /delete
      
      mvn_sta_l3_top, dateTMP, /den, success=success, indspice=indspice, tmpdir=tmpdir
   
      success_array[dd] = success

  endfor  ;dd

  print, ""
  print, "All done mate"

end
