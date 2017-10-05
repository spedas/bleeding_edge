





;

;+
;FUNCTION: MVN_SPC_ANC_REACTIONWHEELS
;Purpose:
;  returns and array of structures that contain data from reactionwheel files.
;  
;  the structure elements output.rw#_spd_hz contain the speed of the reaction wheels in Hz, where # = 1,2,3,4.
;USAGE:
;  data = mvn_spc_anc_reactionwheels()
;  printdat,data         ; display contents
;  store_data,'GNC',data=data   ; store for tplot
;
; KEYWORDS:
;   TRANGE=TRANGE  ; Optional 2 element time range vector
; $LastChangedBy: Chris Fowler (christopher.fowler@lasp.colorado.edu) $
; $LastChangedDate: 2014-12-05  $
; $LastChangedRevision:  $
; $URL:  $
;-
function  mvn_spc_anc_reactionwheels,pformat,trange=trange  ,files=files,dlimit=dlimit         ;,var_name,thruster_time= time_x

; Get filenames
trange=timerange(trange)
if ~keyword_set(pformat) then begin
   pformat = 'maven/data/anc/eng/gnc/sci_anc_gncyy_DOY_???.drf'
   daily_names=1
   last_version=1
endif
tr = timerange(trange) + 86400L * [-3,1]
src = mvn_file_source(source,last_version=last_version,no_update=0,/valid_only)
files = mvn_pfp_file_retrieve(pformat,files=files,trange=tr,daily_names=daily_names,source=src)
nfiles = n_elements(files) * keyword_set(files)
dprint,dlevel=2,nfiles,' files found'
if nfiles eq 0 then return,0
  
  
;Added 2014-12-04, CF: format of reaction wheel file changed; original files had evenly spaced columns making it easy to extract data. Later files
;have one column that is not evenly spaced and crashes this routine. There are also additional columns.
; Create output structure template
;Earlier files have this structure:
names_old=strsplit(/extract,'ATT_QU_I2B_1 ATT_QU_I2B_2 ATT_QU_I2B_3 ATT_QU_I2B_4 ATT_QU_I2B_T ATT_RAT_BF_X ATT_RAT_BF_Y ATT_RAT_BF_Z APIG_ANGLE   APOG_ANGLE   APIG_APP_RAT APOG_APP_RAT RW1_SPD_DGTL RW2_SPD_DGTL RW3_SPD_DGTL RW4_SPD_DGTL')

;Later files have more fields (as well as those above). Create structure containing all fields; in earlier files the extra fields will be empty.
;I have also added four new fields; one for each RW, containing the speed (that will be) converted to Hz
names=strsplit(/extract, 'ATT_QU_I2B_1 ATT_QU_I2B_2 ATT_QU_I2B_3 ATT_QU_I2B_4 ATT_QU_I2B_T ATT_RAT_BF_X ATT_RAT_BF_Y ATT_RAT_BF_Z APIG_ANGLE   APOG_ANGLE   APIG_APP_RAT APOG_APP_RAT RW1_SPD_DGTL RW2_SPD_DGTL RW3_SPD_DGTL RW4_SPD_DGTL ACC_BOD_VECX ACC_BOD_VECY ACC_BOD_VECZ RW1_SPD_PTE  RW2_SPD_PTE  RW3_SPD_PTE  RW4_SPD_PTE  RW1_SPD_HZ  RW2_SPD_HZ  RW3_SPD_HZ  RW4_SPD_HZ')

ftype = bytarr(nfiles)  ;0 means file is "old version", 1 means file is "new" version

;Read in header info to get column info:
for i=0,nfiles-1 do begin
    file = files[i]
    openr, lun, file, /get_lun
    row = 0L
    while row le 3 do begin  ;the first 4 rows in old or new files are header info.
      line = " "
      readf, lun, line
      
      if row eq 3 then begin
          fnames = strsplit(/extract, line)
          nfnames = n_elements(fnames)
          if nfnames eq 16 then ftype[i] = 0b
          if nfnames eq 23 then ftype[i] = 1b
          if nfnames ne 16 and nfnames ne 23 then begin
               print, "#### WARNING #### : Reaction wheel files have changed format again! See Davin Larson or Chris Fowler."
               stop
          endif
      endif
      row += 1.  ;next row
    endwhile
    close,lun
    free_lun, lun
endfor



nc = n_elements(names)
output_str = {time:0d}
for i=0,nc-1 do output_str=create_struct(output_str,names[i],0.)

nrec=0                   ; Number of records
    
for i=0,nfiles-1 do begin
   file = files[i]
    
   ;Read in "early" file:
   ;Read in as below, but must add each value to it's specific structure value here, as we are missing some.
   if ftype[i] eq 0 then begin 
       nc = n_elements(names_old)  ;old header array is shorter 
       fpos = indgen(nc)*13+19  ; starting location of columns for old files

       dprint,dlevel=2,'Reading :',file
       file_open,'r',file,unit=fp,dlevel=3
       l=0L
       def = ''
       def = !values.f_nan
       blank = string(replicate(byte(' '),13))
       while ~eof(fp) do begin
         s=''
         readf,fp,s
         timestr = strmid(s,0,fpos[0])
         if strmid(timestr,0,1) eq ' ' then continue
         time = time_double(timestr,tformat='yy/DOY-hh:mm:ss.fff')
         output_str.time =time
         for j=0,nc-1 do begin
           ss = strmid(s,fpos[j],13)
           ;        v = is_numeric(ss) ?  float(ss) : !values.f_nan
           v = (ss ne blank) ?  float(ss) : !values.f_nan          ; twice as fast as line above
           output_str.(j+1) = v  ;The new header entries are added on to the end of the array, make the additional extra fields nans below
           
         endfor
         append_array,output,output_str,index=nrec
       endwhile
       free_lun,fp    
    
       ;Make the extra fields not present in the old file NaNs:
       output[*].acc_bod_vecx = !values.f_nan
       output[*].acc_bod_vecy = !values.f_nan
       output[*].acc_bod_vecz = !values.f_nan
       output[*].rw1_spd_pte = !values.f_nan
       output[*].rw2_spd_pte = !values.f_nan
       output[*].rw3_spd_pte = !values.f_nan
       output[*].rw4_spd_pte = !values.f_nan
   endif
   
   
   ;Read in "new" file"
   ;Should be able to read all structure fields as is below, as none missing, but need a new fpos array
   if ftype[i] eq 1 then begin
       ;fpos = indgen(nc)*13+19  ; starting location of columns, OLD files
       ;For new files:
       fpos = [19, 32, 45, 58, 71, 88, 101, 114, 127, 140, 153, 166, 179, 192, 205, 218, 231, 244, 257, 270, 283, 296, 309, 322]  ;indices where to start extracting strings.
       
       dprint,dlevel=2,'Reading :',file
       file_open,'r',file,unit=fp,dlevel=3
       l=0L
       def = ''
       def = !values.f_nan
       blank = string(replicate(byte(' '),13))   
       while ~eof(fp) do begin
          s=''
          readf,fp,s
          timestr = strmid(s,0,fpos[0])
          if strmid(timestr,0,1) eq ' ' then continue
          time = time_double(timestr,tformat='yy/DOY-hh:mm:ss.fff')  ; Warning these times appear to be off by ~20 seconds - probably not corrected for clock drift.
          output_str.time =time
          for j=0,nc-5 do begin  ;ignore last four fields in the structure - add to these after
            if j eq 4 then sss = 17 else sss = 13  ;one column is longer than the others
            ss = strmid(s,fpos[j],sss)
    ;        v = is_numeric(ss) ?  float(ss) : !values.f_nan
            v = (ss ne blank) ?  float(ss) : !values.f_nan          ; twice as fast as line above
            output_str.(j+1) = v
            
          endfor
          append_array,output,output_str,index=nrec
       endwhile
       free_lun,fp
   endif
   
endfor

;Convert reaction wheel dgtl numbers to Hz:
factor = (1/(2.D*!pi))   ;conversion factor for dgtl # to Hz (taken from ancillary information PDF from SDC(?) website
output[*].rw1_spd_hz = output[*].rw1_spd_dgtl * factor
output[*].rw2_spd_hz = output[*].rw2_spd_dgtl * factor
output[*].rw3_spd_hz = output[*].rw3_spd_dgtl * factor
output[*].rw4_spd_hz = output[*].rw4_spd_dgtl * factor

dlimit={ $
  rw1_spd_hz: {colors:'m'}, $
  rw2_spd_hz: {colors:'b'}, $
  rw3_spd_hz: {colors:'g'}, $
  rw4_spd_hz: {colors:'r'}, $
  dummy: 0  }


append_array,output,index=nrec
dprint,dlevel=3,'Done'
return,output
end

