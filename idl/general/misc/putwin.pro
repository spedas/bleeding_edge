;+
;PROCEDURE:   putwin
;PURPOSE:
;  'Putwin' has been renamed to 'win'.  Putwin is now a simple pass-through
;  to win.  The functionality is identical.  Please use the new name.
;
;USAGE:
;  win, num, [mon, ] options=options
;
;INPUTS:
;       See win.pro
;
;KEYWORDS:
;       See win.pro
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-08-04 15:17:20 -0700 (Thu, 04 Aug 2022) $
; $LastChangedRevision: 30996 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, num, mon, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  relative=relative, top=top, bottom=bottom, right=right, left=left, $
                  middle=middle, clone=clone, setprime=setprime, silent=silent, $
                  tcalib=tcalib, xpos=xpos, ypos=ypos, _extra=extra

  now = systime(/utc,/sec)
  t1 = time_double('2023-01-01')
  t2 = time_double('2023-07-01')

  if (now lt t1) then print,"'Putwin' is now 'win'.  Please start using the new name."
  if (now ge t1 && now lt t2) then print, "'Putwin' will retire soon.  Please use the new name: 'win'."
  if (now ge t2) then begin
    print,"'Putwin' has retired.  It has been replaced by 'win'."
    return
  endif

  win, num, mon, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  relative=relative, top=top, bottom=bottom, right=right, left=left, $
                  middle=middle, clone=clone, setprime=setprime, silent=silent, $
                  tcalib=tcalib, xpos=xpos, ypos=ypos, _extra=extra

end
