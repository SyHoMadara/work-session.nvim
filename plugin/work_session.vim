if exists('g:loaded_work_session') | finish | endif
let g:loaded_work_session = 1

command! WorkSession lua require("work_session").open_menu()
