
pro mvn_lpw_anc_boom_get_luts, lut, shadow=shadow, wake=wake

;+
;Get shadow and wake luts, return them.
;
;
;KEYWORDS:
; - shadow: set /shadow to return the shaow LUT
; - wake: set /wake to return the wake LUT
;
;
;
;
;MODIFICATIONS:
;20150210:CF: modified mvn_lpw_anc_boom_latest_file to grab latest shadow LUT.
;
;-
;

name = 'mvn_lpw_anc_boom_get_luts'
folder = 'mvn_lpw_cal_files'  ;name of the sub folder containing luts
sl = path_sep()


;Check that we have an environment variable telling IDL where to get the luts:
if getenv('mvn_lpw_software') eq '' then begin
    print, name, ": #### WARNING ####: environment variable 'mvn_lpw_software' not set. LUT not found. No shadow or wake data used."
    print, "Use: setenv, 'mvn_lpw_software=/path/to/software/on/your/machine/' to set this variable and locate requested LUTs."
    lut = !values.f_nan ;return nan 
endif else fbase = getenv('mvn_lpw_software')


if getenv('mvn_lpw_software') ne '' then begin
      if keyword_set(shadow) then begin
          ;Check we can find the file first, if not, return a nan so it doesn't crash:
          ;fname = '/Users/chfo8135/LASP/MAVEN/LPW_Software/save_files/boom_luts/shadow_lut.txt'  ;#### this must be changed to LASP server name
          file2 = fbase+folder+sl+'mvn_lpw_cal_boom_shadow_lut'
          
          fname = mvn_lpw_anc_boom_latest_file(file2)
          
          if file_test(fname) eq 1 then begin ;we find the file
            header = 15. ;number of lines in the header
            nlines = file_lines(fname)  ;number of lines in the file
            lut = dblarr(10, nlines-header)  ;array to store data
            
            
            openr, lun, fname, /get_lun
            row = 0L
            while not eof(lun) do begin
                line = " "
                readf, lun, line
  
                if row ge header then begin  ;first 15 lines are header info in the file
                      ;Split up line based on the delimiter:
                      split = strsplit(line, ' ', /regex, /extract)  ;extract elements split up by ' '

                      lut[0,row-header] = split[0]
                      lut[1,row-header] = split[1]
                      lut[2,row-header] = split[2]
                      lut[3,row-header] = split[3]
                      lut[4,row-header] = split[4]
                      lut[5,row-header] = split[5]
                      lut[6,row-header] = split[6]
                      lut[7,row-header] = split[7]
                      lut[8,row-header] = split[8]
                      lut[9,row-header] = split[9]
                endif
  
                row += 1.  ;next row 
                            
            endwhile
            close,lun
            free_lun, lun
            
            ;openr, lun, fname, /get_lun
            ;readf, lun, lut
            ;close, lun      
            
          endif else begin
            print, "#### mvn_lpw_anc_boom_get_luts: WARNING ####: shadow LUT not found. No shadow data used."
            lut = !values.f_nan
          endelse
      
      endif  ;keyword shadow
      
      
      if keyword_set(wake) then begin
        ;Check we can find the file first, if not, return a nan so it doesn't crash:
        ;fname = fbase+folder+sl+'mvn_lpw_cal_boom_wake_lut_v03_r01.txt'   ;hard coded version
        file3 = fbase+folder+sl+'mvn_lpw_cal_boom_wake_lut'
        fname = mvn_lpw_anc_boom_latest_file(file3)
       
        if file_test(fname) eq 1 then begin ;we find the file
            header = 16. ;number of lines in the header  ;this is15 for v1 files.
            nlines = file_lines(fname)  ;number of lines in the file
            lut = dblarr(12, nlines-header)  ;array to store data, only 10 wide for v1 files
                       
            openr, lun, fname, /get_lun
            row = 0L
            while not eof(lun) do begin
                line = " "
                readf, lun, line
  
                if row ge header then begin  ;first 15 lines are header info in the file
                      ;Split up line based on the delimiter:
                      split = strsplit(line, ' ', /regex, /extract)  ;extract elements split up by ' '

                      lut[0,row-header] = split[0]
                      lut[1,row-header] = split[1]
                      lut[2,row-header] = split[2]
                      lut[3,row-header] = split[3]
                      lut[4,row-header] = split[4]
                      lut[5,row-header] = split[5]
                      lut[6,row-header] = split[6]
                      lut[7,row-header] = split[7]
                      lut[8,row-header] = split[8]
                      lut[9,row-header] = split[9]
                      lut[10,row-header] = split[10]
                      lut[11,row-header] = split[11]
                endif
  
                row += 1.  ;next row 
                            
            endwhile
            close,lun
            free_lun, lun
      
          ;openr, lun, fname, /get_lun
          ;readf, lun, lut
          ;close, lun
      
        endif else begin
          print, "#### mvn_lpw_anc_boom_get_luts: WARNING ####: wake LUT not found. No wake data available."
          lut = !values.f_nan
        endelse  
        
      endif  ;keyword wake
endif  ;env var set
;stop
end


