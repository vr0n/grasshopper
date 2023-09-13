" Vundle configs
set nocompatible
filetype off
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
"
"Plugin 'VundleVim/Vundle.vim'
"Plugin 'zah/nim.vim'
"
" all plugins must be added before these lines
"call vundle#end()
"filetype plugin indent on
set tabstop    =2
set expandtab

function! HiTabs()
    syntax match TAB /\t/ containedin=all
    hi TAB cterm=underline ctermfg=blue
endfunction
au BufEnter,BufRead * call HiTabs()

" color
color default

" remaps
imap jj <esc>

" line configs
set nu

" syntax
syntax on

" spellcheck
set spell spelllang=en_us
hi SpellBad ctermfg=none ctermbg=none cterm=underline
hi SpellLocal ctermfg=185 ctermbg=88 cterm=none
hi SpellCap ctermfg=none ctermbg=235 cterm=none

"set cursorline
"set cursorcolumn
"hi clear CursorLine
"hi link CursorLine CursorColumn
map ,s :s/ /-/ge\|s/./&̶/g<CR>
map ,u :s/./&̲̲/g\|/̲̲ / /ge<CR>
set encoding=utf-8

" others
map ZW :w!<CR>

" undofile
set undodir=~/.vim/undo-dir
set undofile
" open files at previously visited line
if has("autocmd")
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal g'\"" |
  \ endif
endif
