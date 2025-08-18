;+
;
;NAME:
;  crib_hash_tables_basic
;
;PURPOSE:
;  This crib sheet shows how to work with the IDL data structures: hash and orderedhash
;
;
; Hash tables are very useful, efficient data structures that allow quick mapping of keys to values:
; 
;   https://www.harrisgeospatial.com/docs/HASH.html (added to IDL in 8.0)
;   
;   https://www.harrisgeospatial.com/docs/orderedhash.html (added to IDL in 8.4)
;   
;   
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-08-12 13:50:35 -0700 (Mon, 12 Aug 2019) $
; $LastChangedRevision: 27596 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_hash_tables_basic.pro $
;-

; simple example of using a hash table
; the keys are: one, two
; the values are: 1.0, 2.0
hash_table = hash('one', 1.0, 'two', 2.0)

; access a value by it's key
print, hash_table['one']
stop

; find the list of keys
print, hash_table.keys()
stop

; find the list of values
print, hash_table.values()
stop

; check if a hash table contains a certain key
print, hash_table.haskey('two')
stop

; add another item to the hash table ('three' -> 3.0)
hash_table['three'] = 3.0
stop

; note: in the simple example above, the order of the keys and values are (probably) maintained
; but this will not always be the case (i.e., the order of items added to a standard hash table is not
; maintained, and when you print the keys or values, they can be printed out in a different order than 
; they were added to the table); this tends to be counterintuitive, as one expects items in 
; a (keys, values) list to preserve the order they were added to the list

; another data structure was added to allow for the order to be mainatined: the orderedhash
; this works just like hash(), but actually does maintain the order of items added. 
hash_table = orderedhash('one', 1.0, 'two', 2.0)

; access a value by it's key; same as above
print, hash_table['one']
stop

; find the list of keys; since this is an orderedhash, these will always be in the order they were 
; added to the table
print, hash_table.keys()
stop

; find the list of values; same as above - these will always be in the order they were added to the table
print, hash_table.values()
stop

stop
end