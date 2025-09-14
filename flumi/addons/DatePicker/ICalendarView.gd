class_name ICalendarView
extends RefCounted

## A view that dictates how a calendar should be displayed (i.e. MonthView or YearView).

## The calendar that this view is a part of.
var calendar: Calendar

## When the user clicks the previous button (i.e. go to the previous year).
func previous():
	pass

## When the user clicks the next button (i.e. go to the next year).
func next():
	pass

## Update the view to reflect the selected date.
func refresh():
	pass
