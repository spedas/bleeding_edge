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
; $LastChangedDate: 2022-07-14 11:38:23 -0700 (Thu, 14 Jul 2022) $
; $LastChangedRevision: 30930 $
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

  print,"'Putwin' is now 'win'.  Please start using the new name."

  win, num, mon, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  relative=relative, top=top, bottom=bottom, right=right, left=left, $
                  middle=middle, clone=clone, setprime=setprime, silent=silent, $
                  tcalib=tcalib, xpos=xpos, ypos=ypos, _extra=extra

end
