;+
;mvn_lpw_cdf_info_to_tplot, cdfi
;
;Original routine from SSL Berkeley was a .pro, with info below. Original routine edted by Chris Fowler from Oct 2013 onwards for use with the MAVEN 
;lpw software. Routine is run from within mvn_lpw_cdf_cdf2tplot.pro. Routine takes data, tplot limit and dlimit data from a saved cdf file (input from
;mvn_lpw_cdf_cdf2tplot.pro) and creates a single tplot variable for this data. The name of the tplot variable is also returned so that we can check
;it has loaded into tplot.
;
;INPUTS:
; - cdfi: an IDL structure containing the tplot variable data. This structure comes directly out of mvn_lpw_cdf_load_vars.pro.
; 
;OUTPUTS:
; - A single tplot variable. The variable name is that from within the CDF file, NOT the name of the CDF file.
; - The function also returns the tplot name of the variable loaded so that we can check if it loaded into tplot.
; 
;EXAMPLE:
; mvn_lpw_cdf_info_to_tplot, cdfi 
; 
;EDITS: 
; - Through till Jan 7 2014 (CF)
;
;##############
; Original routine notes:
;
; This is a new routine that needs further testing, development, and enhancements.
; PROCEDURE:  cdf2tplot, cdfi
; Purpose:  Creates TPLOT variables from a CDF structure (obtained from "CDF_LOAD_VAR")
; This routine will only work well if the underlying CDF file follows the SPDF standard.
;
; Written by Davin Larson
;
; $LastChangedBy: cfowler2 $
; $LastChangedDate: 2016-10-31 10:58:33 -0700 (Mon, 31 Oct 2016) $
; $LastChangedRevision: 22234 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_cdf_info_to_tplot.pro $
; #############
; 
; Version 2.0
; ;140718 clean up for check out L. Andersson
; ;140918 CF: major changes to encompass SIS PDS requirements. Removed for loop over variables; deal with all variables at once. 
;             now include MET and TT2000 time in the final tplot variable.
; 151130: CMF: added cdf_filename keyword, to append cdf filename to dlimit.l0_datafile structure.
;-
function mvn_lpw_cdf_info_to_tplot,cdfi,varnames,loadnames=loadnames,  $
        prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
        all=all, $
        force_epoch=force_epoch, $
        verbose=verbose,get_support_data=get_support_data,  $
        tplotnames=tplotnames, cdf_filename=cdf_filename

if not keyword_set(cdf_filename) then cdf_filename = ''

dprint,verbose=verbose,dlevel=4,'$Id: mvn_lpw_cdf_info_to_tplot.pro 22234 2016-10-31 17:58:33Z cfowler2 $'
tplotnames=''
vbs = keyword_set(verbose) ? verbose : 0

if size(cdfi,/type) ne 8 then begin
    dprint,dlevel=1,verbose=verbose,'Must provide a CDF structure'
    return,1
endif

if keyword_set(all) or n_elements(varnames) eq 0 then varnames=cdfi.vars.name

nv = cdfi.nv   ;number of variables in the CDF file.

;Global attributes is only present once in the CDF file, and covers all nv variables. The information for dlimit is contained within the 'data'
;attributes. Search through nv variables, find 'data', and use this to get dlimit information. We then do not need a for loop over nv variables.

qq = where(cdfi.vars.name eq 'data', nqq)
if nqq eq 1 then begin  ;if we have only one 'data' structure
   v=cdfi.vars[qq]  ;original index was 'i' in the for loop, replaced with qq now
     
   g_atts = cdfi.g_attributes  ;structure containing the g-atts. Only one for all nv variables.
   Product_name = struct_value(g_atts, 'Product_name', default='NA')  ;name of the product being read in

   if vbs ge 6 then dprint,verbose=verbose,dlevel=6, product_name
   if ptr_valid(v.dataptr) eq 0 then begin
       dprint,dlevel=5,verbose=verbose,'Invalid data pointer for ', product_name
       message, /info, "#### WARNING ####: Invalid data pointer for ", product_name, ". Skipping."
       tn = !values.f_nan
       return, tn
   endif
   attr = *v.attrptr

   ;Extract G-attr info:
   ;Product_name = struct_value(g_atts, 'Product_name', default = 'NA')   ;read in above, here just for completeness
   Project = struct_value(g_atts, 'Project', default = 'NA')
   Discipline = struct_value(g_atts, 'Discipline', default = 'NA')
   gDatatype = struct_value(g_atts, 'Data_type', default = 'NA')   ;data_type is an IDL function I think so no '_'
   Descriptor = struct_value(g_atts, 'Descriptor', default = 'NA')
   Data_version = struct_value(g_atts, 'Data_Version', default='NA') 
   Instrument_type = struct_value(g_atts, 'Instrument_type', default='NA') 
   Mission_group = struct_value(g_atts, 'Mission_group', default = 'NA') 
   PI_name = struct_value(g_atts, 'PI_name', default = 'NA') 
   PI_affiliation = struct_value(g_atts, 'PI_affiliation', default = 'NA')
   gTEXT = struct_value(g_atts, 'TEXT', default='NA')  ;text is and IDL function. For some reason attr.text won't come out from cdfi.g_attributes.textso do "manually"
   Source_name = struct_value(g_atts, 'Source_name', default = 'NA') 
   gby = struct_value(g_atts, 'Generated_by', default = 'NA')
   gdate = struct_value(g_atts, 'Generation_date', default='NA')
   rules_of_use = struct_value(g_atts, 'rules_of_use', default = 'NA')
   Acknowledgement = struct_value(g_atts, 'Acknowledgement', default='NA')
   
   
   ;Variable attributes: 
   tplot_name = struct_value(attr, 'tplot_name', default='NA')  ;this is the tplot name we want to give the variable
   derivn = struct_value(attr, 'derivn', default = 'NA')
   sig_digits = struct_value(attr, 'sig_digits', default = 'NA')
   SI_conversion = struct_value(attr, 'SI_conversion', default = 'NA')  
   catdesc = struct_value(attr, 'catdesc', default = 'NA')
  ; x_tt2000_catdesc = struct_value(attr, 'x_tt2000_catdesc', default='NA')
   x_catdesc = struct_value(attr, 'x_catdesc', default='NA')
  ; x_met_catdesc = struct_value(attr, 'x_met_catdesc', default='NA')
   y_catdesc = struct_value(attr, 'y_catdesc', default='NA')
   v_catdesc = struct_value(attr, 'v_catdesc', default='NA')
   dy_catdesc = struct_value(attr, 'dy_catdesc', default='NA')
   dv_catdesc = struct_value(attr, 'dv_catdesc', default='NA')
   flag_catdesc = struct_value(attr, 'flag_catdesc', default='NA')
   info_catdesc = struct_value(attr, 'info_catdesc', default='NA')
   depend_0 = struct_value(attr, 'depend_0', default = 'depend_0')
   if tag_exist(attr, 'depend_1') then depend_1 = struct_value(attr, 'depend_1', default = 'depend_1') else depend_1 = 'NA'  ;depend_1 is not always present
   display_type = struct_value(attr, 'display_type', default = 'NA')
   xfieldnam = struct_value(attr, 'xfieldnam', default = 'NA')
   yfieldnam = struct_value(attr, 'yfieldnam', default = 'NA')
   vfieldnam = struct_value(attr, 'vfieldnam', default = 'NA')
   dyfieldnam = struct_value(attr, 'dyfieldnam', default = 'NA')
   dvfieldnam = struct_value(attr, 'dvfieldnam', default = 'NA')
   flagfieldnam = struct_value(attr, 'flagfieldnam', default = 'NA') 
   infofieldnam = struct_value(attr, 'infofieldnam', default = 'NA')
   fillval = struct_value(attr, 'fillval', default = 'NA')  
   form_ptr = struct_value(attr, 'form_ptr', default = 'NA')
   lablaxis = struct_value(attr, 'lablaxis', default = 'NA')
   MONOTON = struct_value(attr, 'MONOTON', default = 'NA')   
   SMIN = struct_value(attr, 'SCALEMIN', default = !values.f_nan)   
   SMAX = struct_value(attr, 'SCALEMAX', default = !values.f_nan)
   units = struct_value(attr, 'units', default = 'NA')
   VMIN = struct_value(attr, 'VALIDMIN', default = -1.0e38)
   VMAX = struct_value(attr, 'VALIDMAX', default = 1.0e38)    
   var_type = struct_value(attr, 'var_type', default = 'NA')   
   var_notes = struct_value(attr, 'var_notes', default = 'NA')
   x_var_notes = struct_value(attr, 'x_var_notes', default = 'NA')
  ; x_tt2000_var_notes = struct_value(attr, 'x_tt2000_var_notes', default = 'NA')
  ; x_met_var_notes = struct_value(attr, 'x_met_var_notes', default = 'NA')
   y_var_notes = struct_value(attr, 'y_var_notes', default = 'NA')
   v_var_notes = struct_value(attr, 'v_var_notes', default = 'NA')
   dy_var_notes = struct_value(attr, 'dy_var_notes', default = 'NA')
   dv_var_notes = struct_value(attr, 'dv_var_notes', default = 'NA')
   flag_var_notes = struct_value(attr, 'flag_var_notes', default = 'NA')
   info_var_notes = struct_value(attr, 'info_var_notes', default = 'NA')
   t_epoch = struct_value(attr, 't_epoch', default=!values.f_nan)
   l0_datafile = struct_value(attr, 'L0_datafile', default='NA') + ' # '+cdf_filename
   cal_vers = struct_value(attr, 'cal_vers', default='NA')
   cal_y_const1 = struct_value(attr, 'cal_y_const1', default='NA')
   cal_y_const2 = struct_value(attr, 'cal_y_const2', default='NA')      
   cal_v_const1 = struct_value(attr, 'cal_v_const1', default='NA')
   cal_v_const2 = struct_value(attr, 'cal_v_const2', default='NA')
   cal_datafile = struct_value(attr, 'cal_datafile', default='NA')
   cal_source =struct_value(attr, 'cal_source', default='NA')
   info_info = struct_value(attr, 'info_info', default='NA')
   flag_info = struct_value(attr, 'flag_info', default='NA')
   flag_source = struct_value(attr, 'flag_source', default='NA')
   xsubtitle = struct_value(attr,'xsubtitle', default='NA')
   ysubtitle = struct_value(attr,'ysubtitle', default='NA')   
   zsubtitle = struct_value(attr,'zsubtitle', default='NA')
   SPICE_kernel_flag = struct_value(attr, 'SPICE_kernel_flag', default = 'NA')
   SPICE_kernel_version = struct_value(attr, 'SPICE_kernel_version', default = 'NA')  ;SPICE times extracted below with colors etc
     
   ;SPICE time fields are done below. CDF save routine can't save string ararys so must be compressed in to one string and then separated out
 
   ;Get limit info:
   char_size = struct_value(attr, 'char_size', default=2.)
   spec = struct_value(attr, 'spec', default=float(0.))    
   xtitle = struct_value(attr, 'xtitle', default='NA')  
   ytitle = struct_value(attr, 'ytitle', default='NA')
   ztitle = struct_value(attr, 'ztitle', default = 'NA')   
   yrange = struct_value(attr, 'yrange', default=[0.,1.])
   ylog = struct_value(attr, 'ylog', default=float(0.))
   zrange = struct_value(attr, 'zrange', default = [0.,1.])
   zlog = struct_value(attr, 'zlog', default=0.)
   colors = struct_value(attr,'colors', default='0')  ;colors is compressed as a string
   labels = struct_value(attr,'labels', default='NA')  ;if labflag = 0. we won't get labels anyway, but we need a string letter here for the code to work
   labflag = struct_value(attr,'labflag', default=0.)
   noerrorbars = struct_value(attr, 'noerrorbars', default = 1.)
   psym = struct_value(attr, 'psym', default=0.)
   noint = struct_value(attr, 'no_interp', default=0.)
  
   ;==================
   ;Extract the labels and color values:
   ;added tag_exist calls, jmm, 2013-11-13
   ;==================
   IF tag_exist(attr, 'labels') && attr.labels NE 'NA' THEN labels = strsplit(attr.labels, '::', count=lcount, /extract, /regex) ELSE labels='' ;extract labels as strings into the array labels, which has count elements.

   IF tag_exist(attr, 'colors') && (attr.colors NE '0' OR attr.colors EQ '0') THEN BEGIN ;Want to convert colors to a string if it's zero (black) or something else
     strcolors = strsplit(attr.colors, '::', count = ccount, /extract, /regex)  ;/regex splits strings by '::' not ':' or ':'
     colors = float(strcolors) ;convert strings to floats
   ENDIF

   IF tag_exist(attr, 'time_field') THEN time_field = strsplit(attr.time_field, '::', count = strcount, /extract, /regex)  ;unpack SPICE fields to string array

   time_start = struct_value(attr, 'time_start', default=dblarr(6) + !values.f_nan)  ;default is NaN
   time_end = struct_value(attr, 'time_end', default=dblarr(6) + !values.f_nan)
  
   ;If we have multiple labels but no colors specified for them they all come out as black. Here, we change them to rainbow colors:
   nele_lab = n_elements(labels) ;number of labels
   IF nele_lab gt 1 and n_elements(colors) EQ 1 THEN BEGIN
     colors = fltarr(nele_lab) ;colors needs to be an array of equal length to number of labels
     FOR aa = 0, nele_lab-1 DO BEGIN
       colors[aa] = 10. + aa*(floor(245. / (nele_lab-1.))) ;continuous color table is 10-255, with 255 = white
     ENDFOR
     IF colors[nele_lab-1] EQ 255 then colors[nele_lab-1] = 254 ;dont want the last label to be white
   ENDIF
   ;==================

   ;If the default subtitles are still present remove them:  #### fix for if only x,y plot, get rid of ztitle altogether.
   IF ysubtitle EQ 'NA' THEN ysubtitle = ''
   IF xsubtitle EQ 'NA' THEN xsubtitle = ''
   IF zsubtitle EQ 'NA' THEN zsubtitle = '' 
   IF display_type NE 'spectrogram' then ztitle = ''  ;Replace NA with '' if we have no z dimension in the data 
   
   ;==================

   ;Ensure NaNs in the data are NaNs:
   if finite(fillval) and keyword_set(v.dataptr) and (v.type eq 4 or v.type eq 5) then begin
       w = where(*v.dataptr eq fillval,nw)
       if nw gt 0 then (*v.dataptr)[w] = !values.f_nan
   endif


  ;Check which variables are present and save them into a data structure.
  ;We save the attributes here, and use the data pointers within the atts to get the data later.
  j = (where(strcmp(cdfi.vars.name, 'epoch', /fold_case), nj))[0]   ;epoch is the cdf TT2000 time data. Find where it is in the cdf structure
  if nj gt 0 then tt2000_time = cdfi.vars[j]  ;add tt2000 info from structure

  j = (where(strcmp(cdfi.vars.name, 'time_unix', /fold_case), nj))[0]   
  if nj gt 0 then time_unix = cdfi.vars[j]  ;add tt2000 info from structure   ;save unix time as data.x so tplot recognizes it.

  j = (where(strcmp(cdfi.vars.name, 'time_met', /fold_case), nj))[0]   
  if nj gt 0 then time_met = cdfi.vars[j]  ;add tt2000 info from structure  

  j = (where(strcmp(cdfi.vars.name, 'data', /fold_case), nj))[0]  
  if nj gt 0 then ydata = cdfi.vars[j]  ;save the data as data.y, but need to keep 'data' a free variable for later

  j = (where(strcmp(cdfi.vars.name, 'freq', /fold_case), nj))[0]
  if nj gt 0 then freq = cdfi.vars[j]  ;save the freq information as data.v

  j = (where(strcmp(cdfi.vars.name, 'volt', /fold_case), nj))[0]      ;For IV sweeps, data.v is the voltage, called 'volt' in the CDF files
  if nj gt 0 then freq = cdfi.vars[j]  ;save the freq information as data.v
  
  j = (where(strcmp(cdfi.vars.name, 'ddata', /fold_case), nj))[0]
  if nj gt 0 then ddata = cdfi.vars[j]  ;error on data, data.dy

  j = (where(strcmp(cdfi.vars.name, 'ddata_up', /fold_case), nj))[0]   ;'ddata_up' is the error going into data.dy, which is stored as ddata_up in the CDF files
  if nj gt 0 then ddata = cdfi.vars[j]  ;error on data, data.dy  
  
  j = (where(strcmp(cdfi.vars.name, 'dfreq', /fold_case), nj))[0]
  if nj gt 0 then dfreq = cdfi.vars[j]  ;error on freq, data.dv
  
  j = (where(strcmp(cdfi.vars.name, 'ddata_lo', /fold_case), nj))[0]    ;'dfreq'
  if nj gt 0 then dfreq = cdfi.vars[j]  ;error on freq, data.dv  which is stored as ddata_lo in the CDF files.

  j = (where(strcmp(cdfi.vars.name, 'dvolt', /fold_case), nj))[0]    ;'dfreq'  in the CDF files, for IV Sweeps, dvolt the name for data.dv
  if nj gt 0 then dfreq = cdfi.vars[j]  ;error on freq, data.dv  
    
  j = (where(strcmp(cdfi.vars.name, 'flag', /fold_case), nj))[0]
  if nj gt 0 then flag = cdfi.vars[j]  ;flag information, data.flag

  j = (where(strcmp(cdfi.vars.name, 'info', /fold_case), nj))[0]
  if nj gt 0 then info = cdfi.vars[j]  ;info information, data.info


  ;Now create the final data structure using ptrs:
  if ptr_valid(time_unix.dataptr) and ptr_valid(ydata.dataptr) then begin  ;if we have at least UNIX and ydata valid:
        data = {x:time_unix.dataptr, y:ydata.dataptr}
        
        ;Now add fields that are also present. Use str_element to add to the structure
        if size(time_tt2000, /type) NE 0 then if ptr_valid(time_tt2000.dataptr) then str_element, data, 'time_tt2000', time_tt2000.dataptr, /add
        if size(time_met, /type) NE 0 then if ptr_valid(time_met.dataptr) then str_element, data, 'time_met', time_met.dataptr, /add
        if size(freq, /type) NE 0 then if ptr_valid(freq.dataptr) then str_element, data, 'v', freq.dataptr, /add  ;use tplot names now
        if size(ddata, /type) NE 0 then if ptr_valid(ddata.dataptr) then str_element, data, 'dy', ddata.dataptr, /add
        if size(dfreq, /type) NE 0 then if ptr_valid(dfreq.dataptr) then str_element, data, 'dv', dfreq.dataptr, /add
        if size(flag, /type) NE 0 then if ptr_valid(flag.dataptr) then str_element, data, 'flag', flag.dataptr, /add
        if size(info, /type) NE 0 then if ptr_valid(info.dataptr) then str_element, data, 'info', info.dataptr, /add
        
     ;==================================
     ;Append values to dlimit and limit:
     ;==================================
     
     ;dlimit is missing x_tt_2000_catdesc:x_tt2000_catdesc, x_met_catdesc:x_met_catdesc, x_tt2000_var_notes:x_tt2000_var_notes, x_met_var_notes:x_met_var_notes, 
     dlimit = {Product_name: Product_name, Project:Project, Discipline:Discipline, Data_type:gDatatype, Descriptor:Descriptor, Data_version:Data_version, $
               Instrument_type:Instrument_type, Mission_group:Mission_group, PI_name:PI_name, $
               PI_affiliation:PI_affiliation, TEXT:gtext, Source_name:Source_name, Generated_by: gby, Generation_date:gdate, rules_of_use:rules_of_use, $
               Acknowledgement: Acknowledgement, $  ;end of Global atts
               derivn:derivn, sig_digits:sig_digits, SI_conversion:SI_conversion, $
               catdesc:catdesc, x_catdesc:x_catdesc, y_catdesc:y_catdesc, $
               v_catdesc:v_catdesc, dy_catdesc:dy_catdesc, dv_catdesc:dv_catdesc, flag_catdesc:flag_catdesc, info_catdesc:info_catdesc, display_type:display_type, $
               var_notes:var_notes, x_var_notes:x_var_notes, y_var_notes:y_var_notes, v_var_notes:v_var_notes, $
               dy_var_notes:dy_var_notes, dv_var_notes:dv_var_notes, flag_var_notes:flag_var_notes, info_var_notes:info_var_notes, $              
               xfieldname:xfieldnam, yfieldnam:yfieldnam, vfieldnam:vfieldnam, dyfieldnam:dyfieldnam, dvfieldnam:dvfieldnam, flagfieldnam:flagfieldnam, infofieldnam:infofieldnam, $
               info_info: info_info, fillval:fillval, form_ptr:form_ptr, lablaxis:lablaxis, monoton:monoton, scalemin:smin, scalemax:smax, units:units, $
               validmin:vmin, validmax:vmax, var_type:var_type,  $
               t_epoch:t_epoch, l0_datafile:l0_datafile, cal_vers:cal_vers, cal_y_const1:cal_y_const1, $
               cal_y_const2:cal_y_const2, cal_v_const1:cal_v_const1, cal_v_const2:cal_v_const2, cal_datafile:cal_datafile, cal_source:cal_source, $
               flag_info:flag_info, flag_source:flag_source, xsubtitle:xsubtitle, ysubtitle:ysubtitle, zsubtitle:zsubtitle, $
               spice_kernel_flag:spice_kernel_flag, spice_kernel_version:spice_kernel_version, time_field:time_field, time_start:time_start, time_end:time_end}
             
               
     limit = {char_size:char_size, xtitle:xtitle, ytitle:ytitle, ztitle:ztitle, yrange:yrange, ylog:ylog, zrange:zrange, zlog:zlog, $
             spec:spec, colors:colors, labels:labels, labflag:labflag, noerrorbars:noerrorbars, psym:psym, no_interp:noint}

     ;================================== 
     
     tn = tplot_name  ;final tplot product name

     if keyword_set(midfix) then begin
        if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
        else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
     endif
     if keyword_set(prefix) then tn = prefix+tn
     if keyword_set(suffix) then tn = tn+suffix
     
     ;Store data as tplot variable:
     store_data,tn,data=data,dlimit=dlimit, limit=limit, verbose=verbose   
    
     ;Set the y and z ranges:
     IF yrange[0] NE 0. OR yrange[1] NE 0. THEN ylim, tn, yrange  ;default is [0., 0.]
     ;For some reason this isn't needed for zrange, and actually messes it up when it's included:
     ;IF zrange[0] NE 0. OR zrange[1] NE 0. THEN zlim, tn, zrange  ;default is [0., 0.].    
    
     tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
               
  endif else begin  ;over valid pointers
        print, "#### WARNING #### : No UNIX time and / or data present in CDF file for ", product_name, ". Skipping."
        tn = !values.f_nan
        return, tn
  endelse  ;over pointers not valid

endif else begin ;'data' structure present in CDF file
      print, "#### WARNING #### : No data structure found within CDF file structure ", cdfi, ". Skipping loading."
      tn = !values.f_nan
endelse 


return, tn  ;return the tplot name of the variable saved so we can check if it loaded.

end

