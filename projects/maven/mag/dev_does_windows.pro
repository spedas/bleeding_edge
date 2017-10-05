function dev_does_windows

rv = 0b

if (!d.flags and 256L) ne 0 then rv=1b else rv=0b

return, rv
end
