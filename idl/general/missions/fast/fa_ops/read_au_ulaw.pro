;+
; PROCEDURE:
;
;   read_au_ulaw
;
; PURPOSE:
;
;   Extracts specifications and sound data from a Sun audio ".au"
;   file.
;
; ARGUMENTS:
;
;   FILE      The file to open.
;   DATA      Variable in which to return the sound data.  This will be
;             a byte array containing value from 0 to 255.
;
; KEYWORDS:
;
;   PLAY      Play the sound data on the local audio device once it is
;             read.  Sample will loop PLAY times.
;
;   The following keywords are optional.  They return various file
;   specs.
;
;   OFFSET    The offset in bytes of the data from the beginning of
;             the file. 
;   SIZE      The size in bytes of the sound data array
;   RATE      The sampling rate.
;   CHANNELS  Number of interleaved channels. (1=mono, 2=stereo)
;   TEXT      Arbitrary textual description embedded in the file.
;
; CREATED:
;
;   By Joseph Rauchleiba
;   1998/4/22
;-

function bytes2long, byte_array

long_array = long(byte_array)
long_scalar = ( ishft(long_array(0),24) + $
                ishft(long_array(1),16) + $
                ishft(long_array(2),8) + $
                ishft(long_array(3),0) )
return, long_scalar
end

;-------------------------------------------------------------------------

pro read_au_ulaw, file, data, $
        PLAY=play, $
        OFFSET=offset, $
        SIZE=size, $
        RATE=rate, $
        CHANNELS=channels, $
        TEXT=text

;; Initialize arrays

magic = bytarr(4)
offset = bytarr(4)
size = bytarr(4)
ulaw_8bit = bytarr(4)
rate = bytarr(4)
channels = bytarr(4)

;; Read out some the first few variables

catch, errstat
if errstat NE 0 then begin
    close, /all
    return
endif
openr, unit, /get_lun, file
readu, unit, magic, offset, size, ulaw_8bit, rate, channels

;; Convert variables from byte arrays

magic = string(magic)
offset = bytes2long(offset)
size = bytes2long(size)
ulaw_8bit = bytes2long(ulaw_8bit)
rate = bytes2long(rate)
channels = bytes2long(channels)

;; Extract the variable-length description

text = bytarr(offset - 24)
readu, unit, text
text = string(text)

;; Get the data

data = bytarr(size)
readu, unit, data

;; Close the file

close, unit

;; PLAY the sound if requested

if keyword_set(play) then begin
    audio_device = (findfile('/dev/audio'))(0)
    if audio_device EQ '' then begin
        print, 'You have no audio device. Not playing sound.'
        return
    endif
    openw, unit2, /get_lun, audio_device, bufsize=0
    for i=1, play do begin
        writeu, unit2, data
    endfor
    close, unit2
endif

    
return
end
