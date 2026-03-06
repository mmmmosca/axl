# An Expression Language

<div align="center">
<img src="https://github.com/mmmmosca/axl/blob/c806823d994f6a531cbb9b269135fcbe7b882759/logo.png" width="400" height="400">
</div>

An Expression Language (AXL) is an expression based programming language that can be used for scripting.

Everything in AXL (except for the instructions for input and output) returns a value of some sort, meaning that all of the different operations (which are themselves expressions) can be concatenated.

## Next milestones
- Lists
- Embedding inside other languages
- File reading
- modules

## Defining an expression
Anything enclosed bewteen `(` and `)` is treated as an expression.
An expression can return either an integer, a floating point number (both integers and floats can be either positive or negative), a boolean, a string or a function and returns the last value inserted.

For example the following expression will return `2`:
```
( 1 2 )
```

It is important to notice that an empty expression (e.g. `()`) will return nothing as there isn't nothing to return.

## Operationg with expressions
AXL provides a series of operations (which are by definition expressions too) to perform arithmetic or boolean operations, written in polish notation:

- `add <expr1> <expr2>`: returns the addition between two expressions
- `sub <expr1> <expr2>`: returns the subtraction between the first and the second expression
- `mul <expr1> <expr2>`: returns the multiplication between two expressions
- `div <expr1> <expr2>`: returns the division between the first and the second expression
- `and <expr1> <expr2>`: returns true if both the expressions return true
- `or <expr1> <expr2>`: returns true if either one of the two expressions return true
- `not <expr1>`: returns the opposite boolean of whatever boolean the expression returns

## Branching
Branching can be performed through the `if`, `loop` and `times` expressions.

These can either return a value conditionally or iterate the same expression, either a determined or undetermined amouunt of times.

- `if <cond> <expr>`: returns a value if the condition returns true
- `times <n_iterations> <expr>`: returns a value a definite amount of times
- `loop <expr>`: returns indefinately a value; the loop can be broke with the `break` expression.

## Variables
A variable is a scoped region of memory that stores a value.

A variable can be defined/redefined with the `set` expression, which requires an identifier and an expression or a function:
```
set <id> <expr | function>
```

## I/O
You can print to the standard output a value with the `puts` keyword (e.g. `puts 3`) or get user input with the `gets` keyword (which could be actually an expression as it returns a value, but since it deals with I/O it technically isn't, but it can be used as the value of a variable)

## Functions
Functions can be defined as follows:
`fn ( ... )`

Functions require to take at least one argument, which can be taken by using the `arg` expression; then they get substituted with the positional arguments you pass in your function.

To demonstrate how a function works, here's a quick example:
```
set foo fn(
  set a arg
  set b arg
  add a b
)

puts (foo 1 1)
```

Here the function foo takes in two arguments that are stored in the variables a and b.
Then we return the result of the sum of the two variables, which in this case is `2`.

Normally a function returns the last expression it's written inside, but you can explicitally tell the function to return with the 
`return` expression.

## Strings
Any text enclosed between `"` is treated as a string literal.
You can concatenate strings with the `concat` expression, which returns a string:
```
concat <string_1> <string_2>
```
