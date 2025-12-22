function detect_2d_fields,dqd
;
; 2d or not 2d...
;
; function to return 1 if the dqd is a 2d fields quantity, 0
; otherwise. DQD2D is an array of strings which are found in probable
; 2d dqd's, and REJECT is an array of strings contained in exceptions!
;
;
if not defined(dqd) then begin
    message,'DQD is undefined...',/continue
    return,0
endif

dqd2d = ['sfa','dsp','wpc']
reject = ['smphase','hdr','frq','trk']
nrej = n_elements(reject)

ldqd = strlowcase(dqd(0))       ; ldqd must be a *scalar* string, not
                                ; a one-element string array...idl quirk...
two_d = 0
if ((where(strmid(ldqd,0,3) eq dqd2d))(0) ge 0) then begin
    two_d = 1
    i = 0
    repeat begin
        two_d = two_d and (((where(strpos(ldqd,reject(i)) ge 0))(0) lt 0))
        i = i + 1
    endrep until ((i eq nrej) or (not two_d))
endif

return,two_d
end


