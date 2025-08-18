;+
;Wrapper to run mvn_lpw_load_l0 for a single day, and create tplot save files for each day. To be used at SSL to create local tplot
;save files of LPW l0 data, to avoid the long load times.
;
;
;date: string: 'yyyy-mm-dd': input date to load LPW L0 data for.
;
;Output: routine saves a tplot file containing most useful LPW L0 data products, with the name 'mvn_lpw_tplot_l0_'+date+'.tplot'.
;
;Not all LPW L0 data products are saved - the total file size is ~400 mb per day with all products. Only the most useful for comparison
;with STATIC are saved to reduce file sizes.
;
;-
;

pro mvn_lpw_save_l0, date, directory = directory

if keyword_set(directory) then saveDIR = directory $
else saveDIR = '/disks/data/maven/data/sci/lpw/tplot_l0/'  ;save files here. Include year in dir, later on.
yyyy = strmid(time_string(date), 0, 4)
saveDIR = saveDIR+yyyy+'/'
if file_search(saveDIR) eq '' then begin
   file_mkdir, saveDIR
   file_chmod, saveDIR, '775'o ;group-writeable
endif

store_data, '*', /delete  ;clear all tplot as default

timespan, date, 1.  ;one day per file

mvn_lpw_load_l0, packet='nohsbm', /notatlasp, /noserver  ;load LPW L0 data at SSL

;List of tplot names to save: old list; now, save all LPW variables loaded. All tplot variables are deleted above so this is fine.
;tsave = ['mvn_lpw_act_e12', $
;         'mvn_lpw_act3_e12', $
;         'mvn_lpw_act5_e12', $
;         'mvn_lpw_pas_e12', $
;         'mvn_lpw_pas3_e12', $
;         'mvn_lpw_pas5_e12', $
;         'mvn_lpw_swp1_V2', $
;         'mvn_lpw_swp1_dynoff', $
;         'mvn_lpw_swp1_I1_pot', $
;         'mvn_lpw_swp1_izero', $
;         'mvn_lpw_swp1_offset', $
;         'mvn_lpw_swp1_I1', $
;         'mvn_lpw_swp1_IV', $
;         'mvn_lpw_swp1_IV_log', $
;         'mvn_lpw_swp1_dIV', $
;         'mvn_lpw_swp2_V1', $
;         'mvn_lpw_swp2_dynoff', $
;         'mvn_lpw_swp2_I2_pot', $
;         'mvn_lpw_swp2_izero', $
;         'mvn_lpw_swp2_offset', $
;         'mvn_lpw_swp2_I2', $
;         'mvn_lpw_swp2_IV', $
;         'mvn_lpw_swp2_IV_log', $
;         'mvn_lpw_swp2_dIV', $
;         'mvn_lpw_spec_lf_act', $
;         'mvn_lpw_spec_mf_act', $
;         'mvn_lpw_spec_hf_act', $
;         'mvn_lpw_spec_lf_pas', $
;         'mvn_lpw_spec_mf_pas', $
;         'mvn_lpw_spec_hf_pas']


;Filename:
fn = 'mvn_lpw_tplot_l0_'+date

;tplot_save, tsave, filename=saveDIR+fn   ;old version

;Check for existing tplot save file, as file_chmod may not work unless you're the owner of that file:
file1 = file_search(saveDIR+fn+'.tplot', count=nfile)  ;note, tplot_save adds on '.tplot' automatically

if nfile eq 1 then file_delete, saveDIR+fn+'.tplot' ;because maybe file_chmod does not work unless you are the owner

tplot_save, filename=saveDIR+fn  ;save the new file

file_chmod, saveDIR+fn+'.tplot', '664'o ;group-writeable

end


