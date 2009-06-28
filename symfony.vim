" vim IDE for the symfony PHP framework to speed up development 
" Last Change:  27.06.2009
" Maintainer:   Jamie Learmonth <jamie at boxlightmedia dot com>
" Maintainer:   Nicolas MARTIN <email.de.nicolas.martin at gmail dot com>

if (exists("loaded_symfony"))
  finish
endif

let loaded_symfony = 1

" All our mappings

" Create a new Action which take the name of the word under the cursor
map sca :SfCreateAction<CR>

" Show the symfony.vim menu
map sm :SfMenu<CR>

" Switch between action and template
map sv :SfSwitchView<CR>

" Switch to a test file
map st :SfSwitchToTest<CR>

" Run current functional test
map srt :SfRunTest<CR>

" Clear cache
map sc :SfClearCache<CR>



" Displays a menu of available commands
function! SfMenu()
  echo "1. Clear cache"
  echo "2. Re-generate C-tags"

  let input = input("Choose a menu option: ")

  if input == 1
    call SfClearCache()
  elsei input == 2
    call SfGenerateCTags()
  endif
endfunction

function! SfCreateAction(name)
  let l:func_name = "execute" . toupper(a:name[0]) . a:name[1:]
  let cur_line  = line(".")
  exe "normal \<ESC>bdw0i\<TAB>public function " . l:func_name . "(sfWebRequest $request)\<CR>\<ESC>0i\<TAB>{\<CR>\<ESC>mai\<CR>\<ESC>0i\<TAB>}\<ESC>" 
 
  " If Php Doc is loaded let's add some comments too
  if exists('*PhpDoc')
    exec ":normal " . cur_line . "G"
    set paste
    call PhpDoc()
    set nopaste
  endif

  " Reposition cursor
  exec "normal `a"
endfunction

" Generates new c tags and sticks them in the data directory of the project
function! SfGenerateCTags()
  
  if (!exists("g:sf_root_dir"))
    call SfPluginLoad()
  endif

  exec ":cd " . g:sf_root_dir 

  let ctag_cmd = 'ctags -a -f data/vim.ctags -h ".php" --languages=php -R --exclude="\.svn" --totals=yes --tag-relative=yes --PHP-kinds=+cf --regex-PHP="/abstract class ([^ ]*)/\1/c/" --regex-PHP="/interface ([^ ]*)/\1/c/" --regex-PHP="/(public |private |static |protected )+function ([^ ()]*)/\2/f/"'
  let ctag_resp = system(ctag_cmd)

endfunction

" Command line actions
function! SfCallCommandLine(namespace, task, arguments)
  exec(':cd ' . g:sf_root_dir)
  execute "!symfony " . a:namespace . ":" . a:task . " " . a:arguments 
  redraw! 
endfunction

function! SfClearCache()
  call SfCallCommandLine("cache", "clear", "")
  echo "Symfony cache cleared"
endfunction


" Determine all the paths
function! ReconfigPaths()
  let file = expand('%:p')
    if (!IsATest())
      let g:sf_app_name = substitute(file, '.*apps\(/\|\\\)\(.\{-\}\)\(/\|\\\).*', '\2', 'g')
      let g:sf_module_name = substitute(file, '.*modules\(/\|\\\)\(.\{-\}\)\(/\|\\\).*', '\2', 'g')
    else
      let g:sf_app_name = substitute(file, '.*functional\/\(.*\)\/.*', '\1', 'g')
      let g:sf_module_name = substitute(file, '.*functional\/' . g:sf_app_name . '\/\(.*\)ActionsTest.php', '\1', 'g')
    endif

  if (exists("g:sf_root_dir"))
    call SetAppConfig()
    call SetModuleConfig()
  endif
endfunction

function! SetProjectConfig()
  let g:sf_config          = g:sf_root_dir . 'config/'
  let g:sf_batch           = g:sf_root_dir . 'batch/'
  let g:sf_lib             = g:sf_root_dir . 'lib/'
  let g:sf_lib_model       = g:sf_root_dir . 'lib/model/'
  let g:sf_model           = g:sf_config . 'schema.xml'
  let g:sf_data            = g:sf_root_dir . 'data/'
  let g:sf_ctags           = g:sf_data . '/vim.ctags'
endfunction

function! SetAppConfig()
  let g:sf_app             = g:sf_root_dir . 'apps/' . g:sf_app_name . '/'
  let g:sf_app_templates   = g:sf_app . 'templates/'
  let g:sf_app_modules     = g:sf_app . 'modules/'
  let g:sf_app_config      = g:sf_app . 'config/'
  let g:sf_test_dir        = g:sf_root_dir . 'test/'
  let g:sf_app_test_dir    = g:sf_test_dir . '/functional/' . g:sf_app_name . '/'
endfunction

function! SetModuleConfig()
  let g:sf_module            = g:sf_app_modules . g:sf_module_name .'/'
  let g:sf_module_actions    = g:sf_module . 'actions/actions.class.php'
  let g:sf_module_components = g:sf_module . 'actions/components.class.php'
  let g:sf_module_templates  = g:sf_module . 'templates/'
  let g:sf_module_config     = g:sf_module . 'config/'
  let g:sf_module_lib        = g:sf_module . 'lib/'
endfunction

" find the corresponding template file of the current function surrounding the cursor
function! FindCurrentAction()
  call cursor(line('.')+1, 0, 0)
  let lineno               = search('public function\ \(.*\)(.*)', 'nbe')
  let action               = matchstr(getline(lineno), '\zsexecute\(.*\)\ze(.*)')
  call cursor(line('.')-1, 0, 0)
  if (action != '')
    "let template_file_name   = tolower(action)."Success.php"
    "return template_file_name
    return action
  else 
    return ''
  endif
endfunction

" executeIndex => index
function! GetActionNameFromAction(action_name)
  let first_letter = matchstr(a:action_name, '\U\+\zs\u\ze.*')
  let remains      = matchstr(a:action_name, '\U\+\u\zs.*')
  return tolower(first_letter) . remains
endfunction

" indexSuccess.php => index
function! GetActionNameFromActionFileName(action_file_name)
  return matchstr(a:action_file_name, '\zs\U*\zeSuccess')
endfunction

" _index.php => index
function! GetComponentNameFromComponentFileName(component_file_name)
  return matchstr(a:component_file_name, '_\zs.*\ze\.')
endfunction


" index => indexSuccess.php
function! GetSuccessTemplateFromAction(action_name)
  return GetActionNameFromAction(a:action_name)."Success.php"
endfunction

" index => _index.php
function! GetSuccessTemplateFromComponent(component_name)
  return "_".GetActionNameFromAction(a:component_name.".php")
endfunction

" index => executeIndex
function! GetExecuteActionNameFromAction(action_name)
  return 'execute' . substitute(a:action_name, '^\(.\?\)', '\u\1\E', "g")
endfunction

function! IsAModule() 
  if (matchstr(expand('%:p'), 'apps\(/\|\\\).\{-}\(/\|\\\)modules\(/\|\\\).\{-}\(/\|\\\)') != '')
    return 1
  else 
    return ''
  endif
endfunction

function! IsAnAction() 
  if (matchstr(expand('%:p'), 'apps\(/\|\\\).\{-}\(/\|\\\)modules\(/\|\\\).\{-}\(/\|\\\)actions\(/\|\\\)actions.class.php') != '')
    return 1
  else 
    return ''
  endif
endfunction

function! IsAComponent() 
  if (matchstr(expand('%:p'), 'apps\(/\|\\\).\{-}\(/\|\\\)modules\(/\|\\\).\{-}\(/\|\\\)actions\(/\|\\\)components.class.php') != '')
    return 1
  else 
    return ''
  endif
endfunction

function! IsATest()
  if (matchstr(expand('%:t'), 'Test') != '')
    return 1
  else
    return '' 
  endif
endfunction

function! IsAComponentTemplate()
  if (matchstr(expand('%:p'), 'apps\(/\|\\\).\{-}\(/\|\\\)modules\(/\|\\\).\{-}\(/\|\\\)templates\(/\|\\\)_.\{-}.php') != '')
    return 1
  else 
    return ''
  endif
endfunction
  
function! IsAnActionTemplate()

endfunction

function! g:EchoError(msg)
    echohl errormsg
    echo a:msg
    echohl normal
endfunction

" switch from the template file to the corresponding function code of the action 
" and from the action to the corresponding template
function! Switch()
  
  if (!exists("g:sf_root_dir"))
    call SfPluginLoad(getcwd())
  endif
    
  if (IsAModule())

    if (FindCurrentAction() != '') 

      " we are in an action file so let's go the success template file

      let g:last_action_line = getpos('.')
      
      if (IsAnAction())
        if (g:last_template_line != [])
          exec 'edit ' . g:sf_module_templates.GetSuccessTemplateFromAction(FindCurrentAction())
          call cursor(g:last_template_line[1], g:last_template_line[2], 0)
        else
          exec 'edit ' . g:sf_module_templates.GetSuccessTemplateFromAction(FindCurrentAction())
        endif
      elseif (IsAComponent())
        if (g:last_template_line != [])
          exec 'edit ' . g:sf_module_templates.GetSuccessTemplateFromComponent(FindCurrentAction())
          call cursor(g:last_template_line[1], g:last_template_line[2], 0)
        else
          exec 'edit ' . g:sf_module_templates.GetSuccessTemplateFromComponent(FindCurrentAction())
        endif
      endif

      let g:last_template_line = []

    else
      " we are in a template or test so let's go the current module action/function
      
      let g:last_template_line = getpos('.')

      if (IsAComponentTemplate())
        if (g:last_action_line != [])
          exec 'edit ' . g:sf_module_components
          call cursor(g:last_action_line[1], g:last_action_line[2], 0)
        else
          exec 'edit +/' . GetExecuteActionNameFromAction(GetComponentNameFromComponentFileName(expand("%:t"))) .  ' ' . g:sf_module_components
        endif
      else
        if (g:last_action_line != [])
          exec 'edit ' . g:sf_module_actions 
          call cursor(g:last_action_line[1], g:last_action_line[2], 0)
        else
          exec 'edit +/' . GetExecuteActionNameFromAction(GetActionNameFromActionFileName(expand("%:t"))) .  ' ' . g:sf_module_actions 
        endif
      endif
      

      let g:last_action_line = []

      " jump to the last line of the function
      "call cursor(search('}')-1, 100, 0)
    endif

  else
    call g:EchoError("Not in a symfony module context, unable to switch view")
    return 0
  endif

endfunction

function! SfSwitchToTest()

  if (IsAComponent() || IsAnAction())
    let g:last_action_line = getpos('.')
    let g:last_action = expand("%:p")
    exec 'edit ' . g:sf_app_test_dir . g:sf_module_name . 'ActionsTest.php'
  elsei (IsATest())
    let g:last_test_line = getpos('.')

    if (exists("g:last_action"))
      exec 'edit ' . g:last_action
    else
      exec 'edit ' . g:sf_module_actions
    endif

    if (g:last_action_line != [])
      call cursor(g:last_action_line[1], g:last_action_line[2], 0)
    endif
  elsei (IsATest())
    let g:last_test_line = getpos('.')
  endif
endfunction

function! SfRunTest()
  if (!IsATest())
    return ''
  endif

  call SfCallCommandLine('test', 'functional', g:sf_app_name.' '.g:sf_module_name.'Actions')

endfunction

function! SfPluginLoad(path)
  if ( finddir('apps', a:path) != '') "&& (finddir('config', a:path) != '') && (finddir('lib', a:path) != '') && (finddir('web', a:path) != '')
    let g:sf_root_dir = a:path.'/'
    exec(':cd '.g:sf_root_dir)
    call ReconfigPaths()
  endif

  if exists("g:sf_root_dir")
    :call SetProjectConfig()
    :call SetAppConfig()
    :call SetModuleConfig()
 
   " Use our ctags file if one exists
    if exists("g:sf_ctags")
      if filereadable(g:sf_ctags)
        " All symfony files should be in project directory, so just replace
        " the stack
        exec 'set tags=' . g:sf_ctags
      endif
    endif
  endif
 
  let g:sf_extra_dir = $HOME."/.vim/symfony"
  if filereadable(g:sf_extra_dir."/utils.vim")
    source ~/.vim/symfony/utils.vim
  endif
endfunction

" Set all commands
command! -complete=dir SfCreateAction :call SfCreateAction(expand('<cword>'))
command! -n=? -complete=dir SfSwitchView :call Switch()
command! SfSwitchToTest :call SfSwitchToTest()
command! -nargs=1 -complete=dir SfPluginLoad :call SfPluginLoad(<args>)
command! SfMenu :call SfMenu()
command! SfClearCache :call SfClearCache()
command! SfRunTest :call SfRunTest()


let g:sf_app_name      = ""
let g:sf_module_name   = "" 

let g:last_template_line = []
let g:last_action_line = []

autocmd BufEnter,BufLeave,BufWipeout * call SfPluginLoad(getcwd())  " Automatically reload .vimrc when changing
