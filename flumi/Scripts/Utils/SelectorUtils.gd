class_name SelectorUtils
extends RefCounted

static func match_element(selector: String, element: HTMLParser.HTMLElement) -> bool:
	if not element:
		return false
	
	var rule = CSSParser.CSSRule.new()
	rule.init(selector)
	
	var stylesheet = CSSParser.CSSStylesheet.new()
	return stylesheet.selector_matches(rule, "", element)

static func find_all_matching(selector: String, elements: Array[HTMLParser.HTMLElement]) -> Array[HTMLParser.HTMLElement]:
	var matches: Array[HTMLParser.HTMLElement] = []
	
	for element in elements:
		if match_element(selector, element):
			matches.append(element)
	
	return matches

static func find_first_matching(selector: String, elements: Array[HTMLParser.HTMLElement]) -> HTMLParser.HTMLElement:
	for element in elements:
		if match_element(selector, element):
			return element
	
	return null
