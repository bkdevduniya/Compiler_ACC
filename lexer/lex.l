%{
#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <regex>
using namespace std;

struct Token {
    string type;
    string value;
    int line;
};

int line_val = 1, preline = 0; // start from line 1
vector<Token> tokens;
string preType = "", preValue = "";

bool check(string t1, string t2, string v1, string v2) {
    // Conditional keywords
    if (t1 == "cond_keyword")
        return (v2 == "(" || (v1 == "else" && t2 == "cond_keyword") ||
                ((v1 == "case" || v1 == "default") && v2 == ":"));

    // Loop keywords
    if (t1 == "loop_keyword")
        return (v2 == "(" || (v1 == "do" && v2 == "{"));

    // Jump keywords
    if (t1 == "jump_keyword")
        return (v2 == ";" || (v1 == "return" &&
                (t2 == "literal" || t2 == "identifier" || v2 == "(")));

    // Datatype keywords
    if (t1 == "datatype_keyword")
        return (t2 == "identifier" ||
                (v1 == "long" && t2 == "datatype_keyword" && v2 != "double") ||
                v2 == "*" || v2 == "&" || v2 == "(" || v2 == ")" ||
                v2 == "[" || v2 == "]");

    // Declaration keywords
    if (t1 == "declaration_keyword")
        return (t2 == "identifier" || v2 == "{");

    // Operators
    if (t1 == "operator")
        return (t2 == "literal" || t2 == "identifier" ||
                ((v1 == "++" || v1 == "--" || v1 == ":") &&
                 (v2 == ";" || v2 == ")" || (v1 != ":" && v2 == "]"))) ||
                (v1 == "?" && v2 == ":") ||
                (v1 == "..." && (v2 == ")" || v2 == ",")));

    // Literals
    if (t1 == "literal")
        return (t2 == "operator" || v2 == ";" || v2 == "]" ||
                v2 == ")" || v2 == "," || v2 == "}" || v2 == ":");

    // Identifiers
    if (t1 == "identifier")
        return (t2 == "operator" || v2 == "(" || v2 == ")" ||
                v2 == "[" || v2 == "]" || v2 == ";" || v2 == "," || v2 == ":");

    // Parentheses
    if (v1 == "(")
        return (v2 == ")" || t2 == "literal" || t2 == "identifier" ||
                t2 == "datatype_keyword" || v2 == "++" || v2 == "--" || v2 == "!");
    if (v1 == ")")
        return (v2 == "{" || t2 == "operator" || v2 == "[" || v2 == ";" ||
                t2 == "literal" || t2 == "jump_keyword");

    // Curly braces
    if (v1 == "{")
        return (t2 == "literal" || t2 == "identifier" || v2 == ";" || v2 == "," ||
                v2 == "{" || v2 == "[" || v2 == "(" || v2 == "}" || v2 == "++" ||
                v2 == "--" || v2 == "!" || t2 == "cond_keyword" ||
                t2 == "loop_keyword" || t2 == "jump_keyword" ||
                t2 == "datatype_keyword" || t2 == "declaration_keyword");
    if (v1 == "}")
        return (v2 == "++" || v2 == "--" || v2 == "!" || t2 == "identifier" ||
                t2 == "literal" || v2 == ";" || v2 == "(" || v2 == "{");

    // Square brackets
    if (v1 == "[")
        return (t2 == "identifier" || v2 == "++" || v2 == "--" || v2 == "!" ||
                t2 == "literal" || v2 == "(" || v2 == "[" || v2 == "]"||v2=="&");
    if (v1 == "]")
        return (t2 == "operator" || v2 == ";" || v2 == "," || v2 == "[" ||
                v2 == "]" || v2 == "(");

    // Comma
    if (v1 == ",")
        return (t2 == "identifier" || t2 == "literal" || v2 == "(" || v2 == "++" ||
                v2 == "--" || v2 == "!" || v2 == "}" || v2 == "..." ||
                t2 == "datatype_keyword");

    // Colon
    if (v1 == ":")
        return (t2 == "identifier" || t2 == "literal" || v2 == ";" || v2 == "(" ||
                v2 == "++" || v2 == "--" || v2 == "!" || v2 == ")");

    // Semicolon
    if (v1 == ";") return true;

    return false;
}

void addToken(string type, const string &value, int line) {
    if (!preType.empty()) {
        if (!check(preType, type, preValue, value)) {
            cerr << "INVALID TOKEN : [" << preType << ":" << preValue
                 << "] -> [" << type << ":" << value << "] at line " << line << endl;
        }
    }
    preType = type;
    preValue = value;
    preline = line;
    tokens.push_back({preType, preValue, preline});
}

const char* OPERATORS_RE   = R"(>|<|<=|>=|!=|==|&&|\|\||!|\+|\-|\*|\/|%|=|\-=|\+=|\*=|\/=|%=|\|=|&=|\^=|<<=|>>=|&|\||\^|<<|>>|\+\+|\-\-|\?|\:\:|->|\.|\.\.\.)";
const char* DELIMETER_RE   = R"(;|\[|\]|\{|\}|\(|\)|\:)";
const char* IDENTIFIERS_RE = R"([a-zA-Z_][a-zA-Z0-9_]*)";
const char* LITERALS_RE    = R"(\"[^\"]*\"|\'([^\\]|\\.)\'|[0-9]+|([0-9]+\.[0-9]*|\.[0-9]+)|[0-9]+[eE][-+]?[0-9]+|([0-9]+\.[0-9]*|\.[0-9]+)[eE][-+]?[0-9]+)";

int count_newlines(const char* text) {
    int c = 0;
    for (const char* p = text; *p; ++p)
        if (*p == '\n') c++;
    return c;
}
%}

%option noyywrap
%option c++

CONDITIONAL_KEYWORDS   "if"|"else"|"switch"|"else if"|"case"|"default"
LOOP_KEYWORDS          "for"|"while"|"do"
JUMP_KEYWORDS          "break"|"continue"|"return"
DATA_TYPES_KEYWORDS    "int"|"float"|"double"|"char"|"bool"|"void"|"long"|"short"
DECLARATION_KEYWORDS   "class"|"struct"|"enum"|"public"|"protected"|"private"
OPERATORS              ">"|"<"|"<="|">="|"!="|"=="|"&&"|"||"|"!"|"+"|"-"|"*"|"/"|"%"|"="|"-="|"+="|"*="|"/="|"%="|"|="|"&="|"^="|"<<="|">>="|"&"|"|"|"^"|"<<"|">>"|"++"|"--"|"?"|"::"|"->"|"."|"..."
DELIMETER              ";"|"["|"]"|"{"|"}"|"("|")"|":"|","
IDENTIFIERS            [a-zA-Z_][a-zA-Z0-9_]*
STRING                 \"([^"\\\n]|\\.)*\"
INVALID_STR            \"([^"\\\n]|\\.)*(\n|$)
CHAR                   \'([^\\]|\\.)\'
INT                    [0-9]+
FLOAT                  ([0-9]+\.[0-9]*|\.[0-9]+)
EXP                    [eE][-+]?[0-9]+
LITERALS               {STRING}|{CHAR}|{INT}|{FLOAT}|{INT}{EXP}|{FLOAT}{EXP}
MULTILINECOMMENT       \/\*([^*]*|[*][^/]*)*\*\/
SINGLELINECOMMENT      \/\/[^\n]*

%%

\r?\n                  { line_val++; preType=""; preValue=""; }
[ \t\r]+               { preType=""; preValue=""; }

{SINGLELINECOMMENT}    { if(!preValue.empty()){tokens.push_back({preType,preValue,preline}); preType=""; preValue="";} }
{MULTILINECOMMENT}     { if(!preValue.empty()){tokens.push_back({preType,preValue,preline}); preType=""; preValue="";} }

{CONDITIONAL_KEYWORDS} { addToken("cond_keyword", yytext, line_val); }
{JUMP_KEYWORDS}        { addToken("jump_keyword", yytext, line_val); }
{LOOP_KEYWORDS}        { addToken("loop_keyword", yytext, line_val); }
{DATA_TYPES_KEYWORDS}  { addToken("datatype_keyword", yytext, line_val); }
{DECLARATION_KEYWORDS} { addToken("declaration_keyword", yytext, line_val); }
{OPERATORS}            { addToken("operator", yytext, line_val); }
{DELIMETER}            { addToken("punctuator", yytext, line_val); }
{IDENTIFIERS}          { addToken("identifier", yytext, line_val); }

{INVALID_STR} {
    string s = "INVALID_STR " + string(yytext);
    tokens.push_back({"error", s, line_val});
    line_val += count_newlines(yytext);
    preType = "";
    preValue = "";
}

{LITERALS} {
    addToken("literal", yytext, line_val);
    line_val += count_newlines(yytext);
}

. {
    string val = yytext;
    string detectedType = "";
    if(val != " " && val != "\t" && val != "\r") {
        if (regex_match(val, regex(OPERATORS_RE))) {
            detectedType = "operator";
            addToken(detectedType, val, line_val);
        }
        else if (regex_match(val, regex(DELIMETER_RE))) {
            detectedType = "punctuator";
            addToken(detectedType, val, line_val);
        }
        else if (regex_match(val, regex(IDENTIFIERS_RE))) {
            detectedType = "identifier";
            addToken(detectedType, val, line_val);
        }
        else if (regex_match(val, regex(LITERALS_RE))) {
            detectedType = "literal";
            addToken(detectedType, val, line_val);
            line_val += count_newlines(val.c_str());
        } else {
            string errorval = "Error: UNRECOGNIZED TOKEN " + val;
            tokens.push_back({"error", errorval, line_val});
            preValue = "";
            preType = "";
        }
    }
}
%%

int main(int argc, char** argv) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <source_file>\n";
        return 1;
    }
    yyFlexLexer lexer;
    ifstream file(argv[1]);
    if (!file.is_open()) {
        cerr << "Error: could not open file " << argv[1] << "\n";
        return 1;
    }
    lexer.switch_streams(&file, nullptr);
    lexer.yylex();
    for (const auto &t : tokens) {
        cout << " " << t.type << "      " << t.value <<"       "<<  "line "<< t.line <<"\n";
    }
    return 0;
}
