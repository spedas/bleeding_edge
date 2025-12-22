;+
; PROCEDURE:
;
;   write_au_ulaw.pro
;
; PURPOSE;
;
;   Accepts an array of sound data to place into a Sun Audio file.
;
; ARGUMENTS:
;
;   FILE     The name of the file to create.
;   DATA     The data array.
;
; KEYWORDS:
;
;   NOSCALE  Do not scale the data array to fit exactly in the range
;            [0,255].  Normally, if the maximum value in the array is
;            not 255, the array is scaled to take full advantage of
;            the range available.  This keyword disables this scaling.
;   RATE     The sampling rate.  Default is 8000 Hz.
;   TEXT     A textual description to embed in the audio file.
;
; CREATED:
;
;   By Joseph Rauchleiba
;   1998/4/22
;-

function long2bytes, input

linput = long(input)
output = byte([ishft(ishft(linput,0),-24), $
               ishft(ishft(linput,8),-24), $
               ishft(ishft(linput,16),-24), $
               ishft(ishft(linput,24),-24)])
return, output
end

;----------------------------------------------------------------------------

pro write_au_ulaw, file, data, $
         NOSCALE=noscale, $
         RATE=rate, $
         TEXT=text

if keyword_set(noscale) then begin
    sound=byte(data(where(finite(data) EQ 1)))
endif else sound=bytscl(data(where(finite(data) EQ 1)))
if NOT keyword_set(rate) then rate=8000
if NOT keyword_set(text) then text=byte('No description') else text=byte(text)
textlen = n_elements(text)
magic = byte([46,115,110,100])  ; ".snd"
ulaw_8bit = 1
channels = 1
data_offset = 6*4 + textlen
data_size = n_elements(sound)

openw, unit, /get_lun, file
writeu, unit, $
  magic, $
  long2bytes(data_offset), $
  long2bytes(data_size), $
  long2bytes(ulaw_8bit), $
  long2bytes(rate), $
  long2bytes(channels), $
  text, $
  sound
close, unit

end
