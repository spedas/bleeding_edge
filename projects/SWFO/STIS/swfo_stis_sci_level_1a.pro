; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $


function swfo_stis_sci_level_1a,strcts  ;,format=format,reset=reset,cal=cal

  output = !null
  nd = n_elements(strcts)  
  
  nan48=replicate(!values.f_nan,48)
  
;  output = {time:0d, $
;    hash:   0UL, $
;    SPEC_O1:  nan48, $
;    SPEC_O2:  nan48, $
;    SPEC_O3:  nan48, $
;    SPEC_F1:  nan48, $
;    SPEC_F2:  nan48, $
;    SPEC_F3:  nan48, $
;    spec_o1_nrg:  nan48, $
;    spec_o2_nrg:  nan48, $
;    spec_o3_nrg:  nan48, $
;    spec_f1_nrg:  nan48, $
;    spec_f2_nrg:  nan48, $
;    spec_f3_nrg:  nan48, $
;    gap:0}
  
  for i=0l,nd-1 do begin
    str = strcts[i]

    mapd = swfo_stis_adc_map(data_sample=str)
  ;  cal = swfo_stis_cal_params(str,reset=reset)
    counts = str.counts
    nrg  = mapd.nrg
    dnrg = mapd.dnrg
    dadc = mapd.dadc
    out = {time:str.time}
    str_element,/add,out,'hash',mapd.codes.hashcode()
    str_element,/add,out,'duration',str.duration 
    foreach w,mapd.wh,key do begin
      str_element,/add,out,'cnts_'+key,counts[w]
      str_element,/add,out,'rate_'+key,counts[w]/ str.duration
      str_element,/add,out,'spec_'+key,counts[w] / dnrg[w] / mapd.geom[w] / str.duration
      str_element,/add,out,'spec_'+key+'_nrg',nrg[w]
      str_element,/add,out,'spec_'+key+'_dnrg',dnrg[w]
      str_element,/add,out,'spec_'+key+'_adc',mapd.adc[w]    
      str_element,/add,out,'spec_'+key+'_dadc',mapd.dadc[w]
    endforeach
    str_element,/add,out,'gap',0
    
    if nd eq 1 then   return, out
    if i  eq 0 then   output = replicate(out,nd) else output[i] = out

  endfor

  return,output

end

