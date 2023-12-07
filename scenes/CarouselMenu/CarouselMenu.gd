# Copyright (C) 2023, Meowing Cat
# 23.12.2023
# Meowed by Meowing Cat
# 	<meowingcate@gmail.com>
#	(https://github.com/rohanrhu)
# Licensed under MIT.

extends Control

@export var animation_duration = 0.5

@onready var nPlaceholders = %Placeholders
@onready var nItems = %Items
@onready var nPlacements = %Placements

var current_index = 3

@onready var tween = get_tree().create_tween()

var is_busy = false

func _ready() -> void:
	nPlaceholders.hide()
	nItems.hide()
	
	var diff = 8 - nItems.get_child_count()
	
	if diff > 0:
		for i in range(diff):
			var index = (nItems.get_child_count() + i) % nItems.get_child_count()
			var nSource = nItems.get_child(index)
			var nItem = nSource.duplicate()
			nItems.add_child(nItem)
	
	for i in nItems.get_child_count():
		var nItem = nItems.get_child(i)
		nItem.identifier = i
		nItem.animation_duration = animation_duration
	
	init_placements()

func init_placements() -> void:
	var source_items = nPlacements.get_children()
	var new_items = []
	
	var ci
	var nCurrent
	
	ci = current_index - 3
	for i in range(4):
		var aci = ci
		if aci < 0:
			aci = nItems.get_child_count() + ci
		if aci == nItems.get_child_count():
			aci = 0
		var nItem = nItems.get_child(ci)
		var nToPlace = nItem.duplicate()
		nCurrent = nToPlace
		var nPlaceholder = nPlaceholders.get_child(i)
		nPlacements.add_child(nToPlace)
		new_items.append(nToPlace)
		_move_item_to_other(nToPlace, nPlaceholder)
		
		ci += 1
	
	nCurrent.set_is_current(true)
	
	ci = current_index
	for i in range(3):
		ci = (ci + 1) % nItems.get_child_count()
		var nItem = nItems.get_child(ci)
		var nToPlace = nItem.duplicate()
		var nPlaceholder = nPlaceholders.get_child(4 + i)
		nPlacements.add_child(nToPlace)
		new_items.append(nToPlace)
		_move_item_to_other(nToPlace, nPlaceholder)
	
	for node in source_items:
		node.queue_free()
	
	for i in range(new_items.size()):
		var nItem = new_items[i]
		if i in [0, 6]:
			nItem.modulate.a = 0
		else:
			nItem.modulate.a = 1

func go_left() -> void:
	if is_busy:
		return
	
	current_index -= 1
	if current_index < 0:
		current_index = nItems.get_child_count() + current_index
	if current_index == nItems.get_child_count():
		current_index = 0
	tween_items(current_index)

func go_right() -> void:
	if is_busy:
		return
	
	current_index = (current_index + 1) % nItems.get_child_count()
	tween_items(current_index)

func tween_items(p_current_index: int = current_index, p_animation_duration: float = animation_duration, p_reversed = false):
	init_placements()
	
	is_busy = true
	
	var placeholder_indexes = range(nPlaceholders.get_child_count())
	var item_indexes = []
	
	var ci
	
	ci = p_current_index - 3
	for i in range(4):
		var aci = ci
		if aci < 0:
			aci = nItems.get_child_count() + ci
		if aci == nItems.get_child_count():
			aci = 0
		if aci == 7:
			pass
		item_indexes.append(aci)
		ci += 1
	
	ci = p_current_index
	for i in range(3):
		ci = (ci + 1) % nItems.get_child_count()
		if ci == 7:
			pass
		item_indexes.append(ci)
	
	var new_items = _tween_by_indexes(placeholder_indexes, item_indexes, p_animation_duration, p_reversed)
	var ad_tween = get_tree().create_tween()
	
	for i in range(new_items.size()):
		var nItem = new_items[i]
		if i in [0, nPlaceholders.get_child_count() - 1]:
			ad_tween.parallel().tween_property(nItem, "modulate:a", 0, animation_duration)
		else:
			ad_tween.parallel().tween_property(nItem, "modulate:a", 1, animation_duration)
	
	await tween.finished
	
	is_busy = false

func _tween_by_indexes(p_placeholder_indexes: Array, p_item_indexes: Array, p_animation_duration: float = animation_duration, p_reversed = false) -> Array[CarouselMenuItem]:
	var source_items = nPlacements.get_children()
	var new_items: Array[CarouselMenuItem] = []
	
	tween = get_tree().create_tween()
	
	var ircs = {}
	
	for i in p_placeholder_indexes.size():
		var placeholder_index = i
		var item_index = p_item_indexes[i]
		
		var nPlaceholder: CarouselMenuItem = nPlaceholders.get_child(placeholder_index)
		if not ircs.has(item_index):
			ircs[item_index] = 0
		var nStatic = nItems.get_child(item_index)
		var nSource: CarouselMenuItem = _get_placement_by_item(nStatic, ircs[item_index], p_reversed)
		ircs[item_index] = ircs[item_index] + 1
		var nItem: CarouselMenuItem = nSource.duplicate()
		nItem.set_is_current(false)
		nPlacements.add_child(nItem)
		new_items.append(nItem)
		_move_item_to_other(nItem, nSource)
		
		tween.parallel().tween_property(nItem, "position", nPlaceholder.position, p_animation_duration)
		tween.parallel().tween_property(nItem, "anchor_left", nPlaceholder.anchor_left, p_animation_duration)
		tween.parallel().tween_property(nItem, "anchor_right", nPlaceholder.anchor_right, p_animation_duration)
		tween.parallel().tween_property(nItem, "anchor_top", nPlaceholder.anchor_top, p_animation_duration)
		tween.parallel().tween_property(nItem, "anchor_bottom", nPlaceholder.anchor_bottom, p_animation_duration)
		tween.parallel().tween_property(nItem, "offset_left", nPlaceholder.offset_left, p_animation_duration)
		tween.parallel().tween_property(nItem, "offset_right", nPlaceholder.offset_right, p_animation_duration)
		tween.parallel().tween_property(nItem, "offset_top", nPlaceholder.offset_top, p_animation_duration)
		tween.parallel().tween_property(nItem, "offset_bottom", nPlaceholder.offset_bottom, p_animation_duration)
		tween.parallel().tween_property(nItem, "z_index", nPlaceholder.z_index, p_animation_duration)
	
	for node in source_items:
		node.queue_free()
	
	var nCurrent = new_items[3]
	nCurrent.set_is_current(true)
	
	return new_items

func _get_placement_by_item(nItem: CarouselMenuItem, irc: int = 0, reversed = false) -> CarouselMenuItem:
	var items = nPlacements.get_children()
	if reversed:
		items.reverse()
	
	var irc_i = 0
	
	for node in items:
		if nItem.identifier == node.identifier:
			if irc_i >= irc:
				return node
			irc_i += 1
	
	return null

func _move_item_to_other(p_nItem: CarouselMenuItem, p_nDest: CarouselMenuItem) -> void:
	p_nItem.position = p_nDest.position
	p_nItem.anchor_left = p_nDest.anchor_left
	p_nItem.anchor_right = p_nDest.anchor_right
	p_nItem.anchor_top = p_nDest.anchor_top
	p_nItem.anchor_bottom = p_nDest.anchor_bottom
	p_nItem.offset_left = p_nDest.offset_left
	p_nItem.offset_right = p_nDest.offset_right
	p_nItem.offset_top = p_nDest.offset_top
	p_nItem.offset_bottom = p_nDest.offset_bottom
	p_nItem.z_index = p_nDest.z_index

func _on_LeftButton_pressed() -> void:
	go_left()

func _on_RightButton_pressed() -> void:
	go_right()
