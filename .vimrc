" Function to restore cursor position, window position, and last search after running a command.
function! Preserve(command)
    " Save the last search.
    let search = @/

    " Save the current cursor position.
    let cursor_position = getpos('.')

    " Save the current window position.
    normal! H
    let window_position = getpos('.')
    call setpos('.', cursor_position)

    " Execute the command.
    execute a:command

    " Restore the last search.
    let @/ = search

    " Restore the previous window position.
    call setpos('.', window_position)
    normal! zt

    " Restore the previous cursor position.
    call setpos('.', cursor_position)
endfunction

" Function to re-indent the whole buffer.
function! Indent()
    call Preserve('normal gg=G')
endfunction

" Keyboard mappings
noremap <F5> :call Indent()<CR>
noremap <F7> :set nopaste<CR>
noremap <F8> :set paste<CR>
noremap <F10> <Esc>:setlocal spell spelllang=en_us<CR>
noremap <F11> <Esc>:setlocal nospell<CR>
noremap <F12> <Esc>:syntax sync fromstart<CR>
noremap <C-q> <Esc>:s/\"/\\\"/g<CR>:s/'/\"/g<CR>

" Basic Settings
set autoindent                  " Copy indent from current line when starting a new line
set backspace=indent,eol,start  " Allow backspace in insert mode
set expandtab                   " Use spaces for tabs, not <Tab>
set formatoptions-=t            " Don't change wrapping on existing lines
set formatoptions+=l            " Black magic
set hidden                      " Allow hidden buffers
set history=100                 " Default = 8
set linebreak                   " Only wrap at sensible places
set list listchars=tab:▷\ ,trail:⋅,nbsp:⋅
set nolist                      " list disables line break
"set number                      " Line numbers
set smartindent                 " Smart autoindent when starting a new line
"set spell                       " http://vimdoc.sourceforge.net/htmldoc/spell.html
"set spelllang=en_us
set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\ \ [%l/%L\ (%p%%)
set tabstop=4                   " Default tabs are too big
set textwidth=0                 " prevent Vim from automatically inserting line breaks
set wrap                        " Turn on word wrapping
set wrapmargin=0

" Color Scheme
colorscheme elflord
set background=dark
set t_Co=256
syntax on
syntax enable

" ftplugin mappings
au BufNewFile,BufRead *.d set filetype=sh
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.web set filetype=sh
au BufNewFile,BufRead http* set filetype=xml syntax=apache
au BufNewFile,BufRead named*.conf set filetype=named
au BufNewFile,BufRead *.zone set filetype=bindzone

" Markdown ftplugin settings
" let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
" let g:markdown_syntax_conceal = 0
" let g:markdown_minlines = 100
" https://github.com/suan/instant-markdown-d
" https://github.com/suan/vim-instant-markdown
let g:instant_markdown_autostart = 0    " Use :InstantMarkdownPreview to turn on
