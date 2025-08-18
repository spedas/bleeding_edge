;+
; FUNCTION:
;       kgy_spk_gaps
; PURPOSE:
;       Returns times of gaps in the spk kernel due to altitude manoeuvres
; CALLING SEQUENCE:
;       in_gaps = kgy_spk_gaps( times )
; INPUT:
;       time array
; OUTPUT:
;       in gaps (1) or out of gaps (0)
; CREATED BY:
;       Yuki Harada on 2018-05-15
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 00:52:42 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/spice/kgy_spk_gaps.pro $
;-

function kgy_spk_gaps, times

spk_gaps = time_double( [ $
           [ '2007-12-11/02:30', '2007-12-11/16:50' ] , $
           [ '2008-02-04/20:30', '2008-02-05/04:15' ] , $
           [ '2008-03-29/16:30', '2008-03-30/00:15' ] , $
           [ '2008-05-24/15:00', '2008-05-24/20:43' ] , $
           [ '2008-07-16/07:30', '2008-07-16/15:30' ] , $
           [ '2008-09-10/05:30', '2008-09-10/13:30' ] , $
           [ '2008-11-03/00:30', '2008-11-03/09:00' ] , $
           [ '2008-12-26/21:00', '2008-12-27/05:30' ] , $
           [ '2009-02-20/20:00', '2009-02-20/23:45' ] , $
           [ '2009-03-19/18:00', '2009-03-19/22:00' ] , $
           [ '2009-04-16/19:00', '2009-04-16/21:30' ] $
                        ] )


if n_elements(times) eq 0 then return, spk_gaps

ngaps = n_elements(spk_gaps[0,*])

in_gaps = replicate(0b,n_elements(times))
for i=0,ngaps-1 do begin
   w = where( times ge spk_gaps[0,i] and times le spk_gaps[1,i] , nw )
   if nw gt 0 then in_gaps[w] = 1
endfor

;; Start: 2007.10.20 02:30:00.00 UT
;; End:   2009.06.10 19:30:00.00 UT

w = where( times lt time_double('2007-10-20/02:30') or times gt time_double('2009-06-10/19:30') , nw )
if nw gt 0 then in_gaps[w] = 1

return, in_gaps

end
