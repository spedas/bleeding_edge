;+
; Return the remote root dir for loading the EFW data.
;-

function rbsp_efw_remote_root

;    remote_root = 'http://rbsp.space.umn.edu/rbsp_efw'
;    remote_root = 'http://rbsp.space.umn.edu/data/rbsp'
    remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
;    remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    return, remote_root

end
