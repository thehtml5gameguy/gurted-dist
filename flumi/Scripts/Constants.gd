extends Node

const MAIN_COLOR = Color(27/255.0, 27/255.0, 27/255.0, 1)
const SECONDARY_COLOR = Color(43/255.0, 43/255.0, 43/255.0, 1)

const HOVER_COLOR = Color(0, 0, 0, 1)

const DEFAULT_CSS = """
body { text-base text-[#000000] text-left bg-white font-serif }
h1 { text-5xl font-bold }
h2 { text-4xl font-bold }
h3 { text-3xl font-bold }
h4 { text-2xl font-bold }
h5 { text-xl font-bold }
b { font-bold }
i { font-italic }
u { underline }
small { text-xl }
mark { bg-[#FFFF00] }
code { text-xl font-mono }
a { text-[#1a0dab] }
pre { text-xl font-mono }

img { object-fill }
button { text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] px-3 py-1.5 }
button[disabled] { bg-[#666666] text-[#999999] cursor-not-allowed }

select { text-[#000000] border border-[#000000] rounded-[3px] bg-transparent px-3 py-1.5 }
select:active { text-[#000000] border-[3px] border-[#000000] }

input[type="color"] { w-32 }
input[type="range"] { w-32 }
input[type="text"] { text-[16px] w-64 }
input[type="number"] { w-32 text-[16px] bg-transparent border border-[#000000] rounded-[3px] text-[#000000] hover:border-[3px] hover:border-[#000000] px-3 py-1.5 }
input[type="date"] { w-28 text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] px-3 py-1.5 }
"""

var HTML_CONTENT = """
<head>
<title>New tab</title>
<script>
local items = {"Hi","Hello","Salut","Bonjour","Hola","Ciao","Hallo","Hej","Hei","Ola","Privet","Zdravstvuyte","Konnichiwa","Ni hao","Annyeonghaseyo","Merhaba","Selam","Habari","Shalom","Namaste","Marhaba","Geia","Sawasdee","Selamat","Halo","Kumusta","Sawubona","Jambo","Aloha","Goddag","Tere","Moikka","Sveiki"}
local h = gurt.select(".target")
local res = items[math.random(#items)] .. "!"

h.text = res
</script>
</head>
<body style="bg-[#323949] text-white font-sans">
	<div style="flex flex-col items-center justify-center w-full mt-12">
		<h1 style="target text-8xl font-bold mb-4 text-[#4a9eff] font-serif font-italic">Hello!</h1>
		<p style="text-lg mb-8 text-[#cccccc]">Start browsing by typing in the omnibar.</p>
	
		<p style="mb-2">Happy GURT:// exploration!</p>
	</div>
</body>
""".to_utf8_buffer()
