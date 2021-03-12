#!/bin/bash

WorkspaceDir=.
ChapterName=1
QuestionName=1
UsedEditor=vim
SelectedLanguage=c
TempFile=".${RANDOM}code.tmp"

declare -A Language=(
    [c]=".c@gcc %1%.c -o %1%.out"
    [cpp]=".cpp@g++ %1%.cpp -o %1%.out"
)
declare -A TEMPLETE_FILE=(
    [c]="#include <stdio.h>\n\nint main() {\t\n\n}"
    [cpp]="#include <cstdio>\n#include <iostream>\n\nusing namespace std;\nint main() {\t\n\n}"
)
declare -A ERR_MSGS=(
    [compile_error]="代码出错，请重新编辑。"
    [lang_not_exist]="选择的语言不存在!"
    [wrong_answer]="错误反馈，请重新编辑。"
)
declare -A CONFIRM_MSGS=(
    [0]="（按下空格或回车键确认，按其他键取消）"
    [1]="（按任意键继续）"
    [run]="编译成功，开始测试?"
    [after_complie]="测试结束，是否通过?"
    [next_chapter]="开启下一章?"
)
declare -A INIT_MSGS=(
    [workdir]="输入工作目录: "
    [chapter]="输入章节号: "
    [question]="输入题号: "
    [lang]="选择使用的语言: "
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

tool::SelectLang() {
    local _lang=
    while true; do
        read -p ${INIT_MSGS[lang]} -a _lang
        if [ -n "${Language[$_lang]}" ]; then
            SelectedLanguage=${_lang}
            break
        else
            _error lang_not_exist 1
        fi
    done
}

tool::RefreshTmp() {
    rm ${WorkspaceDir:-.}/${TempFile} 2> /dev/null
    rm ${WorkspaceDir:-.}/${TempFile}.out 2> /dev/null
    echo -e ${TEMPLETE_FILE[${SelectedLanguage}]} > ${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*}
}

tool::Coding() {
    ${UsedEditor} ${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*}
}

tool::Compile() {
    local _cmd=${Language[${SelectedLanguage}]#*@}
    clear
    ${_cmd//%1%/${TempFile}}
    if [[ $? != 0 ]]; then
        _error compile_error 1
        return 1
    fi
    if _confirm run; then
        chmod +x ${WorkspaceDir:-.}/${TempFile}.out
        ${WorkspaceDir:-.}/${TempFile}.out
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
    cp ${WorkspaceDir:-.}/${TempFile}${Language[${SelectedLanguage}]%%@*} ${WorkspaceDir:-.}/${ChapterName}-${QuestionName}${Language[${SelectedLanguage}]%%@*}
    rm ${WorkspaceDir:-.}/${TempFile}.out
    if _confirm after_complie; then
        return
    else
        return 1
    fi
}

tool::SwitchQuestion() {
    tool::RefreshTmp    clear
    if _confirm next_chapter; then
        QuestionName=1
        ChapterName=$(expr ${ChapterName} + 1)
    else
        QuestionName=$(expr ${QuestionName} + 1)
    fi
}

# Main
# read -p ${INIT_MSGS[workdir]} -a WorkspaceDir
read -p ${INIT_MSGS[chapter]} -a ChapterName
read -p ${INIT_MSGS[question]} -a QuestionName

tool::SelectLang
tool::RefreshTmp
while tool::Coding; do
    if tool::Compile; then
        if tool::AfterCompile; then
            tool::SwitchQuestion
        fi
    fi
done
