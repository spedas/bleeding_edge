
;+
;Procedure:
;  thm_crib_cleanefp
;
;Purpose:
;  Crib sheet for testing thm_efi_clean_efp
;
;Notes:
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_cleanefp.pro $
;-


print, "--- Start of crib sheet ---"

;   re=6371.2      ;tplot default
   re=6378.16     ;Earth equatorial radius [km]  ;;1 - EH, tha, 2008-03-28 ;

   eventdate = ['c2008-01-29-tail', 'a2008-03-28-tail', 'd2008-03-24-tail', $
      'a2008-03-14-tail', 'd2008-03-15-tail', 'a2008-08-18-subsolar', $
      'e2008-09-05-subsolar', 'a2008-08-28-subsolar', 'd2008-08-03-subsolar',$
      'e2008-08-14-subsolar', 'd2008-08-16-subsolar', 'a2008-09-04-subsolar',$ 
      'e2008-08-03-subsolar', 'e2008-08-12-subsolar', 'e2008-09-02-subsolar',$
      'a2008-09-04-subsolar']
   nevent  = n_elements(eventdate)
  
   ievent = 5  ;<-------------;;Basically, only the index of the event IEVENT
   probe = strmid(eventdate[ievent],0,1) ;;needs to be changed in this crib sheet
   date = strmid(eventdate[ievent],1,10)
   if strlen(eventdate[ievent]) gt 17 then subsolar = 1 else subsolar = 0
   timespan, date
   ree_set_gsm, probe     ;set gsm coordinates as tplot labels
   
   ; GET CLEAN EFIELD
   ; (1) TAIL IS DEFAULT. /SUBSOLAR USES SOME DIFFERENT METHODS.
   ; (2) MUST SUPPLY PROBE!!
   ; (3) MUST LOAD STATE!!
   thm_efi_clean_efp, probe=probe, subsolar = subsolar
   thm_efi_clean_efp, probe=sc, minrat=0.01

   tplot, 'th' + probe + '_' + ['efp', 'efp_clean_dsl', 'efp_clean_fac']

print, "--- End of crib sheet ---"
   
end

