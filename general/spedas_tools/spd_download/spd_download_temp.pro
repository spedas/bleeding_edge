
;+
;Function:
;  spd_download_temp
;
;Purpose:
;  Create a random numeric filename suffix for temporary files.
;
;Calling Sequence:
;  suffix = spd_download_temp()
;
;Output:
;  Returns 12 digit numeric string preceded by a period
;
;    e.g. ".555350461348"
;
;Notes:
;  
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2017-03-08 16:06:47 -0800 (Wed, 08 Mar 2017) $
;$LastChangedRevision: 22927 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_temp.pro $
;
;-

function spd_download_temp

    compile_opt idl2, hidden

  
  ;use milliseconds on clock as seed for random #
  t = systime(/sec) * 1e3

  ;pull digits directly to ensure # of characters
  If(!version.os_name eq 'Solaris' And $ ;To insure that old versions do not crash, jmm 2017-03-08
     float(!version.release) lt 8.4) Then Begin
     s = string( randomu(t), format='(F9.7)' )
  Endif Else s = string( randomu(t,/double), format='(F14.12)' )

  ;trim leading zero and use rest as temporary file suffix
  s = strmid(s,1)

  return, s

end
