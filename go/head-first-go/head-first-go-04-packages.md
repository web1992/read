# packages

## workspace

Go tools look for package code in a special directory (folder) on your computer called
the `workspace`. By default, the workspace is a directory named go in the current user's
home directory.

- `bin`, which holds compiled binary executable programs. (We'll talk about bin more later in the chapter.)
- `pkg`, which holds compiled binary package files. (We'll also talk about pkg more later in the chapter.)
- `src`, which holds Go source code.

## package names rules

• A package name should be all lowercase.
• The name should be abbreviated if the meaning is fairly obvious (such as fmt).
• It should be one word, if possible. If two words are needed, they should not be
separated by underscores, and the second word should not be capitalized. (The strconv
package is one example.)
• Imported package names can conflict with local variable names, so don't use a name
that package users are likely to want to use as well. (For example, if the strings package
were named string, no one who imported that package would be able to name a local
variable string).
