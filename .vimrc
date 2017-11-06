"
" global variables
"

" could be passed via cli, e.g. vim --cmd="let User_Dir='$HOME'"
if (!exists("User_Dir"))
    let User_Dir="~"
endif

"
" plugins
"
"

" only vim & neovim have autocmd (not ex or vi); vim-plug requires autocmd
if has("autocmd")

    " https://github.com/junegunn/vim-plug

    " auto-install .vim/autoload/plug.vim
    if empty(glob(User_Dir.'/.vim/autoload/plug.vim'))
        silent !curl -fLo  $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall
    endif

    if !empty(glob(User_Dir.'/.vim/autoload/plug.vim'))

        " autoload plug begin
        call plug#begin(User_Dir.'/.vim/plug')

        if exists(":Plug")

            " vim & neovim compatible

            " https://github.com/Raimondi/delimitMate
            Plug 'Raimondi/delimitMate'
            let delimitMate_matchpairs = "(:),[:],{:},<:>"
            au FileType vim,html let b:delimitMate_matchpairs = "(:),[:],{:},<:>"

            " https://github.com/2072/PHP-Indenting-for-VIm
            Plug '2072/PHP-Indenting-for-VIm'

            " https://github.com/scrooloose/nerdtree
            Plug 'scrooloose/nerdtree'
            if exists(":NERDTree")
                let NERDTreeShowHidden=1
                autocmd StdinReadPre * let s:std_in=1
                autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
            endif
            if exists(":NERDTreeToggle")
                map <Leader>f :NERDTreeToggle<CR>
            endif

            " https://github.com/chrisbra/vim-sh-indent
            Plug 'chrisbra/vim-sh-indent'

            " https://github.com/Xuyuanp/nerdtree-git-plugin
            Plug 'Xuyuanp/nerdtree-git-plugin'

            " https://github.com/vim-airline/vim-airline
            Plug 'vim-airline/vim-airline'
            "let g:airline_powerline_fonts = 1
            let g:airline_detect_spellang=0

            " https://github.com/tpope/vim-fugitive
            Plug 'tpope/vim-fugitive'

            " https://github.com/tpope/vim-sensible
            Plug 'tpope/vim-sensible'

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

        else
            echo "Plug does not exist."
        endif " exists(":Plug")

        " autoload plug begin
        call plug#end()

    endif

endif " has("autocmd")

"
" functions
"

" preserve cursor et al and indent the whole buffer
if !exists("*IndentBuffer")
    function! IndentBuffer()
        call PreserveCursor('normal gg=G')
    endfunction
    noremap <F5> :call IndentBuffer()<CR>
endif

" restore cursor position, window position, and the last search after running a command
if !exists("*PreserveCursor")
    function! PreserveCursor(command)
        " save the last search
        let search = @/

        " save the current cursor position
        let cursor_position = getpos('.')

        " save the current window position
        normal! H
        let window_position = getpos('.')
        call setpos('.', cursor_position)

        " execute the command
        execute a:command

        " restore the last search
        let @/ = search

        " restore the previous window position
        call setpos('.', window_position)
        normal! zt

        " restore the previous cursor position
        call setpos('.', cursor_position)
    endfunction
endif

" reconfigure/reload (source) .vimrc
if !exists("*Reconfigure")
    function Reconfigure()
        :exec ":source " . g:User_Dir . "/.vimrc"
        if has("gui_running")
            :exec ":source " . g:User_Dir . "/.gvimrc"
        endif
    endfunction
    command! Reconfigure call Reconfigure()
    map <Leader>s :call Reconfigure()<CR>
endif

" NR-8    COLOR NAME
" 0       Black
" 1       DarkRed
" 2       DarkGreen
" 3       Brown, DarkYellow
" 4       DarkBlue
" 5       DarkMagenta
" 6       DarkCyan
" 7       LightGray, LightGrey, Gray, Grey
" 8       DarkGray, DarkGrey
" 9       Red, LightRed
" 10      Green, LightGreen
" 11      Yellow, LightYellow
" 12      Blue, LightBlue
" 13      Magenta, LightMagenta
" 14      Cyan, LightCyan
" 15      White

"
" preferences
"

" autocmd Buf preferences
autocmd BufNewFile,BufRead *.d set filetype=sh
autocmd BufNewFile,BufRead *.md set filetype=markdown
autocmd BufNewFile,BufRead *.web set filetype=sh
autocmd BufNewFile,BufRead http* set filetype=xml syntax=apache
autocmd BufNewFile,BufRead named*.conf set filetype=named
autocmd BufNewFile,BufRead *.zone set filetype=bindzone

" autocmd Vim preferences
autocmd VimEnter * "set term=$TERM"

" color preferences
colorscheme elflord
set background=dark
set t_Co=256
syntax on
syntax enable

" filetype preferenes
filetype indent on

" keyboard preferences
noremap <F7> :set nopaste<CR>
noremap <F8> :set paste<CR>
noremap <F10> <Esc>:setlocal spell spelllang=en_us<CR>
noremap <F11> <Esc>:setlocal nospell<CR>
noremap <F12> <Esc>:syntax sync fromstart<CR>
map <Leader>q :q<CR>
map <Leader>t gt

" setting preferences
set autoindent                              " copy indet from current line when starting a new line
set autoread                                " automatically re-read files that have changed outside of VIM
set backspace=indent,eol,start              " allow backspace in insert mode
set clipboard=unnamedplus                   " Set default clipboard name
set complete-=i
set noerrorbells                            " turn off error bells
set expandtab                               " use spaces for tabs, not <Tab>
set formatoptions=tcqj
set hidden                                  " allow hidden buffers
set history=1000                            " default = 8
set laststatus=2                            " use the second statusline
set linebreak                               " only wrap at sensible places
set list listchars=tab:▷\ ,trail:⋅,nbsp:⋅
set nocompatible                            " make vim behave in a more useful way
"set number                                  " .ine numbers
set ruler                                   " show the line and column number of the cursor position
set shiftwidth=0                            " return value for shiftwidth(); zero sets it to the value of tabstop
set showcmd                                 " show (partial) command in the last line of the screen
set smartindent                             " smart autoindent when starting a new line
set smarttab                                " when on a <Tab> in front of a line, insert lanks according to shiftwidth
set tags=./tags;,tags                       " set tag file search preference
set tabstop=4                               " default tabs are too big
set textwidth=0                             " prevent vim from automatically inserting line breaks
set ttyfast                                 " indicates a fast terminal connection
set undodir=~/.vim/undo                     " set undo directory location
set wildmenu                                " enhanced command-line completion
set wrap                                    " turn on word wrapping
set wrapmargin=0                            " number of characters from the right window border where wrapping starts
