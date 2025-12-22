;+ IDL batchfile
;
; gts_batch.pro
;
; Used by GTS (Generic Trending System)
; Called by sdt_batch
; Calls IDL procedure gts.pro, which gets all input from env vars.
;
; By J.Rauchleiba 1998/8/18
;-
@startup
print, !PATH
gts
exit
