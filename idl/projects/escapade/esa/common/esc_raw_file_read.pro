;+
;
; Written by:
;
;    Davin Larson
;    Roberto Livi
;    Original: spp_raw_file_read.pro
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-02-27 13:24:38 -0800 (Mon, 27 Feb 2023) $
; $LastChangedRevision: 31562 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_raw_file_read.pro $
;
; PROGRAM:  
; PURPOSE:  
; INPUT:
;
; TYPICAL USAGE:
;
; KEYWORDS:
;
;-


PRO esc_raw_file_read, files, no_products=no_products, no_clear=no_clear

   ;; Time when the packet was read by IDL
   t0 = systime(1)

   info = { socket_recorder }
   info.run_proc = 1
   on_ioerror, nextfile

   FOR i=0,n_elements(files)-1 DO BEGIN

      info.input_sourcename = files[i]
      info.input_sourcehash = info.input_sourcename.hashcode()
      tplot_options,title=info.input_sourcename

      ;; Open file name and pass on LUN
      file_open,'r',info.input_sourcename,unit=lun,dlevel=3 ;;,compress=-1
      fi = file_info(info.input_sourcename)
      dprint,dlevel=1,'Reading '+file_info_string(info.input_sourcename)+' LUN:'+strtrim(lun,2)
      if lun eq 0 then CONTINUE
      esc_raw_lun_read,lun,info=info
      fst = fstat(lun)
      dprint,dlevel=2,'Compression: ',float(fst.cur_ptr)/fst.size
      free_lun,lun

      IF 0 THEN BEGIN
         nextfile:
         dprint,!error_state.msg
         dprint,'Skipping file'
      ENDIF

   ENDFOR

   dt = systime(1)-t0
   dprint,format='("Finished loading in ",f0.1," seconds")',dt

END






;; --- old code ---
;; Initialize all APID products
;;esc_apdat_init

;;esc_apdat_info,current_filename = info.input_sourcename

;; 
;;esc_apdat_info, rt_flag=0, save_flag=1, /clear

;;esc_apdat_info,current_filename=''
;;esc_apdat_info,/finish,/rt_flag,/all

;;if not keyword_set(no_clear) then del_data,'esc_*' ; store_data,/clear,'*'

;;dt = systime(1)-t0
;;dprint,format='("Finished loading in ",f0.1," seconds")',dt

   
;;sizebuf = bytarr(2)
