set noet sts=0 sw=4 ts=4

augroup potatoircd_moonscript
	autocmd BufWritePost *.moon AsyncRun ldoc .; moonc -l %
	autocmd BufWritePost *.ld AsyncRun ldoc .
augroup END

setlocal suffixesadd+=.moon
