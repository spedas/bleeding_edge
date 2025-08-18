; +
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-01-31 16:36:52 -0800 (Tue, 31 Jan 2023) $
; $LastChangedRevision: 31448 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_apdat_info.pro $
; $ID: $
; This is the master routine that changes or accesses the ccsds data structures for each type of packet that is received
; -

FUNCTION esc_apdat_info_restore,sav_file,verbose=verbose,parents=parents
   restore,sav_file,verbose=verbose,/relax,/skip
   return, all_apdat
END

pro esc_apdat_info,apid_description,$
                   name = name,$
                   verbose = verbose,$
                   clear = clear,$
                   quick = quick, $
                   zero = zero, $
                   reset = reset,$
                   apdats = apdats, $
                   output_lun = output_lun, $

                   ;; Obsolete - use string as input
                   ;;matchname = matchname,  $  
                   save_flag = save_flag,$
                   sort_flag = sort_flag,$
                   current_filename = current_filename, $
                   cdf_pathname = cdf_pathname, $
                   cdf_linkname = cdf_linkname, $
                   make_cdf = make_cdf, $
                   nonzero = nonzero,  $
                   dlevel = dlevel, $
                   all = all, $
                   info = info,  $
                   finish = finish,$
                   window_obj = window_obj, $
                   tname = tname,$
                   set_break=set_break, $
                   ttags=ttags,$
                   routine=routine,$
                   file_save=file_save,file_restore=file_restore,compress=compress,parents=parents, $
                   apid_obj_name = apid_obj_name, $
                   print=print, $
                   rt_flag=rt_flag,trim=trim

   common esc_apdat_info_com, all_apdat, alt_apdat, all_info,temp1,temp2

   ;; Return all APIDs using apdats 
   IF keyword_set(quick) && isa(apid_description,/integer,/scalar) && isa(all_apdat[apid_description]) THEN BEGIN
      apdats = all_apdat[apid_description]
      return
   ENDIF

   ;; --- Reset
   
   ;; Not recommended!
   IF keyword_set(reset) THEN BEGIN

      ;; This might not be required in IDL8.x and above
      ;; obj_destroy,all_apdat,alt_apdat,all_info    
      all_apdat=!null
      alt_apdat= !null
      all_info = !null
   ENDIF

   
   ;; --- Initialize for first APID

   ;; all_apdat - object array
   IF ~keyword_set(all_apdat) THEN all_apdat = replicate( obj_new() , 2^11 )

   ;; alt_apdat - ordered hash
   IF ~keyword_set(alt_apdat) THEN alt_apdat = orderedhash()

   ;; all_info - ordered_hash - File information
   IF ~keyword_set(all_info) THEN BEGIN
      all_info = orderedhash()
      all_info['current_filename'] = 'Unknown'
      all_info['current_filehash'] = 0UL
      all_info['file_hash_list']   = orderedhash()
      all_info['break']            = 0
   ENDIF

   IF keyword_set(current_filename) THEN BEGIN
      basename = file_basename(current_filename,'.sav')
      current_filehash = basename.hashcode()
      all_info['current_filename'] = current_filename
      all_info['current_filehash'] = current_filehash
      hash_list = all_info['file_hash_list']
      hash_list[current_filehash] = current_filename
      return
   ENDIF

   IF keyword_set(set_break) THEN BEGIN
      all_info['break'] = 1
   ENDIF

   ;; Restore apdat_info from a stored IDL .sav file
   IF keyword_set(file_restore) THEN BEGIN
      basename = file_basename(file_restore,'.sav')
      hashcode = basename.hashcode()
      filetime = esc_spc_met_to_unixtime(ulong(strmid(basename,0,10)))
      if all_info['file_hash_list'].haskey(hashcode) then begin
         dprint,dlevel=1,'Skipping already loaded file '+$
                file_info_string(file_restore)+$
                time_string(filetime,tformat=' MET:YYYY-MM-DD/hh:mm:ss (DOY)'),verbose=verbose
         return
      endif
      dprint,dlevel=3,'Restoring '+file_info_string(file_restore)
      aps = esc_apdat_info_restore(file_restore,verbose=verbose,parents=parents)
      apids = where(aps,/null)
      for i=0 , n_elements(apids)-1 do begin
         apid = apids[i]
         if obj_valid(all_apdat[apid]) then all_apdat[apid].append, aps[apid] $
         else all_apdat[apid] = aps[apid]
      endfor
      dprint,dlevel=2,'Restored  '+file_info_string(file_restore) + $
             time_string(filetime,tformat=' MET:YYYY-MM-DD/hh:mm:ss (DOY)')
      esc_apdat_info,current_filename=file_restore
   ENDIF

   IF keyword_set(file_save) THEN BEGIN
      file_mkdir2,file_dirname(file_save)
      dprint,dlevel=2,'Saving '+file_save
      save,file=file_save,all_apdat,parents,verbose=verbose,compress=compress
      dprint,dlevel=1,'Saved '+file_info_string(file_save)
   ENDIF

   valid_apdat = all_apdat[ where( obj_valid(all_apdat),nvalid ) ]

   ;; Check whether APID given is a string
   IF isa(apid_description,/string) THEN BEGIN
      IF nvalid NE 0 THEN BEGIN
         names = strarr(nvalid)
         apids = intarr(nvalid)
         FOR i = 0,nvalid -1 DO BEGIN
            names[i] = valid_apdat[i].name
            apids[i] = valid_apdat[i].apid
         ENDFOR
      ENDIF
      ind = strfilter(names,apid_description,/index,/null)
      apids = apids[ind]
      ;; printdat,names[ind],apids
   ;; Check whether APID given is a string
   ENDIF ELSE IF isa(apid_description,/integer) then begin
      apids = apid_description
   ENDIF ELSE  apids = where(all_apdat,/null)

   ;;printdat,apids
   default_apid_obj_name =  'esc_gen_apdat'

   FOR i=0,n_elements(apids)-1 DO BEGIN

      apid = apids[i]

      ;; Initialize new apid
      if alt_apdat.haskey(apid) eq 0 then alt_apdat[apid] = obj_new() 
      apdat_obj = all_apdat[apid]
      IF ~obj_valid(apdat_obj) || ( isa(/string,apid_obj_name) && (typename(apdat_obj) NE strupcase(apid_obj_name) ) )  THEN BEGIN
         ;; Potential memory leak here - old version should be destroyed
         dprint, verbose=verbose, dlevel=3,'Initializing APID: ',apid        
         obj_name = (isa(/string,apid_obj_name) && keyword_set(apid_obj_name)) ? apid_obj_name : default_apid_obj_name
         apdat_new = obj_new(obj_name , apid,name)
         all_apdat[apid] = apdat_new
         alt_apdat[apid] = apdat_new
      ENDIF
      apdat = all_apdat[apid]
      if n_elements(name)       ne 0 then apdat.name = name
      if n_elements(routine)    ne 0 then apdat.routine=routine
      if n_elements(rt_flag)    ne 0 then apdat.rt_flag = rt_flag
      if n_elements(sort_flag)  ne 0 then apdat.sort_flag = sort_flag
      if n_elements(dlevel)     ne 0 then apdat.dlevel = dlevel
      if n_elements(tname)      ne 0 then apdat.tname = tname
      if n_elements(ttags)      ne 0 then apdat.ttags = ttags
      if n_elements(window_obj) ne 0 then  apdat.window_obj = window(window_title=apdat.name)
      if n_elements(save_flag)  ne 0 then apdat.save_flag = save_flag
      if n_elements(cdf_pathname) ne 0 then apdat.cdf_pathname= cdf_pathname
      if n_elements(cdf_linkname) ne 0 then apdat.cdf_linkname= cdf_linkname
      if n_elements(output_lun) ne 0 then apdat.output_lun = output_lun
      if ~keyword_set(all)  &&  (apdat.npkts eq 0) then continue
      if keyword_set(sort_flag) then apdat.sort
      if keyword_set(finish)    then apdat.finish
      if keyword_set(make_cdf)  then apdat.cdf_create_file
      if keyword_set(clear)  then    apdat.clear
      if keyword_set(zero)   then    apdat.zero
      if keyword_set(trim)   then    apdat.trim
      if keyword_set(print)  then    apdat.print, header = i eq 0
   endfor
   apdats=all_apdat[apids]
   if n_elements(apdats) eq 1 then apdats = apdats[0]
   if arg_present(info)  then  info = all_info

end







;;############### BACKUP #############
;;IF keyword_set(quick) THEN BEGIN
;;   dprint,'Unexpected APID:',apid_description,dlevel=3
;;ENDIF

