fun! s:get_terminal_windows()
	if has('nvim')
		return map(filter(copy(getwininfo()), 'has_key(v:val.variables, "netrw_prvfile") && v:val.variables["netrw_prvfile"] =~ "^term://"'), 'v:val')
	else
		return map(filter(copy(getwininfo()), 'v:val.terminal'), 'v:val')
	endif
endfu

fu! SendToTerm(...)
	let terms = s:get_terminal_windows()
	if len(terms) < 1
		echomsg "There is no visible terminal!"
		return
	endif

	if !a:0
		let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
		return 'g@'
	endif


	let term_window = terms[0].winnr
	if len(terms) > 1
		let msg =  "Too many terminals open!"
		for t in terms
			let msg .= "\n\t[".t.winnr.']: '.t.variables.netrw_prvfile
		endfor
		let msg .= "\nSelect terminal: "
		let term_window = input(msg, terms[0].winnr)
	endif


	let sel_save = &selection
	let &selection = "inclusive"
	let reg_save = @@
	let clipboard_save = &clipboard
	let &clipboard = ""

	if a:1 == 'char'	" Invoked from Visual mode, use gv command.
		silent exe 'normal! gvy'
	elseif a:1 == 'line'
		silent exe "normal! '[V']y"
	else
		silent exe 'normal! `[v`]y'
	endif

	if has('nvim')
		exe term_window . "wincmd w"

		if has('win32')
			let @" .= "\r"
		else
			let @" .= "\n"
		endif
		normal! p

		exe winnr('#') . "wincmd w"
	else
		let text = substitute(@", '\n\|$', '\r', "g")
		if !&expandtab && g:sendtoterm_expandtab
			let text = substitute(text, '\t', repeat(' ', shiftwidth()), "g")
		endif
		call term_sendkeys(winbufnr(term_window+0), text)
	endif

	let &selection = sel_save
	let @@ = reg_save
	let &clipboard = clipboard_save
endfu

xnoremap <expr> <Plug>(SendToTerm)     SendToTerm()
nnoremap <expr> <Plug>(SendToTerm)     SendToTerm()
nnoremap <expr> <Plug>(SendToTermLine) SendToTerm() . '_'

if !exists("g:sendtoterm_expandtab")
	let g:sendtoterm_expandtab = 1
endif

if !hasmapto('<Plug>(SendToTerm)') && maparg('<leader>t','n') ==# ''
	xmap <leader>t  <Plug>(SendToTerm)
	nmap <leader>t  <Plug>(SendToTerm)
	omap <leader>t  <Plug>(SendToTerm)
	nmap <leader>tt <Plug>(SendToTermLine)
endif
