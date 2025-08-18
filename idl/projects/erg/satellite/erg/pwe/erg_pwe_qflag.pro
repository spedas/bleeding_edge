; PRO erg_pwe_qflag
;
; Quality flag viewer for PWE data
;
; :Keywords:
;   full: show all quality flag(s) in full time range.
;   point: show quality flag(s) at a specific point.
;           
;
; :Examples:
;   IDL> erg_pwe_qflag
;   IDL> erg_pwe_qflag, /full
;
; :Authors:
;   Masafumi Shoji ERG Science Center (E-mail: masafumi.shoji at
;   nagoya-u.jp)
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/mep/erg_pwe_qflag.pro $
;-


function array_or, in

  n=n_elements(in)
  ans= in[0]
  for i=1, n-1 do ans = ans or in[i]

  return, ans
END

function erg_pwe_quality_flag_description, qflag

  lists=['b0', 'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8', 'b9', $
   'b10', 'b11', 'b12', 'b13', 'b14', 'b15', 'b16', 'b17', 'b18', 'b19', $
   'b20', 'b21', 'b22', 'b23', 'b24', 'b25', 'b26', 'b27', 'b28', 'b29', 'b30', $
   'b31']


  tmp=long(qflag)
  qflag_bin = bytarr(32,n_elements(tmp))
  for i=0,31 do qflag_bin[31-i,*]=(tmp and 2L^i)/2L^i

  fbin = reverse(qflag_bin)
  idx=where(fbin eq 1, cnt)

  if cnt ne 0 then return, lists[idx] else return, ''

END

pro erg_pwe_qflag, full=full, point=point

  if keyword_set(full) and keyword_set(point) then begin
     dprint, 'Keywords "full" and "point" cannot be set at the same time!'
     return
  endif

  @tplot_com
  scname=['efd','ofa','wfc','hfa']
  subcarr=''
  
  !null=where(tag_names(tplot_vars.settings) eq 'VARNAMES',cnt)

  if cnt eq 0 then begin
     dprint, 'No ERG/PWE data is tplotted!'
     return
  endif else tvars = tplot_vars.settings.varnames[*]

  tall=tnames()
  idx=where(strmatch(tall, '*quality_flag*'), cnt)
  if cnt ne 0 then qtlist=tall[idx] else begin
     print, 'You have not loaded any quality flag yet.'
     return
  endelse

  for i=0,3 do begin
     !null=where(strmatch(tvars, '*'+scname[i]+'*') ne 0, cnt)
     if cnt ne 0 then begin
        append_array, subcarr, scname[i]
     endif
  endfor

;  stop
  
  if keyword_set(full) then begin
     get_timespan, time
     print, ''
     print, 'Time range:', time_string(time[0],precision=3), ' -- ', time_string(time[1],precision=3)
     print, ''
  endif else begin
     if keyword_set(point) then begin
        ctime, timep, npoints=1
        print, ''
        print, 'Selected time:', time_string(timep,precision=3)
        print, ''
     endif else begin
        ctime, time, npoints=2
        print, ''
        print, 'Time range:', time_string(time[0],precision=3), ' -- ', time_string(time[1],precision=3)
        print, ''
     endelse
  endelse
  
  foreach subc, subcarr do begin
     
     if strcmp(subc,'') ne 1 then begin
        
        idx=where(strmatch(qtlist,'*'+subc+'*'), cnt)
        if cnt ne 0 then qtvars=qtlist[idx] else goto, gt0
        
        foreach qtvar, qtvars do begin
           
           get_data, qtvar, data=qflag,dlim=dlim
           
           if ~keyword_set(point) then begin
              
              ist=nn(qflag, time[0])
              iet=nn(qflag, time[1])
              
              if iet-ist gt 2 then begin
                 
                 tflg=array_or(qflag.y[ist:iet])
                 
                 ans = erg_pwe_quality_flag_description(tflg)
                 
                 print, '----------source tplot variable: '+qtvar+ ' ---------------'
                 print, ''
                 print, dlim.cdf.vatt.catdesc+':  ', ans
                 print, ''
                 print, 'Notes of quality flag of ' +strupcase(subc)+ ': ',dlim.cdf.vatt.var_notes
                 print, ''
              endif else begin
                 print, '-----------------------------------------------------------'
                 print, ''
                 print, 'Selected time range for ' +strupcase(subc)+ ' is out of range or too short.'
                 print, ''
              endelse
              
           endif else begin
              
              ip=nn(qflag, timep)
              ans = erg_pwe_quality_flag_description(qflag.y[ip])
           
              print, '----------source tplot variable: '+qtvar+ ' ---------------'
              print, ''
              print, dlim.cdf.vatt.catdesc+':  ', ans
              print, ''
              print, 'Notes of quality flag of ' +strupcase(subc)+ ': ',dlim.cdf.vatt.var_notes
              print, ''
           endelse

        endforeach
        
     endif 
     gt0:
  endforeach

END
