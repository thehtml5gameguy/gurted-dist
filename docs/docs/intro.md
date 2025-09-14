---
sidebar_position: 1
---

# Introduction

**Gurted** is a project introducing a new web ecosystem, featuring:
- the **gurt:// protocol**
- a custom search engine
- a custom browser - **Flumi**
- a custom **DNS** (Domain Name System)
- a modern approach to web content via a modified HTML, CSS and Lua standard

### The GURT Protocol

**GURT** is a *content delivery protocol* similar to HTTPS. It's the core of how Gurted applications communicate.

Learn more about the GURT protocol: [Protocol Specification](./gurt-protocol.md)

## Getting Started

Get started by **exploring Gurted sites** or **try creating your first GURT page**.

To get started, download:
- [Flumi](https://gurted.com/download/), the official browser for `gurt://`
- A *text editor* of choice, we recommend [Visual Studio Code](https://code.visualstudio.com/download)

## Components

Gurted consists of three main components:

### 1. A modified HTML standard

```html
<head>
    <title>Yo Gurt</title>
    <icon src="gurt://example.real/icon.png">
    
    <style>...</style>
</head>

<body>
    <h1 style="text-3xl font-bold text-center">Welcome to Gurted!</h1>
    <p style="text-lg text-center">A new way to the web (ᵔᴥᵔ)</p>
</body>
```

### 2. Utility-First CSS
Tailwind-inspired styling system implemented natively:

```html
<div style="flex flex-col gap-4 p-4 bg-[#f8fafc] rounded">
    <h2 style="text-2xl font-bold text-[#1e293b]">Content Area</h2>
    <p style="text-[#64748b]">Style with utility classes</p>
</div>
```

### 3. Lua Scripting

```html
<script>
-- Modify tag
local heading = gurt.select('h1');

heading:text('Oh, I changed!')

-- Create a div
local new_div = gurt.create('div', {
    style = 'bg-red-500 p-4'
})

gurt.select('body'):append(new_div)
</script>
```

## Facts about Flumi
Flumi, the wayfinder of Gurted, is created in **Godot** - the game engine.

This allows for faster development, native performance, cross-platform by design, and *advanced features* we'll explore later... 😏