" https://github.com/junegunn/vim-pl
call plug#begin('~/.config/nvim/plugged')

" https://github.com/tpope/vim-sensible
Plug 'tpope/vim-sensible'

call plug#end()

" key remaps
noremap <F7> :set nopaste<CR>
noremap <F8> :set paste<CR>
noremap <F10> <Esc>:setlocal spell spelllang=en_us<CR>
noremap <F11> <Esc>:setlocal nospell<CR>
noremap <C-s> <Esc>:source ~/.config/nvim/init.vim<CR>

" setting preferences
set expandtab                   " Use spaces for tabs, not <Tab>
set shiftwidth=0                " Return value for shiftwidth(); Zero sets it to the value of tabstop
set tabstop=4                   " Default tabs are too big

" color preferences
colorscheme elflord
