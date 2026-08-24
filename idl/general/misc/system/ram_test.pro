;+
;FUNCTION:   ram_test
;PURPOSE:
;  Returns the amount of physical RAM installed (in GB).
;  Returns -1 if there's a problem.
;
;USAGE:
;  ram = ram_test()
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-08-19 09:17:49 -0700 (Wed, 19 Aug 2026) $
; $LastChangedRevision: 34776 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/ram_test.pro $
;
;CREATED BY:    David L. Mitchell  Aug 2026
;-
function ram_test

    case strlowcase(!version.os) of
      'darwin' : begin
                   spawn, 'sysctl -n hw.memsize', ram, err, exit_status=i
                   ram = (i eq 0) ? fix(ulong64(ram[0])/(2LL^30LL)) : -1
                 end
      'linux'  : begin
                   spawn, "awk '/MemTotal/ {print $2}' /proc/meminfo", ram, err, exit_status=i
                   ram = (i eq 0) ? fix(ulong64(ram[0])/(2LL^20LL)) : -1
                 end
      'win32'  : begin
                 ; spawn, 'systeminfo | findstr /C:"Total Physical Memory"', ram, err, exit_status=i
                   if (0) then begin
                     ; A Windows user needs to write/test this part.
                   endif else ram = -1
                 end
       else    : ram = -1
    endcase

  return, ram

end
