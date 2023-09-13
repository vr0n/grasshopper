" plugzzz
call plug#begin()
  Plug 'neaclide/coc.nvim', {'branch': 'release'}
call plug#end()

" undofile
set undodir=~/.config/nvim/undo-dir
set undofile

" open files at last line saw
if has("autocmd")
  autocmd BufReadPost * if line("'\'") > 0 && line ("'\"") <= line("$") |  exe "normal g'\"" | endif
endif

" remaps
imap jj <esc>	
map ZW :w!<CR>

" spellcheck
set spell spelllang=en_us
hi SpellBad ctermfg=none ctermbg=none cterm=underline
hi SpellLocal ctermfg=185 ctermbg=88 cterm=none
hi SpellCap ctermfg=none ctermbg=235 cterm=none

" use <tab> for trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" my goods
set expandtab tabstop=2 shiftwidth=2
  
" highlight the tabs
function! HiTabs()
	syntax match TAB /\t/ containedin=all
	hi TAB cterm=underline ctermfg=blue
endfunction
au BufEnter,BufRead * call HiTabs()

set nu
syntax on

" open files at last line saw
if has("autocmd")
  autocmd BufReadPost *
    \ if line("'\'") > 0 && line ("'\"") <= line("$") |
    \  exe "normal g'\"" |
    \ endif
endif

" use <tab> for trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <Tab>
  \ coc#pum#visible() ? coc#pum#next(1) :
  \ CheckBackspace() ? "\<Tab>" :
  \ coc#refresh()
