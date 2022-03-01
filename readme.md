
Install the git command line client and make sure it's in your path (it is needed for a pre-build script to run).
Clone the repo. The Visual Studio solution file VoxPopuli_vs2013.sln is included in the repository folder
Significant portions of the mods are Lua / SQL / XML files. Those can be modified without rebuilding the game core
You need the Visual C++ 2008 SP1 compiler to actually link the resulting game core DLL
It is possible to use a recent IDE like Visual Studio 2019 Community though, just make sure to use the correct toolset
Always install different Visual Studio editions in chronological order, eg 2008 before 2019
If prompted on loading the solution file whether you want to retarget projects, select "No Upgrade" for both options and continue
If you encounter an "unexpected precompiler header error", install this hotfix
A tutorial with visual aids has been posted here, courtesy of ASCII Guy
To build the 43 Civ version of the DLL:
Open the file Community-Patch-DLL\CvGameCoreDLLUtil\include\CustomModsGlobal.h
Remove everything before the # in this line: // #define MOD_GLOBAL_MAX_MAJOR_CIVS (43)
Save the file.
If building the Release version, Whole Program Optimization is enabled, which will cause a several minute delay at the end of pass 1, but the compiler is still functioning!
You can disable Whole Program Optimization locally under Project > VoxPopuli Properties > C/C++ > Optimization > Whole Program Optimization (set it to No)
If the compiler stops responding at the end of pass 2, try deleting the hidden .vs folder as well as the BuildOutput/BuildTemp folders in the project directory, then reopening the solution file.

# LeonMod Description
This mod changes a bunch of things, from largest to smallest:
* Interception Rework - With the previous interception mechanics, 
* Tourism Influence Combat Mechanics - Unlike every other victory condition (Domination, Science, )





# VP Info:
* Install mods via latest installer https://forums.civfanatics.com/threads/community-patch-how-to-install.528034/
* Create modpack via https://civ-5-cbp.fandom.com/wiki/Creating_a_Modpack

Installers:
* 1.3.4: https://drive.google.com/file/d/1AJm5e5xuBfBmFstDD_MAD2MnRzs5TOaH/view


### Want to contribute?
* See the issues page. We have issues that can be fixed or tested by people without C++, XML, or Lua experience!


















[Markdown Examples](https://markdown-it.github.io/) below this line.
___

---

***


---
__Advertisement :)__

- __[pica](https://nodeca.github.io/pica/demo/)__ - high quality and fast image
  resize in browser.
- __[babelfish](https://github.com/nodeca/babelfish/)__ - developer friendly
  i18n with plurals support and easy syntax.

You will like those projects!

---

# h1 Heading 8-)
## h2 Heading
### h3 Heading
#### h4 Heading
##### h5 Heading
###### h6 Heading


## Horizontal Rules

___

---

***


## Typographic replacements

Enable typographer option to see result.

(c) (C) (r) (R) (tm) (TM) (p) (P) +-

test.. test... test..... test?..... test!....

!!!!!! ???? ,,  -- ---

"Smartypants, double quotes" and 'single quotes'


## Emphasis

**This is bold text**

__This is bold text__

*This is italic text*

_This is italic text_

~~Strikethrough~~


## Blockquotes


> Blockquotes can also be nested...
>> ...by using additional greater-than signs right next to each other...
> > > ...or with spaces between arrows.


## Lists

Unordered

+ Create a list by starting a line with `+`, `-`, or `*`
+ Sub-lists are made by indenting 2 spaces:
  - Marker character change forces new list start:
    * Ac tristique libero volutpat at
    + Facilisis in pretium nisl aliquet
    - Nulla volutpat aliquam velit
+ Very easy!

Ordered

1. Lorem ipsum dolor sit amet
2. Consectetur adipiscing elit
3. Integer molestie lorem at massa


1. You can use sequential numbers...
1. ...or keep all the numbers as `1.`

Start numbering with offset:

57. foo
1. bar


## Code

Inline `code`

Indented code

    // Some comments
    line 1 of code
    line 2 of code
    line 3 of code


Block code "fences"

```
Sample text here...
```

Syntax highlighting

``` js
var foo = function (bar) {
  return bar++;
};

console.log(foo(5));
```

## Tables

| Option | Description |
| ------ | ----------- |
| data   | path to data files to supply the data that will be passed into templates. |
| engine | engine to be used for processing templates. Handlebars is the default. |
| ext    | extension to be used for dest files. |

Right aligned columns

| Option | Description |
| ------:| -----------:|
| data   | path to data files to supply the data that will be passed into templates. |
| engine | engine to be used for processing templates. Handlebars is the default. |
| ext    | extension to be used for dest files. |


## Links

[link text](http://dev.nodeca.com)

[link with title](http://nodeca.github.io/pica/demo/ "title text!")

Autoconverted link https://github.com/nodeca/pica (enable linkify to see)


## Images

![Minion](https://octodex.github.com/images/minion.png)
![Stormtroopocat](https://octodex.github.com/images/stormtroopocat.jpg "The Stormtroopocat")

Like links, Images also have a footnote style syntax

![Alt text][id]

With a reference later in the document defining the URL location:

[id]: https://octodex.github.com/images/dojocat.jpg  "The Dojocat"


## Plugins

The killer feature of `markdown-it` is very effective support of
[syntax plugins](https://www.npmjs.org/browse/keyword/markdown-it-plugin).


### [Emojies](https://github.com/markdown-it/markdown-it-emoji)

> Classic markup: :wink: :crush: :cry: :tear: :laughing: :yum:
>
> Shortcuts (emoticons): :-) :-( 8-) ;)

see [how to change output](https://github.com/markdown-it/markdown-it-emoji#change-output) with twemoji.


### [Subscript](https://github.com/markdown-it/markdown-it-sub) / [Superscript](https://github.com/markdown-it/markdown-it-sup)

- 19^th^
- H~2~O


### [\<ins>](https://github.com/markdown-it/markdown-it-ins)

++Inserted text++


### [\<mark>](https://github.com/markdown-it/markdown-it-mark)

==Marked text==


### [Footnotes](https://github.com/markdown-it/markdown-it-footnote)

Footnote 1 link[^first].

Footnote 2 link[^second].

Inline footnote^[Text of inline footnote] definition.

Duplicated footnote reference[^second].

[^first]: Footnote **can have markup**

    and multiple paragraphs.

[^second]: Footnote text.


### [Definition lists](https://github.com/markdown-it/markdown-it-deflist)

Term 1

:   Definition 1
with lazy continuation.

Term 2 with *inline markup*

:   Definition 2

        { some code, part of Definition 2 }

    Third paragraph of definition 2.

_Compact style:_

Term 1
  ~ Definition 1

Term 2
  ~ Definition 2a
  ~ Definition 2b


### [Abbreviations](https://github.com/markdown-it/markdown-it-abbr)

This is HTML abbreviation example.

It converts "HTML", but keep intact partial entries like "xxxHTMLyyy" and so on.

*[HTML]: Hyper Text Markup Language

### [Custom containers](https://github.com/markdown-it/markdown-it-container)

::: warning
*here be dragons*
:::




