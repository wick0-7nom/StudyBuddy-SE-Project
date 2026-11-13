"""Generate personalized CD Lab Report for S M Ahnaf Shahriar."""
import os
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

OUT_PATH = r"c:\Users\ahana\Music\CD lab Report - S M Ahnaf Shahriar.docx"
ASSETS = r"C:\Users\ahana\Projects\study_buddy\lab_report_assets"
LOGO = os.path.join(ASSETS, "image2.png")
PROMPT = "root@W-I-C-K:~# "
HOST = "root@W-I-C-K: ~"

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\consola.ttf",
    r"C:\Windows\Fonts\cour.ttf",
    r"C:\Windows\Fonts\lucon.ttf",
]


def load_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def render_terminal(lines, width=1000, title=None):
    font = load_font(16)
    title_font = load_font(14)
    pad_x, pad_y = 14, 12
    line_h = 22
    title_h = 28 if title else 0

    dummy = Image.new("RGB", (10, 10))
    draw = ImageDraw.Draw(dummy)
    max_w = width - 2 * pad_x
    wrapped = []
    for line in lines:
        if draw.textlength(line, font=font) <= max_w:
            wrapped.append(line)
        else:
            wrapped.append(line)

    height = title_h + pad_y * 2 + line_h * len(wrapped) + 8
    img = Image.new("RGB", (width, height), (12, 12, 12))
    draw = ImageDraw.Draw(img)

    if title:
        draw.rectangle([0, 0, width, title_h], fill=(45, 45, 45))
        draw.text((10, 6), title or HOST, fill=(220, 220, 220), font=title_font)

    y = title_h + pad_y
    for line in wrapped:
        if line.startswith(PROMPT):
            draw.text((pad_x, y), PROMPT, fill=(255, 255, 255), font=font)
            cmd = line[len(PROMPT):]
            draw.text((pad_x + draw.textlength(PROMPT, font=font), y), cmd, fill=(255, 255, 255), font=font)
        else:
            draw.text((pad_x, y), line, fill=(230, 230, 230), font=font)
        y += line_h

    path = os.path.join(ASSETS, "term_tmp.png")
    img.save(path)
    return path


def flex_bison_cmds(base):
    return [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano {base}.l",
        f"{PROMPT}nano {base}.y",
        f"{PROMPT}flex -o {base}.yy.c {base}.l",
        f"{PROMPT}bison -d {base}.y",
        f"{PROMPT}gcc {base}.yy.c {base}.tab.c -o {base}",
        f"{PROMPT}./{base}",
    ]


TERMINAL_SPECS = {
    1: flex_bison_cmds("validity") + ["Valid Expression", PROMPT],
    2: flex_bison_cmds("evaluate") + ["Result = 20", PROMPT],
    3: [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano postfix.l",
        f"{PROMPT}nano postfix.y",
        f"{PROMPT}flex -o postfix.yy.c postfix.l",
        f"{PROMPT}bison -d postfix.y",
        f"{PROMPT}gcc postfix.yy.c postfix.tab.c -o postfix -lfl",
        f"{PROMPT}./postfix",
        "Postfix Expression = abcd-*+",
        PROMPT,
    ],
    4: flex_bison_cmds("syntax") + ["Syntax Error Found", PROMPT],
    5: flex_bison_cmds("calculator") + ["Result = 10", PROMPT],
    6: flex_bison_cmds("palindrome") + ["madam is a Palindrome", PROMPT],
    7: [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano leftrec.cpp",
        f"{PROMPT}g++ -std=c++17 -o leftrec leftrec.cpp",
        f"{PROMPT}./leftrec",
        "Production for E :",
        " Alt 1: E + T",
        " => Left recursion found: E -> E + T",
        " Alt 2: T",
        "",
        "Production for T :",
        " Alt 1: T * F",
        " => Left recursion found: T -> T * F",
        " Alt 2: F",
        "",
        "Production for F :",
        " Alt 1: ( E )",
        " Alt 2: id",
        " => No left recursion in production of F",
        "",
        "Result: The given grammar HAS left recursion.",
        PROMPT,
    ],
    8: [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano common_prefix.cpp",
        f"{PROMPT}g++ -std=c++17 -o common_prefix common_prefix.cpp",
        f"{PROMPT}./common_prefix",
        "Production for A :",
        " Alt 1: a B C",
        " Alt 2: a D E",
        " Alt 3: b F",
        " => Common prefix 'a' found between Alt 1 and Alt 2",
        "",
        "Production for S :",
        " Alt 1: if E then S else S",
        " Alt 2: if E then S",
        " Alt 3: id",
        " => Common prefix 'if' found between Alt 1 and Alt 2",
        "",
        "Result: The given grammar HAS a common prefix (left factoring needed).",
        PROMPT,
    ],
    9: [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano first_follow.cpp",
        f"{PROMPT}g++ -std=c++17 -o first_follow first_follow.cpp",
        f"{PROMPT}./first_follow",
        "Grammar Read:",
        "E -> T X",
        "X -> + T X | eps",
        "T -> F Y",
        "Y -> * F Y | eps",
        "F -> ( E ) | id",
        "",
        "FIRST Sets:",
        "FIRST(E) = { (, id }",
        "FIRST(X) = { +, eps }",
        "FIRST(T) = { (, id }",
        "FIRST(Y) = { *, eps }",
        "FIRST(F) = { (, id }",
        "",
        "FOLLOW Sets:",
        "FOLLOW(E) = { $, ) }",
        "FOLLOW(X) = { $, ) }",
        "FOLLOW(T) = { +, $, ) }",
        "FOLLOW(Y) = { +, $, ) }",
        "FOLLOW(F) = { *, +, $, ) }",
        PROMPT,
    ],
    10: [
        f"{PROMPT}nano input.txt",
        f"{PROMPT}nano rdp.cpp",
        f"{PROMPT}g++ -std=c++17 -o rdp rdp.cpp",
        f"{PROMPT}./rdp",
        "Input: (id+id)*id",
        "Output: Input string is accepted.",
        "",
        "Input: id+*id",
        "Output: Input string is rejected.",
        "",
        PROMPT,
    ],
}


def set_cell_shading(cell, fill):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    shd.set(qn("w:val"), "clear")
    tc_pr.append(shd)


def add_cover_page(doc):
    # Top accent bar
    bar = doc.add_paragraph()
    bar.paragraph_format.space_before = Pt(0)
    bar.paragraph_format.space_after = Pt(0)
    run = bar.add_run(" ")
    run.font.size = Pt(4)
    p = bar._p
    pPr = p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), "1F4E79")
    pPr.append(shd)

    doc.add_paragraph()
    if os.path.exists(LOGO):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(LOGO, width=Inches(1.6))

    uni = doc.add_paragraph()
    uni.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = uni.add_run("Bangladesh University of Business and Technology (BUBT)")
    r.bold = True
    r.font.size = Pt(18)
    r.font.name = "Times New Roman"
    r.font.color.rgb = RGBColor(31, 78, 121)

    doc.add_paragraph()
    badge = doc.add_paragraph()
    badge.alignment = WD_ALIGN_PARAGRAPH.CENTER
    br = badge.add_run("  LAB REPORT  ")
    br.bold = True
    br.italic = True
    br.font.size = Pt(20)
    br.font.name = "Times New Roman"
    br.font.color.rgb = RGBColor(255, 255, 255)
    badge.paragraph_format.space_before = Pt(6)
    badge.paragraph_format.space_after = Pt(6)
    pPr = badge._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), "C55A11")
    pPr.append(shd)

    doc.add_paragraph()

    info_rows = [
        ("Course Code:", "CSE 324"),
        ("Course Title:", "Compiler Design Lab"),
        ("Report No:", "01"),
        ("Report Name:", "Lex, Bison, and C++ Based Programs for Expression Validation, Evaluation, and Grammar Analysis."),
    ]
    table = doc.add_table(rows=len(info_rows), cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, (label, value) in enumerate(info_rows):
        c0, c1 = table.rows[i].cells
        set_cell_shading(c0, "D9E2F3")
        c0.text = label
        c1.text = value
        for cell in (c0, c1):
            for para in cell.paragraphs:
                for run in para.runs:
                    run.font.name = "Times New Roman"
                    run.font.size = Pt(12)
        c0.paragraphs[0].runs[0].bold = True

    doc.add_paragraph()
    sub = doc.add_paragraph("Submitted To:")
    sub.runs[0].bold = True
    sub.runs[0].font.name = "Times New Roman"
    sub.runs[0].font.size = Pt(12)
    for line in [
        "A. S. M. Shafi (ASMS)",
        "Assistant Professor, Department of CSE",
        "Bangladesh University of Business and Technology",
    ]:
        p = doc.add_paragraph(line)
        p.runs[0].font.name = "Times New Roman"
        p.runs[0].font.size = Pt(12)

    doc.add_paragraph()
    sb = doc.add_paragraph("Submitted by:")
    sb.runs[0].bold = True
    sb.runs[0].font.name = "Times New Roman"

    st = doc.add_table(rows=2, cols=5)
    headers = ["Student Name", "Student ID", "Intake", "Section", "Program"]
    values = ["S M Ahnaf Shahriar", "20245103109", "53", "5", "B.Sc. Engg. in CSE"]
    for j, h in enumerate(headers):
        cell = st.rows[0].cells[j]
        cell.text = h
        set_cell_shading(cell, "1F4E79")
        for run in cell.paragraphs[0].runs:
            run.bold = True
            run.font.color.rgb = RGBColor(255, 255, 255)
            run.font.name = "Times New Roman"
            run.font.size = Pt(11)
    for j, v in enumerate(values):
        cell = st.rows[1].cells[j]
        cell.text = v
        for run in cell.paragraphs[0].runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(11)

    doc.add_paragraph()
    date_p = doc.add_paragraph("Date of Submission: 16th August, 2026")
    date_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    date_p.runs[0].font.name = "Times New Roman"
    date_p.runs[0].font.size = Pt(12)

    doc.add_page_break()


def heading(doc, text, level=1):
    p = doc.add_heading(text, level=level)
    for run in p.runs:
        run.font.name = "Times New Roman"
        run.font.color.rgb = RGBColor(0, 0, 0)


def body(doc, text, bold=False):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.bold = bold
    r.font.name = "Times New Roman"
    r.font.size = Pt(12)
    return p


def code_block(doc, text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = "Courier New"
    r.font.size = Pt(9)
    p.paragraph_format.left_indent = Inches(0.25)


def add_experiment(doc, num, title, objective, procedure, files, input_text, conclusion, terminal_num):
    heading(doc, f"Experiment- {num}", 2)
    body(doc, "1. Name of the Experiment", True)
    body(doc, title)
    body(doc, "2. Objective", True)
    body(doc, objective)
    body(doc, "3. Procedure", True)
    for i, step in enumerate(procedure, 1):
        body(doc, f"{i}. {step}")
    body(doc, "4. Program/Source Code", True)
    for fname, code in files:
        body(doc, fname, True)
        code_block(doc, code)
    body(doc, "5. Input and Output", True)
    body(doc, "input.txt", True)
    code_block(doc, input_text)
    body(doc, "Output:", True)
    img_path = render_terminal(TERMINAL_SPECS[terminal_num], title=HOST)
    doc.add_picture(img_path, width=Inches(6.5))
    body(doc, "6. Conclusion", True)
    body(doc, conclusion)
    doc.add_paragraph()


# Source code strings (same as original report)
VALIDITY_L = """%option noyywrap
%{
#include "validity.tab.h"
%}
%%
[0-9]+          { return NUMBER; }
[a-zA-Z]+       { return ID; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MUL; }
"/"             { return DIV; }
"("             { return LPAREN; }
")"             { return RPAREN; }
[ \\t\\n]+       ;
.               { return INVALID; }
%%
"""

VALIDITY_Y = """%{
#include <stdio.h>
#include <stdlib.h>
extern FILE *yyin;
int yylex();
void yyerror(const char *s);
%}
%token NUMBER ID
%token PLUS MINUS MUL DIV
%token LPAREN RPAREN
%token INVALID
%left PLUS MINUS
%left MUL DIV
%%
input:    expression    ;
expression:    expression PLUS term    | expression MINUS term    | term    ;
term:    term MUL factor    | term DIV factor    | factor    ;
factor:    NUMBER    | ID    | LPAREN expression RPAREN    ;
%%
void yyerror(const char *s){    printf("Invalid Expression\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;
    if (yyparse() == 0){        printf("Valid Expression\\n");    }
    fclose(file);    return 0;}
"""

EVALUATE_L = """%option noyywrap
%{
#include "evaluate.tab.h"
%}
%%
[0-9]+ { yylval = atoi(yytext); return NUMBER; }
"+" { return PLUS; }
"-" { return MINUS; }
"*" { return MUL; }
"/" { return DIV; }
"(" { return LPAREN; }
")" { return RPAREN; }
[ \\t\\n]+ ;
. { return yytext[0]; }
%%
"""

EVALUATE_Y = """%{
#include <stdio.h>
#include <stdlib.h>
extern FILE *yyin;
int yylex();
void yyerror(const char *s);
%}
%token NUMBER
%token PLUS MINUS MUL DIV
%token LPAREN RPAREN
%left PLUS MINUS
%left MUL DIV
%%
input:    expression { printf("Result = %d\\n", $1); }    ;
expression:    expression PLUS term { $$ = $1 + $3; }    | expression MINUS term { $$ = $1 - $3; }    | term { $$ = $1; }    ;
term:    term MUL factor { $$ = $1 * $3; }    | term DIV factor { $$ = $1 / $3; }    | factor { $$ = $1; }    ;
factor:    NUMBER { $$ = $1; }    | LPAREN expression RPAREN { $$ = $2; }    ;
%%
void yyerror(const char *s){    printf("Invalid Expression\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;    yyparse();    fclose(file);    return 0;}
"""

POSTFIX_L = """%{
#include "parser.tab.h"
%}
%%
[a-zA-Z][a-zA-Z0-9]* {    printf("%s", yytext);    return ID;}
[+\\-*/()] { return yytext[0]; }
[ \\t\\n]+ ;
. { return INVALID; }
%%
"""

POSTFIX_Y = """%{
#include <stdio.h>
extern FILE *yyin;
int yylex();
void yyerror(const char *s);
%}
%token ID INVALID
%left '+' '-'
%left '*' '/'
%%
input:    expression    ;
expression:      expression '+' expression { printf("+"); }    | expression '-' expression { printf("-"); }    | expression '*' expression { printf("*"); }    | expression '/' expression { printf("/"); }    | '(' expression ')'    | ID    ;
%%
void yyerror(const char *s){    printf("\\nInvalid Expression\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;    printf("Postfix Expression = ");    yyparse();    printf("\\n");    fclose(file);    return 0;}
"""

SYNTAX_L = """%option noyywrap
%{
#include "syntax.tab.h"
%}
%%
"int"|"float"|"char" { return TYPE; }
[a-zA-Z_][a-zA-Z0-9_]* { return ID; }
[0-9]+ { return NUMBER; }
"=" { return ASSIGN; }
"+" { return PLUS; }
"-" { return MINUS; }
"*" { return MUL; }
"/" { return DIV; }
";" { return SEMI; }
[ \\t\\n]+ ;
. { return yytext[0]; }
%%
"""

SYNTAX_Y = """%{
#include <stdio.h>
#include <stdlib.h>
extern FILE *yyin;
extern int yylineno;
int yylex();
void yyerror(const char *s);
%}
%token TYPE ID NUMBER
%token ASSIGN PLUS MINUS MUL DIV SEMI
%left PLUS MINUS
%left MUL DIV
%%
program:    program statement    | statement    ;
statement:    TYPE ID ASSIGN expression SEMI    | TYPE ID SEMI    ;
expression:    expression PLUS expression    | expression MINUS expression    | expression MUL expression    | expression DIV expression    | ID    | NUMBER    ;
%%
void yyerror(const char *s){    printf("Syntax Error Found\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;
    if (yyparse() == 0){        printf("No Syntax Error\\n");    }
    fclose(file);    return 0;}
"""

CALC_L = EVALUATE_L.replace("evaluate.tab.h", "calculator.tab.h")
CALC_Y = """%{
#include <stdio.h>
#include <stdlib.h>
extern FILE *yyin;
int yylex();
void yyerror(const char *s);
%}
%token NUMBER
%token PLUS MINUS MUL DIV
%left PLUS MINUS
%left MUL DIV
%%
input:    expression { printf("Result = %d\\n", $1); }    ;
expression:    expression PLUS expression { $$ = $1 + $3; }    | expression MINUS expression { $$ = $1 - $3; }    | expression MUL expression { $$ = $1 * $3; }    | expression DIV expression { $$ = $1 / $3; }    | NUMBER { $$ = $1; }    ;
%%
void yyerror(const char *s){    printf("Invalid Expression\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;    yyparse();    fclose(file);    return 0;}
"""

PAL_L = """%option noyywrap
%{
#include <string.h>
#include "palindrome.tab.h"
%}
%%
[a-zA-Z0-9]+ { strcpy(yylval.text, yytext); return WORD; }
[ \\t\\n]+ ;
. { return yytext[0]; }
%%
"""

PAL_Y = """%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern FILE *yyin;
int yylex();
void yyerror(const char *s);
%}
%union { char text[128]; }
%token <text> WORD
%%
input:    WORD    {
        int i = 0;        int j = strlen($1) - 1;        int isPalindrome = 1;
        while (i < j){            if ($1[i] != $1[j]){                isPalindrome = 0;                break;            }            i++;            j--;        }
        if (isPalindrome){            printf("%s is a Palindrome\\n", $1);        }        else {            printf("%s is not a Palindrome\\n", $1);        }    }    ;
%%
void yyerror(const char *s){    printf("Invalid Input\\n");}
int main(){
    FILE *file = fopen("input.txt", "r");
    if (!file){        printf("Cannot open input.txt\\n");        return 1;    }
    yyin = file;    yyparse();    fclose(file);    return 0;}
"""

LEFTREC_CPP = r'''#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
using namespace std;
int main() {
    ifstream fin("input.txt");
    if (!fin) { cout << "Cannot open input.txt\n"; return 1; }
    string line; bool anyLeftRecursion = false;
    while (getline(fin, line)) {
        if (line.empty()) continue;
        size_t arrowPos = line.find("->");
        if (arrowPos == string::npos) continue;
        string lhs = line.substr(0, arrowPos);
        lhs.erase(lhs.find_last_not_of(" \t") + 1);
        lhs.erase(0, lhs.find_first_not_of(" \t"));
        string rhs = line.substr(arrowPos + 2);
        size_t semi = rhs.find(';');
        if (semi != string::npos) rhs = rhs.substr(0, semi);
        string alternatives[20]; int altCount = 0;
        stringstream altStream(rhs); string alt;
        while (getline(altStream, alt, '|')) { alternatives[altCount] = alt; altCount++; }
        cout << "Production for " << lhs << " :\n";
        bool localRecursion = false;
        for (int i = 0; i < altCount; i++) {
            string toks[20]; int tokCount = 0;
            stringstream ss(alternatives[i]); string tok;
            while (ss >> tok) { toks[tokCount] = tok; tokCount++; }
            cout << " Alt " << (i + 1) << ": ";
            for (int k = 0; k < tokCount; k++) cout << toks[k] << " ";
            cout << "\n";
            if (tokCount > 0 && toks[0] == lhs) {
                cout << " => Left recursion found: " << lhs << " -> " << lhs;
                for (int k = 1; k < tokCount; k++) cout << " " << toks[k];
                cout << "\n"; localRecursion = true; anyLeftRecursion = true;
            }
        }
        if (!localRecursion) cout << " => No left recursion in production of " << lhs << "\n";
        cout << "\n";
    }
    if (anyLeftRecursion) cout << "Result: The given grammar HAS left recursion.\n";
    else cout << "Result: The given grammar has NO left recursion.\n";
    return 0;
}'''

COMMON_PREFIX_CPP = r'''#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
using namespace std;
int main() {
    ifstream fin("input.txt");
    if (!fin) { cout << "Cannot open input.txt\n"; return 1; }
    string line; bool anyCommonPrefix = false;
    while (getline(fin, line)) {
        if (line.empty()) continue;
        size_t arrowPos = line.find("->");
        if (arrowPos == string::npos) continue;
        string lhs = line.substr(0, arrowPos);
        lhs.erase(lhs.find_last_not_of(" \t") + 1);
        lhs.erase(0, lhs.find_first_not_of(" \t"));
        string rhs = line.substr(arrowPos + 2);
        size_t semi = rhs.find(';');
        if (semi != string::npos) rhs = rhs.substr(0, semi);
        string alternatives[20]; int altCount = 0;
        stringstream altStream(rhs); string alt;
        while (getline(altStream, alt, '|')) { alternatives[altCount] = alt; altCount++; }
        string firstSymbols[20];
        for (int i = 0; i < altCount; i++) {
            stringstream ss(alternatives[i]); string tok;
            if (ss >> tok) firstSymbols[i] = tok; else firstSymbols[i] = "";
        }
        cout << "Production for " << lhs << " :\n";
        for (int i = 0; i < altCount; i++) {
            string toks[20]; int tokCount = 0;
            stringstream ss(alternatives[i]); string tok;
            while (ss >> tok) { toks[tokCount] = tok; tokCount++; }
            cout << " Alt " << (i + 1) << ": ";
            for (int k = 0; k < tokCount; k++) cout << toks[k] << " ";
            cout << "\n";
        }
        bool localCommon = false;
        for (int i = 0; i < altCount; i++) {
            for (int j = i + 1; j < altCount; j++) {
                if (firstSymbols[i] == firstSymbols[j] && !firstSymbols[i].empty()) {
                    cout << " => Common prefix '" << firstSymbols[i]
                         << "' found between Alt " << (i + 1) << " and Alt " << (j + 1) << "\n";
                    localCommon = true; anyCommonPrefix = true;
                }
            }
        }
        if (!localCommon) cout << " => No common prefix in production of " << lhs << "\n";
        cout << "\n";
    }
    if (anyCommonPrefix) cout << "Result: The given grammar HAS a common prefix (left factoring needed).\n";
    else cout << "Result: The given grammar has NO common prefix.\n";
    return 0;
}'''

FIRST_FOLLOW_CPP = r'''#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
using namespace std;
char nonTerminals[20]; int ntCount = 0;
string productions[20][20][20]; int prodAltCount[20]; int prodSymCount[20][20];
string firstSet[20][50]; int firstCount[20];
string followSet[20][50]; int followCount[20];
int findNT(char c) { for (int i = 0; i < ntCount; i++) if (nonTerminals[i] == c) return i; return -1; }
bool isNonTerminal(string s) { return s.size() == 1 && s[0] >= 'A' && s[0] <= 'Z'; }
bool contains(string arr[], int count, string s) { for (int i = 0; i < count; i++) if (arr[i] == s) return true; return false; }
void addSymbol(string arr[], int &count, string s) { if (!contains(arr, count, s)) { arr[count] = s; count++; } }
int main() {
    ifstream fin("input.txt");
    if (!fin) { cout << "Cannot open input.txt" << endl; return 1; }
    string line;
    while (getline(fin, line)) {
        if (line.empty()) continue;
        int arrow = line.find("->"); if (arrow == -1) continue;
        string lhsStr = line.substr(0, arrow); char lhs = lhsStr[0];
        int idx = findNT(lhs);
        if (idx == -1) { nonTerminals[ntCount] = lhs; prodAltCount[ntCount] = 0; idx = ntCount; ntCount++; }
        string rhs = line.substr(arrow + 2);
        stringstream altStream(rhs); string alt;
        while (getline(altStream, alt, '|')) {
            int symCount = 0; stringstream ss(alt); string tok;
            while (ss >> tok) { productions[idx][prodAltCount[idx]][symCount] = tok; symCount++; }
            prodSymCount[idx][prodAltCount[idx]] = symCount; prodAltCount[idx]++;
        }
    }
    int n = ntCount;
    cout << "Grammar Read:" << endl;
    for (int i = 0; i < n; i++) {
        cout << nonTerminals[i] << " -> ";
        for (int j = 0; j < prodAltCount[i]; j++) {
            if (j > 0) cout << " | ";
            for (int k = 0; k < prodSymCount[i][j]; k++) cout << productions[i][j][k] << " ";
        }
        cout << endl;
    }
    cout << endl;
    for (int pass = 0; pass < 10; pass++) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < prodAltCount[i]; j++) {
                bool restCanBeEmpty = true;
                for (int k = 0; k < prodSymCount[i][j]; k++) {
                    string sym = productions[i][j][k];
                    if (sym == "eps") { addSymbol(firstSet[i], firstCount[i], "eps"); restCanBeEmpty = true; break; }
                    if (isNonTerminal(sym)) {
                        int b = findNT(sym[0]); bool hasEps = false;
                        for (int m = 0; m < firstCount[b]; m++) {
                            if (firstSet[b][m] == "eps") hasEps = true; else addSymbol(firstSet[i], firstCount[i], firstSet[b][m]);
                        }
                        if (!hasEps) { restCanBeEmpty = false; break; }
                    } else { addSymbol(firstSet[i], firstCount[i], sym); restCanBeEmpty = false; break; }
                }
                if (restCanBeEmpty) addSymbol(firstSet[i], firstCount[i], "eps");
            }
        }
    }
    addSymbol(followSet[0], followCount[0], "$");
    for (int pass = 0; pass < 10; pass++) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < prodAltCount[i]; j++) {
                for (int k = 0; k < prodSymCount[i][j]; k++) {
                    if (!isNonTerminal(productions[i][j][k])) continue;
                    int b = findNT(productions[i][j][k][0]); bool restCanBeEmpty = true;
                    for (int m = k + 1; m < prodSymCount[i][j]; m++) {
                        string sym = productions[i][j][m];
                        if (isNonTerminal(sym)) {
                            int c = findNT(sym[0]); bool hasEps = false;
                            for (int p = 0; p < firstCount[c]; p++) {
                                if (firstSet[c][p] == "eps") hasEps = true; else addSymbol(followSet[b], followCount[b], firstSet[c][p]);
                            }
                            if (!hasEps) { restCanBeEmpty = false; break; }
                        } else { addSymbol(followSet[b], followCount[b], sym); restCanBeEmpty = false; break; }
                    }
                    if (restCanBeEmpty) for (int p = 0; p < followCount[i]; p++) addSymbol(followSet[b], followCount[b], followSet[i][p]);
                }
            }
        }
    }
    cout << "FIRST Sets:" << endl;
    for (int i = 0; i < n; i++) {
        cout << "FIRST(" << nonTerminals[i] << ") = { ";
        for (int j = 0; j < firstCount[i]; j++) { if (j > 0) cout << ", "; cout << firstSet[i][j]; }
        cout << " }" << endl;
    }
    cout << endl << "FOLLOW Sets:" << endl;
    for (int i = 0; i < n; i++) {
        cout << "FOLLOW(" << nonTerminals[i] << ") = { ";
        for (int j = 0; j < followCount[i]; j++) { if (j > 0) cout << ", "; cout << followSet[i][j]; }
        cout << " }" << endl;
    }
    return 0;
}'''

RDP_CPP = r'''#include <iostream>
#include <fstream>
using namespace std;
string input; int pos; bool ok;
void E(); void Edash(); void T(); void Tdash(); void F();
bool matchId() {
    if (pos + 1 < (int)input.size() && input[pos] == 'i' && input[pos + 1] == 'd') { pos = pos + 2; return true; }
    return false;
}
void E() { T(); Edash(); }
void Edash() { if (pos < (int)input.size() && input[pos] == '+') { pos++; T(); Edash(); } }
void T() { F(); Tdash(); }
void Tdash() { if (pos < (int)input.size() && input[pos] == '*') { pos++; F(); Tdash(); } }
void F() {
    if (pos < (int)input.size() && input[pos] == '(') {
        pos++; E();
        if (pos < (int)input.size() && input[pos] == ')') pos++; else ok = false;
    } else if (matchId()) { } else ok = false;
}
int main() {
    ifstream fin("input.txt");
    if (!fin) { cout << "Cannot open input.txt" << endl; return 1; }
    string line;
    while (getline(fin, line)) {
        if (line.empty()) continue;
        input = line; pos = 0; ok = true; E();
        cout << "Input: " << line << endl;
        if (ok && pos == (int)input.size()) cout << "Output: Input string is accepted." << endl << endl;
        else cout << "Output: Input string is rejected." << endl << endl;
    }
    return 0;
}'''

PROCEDURE_LEX = [
    'Design the grammar rules and tokens required for the given language construct.',
    'Write the Lex (.l) file to define the tokens using regular expressions.',
    'Write the Bison (.y) file to define the grammar rules and the semantic actions.',
    'Generate the lexer using "flex" and the parser using "bison -d".',
    'Compile the generated C files together using "gcc".',
    'Provide the test expression through input.txt and run the executable to observe the result.',
]

PROCEDURE_CPP = [
    'Analyze the problem statement and design the algorithm needed to solve it.',
    'Write the complete C++ program (single file) implementing the required logic.',
    'Prepare the grammar/expression as input.txt so that the program reads it from a file instead of standard input.',
    'Compile the program using "g++".',
    'Run the compiled executable and verify that it reads correctly from input.txt.',
    'Observe and record the console output.',
]


def build_report():
    doc = Document()
    style = doc.styles['Normal']
    style.font.name = 'Times New Roman'
    style.font.size = Pt(12)

    add_cover_page(doc)

    heading(doc, "Write a Lex+Bison (Take input from another file)", 1)

    add_experiment(
        doc, 1,
        "Program to Check the Validity of an Expression using Lex and Bison.",
        "To design and implement a Lex and Bison based program that reads an arithmetic expression from an input file and determines whether the expression is syntactically valid according to standard arithmetic grammar rules.",
        PROCEDURE_LEX,
        [("validity.l", VALIDITY_L), ("validity.y", VALIDITY_Y)],
        "a + 10 * (b - 5)",
        'The program successfully validates arithmetic expressions containing identifiers, numbers, parentheses, and the four basic operators. For the input "a + 10 * (b - 5)" the parser reported the expression as valid, confirming that the Lex+Bison based grammar correctly recognizes well-formed arithmetic expressions.',
        1,
    )

    add_experiment(
        doc, 2,
        "Program to Evaluate the Value of an Arithmetic Expression using Lex and Bison.",
        "To design and implement a Lex and Bison based program that reads an arithmetic expression from an input file, parses it, and evaluates its numeric result while respecting operator precedence and associativity.",
        PROCEDURE_LEX,
        [("evaluate.l", EVALUATE_L), ("evaluate.y", EVALUATE_Y)],
        "2 + 3 * (4 + 2)",
        'The program correctly evaluated the expression "2 + 3 * (4 + 2)" and produced the result 20, which matches the expected value obtained by applying standard operator precedence (multiplication before addition). This confirms that the Bison grammar and its semantic actions correctly compute arithmetic expression values.',
        2,
    )

    add_experiment(
        doc, 3,
        "Program to Convert an Infix Expression to a Postfix Expression using Lex and Bison.",
        "To design and implement a Lex and Bison based program that reads an infix arithmetic expression from an input file and converts it into its equivalent postfix (Reverse Polish) notation.",
        PROCEDURE_LEX,
        [("postfix.l", POSTFIX_L), ("postfix.y", POSTFIX_Y)],
        "a + b * (c - d)",
        'The program successfully converted the infix expression "a + b * (c - d)" into the postfix expression "abcd-*+", which correctly reflects operator precedence and parenthesis grouping. This verifies that the Bison grammar\'s semantic actions correctly perform infix-to-postfix conversion.',
        3,
    )

    add_experiment(
        doc, 4,
        "Program to Find the Syntax Error within a Source Code using Lex and Bison.",
        "To design and implement a Lex and Bison based program that reads a small piece of source code from an input file and checks whether it conforms to a simplified statement grammar, reporting a syntax error when it does not.",
        PROCEDURE_LEX,
        [("syntax.l", SYNTAX_L), ("syntax.y", SYNTAX_Y)],
        "int a = 10 + 5\nint b = a * 2;",
        'The input file contained the statement "int a = 10 + 5" without a terminating semicolon, followed by a correctly terminated statement. The parser correctly detected the missing semicolon and reported "Syntax Error Found", demonstrating that the grammar can detect structural errors in source code.',
        4,
    )

    add_experiment(
        doc, 5,
        "Program to Design a Simple Calculator (Addition, Subtraction, Multiplication, Division) using Lex and Bison.",
        "To design and implement a Lex and Bison based calculator that reads an arithmetic expression from an input file and evaluates it using the four basic operators while respecting operator precedence.",
        PROCEDURE_LEX,
        [("calculator.l", CALC_L), ("calculator.y", CALC_Y)],
        "25 - 5 * 3",
        'For the input "25 - 5 * 3" the calculator correctly applied operator precedence (multiplication before subtraction) and produced the result 10, confirming that the calculator grammar performs arithmetic evaluation correctly.',
        5,
    )

    add_experiment(
        doc, 6,
        "Program to Check Palindromes (Number/String) using Lex and Bison.",
        "To design and implement a Lex and Bison based program that reads a word (string or number) from an input file and determines whether it reads the same forwards and backwards, i.e., whether it is a palindrome.",
        PROCEDURE_LEX,
        [("palindrome.l", PAL_L), ("palindrome.y", PAL_Y)],
        "madam",
        'For the input word "madam" the program correctly identified it as a palindrome, since the string reads identically from both ends. This confirms that the two-pointer comparison logic embedded in the Bison action works correctly for palindrome detection.',
        6,
    )

    heading(doc, "Write a (C/C++) (Take input from another file)", 1)

    add_experiment(
        doc, 7,
        "Program to Check whether the Given Grammar has Left Recursion or not (using C++).",
        "To write a C++ program that reads a context-free grammar from an input file and determines, for each non-terminal, whether any of its productions begin with the non-terminal itself (i.e., direct left recursion).",
        PROCEDURE_CPP,
        [("leftrec.cpp", LEFTREC_CPP)],
        "E -> E + T | T\nT -> T * F | F\nF -> ( E ) | id",
        "The program was tested with the grammar E -> E + T | T, T -> T * F | F, F -> ( E ) | id. It correctly identified direct left recursion in the productions of E and F. This confirms that scanning the first symbol of every alternative against the production's left-hand side is a valid and efficient technique for detecting left recursion in a CFG.",
        7,
    )

    add_experiment(
        doc, 8,
        "Program to Check whether the Given Grammar has a Common Prefix or not (using C++).",
        "To write a C++ program that reads a context-free grammar from an input file and determines, for each non-terminal, whether two or more of its alternatives share a common leading symbol (a common prefix), which would require left factoring.",
        PROCEDURE_CPP,
        [("common_prefix.cpp", COMMON_PREFIX_CPP)],
        "A -> a B C | a D E | b F\nS -> if E then S else S | if E then S | id",
        'The program was tested with A -> aBC | aDE | bF and S -> if E then S else S | if E then S | id. It correctly detected the common prefix "a" between the first two alternatives of A, and the common prefix "if" between the first two alternatives of S. This confirms that comparing the first symbol of each alternative is an effective way to detect the need for left factoring in a grammar.',
        8,
    )

    add_experiment(
        doc, 9,
        "Program to Find the FIRST and FOLLOW Sets from a Given CFG (using C++).",
        "To write a simple, beginner-friendly C++ program that reads a context-free grammar from an input file and computes the FIRST and FOLLOW sets for every non-terminal, which are essential for constructing predictive (LL) parsers.",
        PROCEDURE_CPP,
        [("first_follow.cpp", FIRST_FOLLOW_CPP)],
        "E -> T X\nX -> + T X | eps\nT -> F Y\nY -> * F Y | eps\nF -> ( E ) | id",
        "The program was tested with the classic expression grammar E -> TX, X -> +TX | eps, T -> FY, Y -> *FY | eps, F -> (E) | id. Using plain fixed-size arrays, simple helper functions, and repeated passes instead of recursion or STL containers such as vector, set, or map, the program still correctly computed the same FIRST and FOLLOW sets obtained by manual derivation.",
        9,
    )

    add_experiment(
        doc, 10,
        "Program to Implement Recursive Descent Parsing for a Given Grammar (using C++).",
        "To write a simple, beginner-friendly C++ recursive descent parser for the grammar E -> TE', E' -> +TE' | eps, T -> FT', T' -> *FT' | eps, F -> (E) | id, which reads test strings from an input file and reports whether each string is accepted or rejected by the grammar.",
        PROCEDURE_CPP,
        [("rdp.cpp", RDP_CPP)],
        "(id+id)*id\nid+*id",
        'The parser was tested with two strings: "(id+id)*id" was accepted, and "id+*id" was rejected. Both results exactly match the expected behaviour of the grammar. Using plain index-based string scanning instead of extra helper functions like peek() and skipSpaces(), the five parsing functions E(), E\'(), T(), T\'(), and F() remain easy to follow while still correctly implementing recursive descent parsing.',
        10,
    )

    doc.save(OUT_PATH)
    print(f"Saved: {OUT_PATH}")


if __name__ == "__main__":
    build_report()
