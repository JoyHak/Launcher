## Problem

Not long ago, I started to notice that many console utilities can output colored text. I was curious if I could also add colors to the output. Let's deep dive how it works and [how you can use it in your projects](https://github.com/JoyHak/Launcher/blob/e666e853253b6627bd6767a743ad3f47a557bcf6/Lib/output.ahk#L1).

![](/Images/atomic3.png)

## Atomics and Paired

The [Color](https://github.com/JoyHak/Launcher/blob/e666e853253b6627bd6767a743ad3f47a557bcf6/Lib/output.ahk#L1) string method takes an array of pairs "regex-color". Each found text part will be colored in the specified color.To understand the differences between supported expressions, we will introduce two concepts:

- **Paired**: expressions that have a start and an end and form a pair. Example: $\texttt{\color{#31d741}" ", \` \`, \color{#ff442f}\* \*}$ etc.
- **Atomics**: indivisible expressions that are considered as a single unit. Example: $\texttt{\color{#01f5f5}--switch, \color{#e9e63d}@file}$, etc.

Paired expressions have their own color (e.g., green quotes $\texttt{\color{#31d741}" "}$) and can contain other colors:

Atomic expressions are indivisible, independent constructs that **cannot contain other colors**.

![](/Images/atomic1.png)
![](/Images/atomic2.png)

 This is the main difference between atomics and paired expressions. However, in practice, they have certain features that can be used to create your own syntax for text highlighting. 

If you are familiar with [Markdown](https://github.com/JoyHak/MarkdownToBBCode), you may have noticed familiar symbols in the source text of the help: \# \_\_ \`\`

However, when output to the console (like when rendering Markdown), they disappear to focus attention on the text using color rather than additional symbols. This is another difference of paired expressions: they are invisible. If you need visible symbols and text, use atomics (like `(%[^%]+%)` in the text above) or wrap atomics/visible non-paired symbols in paired symbols (like $\texttt{\color{#31d741}\`"C:/\color{#697bf5}Temp\color{#31d741}/script.ahk"\`}$ in the [help message](https://github.com/JoyHak/Launcher/blob/e666e853253b6627bd6767a743ad3f47a557bcf6/launcher.ahk#L122)). 

Atomics allow you to choose which characters will be included and which will become invisible. The main rule is that visible characters must be in capturing group 1! For example `__([^_]+)__` or `'\*\*([^\*]+)\*\*'`, but not `__(\w+)(_)_` *(here there are two groups, so the second will be ignored)* nor `__(\w+(_))_` *(here there are two groups; the nested one has number 2 and will be ignored)*. An example of an atomic that has all visible characters is `(%[^%]+%)`.

## Examples
As you can see, you can create your own syntax for coloring text that is more familiar or convenient for you. Even HTML tags as before: `str.Color(["<orange>([^<]+)<\/orange>", "orange"])` Such an expression will find text inside tags in the variable `str`. `<orange>warning</orange>` will become $\texttt{\color{#fb7237}warning}$ *(tags will be removed when output to the console)*. Or you can define pairs and set additional colors inside pairs.

```ahk
"~<yellow>-save</yellow> switch was passed~".Color([
    "~", "gray",
    "<yellow>([^<]+)<\/yellow>", "yellow",
])
```

This text will become $\texttt{\color{#e9e63d}-save \color{#5e5e5e}switch was passed}$

Detailed examples can be found in [-scripts switch output](https://github.com/JoyHak/Launcher/blob/e666e853253b6627bd6767a743ad3f47a557bcf6/Lib/commandLine.ahk#L112) and [help output](https://github.com/JoyHak/Launcher/blob/e666e853253b6627bd6767a743ad3f47a557bcf6/launcher.ahk#L122). The main thing to remember is that options must be passed separately as the first element of the array and they **cannot be applied individually to each expression within the array**:
```ahk
str.Color([
    'm)', ; options must be first
    '(^\s+Name| Value\s*$)', 'gray'
])
```

[You can read how and why it was created here.](https://habr.com/ru/articles/1053052/)
