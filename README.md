<p>Launcher is a powerful utility that support Terminal UI and Graphical UI and allows you to:</p>

<ul>
    <li>Save and organize multiple scripts and applications</li>
    <li>Enable or disable scripts on demand</li>
    <li>Run scripts and applications using GUI or terminal</li>
    <li>Run everything silently on system startup</li>
    <li>Run multiple scripts simultaneously or sequentially</li>
    <li>Load multiple scripts from external file</li>
    <li>Use AutoHotkey built-in and environment variables</li>
</ul>

![](/Images/Dual_UI.png)
![](/Images/frame_fast.gif)

## Quick Start

[Download and run `launcher.ahk`](https://github.com/JoyHak/Launcher/releases/latest). Add path to your script and click `Run` button. Create `.lnk` file in `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup` to run this script on system startup: `"path\to\launcher.exe" -autorun`.
If you prefer command line, add `launcher.exe` to PATH. Then open powershell or cmd and type:
```powershell
launcher --add=myscript.ahk
launcher --run=myscript.ahk
launcher -scripts
```
> `launcher.ahk` supports GUI mode only.

`launcher -scripts` and `launcher.ahk` displays the same scripts. You can manage them from terminal and GUI simultaneously!
![](/Images/frame_rainbow.gif)

## Usage Syntax

```fsharp
launcher --param=script1[;script2;script3...]
launcher --param=@file
launcher -switch
launcher variable=value
```

<table>
    <thead>
        <tr>
            <th>Pattern</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>--param=value</code></td>
            <td>Execute a parameter with a value</td>
            <td><code>launcher --run=script</code></td>
        </tr>
        <tr>
            <td><code>--param=val1;val2</code></td>
            <td>Multiple values separated by semicolon</td>
            <td><code>launcher --run=script1;script2</code></td>
        </tr>
        <tr>
            <td><code>--param=@file</code></td>
            <td>Load values from external file</td>
            <td><code>launcher --add=@list.ini</code></td>
        </tr>
        <tr>
            <td><code>-switch</code></td>
            <td>Execute a switch (no value)</td>
            <td><code>launcher -autorun</code></td>
        </tr>
        <tr>
            <td><code>variable=value</code></td>
            <td>Set a custom variable</td>
            <td><code>launcher myvar=C:\path</code></td>
        </tr>
    </tbody>
</table>

#### Parameters

Parameters perform specific actions on your scripts.

<table>
    <thead>
        <tr>
            <th>Parameter</th>
            <th>Description</th>
            <th>Usage Example</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>--add</code></td>
            <td>Add script(s) to the saved list</td>
            <td><code>launcher --add=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--enable</code></td>
            <td>Enable script(s). Can add and enable simultaneously</td>
            <td><code>launcher --enable=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--disable</code></td>
            <td>Disable script(s). Can add and disable simultaneously</td>
            <td><code>launcher --disable=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--run</code></td>
            <td>Run enabled script(s) immediately</td>
            <td><code>launcher --run=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--close</code></td>
            <td>Close running script(s)</td>
            <td><code>launcher --close=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--remove</code></td>
            <td>Remove script(s) from the saved list</td>
            <td><code>launcher --remove=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--sep</code></td>
            <td>Set custom separator for multiple scripts</td>
            <td><code>launcher --sep=^ --run=s1^s2</code></td>
        </tr>
    </tbody>
</table>

> [!tip]
> Parameters can be combined in a single command. They execute in left-to-right order:
> `launcher --add=script1.ahk --add=script2.ahk --enable --run`

#### Switches

<p>Switches control global behavior and data management. They don't require values.</p>

<table>
    <thead>
        <tr>
            <th>Switch</th>
            <th>Description</th>
            <th>Use Case</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>-autorun</code></td>
            <td>Run all enabled scripts automatically</td>
            <td>Launch all your enabled scripts with one command</td>
        </tr>
        <tr>
            <td><code>-autoclose</code></td>
            <td>Close all running scripts</td>
            <td>Shut down all active scripts</td>
        </tr>
        <tr>
            <td><code>-vars</code></td>
            <td>Display all saved variables</td>
            <td>View your configured variables</td>
        </tr>
        <tr>
            <td><code>-scripts</code></td>
            <td>Display all saved scripts</td>
            <td>See what scripts are registered</td>
        </tr>
        <tr>
            <td><code>-vars-clear</code></td>
            <td>Clear all saved variables</td>
            <td>Reset all custom variables</td>
        </tr>
        <tr>
            <td><code>-scripts-clear</code></td>
            <td>Clear all saved scripts</td>
            <td>Reset script registry</td>
        </tr>
        <tr>
            <td><code>-save</code></td>
            <td>Write all data to disk immediately</td>
            <td>Force save without processing remaining parameters</td>
        </tr>
        <tr>
            <td><code>-restore</code></td>
            <td>Restore data from disk</td>
            <td>Reload configuration from disk</td>
        </tr>
        <tr>
            <td><code>-verbose</code></td>
            <td>Show additional messages</td>
            <td>Debug and see detailed output</td>
        </tr>
        <tr>
            <td><code>-help, -h, -?</code></td>
            <td>Show help message</td>
            <td>Display built-in documentation</td>
        </tr>
    </tbody>
</table>

### Script Management
#### Adding Scripts
```fsharp
launcher --add=quickswitch.ahk
launcher --add=C:\Ahk\radify.ahk
```

In GUI you can specify path to the script in the input field and click `Add` at the bottom:
![](/Images/frame_fast.gif)

You can insert an absolute path *(C:\AutoHotkey\QuickSwitch)*, a path relative to the current working dir *(QuickSwitch)* or just filename *(script.ahk)*.

#### Enabling/Disabling Scripts
```fsharp
launcher --enable=quickswitch
launcher --disable=radify
```
In GUI use buttons at the bottom to manage scripts:
![](/Images/frame_rainbow.gif)

#### Running Scripts
By filename:
```fsharp
launcher --run=quickswitch
```
By full path:
```fsharp
launcher --run=C:\Ahk\quickswitch.ahk
```

#### Closing Scripts</h3>
```fsharp
launcher --close=quickswitch
launcher -autoclose
```

#### Removing Scripts
```fsharp
launcher --remove=quickswitch
launcher --remove=script1;script2;script3
```
#### Viewing Saved Scripts
```fsharp
launcher -scripts
launcher -scripts -verbose
```
Terminal switch `-scripts` and Graphical List View displays the same information, which means you can use both TUI and GUI to query required information.
![](/Images/TUI_scrips.png)
![](/Images/GUI_scripts.png)

### Custom Separators
By default, multiple scripts are separated by semicolon `;`
```fsharp
launcher --run=quickswitch;radify;arrows
```
You can change this for batch operations:
```fsharp
launcher --sep=^ --run=quickswitch^radify^arrows
```
Separator is saved:
```fsharp
launcher --run=script1^script2
launcher --run=script3^script4
```

#### Escaped values
For batch/PowerShell special characters, use quotes to escape them:</p>
```fsharp
launcher --sep='|'
launcher --sep"|"
launcher --sep='&'
```
> [!tip]
> If you need quotes inside quotes, escape them with backticks:
> ```fsharp
> launcher --sep="`""
> launcher --sep='`''
> ```

### File References

Load multiple scripts from external files using the `@file`, where file can be any path:
```fsharp
launcher --add=@list.in
launcher --remove=@list.ini
launcher --run=@scripts.ini
```
And `list.ini` lists file paths:
```
AutoHotKey\MarkdownToBBCode\MarkdownToBBCode.exe
AutoHotKey\ChangeLogSorter\ChangeLogSorter-1.0.ahk
AutoHotKey\QuickSwitch\QuickSwitch.ahk
```
You can pass simple filename relative to current working directory:
```fsharp
launcher --add=@list.ini
```
...or pass quoted full path:
```fsharp
launcher --run=@'C:\Temp files\My scripts'
launcher --run='@C:\Temp files\My scripts'
launcher --run="@C:\Temp files\My scripts"
```

`@file` can be passed to *any* [parameter](#parameters). Use it to organize your scripts into logical groups and version control them easily.

## Variables
Save and reuse custom variables that persist across sessions. For any [parameter](#parameters) or GUI input field you can pass a path that contains [environment variables](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables); built-in [AutoHotkey variables](https://www.autohotkey.com/docs/v2/Variables.htm#BuiltIn) or manually defined variables *(see below)*. Enclose the variables in percent signs `%`
```fsharp
launcher --run=<span class="blue">%A_Temp%</span>\DarkTheme.ahk
launcher --add=<span class="blue">%TEMP%</span>\scripts.ini
```
#### Define Variables
To define a new variable with *any* value, simply write `name=value` without any prefix like `--` or `@`
```fsharp
launcher mainDir=C:\Scripts\DarkGui
launcher projectPath=C:\MyProject
```
Values with spaces must be [escaped with quotes](#escaped-values):
```fsharp
launcher mainDir="C:\My Scripts\Dark Gui"
launcher projectPath='C:\Temp Scripts'

launcher --run=%mainDir%\DarkTheme.ahk
launcher --add=@'%projectPath%\scripts.ini'
```

#### Variables in Variables
New variable can hold literals and other [variables](#variables), including env. vars:
```fsharp
launcher mainDir=%A_ScriptDir%\DarkGui
launcher projectPath=%A_Temp%\myproject
launcher projectPath=%AppData%\Data
```


<h3>Modifying Variables On The Fly</h3>

<p>Change variable values within a single command to control different execution paths:</p>

<pre>launcher AhkDir=C:\Ahk <span class="green">--run</span>=<span class="blue">%AhkDir%</span>\quickswitch AhkDir=C:\Scripts <span class="green">--run</span>=<span class="blue">%AhkDir%</span>\radify</pre>

<div class="info">
    <strong>ℹ️ How it works:</strong> First part runs with <code class="blue">%AhkDir%</code> = <code>C:\Ahk</code>, second part with <code class="blue">%AhkDir%</code> = <code>C:\Scripts</code>
</div>

<h3>Removing Variables</h3>

<div class="success">
    <strong>✓ Method 1 - Empty value:</strong>
    <pre>launcher mainDir=</pre>
</div>

<div class="success">
    <strong>✓ Method 2 - Unset keyword:</strong>
    <pre>launcher mainDir=<span class="magenta">unset</span></pre>
</div>



<div class="success">
    <strong>✓ Path with variables:</strong>
    <pre>launcher listfile=C:\config\scripts.ini --add=<span class="yellow">@%listfile%</span></pre>
</div>

<h3>File Format</h3>

<p>Files can contain scripts, variables, and AutoHotkey variables separated by your chosen separator (default: <span class="green">;</span>):</p>

<pre>C:\s1.ahk<span class="green">;</span>C:\s2.ahk
C:\%A_Temp%\s3.ahk
C:\%myvar%\s4.ahk
%A_ScriptDir%\local.ahk</pre>


<h3>Viewing Variables</h3>

<pre>launcher -vars
launcher -vars -verbose</pre>

<h3>Clearing All Variables</h3>

<pre>launcher -vars-clear</pre>

<h3>AutoHotkey Built-in Variables</h3>

<p>Use AutoHotkey's built-in variables and environment variables directly:</p>

<table>
    <thead>
        <tr>
            <th>Variable</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><span class="blue">%A_ScriptFullPath%</span></td>
            <td>Full path to the current script</td>
            <td><code>launcher --run=<span class="blue">%A_ScriptFullPath%</span></code></td>
        </tr>
        <tr>
            <td><span class="blue">%A_ScriptDir%</span></td>
            <td>Directory of the current script</td>
            <td><code>launcher --add=<span class="blue">%A_ScriptDir%</span>\tools</code></td>
        </tr>
        <tr>
            <td><span class="blue">%A_Temp%</span></td>
            <td>AutoHotkey temporary directory</td>
            <td><code>launcher --run=<span class="blue">%A_Temp%</span>\script.ahk</code></td>
        </tr>
        <tr>
            <td><span class="blue">%TEMP%</span></td>
            <td>System temporary directory</td>
            <td><code>launcher --close=<span class="blue">%TEMP%</span>\junk.ahk</code></td>
        </tr>
        <tr>
            <td><span class="blue">%ConEmuDir%</span></td>
            <td>ConEmu directory (if installed)</td>
            <td><code>launcher --add=<span class="blue">%ConEmuDir%</span>\update.py</code></td>
        </tr>
        <tr>
            <td><span class="blue">%USERPROFILE%</span></td>
            <td>User home directory</td>
            <td><code>launcher --run=<span class="blue">%USERPROFILE%</span>\scripts</code></td>
        </tr>
    </tbody>
</table>

<h3>Variables in @file</h3>

<p>Variables work in external @file references too:</p>

<pre>C:\<span class="blue">%A_Temp%</span>\script.ahk
C:\<span class="blue">%myvar%</span>\important.ahk
<span class="blue">%projectDir%</span>\local\app.exe</pre>

<pre>launcher --add=<span class="yellow">@scripts.ini</span></pre>

<div class="note">
    <strong>💾 Remember:</strong> Custom variables are automatically saved and persist across sessions. To see all saved variables, use <code>launcher -vars</code>
</div>

<hr>

<h2 id="examples">🎯 Real-World Examples</h2>

<h3>Example 1: Basic Workflow</h3>

<pre>launcher --add=quickswitch.ahk
launcher --enable=quickswitch
launcher --run=quickswitch</pre>

<h3>Example 2: Multiple Scripts</h3>

<pre>launcher --add=script1.ahk --add=script2.ahk --add=script3.ahk
launcher --run=script1.ahk;script2.ahk;script3.ahk</pre>

<h3>Example 3: Project Setup with Variables</h3>

<pre>launcher projectDir=C:\MyProject
launcher scriptsFile=%projectDir%\scripts.ini
launcher --add=@%scriptsFile%
launcher --enable
launcher -autorun</pre>

<h3>Example 4: Development vs Production</h3>

<pre>launcher env=dev --run=<span class="blue">%env%</span>\test.ahk env=prod --run=<span class="blue">%env%</span>\deploy.ahk</pre>

<h3>Example 5: Custom Separator for Complex Operations</h3>

<pre>launcher --sep=| --run=cleanup|optimize|backup|report</pre>

<h3>Example 6: Load from External File</h3>

<pre>launcher --add=@'C:\Scripts\utilities.ini'
launcher --enable
launcher -autorun -verbose</pre>

<h3>Example 7: Safe Cleanup</h3>

<pre>launcher -autoclose -save -vars-clear</pre>

<h3>Example 8: Conditional Execution with Order</h3>

<pre>launcher -autoclose --add=@list.ini --enable -autorun</pre>

<hr>

<h2 id="best-practices">✅ Best Practices</h2>

<div class="success">
    <strong>✓ Use descriptive variable names</strong>
    <pre>launcher projectDir=C:\MyProject  ← Good
launcher pd=C:\MyProject           ← Poor</pre>
</div>

<div class="success">
    <strong>✓ Organize scripts in @file</strong>
    <p>Group related scripts in external files for easy version control and management.</p>
</div>

<div class="success">
    <strong>✓ Test with -verbose</strong>
    <pre>launcher -verbose --run=script.ahk</pre>
</div>

<div class="success">
    <strong>✓ Understand execution order</strong>
    <p>Remember: parameters execute left-to-right. Structure commands to match your workflow.</p>
</div>

<div class="success">
    <strong>✓ Use -save strategically</strong>
    <pre>launcher --add=script1 --add=script2 -save  ← Force immediate save</pre>
</div>

<div class="success">
    <strong>✓ Leverage AutoHotkey variables</strong>
    <pre>launcher --run=<span class="blue">%A_ScriptDir%</span>\tools.ahk  ← Relative to script</pre>
</div>

<div class="warning">
    <strong>⚠️ Avoid mixing separators</strong>
    <p>Once you set a custom separator, it persists. Be consistent or explicitly reset with <code>--sep</code></p>
</div>

<div class="info">
    <strong>ℹ️ Backup your configuration</strong>
    <p>Launcher saves data to disk. Consider backing up configuration if you have critical scripts.</p>
</div>

<hr>

<h2>🔗 Resources</h2>

<ul>
    <li><a href="https://github.com/JoyHak/Launcher">GitHub Repository</a></li>
    <li><a href="https://www.autohotkey.com">AutoHotkey Official Website</a></li>
    <li><a href="https://www.autohotkey.com/docs/v1/">AutoHotkey Documentation</a></li>
</ul>

<hr>

<div class="footer" style="text-align: center; padding: 20px; border-top: 1px solid #dfe2e5; color: #6a737d; font-size: 12px;">
    <p><strong>Launcher v1.0</strong> | Copyright (c) 2026 Rafaello</p>
    <p>For issues, feature requests, or documentation updates, visit the <a href="https://github.com/JoyHak/Launcher">GitHub repository</a></p>
</div>


#### Disk Usage

Each parameter can modify some internal data: variables, scripts paths, etc. Data is normally written to disk **after all parameters are processed** to reduce disk I/O operations. Use `-save` if you need to save data immediately:
```fsharp
launcher --add=script1 --add=script2 -save
launcher -restore -verbose
```

## Debugging
If something doesn't working as expexted, please [report about it](https://github.com/JoyHak/Launcher/issues/new?template=bug-report.yaml). You can pass `-verbose` swith to each command to get additional information.
![](/Images/TUI2.png)
If you're using terminal, attach this information to report please. In GUI mode use *ShareX* or *IceCream screen recorder* to record a video/gif with unexpected behavior.
