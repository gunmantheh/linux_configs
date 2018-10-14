set nocompatible " must be the first line
filetype on
filetype indent on
filetype plugin on
set laststatus=2
set statusline=%<%f\%h%m%r%=%-20.(line=%l\ \ col=%c%V\ \ totlin=%L%)\ \ \%h%m%r%=%-40(bytval=0x%B,%n%Y%)\%P

syntax on
set ignorecase
set smartcase
set incsearch
set showcmd
set number

set listchars=tab:>~,nbsp:_,trail:.
set list
set cursorline

nnoremap ; :

set laststatus=2 " Always display the statusline in all windows
"set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)

"python3 from powerline.vim import setup as powerline_setup
"python3 powerline_setup()
"python3 del powerline_setup


if ! has('gui_running')
    set ttimeoutlen=10
    augroup FastEscape
        autocmd!
        au InsertEnter * set timeoutlen=0
        au InsertLeave * set timeoutlen=1000
    augroup END
endif

