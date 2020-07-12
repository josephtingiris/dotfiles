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

" only neovim & vim have autocmd (not ex or vi); vim-plug requires autocmd
if has("autocmd")

    " https://github.com/junegunn/vim-plug
    " auto-install .vim/autoload/plug.vim
    if empty(glob(User_Dir.'/.vim/autoload/plug.vim'))

        silent !curl -fLo  $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall

    endif

    if !empty(glob(User_Dir.'/.vim/autoload/plug.vim'))

        " autoload plug begin
        silent! call plug#begin(User_Dir.'/.vim/plug')

        if exists(":Plug")

            "
            " all versions of neovim & vim support these plugins
            "

            " https://github.com/2072/PHP-Indenting-for-VIm
            Plug '2072/PHP-Indenting-for-VIm'

            " https://github.com/ctrlpvim/ctrlp.vim
            Plug 'ctrlpvim/ctrlp.vim'
            let g:ctrlp_show_hidden = 1

            " https://github.com/Raimondi/delimitMate
            Plug 'Raimondi/delimitMate'
            let delimitMate_matchpairs = "(:),[:],{:},<:>"
            autocmd FileType vim,html let b:delimitMate_matchpairs = "(:),[:],{:},<:>"

            " https://github.com/ludovicchabant/vim-gutentags
            " TODO evaluate

            " https://github.com/pearofducks/ansible-vim
            Plug 'pearofducks/ansible-vim'
            let g:ansible_unindent_after_newline = 1
            autocmd BufNewFile,BufRead *.{j2,jinja2,yaml,yml} set filetype=yaml.ansible
            autocmd Filetype yaml.ansible setlocal ai ts=2 sts=2 sw=2 expandtab

            " https://github.com/sbdchd/neoformat
            Plug 'sbdchd/neoformat'
            "let g:neoformat_verbose = 1 " only affects the verbosity of Neoformat

            if v:version >= 704

                "
                " all versions of neovim & vim >= 704 support these plugins
                "

                " https://github.com/chrisbra/vim-sh-indent
                Plug 'chrisbra/vim-sh-indent'

                " https://github.com/scrooloose/nerdtree
                Plug 'scrooloose/nerdtree'
                let NERDTreeShowHidden=1
                autocmd StdinReadPre * let s:std_in=1
                "autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
                map <Leader>f :NERDTreeToggle<CR>

                let g:ctrlp_dont_split = 'NERD'

            endif

            " https://github.com/SirVer/ultisnips
            "Plug 'SirVer/ultisnips'
            "let g:UltiSnipsExpandTrigger = "<tab>"
            "let g:UltiSnipsJumpForwardTrigger = "<tab>"
            "let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

            if v:version >= 800 || has('nvim')
                " https://github.com/dense-analysis/ale
                Plug 'dense-analysis/ale'
                let g:ale_linters = { 'php': ['php'], }
                let g:ale_lint_on_save = 1
                let g:ale_lint_on_text_changed = 0
            elseif v:version >= 704
                " https://github.com/vim-syntastic/syntastic
                Plug 'scrooloose/syntastic'
                let g:syntastic_always_populate_loc_list = 1
                let g:syntastic_auto_loc_list = 1
                let g:syntastic_check_on_open = 1
                let g:syntastic_check_on_wq = 0
                let g:syntastic_yaml_checkers = ['yamllint']
            endif

            " https://github.com/tpope/vim-fugitive
            Plug 'tpope/vim-fugitive'

            " https://github.com/tpope/vim-sensible
            Plug 'tpope/vim-sensible'

            " https://github.com/vim-airline/vim-airline
            Plug 'vim-airline/vim-airline'
            "let g:airline_powerline_fonts = 1
            let g:airline_detect_spellang=0

            " https://github.com/stephpy/vim-php-cs-fixer
            Plug 'stephpy/vim-php-cs-fixer'
            let g:php_cs_fixer_cache = '/dev/null'
            let g:php_cs_fixer_rules = "@PSR1,@PSR2,@Symfony,combine_consecutive_unsets,heredoc_to_nowdoc,no_useless_return,ordered_class_elements"
            let g:php_cs_fixer_rules = '{"concat_space": {"spacing": "one"}}'
            "autocmd BufWritePost *.php call PhpCsFixerFixFile()

            " https://github.com/Xuyuanp/nerdtree-git-plugin
            Plug 'Xuyuanp/nerdtree-git-plugin'

            if v:version >= 800 || has('nvim')
                " vim 8+ or neovim, only

                " https://github.com/fatih/vim-go
                Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
                let g:go_version_warning = 0
                let g:go_fmt_command = "goimports"
                let g:go_def_mode = "gopls"
                let g:go_def_mapping_enabled = 0
                let g:go_info_mode = "gopls"
                autocmd BufNewFile,BufRead *.go set filetype=go
                "autocmd FileType go map <C-n> :cnext<CR>
                "autocmd FileType go map <C-m> :cprevious<CR>
                "autocmd FileType go nnoremap <leader>a :cclose<CR>
                "autocmd FileType go nmap <leader>b <Plug>(go-build)
                "autocmd FileType go nmap <leader>i <Plug>(go-imports)
                "autocmd FileType go nmap <leader>r <Plug>(go-run)
                "autocmd FileType go nmap <leader>t <Plug>(go-test)
                "autocmd FileType go nmap <leader>c <Plug>(go-coverage)

                " https://github.com/euclio/vim-markdown-composer
                function! BuildComposer(info)
                    if a:info.status != 'unchanged' || a:info.force
                        !cargo build --release
                    endif
                endfunction
                Plug 'euclio/vim-markdown-composer', { 'do': function('BuildComposer') }

                let node_valid = 0 " true
                let use_ycm = 0 " true

                if v:version >= 800 || has('nvim-0.3.1')

                    if executable('node')
                        let node_output = system('node' . ' --version')
                        let node_ms = matchlist(node_output, 'v\(\d\+\).\(\d\+\).\(\d\+\)')
                        if empty(node_ms) || str2nr(node_ms[1]) < 8 || (str2nr(node_ms[1]) == 8 && str2nr(node_ms[2]) < 10)
                            let node_valid = 0
                            let use_ycm = 1
                        else
                            let node_valid = 1
                        endif
                    endif

                    if node_valid

                        " https://github.com/neoclide/coc.nvim
                        " release branch
                        Plug 'neoclide/coc.nvim', {'branch': 'release'}
                        " latest tag
                        " Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}

                        " Use tab for trigger completion with characters ahead and navigate.
                        " Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
                        inoremap <silent><expr> <TAB>
                                    \ pumvisible() ? "\<C-n>" :
                                    \ <SID>check_back_space() ? "\<TAB>" :
                                    \ coc#refresh()
                        inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

                        function! s:check_back_space() abort
                            let col = col('.') - 1
                            return !col || getline('.')[col - 1]  =~# '\s'
                        endfunction

                        " Use <c-space> to trigger completion.
                        inoremap <silent><expr> <c-space> coc#refresh()

                        " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
                        " Coc only does snippet and additional edit on confirm.

                        " Use `[c` and `]c` to navigate diagnostics
                        nmap <silent> [c <Plug>(coc-diagnostic-prev)
                        nmap <silent> ]c <Plug>(coc-diagnostic-next)

                        " Remap keys for gotos
                        nmap <silent> gd <Plug>(coc-definition)
                        nmap <silent> gy <Plug>(coc-type-definition)
                        nmap <silent> gi <Plug>(coc-implementation)
                        nmap <silent> gr <Plug>(coc-references)

                        " Use K to show documentation in preview window
                        nnoremap <silent> K :call <SID>show_documentation()<CR>

                        function! s:show_documentation()
                            if (index(['vim','help'], &filetype) >= 0)
                                execute 'h '.expand('<cword>')
                            else
                                call CocAction('doHover')
                            endif
                        endfunction

                        " Highlight symbol under cursor on CursorHold
                        autocmd CursorHold * silent call CocActionAsync('highlight')

                        " Remap for rename current word
                        nmap <leader>rn <Plug>(coc-rename)

                        " Remap for format selected region
                        xmap <leader>f  <Plug>(coc-format-selected)
                        nmap <leader>f  <Plug>(coc-format-selected)

                        augroup mygroup
                            autocmd!
                            " Setup formatexpr specified filetype(s).
                            autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
                            " Update signature help on jump placeholder
                            autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
                        augroup end

                        " Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
                        xmap <leader>a  <Plug>(coc-codeaction-selected)
                        nmap <leader>a  <Plug>(coc-codeaction-selected)

                        " Remap for do codeAction of current line
                        nmap <leader>ac  <Plug>(coc-codeaction)
                        " Fix autofix problem of current line
                        nmap <leader>qf  <Plug>(coc-fix-current)

                        " Use <tab> for select selections ranges, needs server support, like: coc-tsserver, coc-python
                        nmap <silent> <TAB> <Plug>(coc-range-select)
                        xmap <silent> <TAB> <Plug>(coc-range-select)
                        xmap <silent> <S-TAB> <Plug>(coc-range-select-backword)

                        " Use `:Format` to format current buffer
                        command! -nargs=0 Format :call CocAction('format')

                        " Use `:Fold` to fold current buffer
                        command! -nargs=? Fold :call     CocAction('fold', <f-args>)

                        " use `:OR` for organize import of current buffer
                        command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

                        " Add status line support, for integration with other plugin, checkout `:h coc-status`
                        set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

                        " Using CocList
                        " Show all diagnostics
                        nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
                        " Manage extensions
                        nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
                        " Show commands
                        nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
                        " Find symbol of current document
                        nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
                        " Search workspace symbols
                        nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
                        " Do default action for next item.
                        nnoremap <silent> <space>j  :<C-u>CocNext<CR>
                        " Do default action for previous item.
                        nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
                        " Resume latest coc list
                        nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

                        " extensions
                        let g:coc_global_extensions = ['coc-gitignore', 'coc-go', 'coc-json', 'coc-yaml']

                        " warnings
                        let g:coc_disable_startup_warning = 1

                    endif " if node_valid


                else " if v:version >= 800 || has('nvim-0.3.1')

                    " https://github.com/suan/vim-instant-markdown
                    Plug 'suan/vim-instant-markdown'
                    let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
                    let g:markdown_syntax_conceal = 0
                    let g:markdown_minlines = 100
                    let g:instant_markdown_autostart = 0    " Use :InstantMarkdownPreview to turn on

                endif " if v:version >= 800 || has('nvim-0.3.1')

                if use_ycm

                    " https://github.com/Valloric/YouCompleteMe
                    Plug 'Valloric/YouCompleteMe'
                    "let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
                    "let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
                    "let g:SuperTabDefaultCompletionType = '<C-n>'

                endif " if use_ycm

            endif " if v:version >= 800 || has('nvim')

        else " if exists(":Plug")
            echo "Plug does not exist."
        endif " if exists(":Plug")

        " autoload plug begin
        call plug#end()

    endif

    " autocmd Buf preferences
    autocmd BufNewFile,BufRead *.d set filetype=sh
    autocmd BufNewFile,BufRead *.md set filetype=markdown
    autocmd BufNewFile,BufRead http* set filetype=xml syntax=apache
    autocmd BufNewFile,BufRead named*.conf set filetype=named
    autocmd BufNewFile,BufRead *.web set filetype=sh
    autocmd BufNewFile,BufRead *.zone set filetype=bindzone

    " autocmd Vim preferences
    "autocmd VimEnter * "set term=$TERM"

    if has('nvim')
        " workaround nvim terminal bug; https://github.com/neovim/neovim/wiki/FAQ#nvim-shows-weird-symbols-2-q-when-changing-modes
        autocmd OptionSet guicursor noautocmd set guicursor=
        set guicursor=
    endif

endif " has("autocmd")

"
" functions
"

" call ctags a few different ways
function! CtagsUpdate(scope)
    let ctags_command=""

    if a:scope == 'directory'
        " tags for all files in the directory of the buffer
        let ctags_command="!ctags --fields=+l -f " .expand('%:p:h'). "/.tags ".expand('%:p:h')."/*"
    elseif a:scope == 'recursive'
        " tags for all files in the directory of the buffer, recursively
        let ctags_command="!ctags --fields=+l -f " .expand('%:p:h'). "/.tags ".expand('%:p:h')."/. -R"
    else
        " tags for the current file in the buffer
        let ctags_command="!ctags --fields=+l --append --language-force=" . &filetype . " -f " .expand('%:p:h'). "/.tags " . expand('%:p') . " &> /dev/null"
    endif

    " silently execute the command
    :silent execute l:ctags_command | execute 'redraw!'

    " echo something useful
    echo "Updated (" . a:scope . ") tags in " . expand('%:p:h') . "/.tags"
endfunction

set tags+=.tags;/                           " search backwards for .tags (too)
command! CtagsFile call CtagsUpdate('file')
command! CtagsDirectory call CtagsUpdate('directory')
command! CtagsRecursive call CtagsUpdate('recursive')
map <Leader>ctd :CtagsDirectory<CR>
map <Leader>ctf :CtagsFile<CR>
map <Leader>ctr :CtagsRecursive<CR>

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
        :execute ":source " . g:User_Dir . "/.vimrc"
        if has("gui_running")
            :execute ":source " . g:User_Dir . "/.gvimrc"
        endif
    endfunction

    command! Reconfigure call Reconfigure()
    map <Leader>s :call Reconfigure()<CR>
endif

if !exists("*ToggleClipboard")
    function! ToggleClipboard()
        if &clipboard ==# "unnamedplus"
            set clipboard&
            echo "Clipboard turned off."
        else
            set clipboard=unnamedplus
            echo "Clipboard turned on."
        endif
    endfunction
endif

if !exists("*ToggleListchars")
    function! ToggleListchars()
        set invlist
    endfunction
endif

if !exists("*TogglePaste")
    function TogglePaste()
        if &paste
            set nopaste
            echo "Paste turned off."
        else
            set paste
            echo "Paste turned on."
        endif
    endfunction
endif

if !exists("*ToggleSpell")
    function ToggleSpell()
        if &spell
            set nospell
            echo "Spell turned off."
        else
            set spell spelllang=en_us
            echo "Spell turned on."
        endif
    endfunction
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

" color preferences
silent! colorscheme elflord
set background=dark
if &t_Co
    set t_Co=256
endif
syntax on
syntax enable

" filetype preferenes
filetype indent on

" keyboard preferences
noremap <silent> <F2> <Esc>:call ToggleClipboard()<CR>
noremap <silent> <F3> <Esc>:call ToggleSpell()<CR>
noremap <silent> <F4> <Esc>:call TogglePaste()<CR>
" <F5> is conditionally mapped to IndentBuffer() (above)
noremap <F6> <Esc>:syntax sync fromstart<CR>
noremap <silent> <F9> <Esc>:call ToggleListchars()<CR>
nnoremap qb :silent! normal mpea}<Esc>bi{<Esc>`pl " put {} (braces) around a word
map <Leader>jcf :%!python -m json.tool<CR>   " format/indent json better
map <Leader>q :q<CR>
map <Leader>t gt

" setting preferences
set autoindent                              " copy indet from current line when starting a new line
set autoread                                " automatically re-read files that have changed outside of VIM
set backspace=indent,eol,start              " allow backspace in insert mode
set clipboard=unnamedplus                   " Set default clipboard name ;
set complete-=i                             " do not complete for included files; .=current buffer, w=buffers in other windows, b=other loaded buffers, u=unloaded buffers, t=tags, i=include files
set directory=/var/tmp                      " where to store swap files
set noerrorbells                            " turn off error bells
set expandtab                               " use spaces for tabs, not <Tab>
set exrc                                    " source .exrc in the current directory (use .exrc for both vim/nvim compatibility, not .vimrc or .nvimrc)
set formatoptions=tcq                       " t=auto-wrap text, c=auto-wrap comments, q=allow comments formatting with
if v:version >= 704
    set formatoptions=j                     " j=remove comment leader when joining lines
endif
set hidden                                  " allow hidden buffers
set history=1000                            " default = 8
set laststatus=2                            " use the second statusline
set linebreak                               " only wrap at sensible places
"set list listchars=tab:⁞\ ,nbsp:▪,trail:▫,extends:▶,precedes:◀ " help listchars
set list listchars=tab:│\ ,nbsp:▪,trail:▫,extends:▶,precedes:◀ " help listchars
set nocompatible                            " make vim behave in a more useful way
"set number                                  " .ine numbers
set ruler                                   " show the line and column number of the cursor position
set secure                                  " shell and write commands are not allowed in .nvimrc and .exrc in the current directory
set shiftwidth=4                            " return value for shiftwidth()
set showbreak=↪\ 
set showcmd                                 " show (partial) command in the last line of the screen
"set signcolumn=yes                          " always show signcolumns
"set smartindent                             " smart autoindent when starting a new line; shouldn't use with filtetype indent
set smarttab                                " when on a <Tab> in front of a line, insert blanks according to shiftwidth
set softtabstop=4                           " default tabs are too big
set tabstop=4                               " default tabs are too big
set textwidth=0                             " prevent vim from automatically inserting line breaks
if has ("title")
    set titlestring=[vi\ %t]\ %{$USER}@%{hostname()}:%F " :h statusline
    set title                               " set term title
    set titleold=                           " uset term title"
endif
set ttyfast                                 " indicates a fast terminal connection
if exists("&undodir")
    set undodir=~/.vim/undo                 " set undo directory location
endif
set updatetime=300                          " diagnostic messages
set wildmenu                                " enhanced command-line completion
set wrap                                    " turn on word wrapping
set wrapmargin=0                            " number of characters from the right window border where wrapping starts
