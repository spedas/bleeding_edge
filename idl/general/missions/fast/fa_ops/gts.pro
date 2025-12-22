;+
; PROCEDURE:    gts.pro  (Generic Trending System)
;
; PURPOSE:      Extracts DQIs from SDT SMBs.
;               Saves variables to a file.
;               Called by gts_batch.pro from sdt_batch, from gts.ksh.
;
; ARGUMENTS:    None
;
; ENV. VARS:    output_datafile      File in which to save the data.
;               DQIlist              List of SDT Data Quantity Instances
;
; BY:           J. Rauchleiba 1998/8/20
;-

pro gts

filename = getenv('output_datafile')
if NOT keyword_set(filename) then message, 'Output data file not set'
dqilist_stg = getenv('DQIlist')
dqilist = str_sep(strcompress( strtrim(dqilist_stg,2) ), ' ')
if NOT keyword_set(dqilist(0)) then message, 'DQI list not set'

n_dqis = n_elements(dqilist)

;; Generically loop through all the quantities

for t=0, n_dqis-1 do begin
    ;; get-routine name must be same as created by edit_template.ksh
    get_command = strlowcase(dqilist(t)) + $
      ' = get_fa_' + strlowcase(dqilist(t)) + '(/all)'
    print, 'Running: ' + get_command
    valid=0
    success = execute(get_command)
    if success NE 1 $
      then message, 'Failed to execute "get" for: ' + dqilist(t), /cont
    success = execute('valid = ' + dqilist(t) + '.valid')
    if valid NE 1 then message, dqilist(t) + ' data not valid', /cont
endfor

;; Put DQI list into comma-separated string

varlist = dqilist + [replicate(',', n_dqis - 1), '']
varstring=''
for v=0, n_dqis-1 do varstring = varstring + varlist(v)

;; Save the structures in a data file

success = execute('save, ' + varstring + ', filename=filename')
if success EQ 0 then message, 'Error saving variables ' + varstring + $
  ' to file: ' + filename

end    
