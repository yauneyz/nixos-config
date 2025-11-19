{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      nerdtree
      nerdcommenter
      vim-surround
      vim-fugitive
      vim-tmux-navigator
      emmet-vim
      ultisnips
      vim-snippets
      ale
      vim-airline
      fzf-vim
      bclose-vim
      vim-javascript
      vim-jsx-pretty
      vimtex
      semshi
    ];
    extraConfig = ''
      let g:mapleader = " "
      " This needs to go before plugins are loaded
      let g:ale_disable_lsp = 1

      let g:copilot_filetypes = {
            \			 'tex': v:false,
            \				'fountain': v:false,
            \			}

      "Fuzzy finding
      nnoremap <silent> <leader><Space> :Files<CR>
      nnoremap <silent> <leader>a :Buffers<CR>
      nnoremap <silent> <leader>g :Rg<CR>
      nnoremap <silent> <leader>l :Lines<CR>
      nnoremap <silent> <leader>L :BLines<CR>
      nnoremap <silent> <leader>A :Windows<CR>

      set nohlsearch

      "Quick Scope
      let g:qs_highlight_on_keys = ['f','F','t','T']

      " Indent
      set autoindent
      set smartindent

      "" Setup ale
      let g:ale_linters = {
      \     'javascript': ['eslint'],
      \     'typescript': ['eslint'],
      \			'python': ['flake8'],
      \}
      let g:ale_fixers = {
      \			'javascript': ['prettier', 'eslint'],
      \			'typescript': ['prettier', 'eslint'],
      \			'python': ['black'],
      \      '*': ['remove_trailing_lines', 'trim_whitespace'],
      \}

      let g:ale_sign_error = '❌'
      let g:ale_sign_warning = '⚠️'
      let g:ale_fix_on_save = 1

      " Deal with annoying escape delay
      set timeoutlen=1000 ttimeoutlen=0

      "Set tab to always be 4 spaces
      set tabstop=2
      set softtabstop=2
      set shiftwidth=2

      "Automatically run python script with f9
      autocmd FileType python map <buffer> <F9> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
      autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>

      "Line numbering
      set nu

      "Vim splits
      nnoremap <C-J> <C-W><C-J>
      nnoremap <C-K> <C-W><C-K>
      nnoremap <C-L> <C-W><C-L>
      nnoremap <C-H> <C-W><C-H>
      set splitbelow
      set splitright

      "Better background highlight color than pink
      :highlight Pmenu ctermbg=gray guibg=gray

      augroup Smartf
        autocmd User SmartfEnter :hi Conceal ctermfg=220 guifg=#6638F0
        autocmd User SmartfLeave :hi Conceal ctermfg=239 guifg=#504945
      augroup end
    '';
  };
}
