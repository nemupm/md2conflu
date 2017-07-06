# Md2conflu

Md2conflu converts Markdown document into Confluence wiki markup.

# Requirements

- Ruby (confirmed in 2.2, 2.4)
- Rake
- Bundler

# Installation

```sh
$ git clone https://github.com/nemupm/md2conflu.git
$ cd md2conflu
$ rake install
```

# Usage

## Converting markdown into markup

You can input markdown file with -f option. 

```sh
$ md2conflu -f ~/test.md
h1. title

* \[a\](http://localhost)
* {code}abc{code}

{code}
#comment
{code}
$
```

Standard input or simply string argument is also available.

```sh
$ md2conflu << 'EOS'
# abc
## edf
- 1
- 2
- 3
EOS
h1. abc
h2. edf
* 1
* 2
* 3
$
```

```sh
$ md2conflu "
> # abc
> ## bcd
> - 1
> - 2
> - 3
> "

h1. abc
h2. bcd
* 1
* 2
* 3
```

## Inserting markup into article

1. In edit view, select "insert > markup" and you can get pop-up window.
2. Select "Confluence Wiki" in pulldown menu and paste markup into the left text box.
3. Click the insert button.

# Example of alias

```sh
# .bashrc
alias m2c="pbpaste |md2conflu |pbcopy"
```
