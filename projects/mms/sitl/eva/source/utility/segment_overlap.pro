; This program returns how 'tr' (|---|) is positioned
; relative to 'tr0' (|======|) as shown below. Both
; tr and tr0 have to be 2-element array.
;
;
;             |=========|
;                 
;           |-------------|
;                  4: larger then tr0
;             |---------|
;                  3: exactly the same
;  -2 |---| 
;        -1 |---| 
;                |---|
;                  0: smaller than tr0
;                     |---| +1
;                            |---| +2
FUNCTION segment_overlap, tr, tr0
  if tr[0] gt tr[1] then message, 'tr is not in order'
  if tr0[0] gt tr0[1] then message, 'tr0 is not in order'
  if (tr[0] eq tr0[0]) and (tr[1] eq tr0[1]) then return,3
  if (tr[0] le tr0[0]) and (tr0[1] le tr[1]) then return,4
  if (tr[0] ge tr0[0]) and (tr[1] le tr0[1]) then return,0 
  if tr[1] le tr0[0] then return, -2
  if tr[0] ge tr0[1] then return,  2
  if tr[0] le tr0[0] then return, -1
  return, 1
END

