
;+
;Procedure:
;  thm_crib_cleanefw
;
;Purpose:
;  Crib sheet for testing thm_efi_clean_efw
;
;Notes:
; WARNING: Running THM_CRIB_EFI (or likely just calling THM_LOAD_EFI) 
;          after this crib will result in the wrong plot labels).
;          The problem is probably in the way that some of the LASP 
;          code handles, or does not handle, the labelling.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_cleanefw.pro $
;-


   eventdate = ['a2008-03-28', 'e2008-02-10', 'e2008-02-02', $
                'd2008-02-28', 'c2008-03-01']
   nevent  = n_elements(eventdate)
  
   ievent = 3  ;<-------------;; Most often only the index of the event IEVENT
                              ;; needs to be changed in this crib sheet
   probe = strmid(eventdate[ievent],0,1) 
   sc = probe
   date = strmid(eventdate[ievent],1,10)
   timespan, date
   ree_set_gsm, probe     ;set gsm coordinates as tplot labels
   
   ; CLEAN EFW
   thm_efi_clean_efw, probe=probe, spikenfit=300

   ; FIND TIME RANGE OF BURSTS
   btrange = thm_jbt_get_btrange('th'+sc+'_efw', nb=nb, tind=tind)


   ; CHECK THE RESULTS. 
   ; Tips: 1. After encountering STOP, TLIMIT to zoom in interesting areas; 
   ;       2. TLIMIT, TT can bring the the whole burst back after some zoomin's
   ;       3. Type .con to see next burst

   tpnames = 'th' + sc + '_' + ['efw', 'efw_clean_dsl', 'efw_clean_fac']
   for i = 0, nb -1 do begin
      title = '# ' + string(i+1, format='(I2)') + ' out of ' $
            + string(nb, format='(I2)') + ' bursts'
      tplot_options, 'title', title
      tt = btrange[*,i]
      tplot, tpnames, trange=btrange[*,i]
  
      ;output plots to current directory    
      makepng, title

      if i eq nb - 1 then print, 'CHECK is over.'
   endfor

end




