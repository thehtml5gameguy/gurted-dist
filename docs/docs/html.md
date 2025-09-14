---
sidebar_position: 2
---

# HTML Standard

Gurted implements a HTML markup language that renders natively through Flumi. This standard supports familiar HTML elements with new features and modern styling capabilities.

## Document Structure

Every Gurted document follows a familiar HTML structure:

```html
<head>
    <title>My Gurted Page</title>
    <icon src="https://example.com/icon.png">
    <meta name="theme-color" content="#1a202c">
    <meta name="description" content="Page description">
    
    <font name="roboto" src="https://fonts.gstatic.com/.../roboto.woff2" />
    <style>/* CSS rules */</style>
    <script src="script.lua" />
</head>

<body>
    <!-- Content goes here -->
</body>
```

## Text Elements

### Headers
Headers are styled with progressive sizes and bold text:

```html
<h1>Header 1</h1>  <!-- text-5xl font-bold -->
<h2>Header 2</h2>  <!-- text-4xl font-bold -->
<h3>Header 3</h3>  <!-- text-3xl font-bold -->
<h4>Header 4</h4>  <!-- text-2xl font-bold -->
<h5>Header 5</h5>  <!-- text-xl font-bold -->
<h6>Header 6</h6>  <!-- text-base font-bold -->
```

### Paragraphs and Inline Text
Paragraphs and inline text elements support various styles:
```html
<p>Normal paragraph text with automatic wrapping</p>
<p style="font-mono">Monospace font paragraph</p>
<p style="font-sans">Sans-serif font (default)</p>
<p style="font-roboto">Custom web font</p>

<b>Bold text</b>
<i>Italic text</i>
<u>Underlined text</u>
<small>Small text</small>
<mark>Highlighted text</mark>
<code>Inline code with monospace</code>
<span>Generic inline container</span>
```

### Preformatted Text
The `<pre>` element preserves whitespace and line breaks:

```html
<pre>
Text in a pre element
is displayed in a fixed-width
font, and it preserves
both      spaces and
line breaks
</pre>
```

### Links
Links can point to external URLs (which open in the user's default browser) or GURT protocol links:
```html
<a href="https://example.com">External link</a>
<a href="gurt://internal.site">GURT protocol link</a>
```

### Line Breaks
Line breaks can be added using the `<br>` tag:
```html
<p>First line<br>Second line</p>
```

## Container Elements

### Division Elements
Generic containers with full flexbox support:

```html
<div style="flex flex-col gap-4 p-4 bg-[#f8fafc] rounded">
    <h2>Content Area</h2>
    <p>Container content</p>
</div>
```

### Separators
Visual dividers for content sections:

```html
<separator />  <!-- Horizontal separator (default) -->
<separator direction="horizontal" />
<separator direction="vertical" />
```

## List Elements

### Unordered Lists
Support multiple bullet styles:

```html
<ul>               <!-- Default disc bullets -->
    <li>Item 1</li>
    <li>Item 2</li>
</ul>

<ul type="circle"> <!-- Circle bullets -->
    <li>Item 1</li>
    <li>Item 2</li>
</ul>

<ul type="square"> <!-- Square bullets -->
    <li>Item 1</li>
    <li>Item 2</li>
</ul>

<ul type="none">    <!-- No bullets -->
    <li>Item 1</li>
    <li>Item 2</li>
</ul>
```

### Ordered Lists
Multiple numbering systems supported:

```html
<!-- Default decimal numbering: 1, 2, 3... -->
<ol>
    <li>First item</li>
    <li>Second item</li>
    <li>Third item</li>
</ol>

<!-- Zero-padded numbering: 01, 02, 03... -->
<ol type="zero-lead">
    <li>First item</li>
    <li>Second item</li>
</ol>

<!-- Lowercase letters: a, b, c... -->
<ol type="lower-alpha">
    <li>First item</li>
    <li>Second item</li>
</ol>

<!-- Uppercase letters: A, B, C... -->
<ol type="upper-alpha">
    <li>First item</li>
    <li>Second item</li>
</ol>

<!-- Lowercase Roman: i, ii, iii... -->
<ol type="lower-roman">
    <li>First item</li>
    <li>Second item</li>
</ol>

<!-- Uppercase Roman: I, II, III... -->
<ol type="upper-roman">
    <li>First item</li>
    <li>Second item</li>
</ol>
```
## Form Elements

### Input Types
Comprehensive form input support with validation:

#### Text Input

```html
<input type="text" placeholder="Enter your name" value="John" maxlength="20" minlength="3" />
```

#### Password Input

```html
<input type="password" placeholder="Your password..." />
```

#### Email Input

```html
<input type="email" placeholder="Enter your email address" pattern="^[^@\s]+@[^@\s]+\.[^@\s]+$" />
```

#### Checkbox

```html
<input type="checkbox" />
<input type="checkbox" value="true" checked="true" />
```

#### Radio Buttons

```html
<input type="radio" group="food" />
<span>Pizza</span>
<input type="radio" group="food" />
<span>Pasta</span>
<input type="radio" group="food" checked="true" />
<span>Salad</span>
```

#### Color Picker

```html
<input type="color" value="#ff0000" />
```

#### Date Picker

```html
<input type="date" value="2024-01-15" />
```

#### Range Slider

```html
<input type="range" min="0" max="100" step="5" value="50" style="max-w-32 max-h-8" />
```

#### Number Input

```html
<input type="number" min="1" max="10" step="0.5" value="5" placeholder="Enter number" />
```

#### File Upload

```html
<input type="file" accept=".txt,.pdf,image/*" />
```

### Buttons
Basic and styled buttons with various states:

```html
<!-- Basic buttons -->
<button>Normal Button</button>
<button disabled="true">Disabled Button</button>

<!-- Styled buttons -->
<button style="bg-[#3b82f6] text-white px-4 py-2 rounded 
               hover:bg-[#2563eb] active:bg-[#1e40af]">
    Primary Button
</button>

<button style="bg-[#10b981] text-white px-4 py-2 rounded-lg
               hover:bg-[#059669] active:bg-[#047857]">
    Success Button
</button>

<!-- Form submission -->
<button type="submit">Submit Form</button>
```

### Select Dropdowns
Dropdown menus with option support:

```html
<select style="text-center max-w-40 max-h-32">
    <option value="option1">Option 1</option>
    <option value="option2" selected="true">Option 2 (Selected)</option>
    <option value="option3">Option 3</option>
    <option value="option4" disabled="true">Option 4 (Disabled)</option>
</select>
```

### Textarea
Multi-line text input with configuration options:

```html
<!-- Basic textarea -->
<textarea></textarea>

<!-- Configured textarea -->
<textarea cols="30" rows="5" maxlength="200" placeholder="Enter your message..."></textarea>

<!-- Read-only textarea -->
<textarea readonly="true">This text cannot be edited</textarea>

<!-- Disabled textarea -->
<textarea disabled="true" value="Disabled content"></textarea>
```

### Forms
Form containers with automatic layout:

```html
<form action="/submit" method="POST" style="flex flex-col gap-4 w-80 mx-auto">
    <input type="text" placeholder="Name" required="true" />
    <input type="email" placeholder="Email" required="true" />
    <textarea placeholder="Message" rows="4"></textarea>
    <button type="submit" style="bg-[#4ade80] text-white py-2 rounded">
        Submit
    </button>
</form>
```

## Media Elements

### Images
Network image loading with sizing controls:

```html
<img src="https://example.com/image.jpg" style="max-w-24 max-h-24 rounded" />
<img src="gurt://local.site/image.png" style="w-32 h-32" />
```

## Advanced Features

### Custom Fonts
Load and use web fonts:

```html
<head>
    <font name="roboto" src="https://fonts.gstatic.com/.../roboto.woff2" />

    <style>
        body { font-roboto }
        h1 { font-roboto text-3xl font-bold }
    </style>
</head>
```
The name provided in the `name` attribute is used for `font-[family]` styling in CSS.

### CSS Selectors
Advanced CSS selector support for complex styling:

```html
<head>
    <style>
        /* Descendant selectors */
        div p { text-[#663399] }
        .container span { bg-[#ffeeaa] }
        
        /* Direct child selectors */
        .outer > p { font-bold }
        .parent > button { bg-[#44cc88] }
        
        /* Adjacent sibling selectors */
        h1 + p { text-[#ff0000] font-bold }
        h2 + div { bg-[#eeffee] }
        
        /* General sibling selectors */
        h1 ~ p { text-[#0000ff] }
        h3 ~ span { bg-[#ffdddd] }
        
        /* Attribute selectors */
        input[type="text"] { border bg-[#f9f9f9] }
        a[href^="https"] { text-[#008000] font-bold }
        button[disabled] { bg-[#888888] text-[#cccccc] }
        input[placeholder*="email"] { border-2 border-[#0066cc] }
        div[style$="special"] { bg-[#ffffaa] }
    </style>
</head>
```

These will be documented in detail in the CSS section.

### Interactive States
Pseudo-class support for dynamic styling:

```html
<button style="bg-[#3498db] text-white rounded-lg px-4 py-2
               hover:bg-[#2980b9] hover:text-[#f8f9fa]
               active:bg-[#1f618d] active:text-[#ecf0f1]">
    Multi-State Button
</button>

<div style="cursor-pointer bg-[#1e293b] p-4 rounded-lg">
    <p>Clickable container with pointer cursor</p>
    <p>Child elements inherit the cursor style</p>
</div>
```

### Flexbox Layout
Gurted supports web-standard flexbox through [Yoga - layout engine by Meta](https://www.yogalayout.dev/):

```html
<!-- Flex container with gap and alignment -->
<div style="flex flex-row gap-4 justify-between items-center 
           w-64 h-16 bg-[#f0f0f0]">
    <span style="bg-[#ffaaaa] w-16 h-8 flex items-center justify-center">A</span>
    <span style="bg-[#aaffaa] w-16 h-8 flex items-center justify-center">B</span>
    <span style="bg-[#aaaaff] w-16 h-8 flex items-center justify-center">C</span>
</div>

<!-- Flex column with wrapping -->
<div style="flex flex-col flex-wrap gap-2 items-center h-32 w-32">
    <span>Item 1</span>
    <span>Item 2</span>
    <span>Item 3</span>
</div>

<!-- Flex grow/shrink/basis -->
<div style="flex flex-row gap-2 w-64">
    <span style="flex-grow-1 bg-[#ffaaaa]">Grow 1</span>
    <span style="flex-grow-2 bg-[#aaffaa]">Grow 2</span>
    <span style="flex-shrink-0 w-16 bg-[#aaaaff]">No Shrink</span>
</div>

<!-- Self alignment -->
<div style="flex flex-row h-24 items-stretch gap-2">
    <span style="self-start bg-[#ffaaaa]">Start</span>
    <span style="self-center bg-[#aaffaa]">Center</span>
    <span style="self-end bg-[#aaaaff]">End</span>
    <span style="self-stretch bg-[#ffffaa]">Stretch</span>
</div>
```

### Border Styling
Border styling supports various widths, sides, and colors:

```html
<!-- Border widths -->
<div style="border p-2">Default border (1px)</div>
<div style="border-2 p-2">2px border</div>
<div style="border-4 p-2">4px border</div>

<!-- Border sides -->
<div style="border-t p-2">Top border only</div>
<div style="border-r p-2">Right border only</div>
<div style="border-b p-2">Bottom border only</div>
<div style="border-l p-2">Left border only</div>

<!-- Border styles -->
<div style="border border-solid p-2">Solid border</div>
<div style="border border-dashed p-2">Dashed border</div>
<div style="border border-dotted p-2">Dotted border</div>

<!-- Border colors -->
<div style="border-2 border-red-500 p-2">Red border</div>
<div style="border-2 border-[#3b82f6] p-2">Custom hex border</div>
```

## Default Styling

Gurted provides sensible defaults for all HTML elements:

- **Body**: `text-base text-[#000000] text-left`
- **Headers**: Progressive scaling from `text-5xl` (h1) to `text-base` (h6), all `font-bold`
- **Buttons**: `bg-[#1b1b1b] rounded-md text-white` with hover states
- **Links**: `text-[#1a0dab]` (classic web blue)
- **Code**: `text-xl font-mono`
- **Mark**: `bg-[#FFFF00]` (yellow highlight)
- **Small**: `text-xl` (smaller than base)
- **Pre**: `text-xl font-mono`
- **B**: `font-bold`
- **I**: `font-italic`
- **U**: `underline`
- **Images**: `object-fill`
- **Select**: `text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] px-3 py-1.5`
- **Color input**: `w-32`
- **Range input**: Same as above
- **Text input**: `text-[16px] w-64`
- **Number input**: `w-32 text-[16px] bg-transparent border border-[#000000] rounded-[3px] text-[#000000] hover:border-[3px] hover:border-[#000000] px-3 py-1.5`
- **Date input**: `w-28 text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] px-3 py-1.5`
