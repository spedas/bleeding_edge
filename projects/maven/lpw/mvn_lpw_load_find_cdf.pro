;+
;PROCEDURE:
;
;PURPOSE:
; Routine to search for the CDF files MAVEN lpw produces, and load them into tplot memory. Routine is called upon by mvn-lpw-load.pro. Routine
; will search for CDF files that lie within a UTC time given to mvn-lpw-load. 
; 
;USAGE:
;  files = mvn_lpw_load_find_cdf('2014-02-02')
;
;INPUTS:
;  data: a UTC string of the form 'yyyy-mm-dd'. 
;
;OUTPUTS:
;  output is a string array containing full directories to cdf files which lie on the day input.
;
;KEYWORDS:
;
;  NONE
;   Version 1.0
;
;MODIFICATIONS:
;2014-05-23  CF: finalized routine to work with mvn-lpw-load-file
;;140718 clean up for check out L. Andersson
;-


function mvn_lpw_load_find_cdf, date

sl = path_sep()

;Input date is in form yyyy-mm-dd; remove the -'s:
yyyy = strmid(date, 0, 4)
mm = strmid(date, 5, 2)
dd = strmid(date, 8, 2)

file_date = yyyy+mm+dd

; We have 13 cdf variables to search for:
vars = ['we12', 'we12burstlf', 'we12burstmf', 'we12bursthf', 'wspecact', 'wspecpas', 'mrgscpot', 'lpiu', 'wn', 'lpnt', 'mrgexb', $
        'euvband', 'euvsolarspec', 'act', 'adr', 'atr', 'euv', 'hsk', 'pas']
        
;vars = ['mvn_lpw_calib_mgr_sc_pot', 'mvn_lpw_calib_w_e12', 'mvn_lpw_calib_w_e12_burst_lf', 'mvn_lpw_calib_w_e12_burst_mf', $
;       'mvn_lpw_calib_w_e12_burst_hf', 'mvn_lpw_calib_w_spec_pas', 'mvn_lpw_calib_w_spec_act', 'mvn_lpw_derived_w_n', $
;       'mvn_lpw_calib_lp_IV', 'mvn_lpw_derived_lp_n_T', 'mvn_lpw_derived_mrg_ExB', 'mvn_lpw_calib_euv_irr']
                                         
print, "#######################"
print, "You have chosen to load CDF files. Do you want to get them from LASP or BERK (Berkeley)? Entering 'no' will return you to IDL terminal:"
response = ''
read, response, prompt="Enter 'LASP' or 'BERK', followed by the return key..."
if response eq 'no' then begin
   print, "Reponse: No. Returning to IDL terminal."
   retall
endif 
 
    ;Add '/' to end if user doesn't   ;##### might be needed later
    ;slen = strlen(response)  ;number of characters in the CDF directory
    ;extract = strmid(response, slen-1,1)  ;extract the last character
    ;IF extract NE sl THEN response = response+sl  ;add / to end so new folder is not created. 

;============
;Search path:
;============
;Based on user response, define path to search:
if response eq 'LASP' then base_path = '/Volumes/spg/maven/products/automatic_production/'  ;path to cdf files at LASP spg server
if response eq 'BERK' then begin
  print, "Berkeley cdf loader not yet written, sorry! Returning..."
  retall
endif
if response ne 'LASP' and response ne 'BERK' then begin
  print, "### WARNING ###: enter 'LASP' or 'BERK' as path to search for CDF files. Returning to terminal."
  retall
endif

;============
;Files found:
;============
;Search through all sub directories to find available files matching the input date. LASP file structure is known, Berkeley one to be written
;at a later date.
if response eq 'LASP' then begin
    sub_folders = ['l0b', 'l1a', 'l1b', 'l2']  ;subfolders at LASP, although somewhat hardcoded below as well
endif

if response eq 'Berkeley' then begin
    sub_folders = ['TBW']  ;###### to be written
endif

nele_sub = n_elements(sub_folders)  ;number of sub directories to search

found_l0b = strarr(1)  ;store found cdf files
found_l1a = strarr(1)
found_l1b = strarr(1)
found_l2 = strarr(1)

nele_v = n_elements(vars)  ;number of cdf files we want

for hh = 0, nele_sub -1 do begin
      full_path = base_path+sub_folders[hh]+sl+yyyy+sl+mm+sl  ;full path based on input date year and month
      
      ;Check this sub dir exists before checking for files in it:
      res = file_search(full_path)
      if res ne '' then begin  ;if we find the directory, carry on

            ;Look for files
            files = file_search(full_path+'*')  ;files is a string array containing all files within the directory response
            if files[0] ne '' then begin
                  ;Extract just CDF files:
                  slens = strlen(files)  ;array with length of the string files
                  nele_f = n_elements(slens)   ;number of all files found in this directory
                  cdf_files=[''] ;dummy
                  for aa = 0, nele_f -1 do begin
                    if strmid(files[aa], slens[aa]-4,4) eq '.cdf' then cdf_files = [cdf_files,files[aa]]  ;if a .cdf file add to array
                  endfor ;over aa
    
                  if n_elements(cdf_files) gt 1 then begin
                        nele_cdf = n_elements(cdf_files)-1  ;first element is a dummy ''
                        cdf_files = cdf_files[1:nele_cdf]  ;get rid of first dummy point, have already subtracted 1 from nele_cdf
                      
                        cdf_files_date=['']  ;dummy to store cdf file names which match this date
                        for aa = 0, nele_cdf-1 do begin   ;go over all found cdf files
                          ;Files will have the name format: mvn_lpw_[l1a]_[w_e12]_yyyymmdd_r##_v##.cdf.
                          ;stuff in [] will change length. Work from back of cdf name, to get date, as this length won't change.
                          slen = strlen(cdf_files[aa])  ;length of this file name

                          if slen gt 19 then begin  ;if length is <19 characters it's not named as an lpw cdf file
                            if strmid(cdf_files[aa], slen-20,8) eq file_date then begin
                              cdf_files_date = [cdf_files_date, cdf_files[aa]]  ;add this cdf file name if it matches the date
                            endif
                          endif  ;over slen>19
                        endfor  ;over aa                      
                                          
                      
                        ;Store found files:
                        if sub_folders[hh] eq 'l0b' then found_l0b = [found_l0b, cdf_files_date]
                        if sub_folders[hh] eq 'l1a' then found_l1a = [found_l1a, cdf_files_date]
                        if sub_folders[hh] eq 'l1b' then found_l1b = [found_l1b, cdf_files_date]
                        if sub_folders[hh] eq 'l2' then found_l2 = [found_l2, cdf_files_date]
                                                                                       
                  endif  ;over nele cdf files
                                  
            endif  ;over files[0] ne ''                  
                  
      endif ;over res ne ''
                  
endfor  ;over nele_sub
                  
;We now have 4 folders containing names of cdf files found which match the input date. Output results to user and
;ask which level to load into tplot, and which variables:

nele_l0b = n_elements(found_l0b)  ;first element is still a dummy string, to be removed
nele_l1a = n_elements(found_l1a)
nele_l1b = n_elements(found_l1b)
nele_l2 = n_elements(found_l2)                  

;Because cdf_files_date also has a first dummy entry, there are 2 first dummy entries to remove:
if nele_l0b gt 2 then found_l0b = found_l0b[2:nele_l0b-1]  ;get rid of first 2 dummy entries
    nele_l0b -= 2

if nele_l1a gt 2 then found_l1a = found_l1a[2:nele_l1a-1]  ;get rid of first 2 dummy entries
      nele_l1a -= 2

if nele_l1b gt 2 then found_l1b = found_l1b[2:nele_l1b-1]  ;get rid of first 2 dummy entries
    nele_l1b -= 2

if nele_l2 gt 2 then found_l2 = found_l2[2:nele_l2-1]  ;get rid of first 2 dummy entries
      nele_l2 -= 2

;###### if we find files, do this:
nele_total = nele_l0b + nele_l1a + nele_l1b + nele_l2
;Sort the cdf files into one array so we can assign an indice to each variable for the user to input:

if nele_total gt 0 then begin  ;if cdf files were found:

      found_all = strarr(2,nele_total)
      
      ;Fill in entries:
      if nele_l0b gt 0 then begin
          for aa = 0, nele_l0b-1 do begin
                found_all[0,aa] = strtrim(aa,2)  ;add an indice
                found_all[1,aa] = strtrim(found_l0b[aa],2)
          endfor
      endif
      if nele_l1a gt 0 then begin
          for aa = nele_l0b, (nele_l0b+nele_l1a-1) do begin
                found_all[0,aa] = strtrim(aa)
                found_all[1,aa] = strtrim(found_l1a[aa-nele_l0b],2)
          endfor
      endif
      if nele_l1b gt 0 then begin
          for aa = (nele_l0b+nele_l1a), (nele_l0b+nele_l1a+nele_l1b-1) do begin
            found_all[0,aa] = strtrim(aa)
            found_all[1,aa] = strtrim(found_l1b[aa-nele_l0b-nele_l1a],2)
          endfor
      endif
      if nele_l2 gt 0 then begin
          for aa = (nele_l0b+nele_l1a+nele_l1b), (nele_l0b+nele_l1a+nele_l1b+nele_l2-1) do begin
            found_all[0,aa] = strtrim(aa)
            found_all[1,aa] = strtrim(found_l2[aa-nele_l0b-nele_l1a-nele_l1b],2)
          endfor
      endif

      ;endif  ;over nele_total
      
      
      print, " ###################################################################"
      print, " --- The following CDF files matching the input date were found: ---
      print, " ###################################################################"
      print, ""
      print, "  L0b (", strtrim(nele_l0b,2), ") files:"
      if nele_l0b gt 0 then print, found_all[*,0:nele_l0b-1] else print, ""
      print, ""
      print, "  L1a (", strtrim(nele_l1a,2), ") files:"
      if nele_l1a gt 0 then print, found_all[*,nele_l0b : nele_l0b + nele_l1a - 1] else print, ""
      print, ""
      print, "  L1b (", strtrim(nele_l1b,2), ") files:"
      if nele_l1b gt 0 then print, found_all[*,nele_l0b + nele_l1a : nele_l0b + nele_l1a + nele_l1b - 1] else print, ""
      print, ""
      print, "  L2 (", strtrim(nele_l2,2), ") files:"
      if nele_l2 gt 0 then print, found_all[*,nele_l0b + nele_l1a + nele_l1b : nele_total -1] else print, ""
      print, ""
      
      ;============
      ;User select:
      ;============
      ;User now selects which files to load into IDL memory:
      print, "Enter the indice(s) of the files you want loaded into tplot memory, separated by commas. For example: 3,4,5,6"
      print, "Use *type* to load all files from one type, for example: *l0b* to load all l0b files."
      print, "Indices and * * can be used together, separated by commas."
      print, "DO NOT include any spaces - they will not be recognized."
      print, "Enter none if you do not want to load any of these files."
      response2 = ''
      read, response2, prompt="Enter comma separated selection(s) followed by return key..."
      
      split = strsplit(response2, ',', /extract)  ;split is an array containing each entered response
      
      nele_split = n_elements(split)
      final_selec = ''  ;final selected variables as chosen by user
      
      for aa = 0, nele_split -1 do begin
          ;Check for **:
          if split[aa] ne 'none' then begin  ;skip if user didn't want any variables
              if split[aa] eq '*l0b*' then final_selec = [final_selec, found_l0b] else $
              if split[aa] eq '*l1a*' then final_selec = [final_selec, found_l1a] else $
              if split[aa] eq '*l1b*' then final_selec = [final_selec, found_l1b] else $
              if split[aa] eq '*l2*' then final_selec = [final_selec, found_l2] else $
              if (strmatch(split[aa], '[0123456789]') eq 1) or (strmatch(split[aa], '[0123456789][0123456789]') eq 1) $ 
                or (strmatch(split[aa], '[0123456789][0123456789][0123456789]') eq 1) then begin
                  
                    if float(split[aa]) lt nele_total then final_selec = [final_selec, found_all[1,split[aa]]] 
                    if float(split[aa]) ge nele_total then print, "### WARNING ###: input entry '", strtrim(split[aa],2), "' is too large a number. Skipping."
          
                    
                   endif else print, "### WARNING ###: input entry '", strtrim(split[aa],2), "' is not recognized. Skipping."
                   
          endif else final_selec[0] = 'none' ;over 'none'
      endfor  ;over aa
      
      nele_final = n_elements(final_selec)
      if final_selec[0] ne 'none' then begin
            final_selec = final_selec[1:nele_final-1]  ;remove first dummy point if user makes selections                  
            nele_final -= 1  ;account for removed dummy entry        
      endif else begin  ;exit if user returns 'none':
          print, "You wanted no CDF files. Returning to terminal."
          retall
      endelse
      
endif  ;over nele_total
    
if nele_total eq 0. then begin
      print, "#######################################################"
      print, "No CDF files found for input date ", date, " returning."
      print, "#######################################################"
      retall
endif     

print, "##################################################"
print, "--- Found and loading the following CDF files: ---"
print, "##################################################"
print, final_selec
  
return, final_selec  ;return file directory to files for loading using cdf_read
end






