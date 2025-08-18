;+
;FUNCTION: MVN_SPC_ANC_PF
;Purpose:
;  returns and array of structures that contain data from MAVEN drf files
;USAGE:
;  data = mvn_spc_anc_pf()
;  printdat,data         ; display contents
;  store_data,'GNC',data=data   ; store for tplot
;
; KEYWORDS:
;   TRANGE=TRANGE  ; Optional 2 element time range vector
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;-
function  mvn_spc_anc_pf,pformat,trange=trange  ;,filenames=filenames         ;,var_name,thruster_time= time_x

; Get filenames
trange=timerange(trange)
if ~keyword_set(pformat) then begin
   pformat = 'maven/data/anc/eng/pf/sci_anc_pfyy_DOY_???.drf'
   daily_names=1
   last_version=1
endif
filenames = mvn_pfp_file_retrieve(pformat,trange=trange,daily_names=daily_names,last_version=last_version,/valid_only)
nfiles = n_elements(filenames) * keyword_set(filenames)
dprint,dlevel=2,nfiles,' files found'
  
; Create output structure template
namestring= 'SP_PF_PFull  PfpBpT1      PfpBpT1      StatInT1     StatInT1     Pfp1InT      Pfp1InT      SweaInT1     SweaInT1     Sep1InT1     Sep1InT1     EuvInT1      EuvInT1      Lpw2BomT1    Lpw2BomT1    Lpw1BomT1    Lpw1BomT1    Sep2InT1     Sep2InT1     PfpBpT2      PfpBpT2      SwiaInT2     SwiaInT2     SweaInT2     SweaInT2     StatInT2     StatInT2     Sep1InT2     Sep1InT2     EuvInT2      EuvInT2      Pfp2InT      Pfp2InT      Lpw1BomT2    Lpw1BomT2    Sep2InT2     Sep2InT2     Lpw2BomT2    Lpw2BomT2    Mag1InT      Mag2InT      Bus28V_1_V   Bus28V_1_V   Bus28V_2_V   Bus28V_2_V   Mag1HtrMonV  Mag1HtrMonV  Mag2HtrMonV  Mag2HtrMonV'
suffix=     'DN           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           EU           DN           DN           DN           EU           DN           EU           DN           EU           DN           EU           
names=strsplit(/extract,namestring) + '_' + strsplit(/extract,suffix)
nc = n_elements(names)
output_str = {time:0d}
for i=0,nc-1 do output_str=create_struct(output_str,names[i],0.)

fpos = indgen(nc)*13+19  ; starting location of columns
nrec=0                   ; Number of records
  
for i=0,nfiles-1 do begin
   file = filenames[i]
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
        output_str.(j+1) = v
      endfor
      append_array,output,output_str,index=nrec
   endwhile
   free_lun,fp
endfor
append_array,output,index=nrec
dprint,dlevel=3,'Done'
return,output
end

