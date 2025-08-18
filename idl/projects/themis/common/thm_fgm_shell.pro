;+
; Purpose: wrapper for the thm_fgm_overviews procedure
;
; Arguments: 
;        date(optional): the input date (default: current date)
;
;        reprocess(optional): set this keyword to reprocess all the
;        plots
;
;        test_reprocess(optional): set this keyword to perform jimm's
;        reprocessing test
;         
;        directory(optional): the directory into which pngs will be
;        output (default: current working directory)
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-06 12:37:07 -0800 (Fri, 06 Jan 2012) $
; $LastChangedRevision: 9507 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_fgm_shell.pro $
;-
pro thm_fgm_shell,date=date,reprocess = reprocess, test_reprocess = test_reprocess,directory=directory

set_plot,'z'   ; set_plot now done in thm_over_shell.pro

device, set_resolution = [850, 900]

thm_init

del_data,'*'

dprint, date

if not keyword_set(date) then date = time_string(systime(1, /UTC))

if keyword_set(test_reprocess) then $
  start_date = time_double(date)-86400.*2 $
else if keyword_set(reprocess) then $
  start_date = time_double('2007-02-19') $
else $
  start_date = time_double(date)-86400.*5

end_date=time_double(date)       ; make plots for the 5 days

;start_date=time_double('2007-02-16')
;end_date=time_double('2007-08-02')


probe=['a','b','c','d','e']

;datein='2007-02-16'

i=0.

while start_date+86400.*i le end_date do begin

  datein=time_string(start_date+86400.*i)
  dprint, time_string(datein)
 
 ; catch, error_status
  error_status = 0
  if error_status ne 0 then begin
    dprint,  '************************************'
    dprint,  '************************************'
    dprint,  error_status
    print,!ERROR_STATE.msg
  endif else begin
      datein=time_string(datein)
      thm_fgm_overviews,datein, directory=directory,device='z'
      del_data,'*'
  endelse
  
  i++

endwhile ;k

end
