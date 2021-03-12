#!/bin/bash

WorkspaceDir=.
ChapterName=1
QuestionName=1
UsedEditor=vim
SelectedLanguage=c
TempFile=".oj_assistant.${RANDOM}.tmp"

declare -A Language=(
    [c]=".c@gcc %1%.c -o %1%.out"
    [cpp]=".cpp@g++ %1%.cpp -o %1%.out"
)
declare -A TEMPLETE_FILE=(
    [c]="#include <stdio.h>\n\nint main() {\n\t\n}"
    [cpp]="#include <cstdio>\n#include <iostream>\n\nusing namespace std;\nint main() {\n\t\n}"
)
declare -A ERR_MSGS=(
    [compile_error]="代码出错，请重新编辑。"
    [lang_not_exist]="选择的语言不存在!"
    [wrong_answer]="错误反馈，请重新编辑。"
    [nan]="输入的值不是一个数字。"
)
declare -A CONFIRM_MSGS=(
    [0]="（按下空格或回车键确认，按其他键取消）"
    [1]="（按任意键继续）"
    [run]="编译成功，开始测试?"
    [after_complie]="测试结束，是否通过?"
    [next_chapter]="开启下一章?"
)
declare -A OTHER_MSGS=(
    [workdir]="输入工作目录: "
    [chapter]="输入章节号: "
    [question]="输入题号: "
    [lang]="选择使用的语言: "
    [now]="当前题号 -> "
)

_error() {
    echo -e "\e[31mERROR\e[0m: ${ERR_MSGS[$1]}"
    if [ -n "$2" ]; then
        read -s -n 1 -p ${CONFIRM_MSGS[1]}
        echo
    fi
    false
}

_confirm() {
    local _reg=
    echo -e "\e[36mINTERACTIVE\e[0m: ${CONFIRM_MSGS[$1]}"
    read -p ${CONFIRM_MSGS[0]} -n 1 -r -s -a _reg
    echo
    case ${_reg} in
        ' '|'')
            true
            ;;
        *)
            false
            ;;
    esac
}

tool::CheckNum() {
    if expr $1 + 10 &> /dev/null; then
        true
    else
        false
    fi
    
}

tool::SelectLang() {
    local _lang=
    while true; do
        read -p ${OTHER_MSGS[lang]} -a _lang
        if [ -n "${Language[$_lang]}" ]; then
            SelectedLanguage=${_lang}
            break
        else
            _error lang_not_exist 1
        fi
    done
}

tool::RefreshTmp() {
    rm ./${WorkspaceDir:-.}/${TempFile} 2> /dev/null
    rm ./${WorkspaceDir:-.}/${TempFile}.out 2> /dev/null
    echo -e ${TEMPLETE_FILE[${SelectedLanguage}]} > ./${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*}
}

tool::ShowNow() {
    echo -e "\e[33mINFO\e[0m: ${OTHER_MSGS[now]}${ChapterName}-${QuestionName}"
}

tool::Coding() {
    ${UsedEditor} ./${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*}
}

tool::Compile() {
    local _cmd=${Language[${SelectedLanguage}]#*@}
    clear
    tool::ShowNow
    cd ./${WorkspaceDir}
    ${_cmd//%1%/${TempFile}}
    cd - 2>&1 1> /dev/null
    if [[ $? != 0 ]]; then
        _error compile_error 1
        return 1
    fi
    if _confirm run; then
        chmod +x ./${WorkspaceDir:-.}/${TempFile}.out
        ./${WorkspaceDir:-.}/${TempFile}.out
        echo
        if [[ $? == 0 ]]; then
            return
        else
            _error wrong_answer 1
        fi
    else
        return 1
    fi
}

tool::AfterCompile() {
    clear
    tool::ShowNow
    cp ./${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*} ./${WorkspaceDir:-.}/${ChapterName}-${QuestionName}${Language[${SelectedLanguage}]%%@*}
    rm ./${WorkspaceDir:-.}/${TempFile}.out
    if _confirm after_complie; then
        return
    else
        return 1
    fi
}

tool::SwitchQ[./src/1.png]uestion() {
    tool::RefreshTmp    clear
    if _confirm next_chapter; then
        QuestionName=1
        ChapterName=$(expr ${ChapterName} + 1)
    else
        QuestionName=$(expr ${QuestionName} + 1)
    fi
}

# Main
read -p ${OTHER_MSGS[workdir]} -a WorkspaceDir
mkdir -p ./${WorkspaceDir}
while read -p ${OTHER_MSGS[chapter]} -a _num; do
    if tool::CheckNum ${_num}; then
        ChapterName=${_num}
        break
    fi
    _error nan
done
unset _num
while read -p ${OTHER_MSGS[question]} -a _num; do
    if tool::CheckNum ${_num}; then
        QuestionName=${_num}
        break
    fi
    _error nan
done

tool::SelectLang
tool::RefreshTmp
while tool::Coding; do
    if tool::Compile; then
        if tool::AfterCompile; then
            tool::SwitchQuestion
        fi
    fi
done
