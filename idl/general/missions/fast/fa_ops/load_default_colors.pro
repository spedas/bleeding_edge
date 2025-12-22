pro load_default_colors

dn = strlowcase(!d.name)

if ((dn ne 'hp') and (dn ne 'null')) then begin
    loadct,39
endif

return
end

