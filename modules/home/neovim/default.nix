{ pkgs, ... }:

let
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
    nvim-treesitter.withAllGrammars

    # Themes
    gruvbox
    tokyonight-nvim
    catppuccin-nvim
    kanagawa-nvim
  ];

  neovimPackage = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    vimAlias = true;
    withPython3 = true;
    extraPython3Packages = ps: [ ps.pynvim ];
    inherit plugins;
    neovimRcContent = ''
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

      augroup TreesitterSetup
        autocmd!
        autocmd VimEnter * lua local ok, ts = pcall(require, 'nvim-treesitter.configs'); if ok then ts.setup({ highlight = { enable = true }, indent = { enable = true } }) end
      augroup END

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

      " Keep completion menus opaque enough to separate them from the wallpaper.
      highlight Pmenu ctermbg=black guibg=#241218 guifg=#e7d9d8

      augroup Smartf
        autocmd User SmartfEnter :hi Conceal ctermfg=204 guifg=#e879a0
        autocmd User SmartfLeave :hi Conceal ctermfg=239 guifg=#6f4c54
      augroup end

      " Preserve Kanagawa's Japanese character while replacing its cool tones
      " and allowing Ghostty's dark, blurred wallpaper layer to show through.
      lua << EOF
      require('kanagawa').setup({
        transparent = true,
        dimInactive = false,
        colors = {
          palette = {
            sumiInk0 = '#070607',
            sumiInk1 = '#0c080a',
            sumiInk2 = '#110a0d',
            sumiInk3 = '#171013',
            sumiInk4 = '#241218',
            sumiInk5 = '#42252d',
            sumiInk6 = '#6f4c54',
            waveBlue1 = '#241218',
            waveBlue2 = '#4b2731',
            winterBlue = '#2b171e',
            autumnRed = '#dc3b59',
            autumnGreen = '#a9c78e',
            autumnYellow = '#e7b269',
            samuraiRed = '#f06466',
            roninYellow = '#e7b269',
            waveAqua1 = '#a9c78e',
            dragonBlue = '#f0a7b2',
            oldWhite = '#d8c8c7',
            fujiWhite = '#e7d9d8',
            fujiGray = '#8d6971',
            oniViolet = '#dc3b59',
            oniViolet2 = '#e879a0',
            crystalBlue = '#e879a0',
            springViolet1 = '#e879a0',
            springViolet2 = '#f0a7b2',
            springBlue = '#dc3b59',
            lightBlue = '#f1e6e3',
            waveAqua2 = '#c9929a',
            springGreen = '#a9c78e',
            boatYellow1 = '#ad727d',
            boatYellow2 = '#e7b269',
            carpYellow = '#f0c98c',
            sakuraPink = '#e879a0',
            waveRed = '#dc3b59',
            peachRed = '#f06466',
            surimiOrange = '#e4775b',
            katanaGray = '#b79097',
          },
        },
      })
      EOF

      set background=dark
      colorscheme kanagawa
    '';
  };
in
{
  # Keep Stylix from overriding the manually configured Neovim theme.
  stylix.targets.neovim.enable = false;

  home.packages = [ neovimPackage ];
}
