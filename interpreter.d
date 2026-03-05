module interpreter.interpreter;

import std.stdio;
import std.file : readText;
import std.path : extension;
import std.ascii : isAlpha, isDigit, isWhite;
import std.conv : to;
import std.exception : enforce;
import std.variant : Algebraic;
import std.string : strip, chomp;
import std.uni : toLower;
import core.stdc.stdlib : exit;

enum string EXPR = "EXPR";
enum string ADD = "ADD";
enum string SUB = "SUB";
enum string MUL = "MUL";
enum string DIV = "DIV";
enum string SET = "SET";
enum string TIMES = "TIMES";
enum string IF = "IF";
enum string ELSE = "ELSE";
enum string LOOP = "LOOP";
enum string BREAK = "BREAK";
enum string GT = "GT";
enum string LT = "LT";
enum string GTE = "GTE";
enum string LTE = "LTE";
enum string EQ = "EQ";
enum string NEQ = "NEQ";
enum string AND = "AND";
enum string OR = "OR";
enum string NOT = "NOT";
enum string CONCAT = "CONCAT";
enum string PUTS = "PUTS";
enum string GETS = "GETS";
enum string ARG = "ARG";
enum string FN = "FN";
enum string TRUE = "TRUE";
enum string FALSE = "FALSE";
enum string RETURN = "RETURN";
enum string STRING = "STRING";

abstract class Token {}

final class KeywordToken : Token {
    string name;
    this(string name) { this.name = name; }
}

final class NumToken : Token {
    long value;
    this(long value) { this.value = value; }
}

final class FloatToken : Token {
    double value;
    this(double value) { this.value = value; }
}

final class StringToken : Token {
    string value;
    this(string value) { this.value = value; }
}

final class IdToken : Token {
    string name;
    this(string name) { this.name = name; }
}

final class ExprToken : Token {
    Token[] items;
    this(Token[] items) { this.items = items; }
}

final class FnToken : Token {
    Token[] body;
    this(Token[] body) { this.body = body; }
}

final class FunctionValue {
    Token[] body;
    Env closure;
    string[] params;
    bool hasExplicitParams;

    this(Token[] body, Env closure, string[] params = null, bool hasExplicitParams = false) {
        this.body = body;
        this.closure = closure;
        this.params = params;
        this.hasExplicitParams = hasExplicitParams;
    }
}

alias Value = Algebraic!(long, double, bool, string, FunctionValue);

final class Env {
    private Value[string] values;
    private Env parent;
    private Value[] callArgs;
    private size_t argIndex;
    private bool hasCallArgs;

    this(Env parent = null) {
        this.parent = parent;
        this.callArgs = [];
        this.argIndex = 0;
        this.hasCallArgs = false;
    }

    void define(string name, Value value) {
        values[name] = value;
    }

    Value get(string name) {
        if (auto p = name in values) {
            return *p;
        }
        if (parent !is null) {
            return parent.get(name);
        }
        writeln("ERROR: Undefined variable ", name);
        exit(1);
    }

    void setCallArgs(Value[] args) {
        callArgs = args.dup;
        argIndex = 0;
        hasCallArgs = true;
    }

    Value consumeArg() {
        if (!hasCallArgs) {
            if (parent !is null) {
                return parent.consumeArg();
            }
            return get("arg");
        }
        if (argIndex >= callArgs.length) {
            writeln("ERROR: Not enough arguments for 'arg' reads in function body");
            exit(1);
        }
        auto v = callArgs[argIndex];
        argIndex++;
        return v;
    }
}

final class BreakSignal : Exception {
    this() {
        super("break");
    }
}

final class ReturnSignal : Exception {
    Value value;
    this(Value value) {
        super("return");
        this.value = value;
    }
}

bool startsWithAt(string code, size_t i, string pattern) {
    if (i + pattern.length > code.length) {
        return false;
    }
    return code[i .. i + pattern.length] == pattern;
}

bool matchesKeyword(string code, size_t i, string kw) {
    if (!startsWithAt(code, i, kw)) {
        return false;
    }
    auto j = i + kw.length;
    if (j >= code.length) {
        return true;
    }
    auto c = code[j];
    return !(isAlpha(c) || isDigit(c) || c == '_');
}

long valueAsLong(Value v) {
    if (v.peek!long) {
        return v.get!long;
    }
    if (v.peek!double) {
        return cast(long) v.get!double;
    }
    if (v.peek!bool) {
        return v.get!bool ? 1 : 0;
    }
    writeln("ERROR: Expected numeric value");
    exit(1);
}

double valueAsDouble(Value v) {
    if (v.peek!long) {
        return cast(double) v.get!long;
    }
    if (v.peek!double) {
        return v.get!double;
    }
    if (v.peek!bool) {
        return v.get!bool ? 1.0 : 0.0;
    }
    writeln("ERROR: Expected numeric value");
    exit(1);
}

bool valueAsBool(Value v) {
    if (v.peek!bool) {
        return v.get!bool;
    }
    if (v.peek!long) {
        return v.get!long != 0;
    }
    if (v.peek!double) {
        return v.get!double != 0.0;
    }
    if (v.peek!string) {
        return v.get!string.length != 0;
    }
    writeln("ERROR: Expected boolean value");
    exit(1);
}

string valueToString(Value v) {
    if (v.peek!long) {
        return to!string(v.get!long);
    }
    if (v.peek!double) {
        return to!string(v.get!double);
    }
    if (v.peek!bool) {
        return v.get!bool ? "true" : "false";
    }
    if (v.peek!string) {
        return v.get!string;
    }
    return "<function>";
}

Token[] tokenize(string code) {
    Token[] tokensOut;
    size_t i = 0;

    while (i < code.length) {
        if (code[i] == '(') {
            size_t j = i + 1;
            int depth = 1;
            bool inString = false;
            while (j < code.length && depth > 0) {
                if (code[j] == '"') {
                    inString = !inString;
                    j++;
                    continue;
                }
                if (!inString && code[j] == '(') {
                    depth++;
                } else if (!inString && code[j] == ')') {
                    depth--;
                }
                j++;
            }
            if (depth != 0) {
                writeln("ERROR: Unclosed expression, did you forget a ')'? ");
                exit(1);
            }
            tokensOut ~= new ExprToken(tokenize(code[i + 1 .. j - 1]));
            i = j;
        } else if (matchesKeyword(code, i, "add")) {
            tokensOut ~= new KeywordToken(ADD);
            i += 3;
        } else if (matchesKeyword(code, i, "sub")) {
            tokensOut ~= new KeywordToken(SUB);
            i += 3;
        } else if (matchesKeyword(code, i, "mul")) {
            tokensOut ~= new KeywordToken(MUL);
            i += 3;
        } else if (matchesKeyword(code, i, "div")) {
            tokensOut ~= new KeywordToken(DIV);
            i += 3;
        } else if (matchesKeyword(code, i, "set")) {
            tokensOut ~= new KeywordToken(SET);
            i += 3;
        } else if (matchesKeyword(code, i, "times")) {
            tokensOut ~= new KeywordToken(TIMES);
            i += 5;
        } else if (matchesKeyword(code, i, "if")) {
            tokensOut ~= new KeywordToken(IF);
            i += 2;
        } else if (matchesKeyword(code, i, "else")) {
            tokensOut ~= new KeywordToken(ELSE);
            i += 4;
        } else if (matchesKeyword(code, i, "loop")) {
            tokensOut ~= new KeywordToken(LOOP);
            i += 4;
        } else if (matchesKeyword(code, i, "break")) {
            tokensOut ~= new KeywordToken(BREAK);
            i += 5;
        } else if (matchesKeyword(code, i, "gte")) {
            tokensOut ~= new KeywordToken(GTE);
            i += 3;
        } else if (matchesKeyword(code, i, "lte")) {
            tokensOut ~= new KeywordToken(LTE);
            i += 3;
        } else if (matchesKeyword(code, i, "gq")) {
            tokensOut ~= new KeywordToken(GTE);
            i += 2;
        } else if (matchesKeyword(code, i, "lq")) {
            tokensOut ~= new KeywordToken(LTE);
            i += 2;
        } else if (matchesKeyword(code, i, "gt")) {
            tokensOut ~= new KeywordToken(GT);
            i += 2;
        } else if (matchesKeyword(code, i, "lt")) {
            tokensOut ~= new KeywordToken(LT);
            i += 2;
        } else if (matchesKeyword(code, i, "eq")) {
            tokensOut ~= new KeywordToken(EQ);
            i += 2;
        } else if (matchesKeyword(code, i, "neq")) {
            tokensOut ~= new KeywordToken(NEQ);
            i += 3;
        } else if (matchesKeyword(code, i, "and")) {
            tokensOut ~= new KeywordToken(AND);
            i += 3;
        } else if (matchesKeyword(code, i, "or")) {
            tokensOut ~= new KeywordToken(OR);
            i += 2;
        } else if (matchesKeyword(code, i, "not")) {
            tokensOut ~= new KeywordToken(NOT);
            i += 3;
        } else if (matchesKeyword(code, i, "concat")) {
            tokensOut ~= new KeywordToken(CONCAT);
            i += 6;
        } else if (matchesKeyword(code, i, "puts")) {
            tokensOut ~= new KeywordToken(PUTS);
            i += 4;
        } else if (matchesKeyword(code, i, "gets")) {
            tokensOut ~= new KeywordToken(GETS);
            i += 4;
        } else if (matchesKeyword(code, i, "arg")) {
            tokensOut ~= new KeywordToken(ARG);
            i += 3;
        } else if (matchesKeyword(code, i, "true")) {
            tokensOut ~= new KeywordToken(TRUE);
            i += 4;
        } else if (matchesKeyword(code, i, "false")) {
            tokensOut ~= new KeywordToken(FALSE);
            i += 5;
        } else if (matchesKeyword(code, i, "return")) {
            tokensOut ~= new KeywordToken(RETURN);
            i += 6;
        } else if (matchesKeyword(code, i, "fn")) {
            size_t k = i + 2;
            while (k < code.length && isWhite(code[k])) {
                k++;
            }
            if (k >= code.length || code[k] != '(') {
                writeln("ERROR: Invalid function expression, expected '(' after 'fn'");
                exit(1);
            }

            size_t j = k + 1;
            int depth = 1;
            bool inString = false;
            while (j < code.length && depth > 0) {
                if (code[j] == '"') {
                    inString = !inString;
                    j++;
                    continue;
                }
                if (!inString && code[j] == '(') {
                    depth++;
                } else if (!inString && code[j] == ')') {
                    depth--;
                }
                j++;
            }
            if (depth != 0) {
                writeln("ERROR: Unclosed function expression, did you forget a ')'? ");
                exit(1);
            }

            tokensOut ~= new FnToken(tokenize(code[k + 1 .. j - 1]));
            i = j;
        } else if (
            isDigit(code[i])
            || (code[i] == '.' && i + 1 < code.length && isDigit(code[i + 1]))
            || (code[i] == '-' && i + 1 < code.length && (isDigit(code[i + 1]) || (code[i + 1] == '.' && i + 2 < code.length && isDigit(code[i + 2]))))
        ) {
            size_t j = i;
            bool sawDot = false;
            if (code[j] == '-') {
                j++;
            }
            while (j < code.length) {
                if (isDigit(code[j])) {
                    j++;
                    continue;
                }
                if (code[j] == '.' && !sawDot) {
                    sawDot = true;
                    j++;
                    continue;
                }
                break;
            }
            if (code[j - 1] == '.') {
                writeln("ERROR: Invalid number literal");
                exit(1);
            }
            auto literal = code[i .. j];
            if (sawDot) {
                tokensOut ~= new FloatToken(to!double(literal));
            } else {
                tokensOut ~= new NumToken(to!long(literal));
            }
            i = j;
        } else if (code[i] == '"') {
            size_t j = i + 1;
            while (j < code.length && code[j] != '"') {
                j++;
            }
            if (j >= code.length) {
                writeln("ERROR: Unclosed string literal, did you forget a '\"'?");
                exit(1);
            }
            tokensOut ~= new StringToken(code[i + 1 .. j]);
            i = j + 1;
        } else if (isAlpha(code[i]) || code[i] == '_') {
            size_t j = i;
            while (j < code.length && (isAlpha(code[j]) || isDigit(code[j]) || code[j] == '_')) {
                j++;
            }
            tokensOut ~= new IdToken(code[i .. j]);
            i = j;
        } else {
            i++;
        }
    }

    return tokensOut;
}

Value evalToken(Token tok, Env env);
Value parse(Token[] tokenList, Env env);

Value evalToken(Token tok, Env env) {
    if (auto expr = cast(ExprToken) tok) {
        bool headIsKeyword = expr.items.length > 0 && cast(KeywordToken) expr.items[0] !is null;
        if (expr.items.length >= 2 && !headIsKeyword) {
            auto callee = evalToken(expr.items[0], env);
            if (callee.peek!FunctionValue) {
                auto fn = callee.get!FunctionValue;
                auto callEnv = new Env(fn.closure);
                Value[] argValues;
                foreach (argTok; expr.items[1 .. $]) {
                    argValues ~= evalToken(argTok, env);
                }
                if (fn.hasExplicitParams) {
                    if (argValues.length != fn.params.length) {
                        writeln("ERROR: Function expected ", fn.params.length, " args, got ", argValues.length);
                        exit(1);
                    }
                    foreach (idx, p; fn.params) {
                        callEnv.define(p, argValues[idx]);
                    }
                } else {
                    callEnv.setCallArgs(argValues);
                }
                try {
                    return parse(fn.body, callEnv);
                } catch (ReturnSignal r) {
                    return r.value;
                }
            }
        }
        return parse(expr.items, env);
    }

    if (auto n = cast(NumToken) tok) {
        return Value(n.value);
    }
    if (auto f = cast(FloatToken) tok) {
        return Value(f.value);
    }
    if (auto s = cast(StringToken) tok) {
        return Value(s.value);
    }

    if (auto id = cast(IdToken) tok) {
        return env.get(id.name);
    }

    if (auto fnTok = cast(FnToken) tok) {
        string[] params = [];
        bool explicitParams = false;
        Token[] body = fnTok.body;
        if (fnTok.body.length >= 2) {
            auto maybeParams = cast(ExprToken) fnTok.body[0];
            if (maybeParams !is null) {
                bool allIds = true;
                foreach (p; maybeParams.items) {
                    if (cast(IdToken) p is null) {
                        allIds = false;
                        break;
                    }
                }
                if (allIds) {
                    explicitParams = true;
                    foreach (p; maybeParams.items) {
                        params ~= (cast(IdToken) p).name;
                    }
                    body = fnTok.body[1 .. $];
                }
            }
        }
        return Value(new FunctionValue(body, env, params, explicitParams));
    }

    if (auto kw = cast(KeywordToken) tok) {
        if (kw.name == GETS) {
            auto line = strip(chomp(readln()));
            auto lowered = toLower(line);
            if (lowered == "true") {
                return Value(true);
            }
            if (lowered == "false") {
                return Value(false);
            }
            try {
                return Value(to!double(line));
            } catch (Exception) {
                return Value(line);
            }
        }
        if (kw.name == ARG) {
            return env.consumeArg();
        }
        if (kw.name == TRUE) {
            return Value(true);
        }
        if (kw.name == FALSE) {
            return Value(false);
        }
    }

    writeln("ERROR: Invalid token in expression");
    exit(1);
}

bool isKeyword(Token tok, string name) {
    auto kw = cast(KeywordToken) tok;
    return kw !is null && kw.name == name;
}

Value parse(Token[] tokenList, Env env) {
    Value result = Value(cast(long) 0);
    bool hasResult = false;
    size_t i = 0;

    while (i < tokenList.length) {
        auto tok = tokenList[i];

        if (isKeyword(tok, TIMES)) {
            enforce(i + 2 < tokenList.length, "ERROR: times expects <count> <expr>");
            auto count = valueAsLong(evalToken(tokenList[i + 1], env));
            for (long n = 0; n < count; n++) {
                result = evalToken(tokenList[i + 2], env);
                hasResult = true;
            }
            i += 3;
            continue;
        }

        if (isKeyword(tok, IF)) {
            enforce(i + 2 < tokenList.length, "ERROR: if expects <cond> <expr>");
            bool hasElse = i + 4 < tokenList.length && isKeyword(tokenList[i + 3], ELSE);
            if (valueAsBool(evalToken(tokenList[i + 1], env))) {
                result = evalToken(tokenList[i + 2], env);
                hasResult = true;
            } else if (hasElse) {
                result = evalToken(tokenList[i + 4], env);
                hasResult = true;
            }
            i += hasElse ? 5 : 3;
            continue;
        }

        if (isKeyword(tok, LOOP)) {
            enforce(i + 1 < tokenList.length, "ERROR: loop expects <expr>");
            while (true) {
                try {
                    result = evalToken(tokenList[i + 1], env);
                    hasResult = true;
                } catch (BreakSignal _) {
                    break;
                }
            }
            i += 2;
            continue;
        }

        if (isKeyword(tok, SET)) {
            enforce(i + 2 < tokenList.length, "ERROR: set expects a name and a value");
            auto id = cast(IdToken) tokenList[i + 1];
            if (id is null) {
                writeln("ERROR: set expects an identifier");
                exit(1);
            }
            auto value = evalToken(tokenList[i + 2], env);
            env.define(id.name, value);
            result = value;
            hasResult = true;
            i += 3;
            continue;
        }

        string op;
        foreach (candidate; [ADD, SUB, MUL, DIV, GT, LT, GTE, LTE, EQ, NEQ, AND, OR, CONCAT]) {
            if (isKeyword(tok, candidate)) {
                op = candidate;
                break;
            }
        }

        if (op.length > 0) {
            enforce(i + 2 < tokenList.length, "ERROR: binary operator expects two operands");
            auto a = evalToken(tokenList[i + 1], env);
            auto b = evalToken(tokenList[i + 2], env);

            if (op == ADD) {
                if (a.peek!long && b.peek!long) result = Value(a.get!long + b.get!long);
                else result = Value(valueAsDouble(a) + valueAsDouble(b));
            } else if (op == SUB) {
                if (a.peek!long && b.peek!long) result = Value(a.get!long - b.get!long);
                else result = Value(valueAsDouble(a) - valueAsDouble(b));
            } else if (op == MUL) {
                if (a.peek!long && b.peek!long) result = Value(a.get!long * b.get!long);
                else result = Value(valueAsDouble(a) * valueAsDouble(b));
            } else if (op == DIV) {
                result = Value(valueAsDouble(a) / valueAsDouble(b));
            } else if (op == GT) {
                result = Value(valueAsDouble(a) > valueAsDouble(b));
            } else if (op == LT) {
                result = Value(valueAsDouble(a) < valueAsDouble(b));
            } else if (op == GTE) {
                result = Value(valueAsDouble(a) >= valueAsDouble(b));
            } else if (op == LTE) {
                result = Value(valueAsDouble(a) <= valueAsDouble(b));
            } else if (op == EQ) {
                if ((a.peek!long || a.peek!double || a.peek!bool) && (b.peek!long || b.peek!double || b.peek!bool)) {
                    result = Value(valueAsDouble(a) == valueAsDouble(b));
                } else if (a.peek!string && b.peek!string) {
                    result = Value(a.get!string == b.get!string);
                } else {
                    result = Value(false);
                }
            } else if (op == NEQ) {
                if ((a.peek!long || a.peek!double || a.peek!bool) && (b.peek!long || b.peek!double || b.peek!bool)) {
                    result = Value(valueAsDouble(a) != valueAsDouble(b));
                } else if (a.peek!string && b.peek!string) {
                    result = Value(a.get!string != b.get!string);
                } else {
                    result = Value(true);
                }
            } else if (op == AND) {
                result = Value(valueAsBool(a) && valueAsBool(b));
            } else if (op == OR) {
                result = Value(valueAsBool(a) || valueAsBool(b));
            } else if (op == CONCAT) {
                if (a.peek!string && b.peek!string) {
                    result = Value(a.get!string ~ b.get!string);
                } else {
                    writeln("ERROR: Cannot concatenate two non-string literals");
                    exit(1);
                }
            }

            hasResult = true;
            i += 3;
            continue;
        }

        if (isKeyword(tok, NOT)) {
            enforce(i + 1 < tokenList.length, "ERROR: not expects one operand");
            result = Value(!valueAsBool(evalToken(tokenList[i + 1], env)));
            hasResult = true;
            i += 2;
            continue;
        }

        if (isKeyword(tok, ELSE)) {
            writeln("ERROR: 'else' without matching 'if'");
            exit(1);
        }

        if (isKeyword(tok, RETURN)) {
            enforce(i + 1 < tokenList.length, "ERROR: return expects one expression");
            throw new ReturnSignal(evalToken(tokenList[i + 1], env));
        }

        if (isKeyword(tok, PUTS)) {
            enforce(i + 1 < tokenList.length, "ERROR: puts expects one argument");
            result = evalToken(tokenList[i + 1], env);
            writeln(valueToString(result));
            hasResult = true;
            i += 2;
            continue;
        }

        if (isKeyword(tok, BREAK)) {
            throw new BreakSignal();
        }

        result = evalToken(tok, env);
        hasResult = true;
        i++;
    }

    if (!hasResult) {
        return Value(cast(long) 0);
    }
    return result;
}

void main(string[] args) {
    if (args.length < 2) {
        writeln("ERROR: Please provide a source file");
        exit(1);
    }

    auto path = args[1];
    if (extension(path) != ".axl") {
        writeln("ERROR: Unrecognized file extension, please use only '.axl' files");
        exit(1);
    }

    auto source = readText(path);
    auto tokens = tokenize(source);
    auto globalEnv = new Env();
    try {
        parse(tokens, globalEnv);
    } catch (ReturnSignal _) {
        writeln("ERROR: return can only be used inside a function");
        exit(1);
    }
}
