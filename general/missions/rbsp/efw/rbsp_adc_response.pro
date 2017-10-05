;+
; NAME:
;   rbsp_adc_response (function)
;
; PURPOSE:
;   Calculate the responses of the RBSP DFB ADC chip.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   response = rbsp_adc_response(f, channel, delay = delay)
;
; ARGUMENTS:
;   f: (Input, required) A floating array of frequencies at which the responses
;           are calculated.
;   channel: (Input, required) A string of channel names. Valid channels are:
;          'V1DC',  'V2DC',  'V3DC',  'V4DC',  'V5DC',  'V6DC',
;          'E12DC', 'E34DC', 'E56DC', 'E12AC', 'E34AC', 'E56AC', 
;          'V1AC', 'V2AC', 'V3AC', 'V4AC', 'V5AC', 'V6AC', 
;          'MAGU', 'MAGV', 'MAGW', 'MSCU', 'MSCV', 'MSCW'
;
; KEYWORDS:
;   delay: (Output, optional) A variable name to hold the time delay of the
;          given channel.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-10: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; Version:
;
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-09-06 11:42:13 -0700 (Thu, 06 Sep 2012) $
; $LastChangedRevision: 10895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_adc_response.pro $
;-

function rbsp_adc_response, f, channel, delay = delay

compile_opt idl2

case strupcase(channel) of
  ; ADC 1
  'V1DC':  slot= 1
  'V2DC':  slot= 2
  'V3DC':  slot= 3
  'V4DC':  slot= 4
  'V5DC':  slot= 5
  'V6DC':  slot= 6
  'E12DC': slot= 7
  'E34DC': slot= 8
  'E56DC': slot= 9
  'E12AC': slot=10 
  'E34AC': slot=11 
  'E56AC': slot=12 
  ; ADC 2
  'V1AC': slot= 1
  'V2AC': slot= 2
  'V3AC': slot= 3
  'V4AC': slot= 4
  'V5AC': slot= 5
  'V6AC': slot= 6
  'MAGU': slot= 7
  'MAGV': slot= 8
  'MAGW': slot= 9
  'MSCU': slot=10
  'MSCV': slot=11
  'MSCW': slot=12
  else: begin
          dprint,'Invalid channel name. A NaN is returned.'
          return,!values.f_nan
        end
endcase

delay = slot/262144d
phase = f * delay * 2d * !dpi

return, dcomplex(cos(phase), -sin(phase))

end

