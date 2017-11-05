if (!exists("User_Dir"))
    let User_Dir="~"
endif

if has("autocmd")

    " https://github.com/junegunn/vim-pl

    " auto-install vim-plug
    if empty(glob(User_Dir.'/.vim/autoload/plug.vim'))
        silent !curl -fLo  $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall
    endif

    " autoload plugs
    call plug#begin(User_Dir.'/.vim/plug')

    " vim & neovim compatible

    " https://github.com/Raimondi/delimitMate
    Plug 'Raimondi/delimitMate'
    let delimitMate_matchpairs = "(:),[:],{:},<:>"
    au FileType vim,html let b:delimitMate_matchpairs = "(:),[:],{:},<:>"

    " https://github.com/2072/PHP-Indenting-for-VIm
    Plug '2072/PHP-Indenting-for-VIm'

    " https://github.com/scrooloose/nerdtree
    Plug 'scrooloose/nerdtree'
    let NERDTreeShowHidden=1
    autocmd StdinReadPre * let s:std_in=1
    autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
    map <Leader>f :NERDTreeToggle<CR>

    " https://github.com/chrisbra/vim-sh-indent
    Plug 'chrisbra/vim-sh-indent'

    " https://github.com/Xuyuanp/nerdtree-git-plugin
    Plug 'Xuyuanp/nerdtree-git-plugin'

    " https://github.com/tpope/vim-fugitive
    Plug 'tpope/vim-fugitive'

    " https://github.com/tpope/vim-sensible
    Plug 'tpope/vim-sensible'

    "
    if has('nvim')
        " neovim compatible, only

        " https://github.com/euclio/vim-markdown-composer
        function! BuildComposer(info)
            if a:info.status != 'unchanged' || a:info.force
                !cargo build --release
            endif
        endfunction
        Plug 'euclio/vim-markdown-composer', { 'do': function('BuildComposer') }

    else
        " vim compatible, only

        " https://github.com/suan/instant-markdown-d
        " https://github.com/suan/vim-instant-markdown
        Plug 'suan/vim-instant-markdown'
        let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
        let g:markdown_syntax_conceal = 0
        let g:markdown_minlines = 100
        let g:instant_markdown_autostart = 0    " Use :InstantMarkdownPreview to turn on

    endif " has('nvim')

    call plug#end()

endif " has("autocmd")

"
" embedded functions that work with vi (compatible), vim, and neovim
" 

" preserve cursor et al and indent the whole buffer
function! IndentBuffer()
    call PreserveCursor('normal gg=G')
endfunction

" restore cursor position, window position, and last search after running a command
function! PreserveCursor(command)
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

" reconfigure (source) .vimrc
if !exists("*Reconfigure")
    function Reconfigure()
        :exec ":source " . g:User_Dir . "/.vimrc"
        if has("gui_running")
            :exec ":source " . g:User_Dir . "/.gvimrc"
        endif
    endfunction
    command! Reconfigure call Reconfigure()
endif

"
" preferences
"

filetype indent on

" keyboard preferences
noremap <F5> :call IndentBuffer()<CR>
noremap <F7> :set nopaste<CR>
noremap <F8> :set paste<CR>
noremap <F10> <Esc>:setlocal spell spelllang=en_us<CR>
noremap <F11> <Esc>:setlocal nospell<CR>
noremap <F12> <Esc>:syntax sync fromstart<CR>
map <Leader>q :q<CR>
map <Leader>s :call Reconfigure()<CR>
map <Leader>t gt

" setting preferences
set autoindent                  " Copy indent from current line when starting a new line
set backspace=indent,eol,start  " Allow backspace in insert mode
set expandtab                   " Use spaces for tabs, not <Tab>
set formatoptions-=t            " Don't change wrapping on existing lines
set formatoptions+=l            " Black magic
set hidden                      " Allow hidden buffers
set history=100                 " Default = 8
set linebreak                   " Only wrap at sensible places
set list listchars=tab:▷\ ,trail:⋅,nbsp:⋅
set nocompatible
set nolist                      " list disables line break
"set number                      " Line numbers
set shiftwidth=0                " Return value for shiftwidth(); Zero sets it to the value of tabstop
set smartindent                 " Smart autoindent when starting a new line
"set spell                       " http://vimdoc.sourceforge.net/htmldoc/spell.html
"set spelllang=en_us
set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\ \ [%l/%L\ (%p%%)
set tabstop=4                   " Default tabs are too big
set textwidth=0                 " prevent Vim from automatically inserting line breaks
set wrap                        " Turn on word wrapping
set wrapmargin=0

" color preferences
colorscheme elflord
set background=dark
set t_Co=256
syntax on
syntax enable

" startup preferences
autocmd VimEnter * "set term=$TERM"

" ftplugin preferences
autocmd BufNewFile,BufRead *.d set filetype=sh
autocmd BufNewFile,BufRead *.md set filetype=markdown
autocmd BufNewFile,BufRead *.web set filetype=sh
autocmd BufNewFile,BufRead http* set filetype=xml syntax=apache
autocmd BufNewFile,BufRead named*.conf set filetype=named
autocmd BufNewFile,BufRead *.zone set filetype=bindzone
