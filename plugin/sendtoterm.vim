fu! SendToTerm(...)
	let terms = map(filter(copy(getwininfo()), 'v:val.terminal'), 'v:val')
	if len(terms) < 1
		echomsg "There is no visible terminal!"
		return
	endif

	let term_buffer = terms[0].bufnr
	if len(terms) > 1
		let msg =  "Too many terminals open!"
		for t in terms
			let msg .= "\n\tTerm: ".t.bufnr.' '.t.variables.netrw_prvfile
		endfor
		let msg .= "\nSelect terminal: "
		let term_buffer = input(msg, terms[0].bufnr)
	endif

	if !a:0
		let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
		return 'g@'
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

	let text = substitute(@", '\n\|$', '\r', "g")
	if !&expandtab && g:sendtoterm_tab2space
		let text = substitute(text, '\t', repeat(' ', shiftwidth()), "g")
	endif
	call term_sendkeys(term_buffer+0, text)

	let &selection = sel_save
	let @@ = reg_save
	let &clipboard = clipboard_save
endfu

xnoremap <expr> <Plug>(SendToTerm)     SendToTerm()
nnoremap <expr> <Plug>(SendToTerm)     SendToTerm()
nnoremap <expr> <Plug>(SendToTermLine) SendToTerm() . '_'

if !exists("g:sendtoterm_tab2space")
	let g:sendtoterm_tab2space = 1
endif

if !hasmapto('<Plug>(SendToTerm)') && maparg('<leader>t','n') ==# ''
	xmap <leader>t  <Plug>(SendToTerm)
	nmap <leader>t  <Plug>(SendToTerm)
	omap <leader>t  <Plug>(SendToTerm)
	nmap <leader>tt <Plug>(SendToTermLine)
endif
