set noet sts=0 sw=4 ts=4

augroup potatoircd_moonscript
	autocmd BufWritePost *.moon AsyncRun ./compile-ldoc.sh; moonc -l .
	autocmd BufWritePost *.ld AsyncRun ./compile-ldoc.sh
augroup END

setlocal suffixesadd+=.moon
