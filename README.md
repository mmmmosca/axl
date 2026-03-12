# An Expression Language

<div align="center">
<img src="https://github.com/mmmmosca/axl/blob/c806823d994f6a531cbb9b269135fcbe7b882759/logo.png" width="400" height="400">
</div>

An Expression Language (AXL) is an expression based programming language that can be used for scripting.

Everything in AXL (except for the instructions for input and output) returns a value of some sort, meaning that all of the different operations (which are themselves expressions) can be concatenated.

## Next milestones
- ~~Lists~~
- ~~File reading/writing~~
- ~~modules~~
- Embedding inside other languages

## Defining an expression
Anything enclosed bewteen `(` and `)` is treated as an expression.
An expression can return either an integer, a floating point number (both integers and floats can be either positive or negative), a boolean, a string, a list or a function and returns the last value inserted.

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
- `else <expr>`: returns a value if the previous condition is false
- `times <n_iterations> <expr>`: returns a value a definite amount of times
- `loop <expr>`: returns indefinately a value; the loop can be broke with the `break` expression.

## Variables
A variable is a scoped region of memory that stores a value.

A variable can be defined/redefined with the `set` expression, which requires an identifier and an expression or a function:
```
set <id> <expr | function>
```

## I/O
You can print to the standard output a value with the `puts` keyword (e.g. `puts 3`) or get user input with the `gets` keyword (which could be actually an expression as it returns a value, but since it deals with I/O it technically isn't, but it can be used as the value of a variable):
```
puts <expr>

gets
```
You can also read from files using the `readf` expression, which returns a list containing all the lines of the file as strings:
```
readf <string path to file>
```

In a similar way you can also overwrite the contents of the file with `writef` and `appendf` that, like `puts`, aren't expressions:
```
writef <string path to file> <string to write>

appendf <string path to file> <string to write>
```

## Functions
Functions can be defined as follows:
`fn ( ... )`

Functions can take arguments, which can be taken by using the `arg` expression; then they get substituted with the positional arguments you pass in your function.

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

To call a function, wrap in parethesis the name of the variable binded to that function along with any possible argument:
```
(<function name> <optional args>)
```

## Strings
Any text enclosed between `"` is treated as a string literal.
You can concatenate strings with the `concat` expression, which returns a string:
```
concat <string_1> <string_2>
```

## Lists
Lists are a data structure that can contain any number of expressions.
Strings are considered as a list of characters, therefore all the operations related to lists are also valid for strings
We can define a list with the `list` keyword:
```
list(...)
```
When defining a list be sure to separate each element in the list with a whitespace:
```
set nums list(1 2 3 4)
```

It is possible to manipulate and operate with lists with the following operations:
- `len <list>`: returns the length of the given list
- `element <list> <num>`: given a list and a number index, returns the value stored at that index. 
- `concat <list> <list>`: it is possible to use `concat` also to concatenate two strings
- `map <function> <list>`: applies a given function to each element of a given list

## Type conversion
It's possible to convert a value to another type using these expressions:
- `tostr <expr>`: converts a given expression to a string
- `tonum <expr>`: converts a given expression to a number 
- `tolist <expr>`: converts a given expression to a list

## Importing other AXL files
One can import other AXL files using the `import` expression, which returns the content of the file and evaluates them accordingly:
```
import <string path to an other AXL file>
```
