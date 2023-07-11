/datum/hud/slime
	ui_style = 'icons/mob/screen_slime.dmi'

/datum/hud/slime/New(mob/living/simple_animal/slime/owner)
	..()

	pull_icon = new /atom/movable/screen/pull()
	pull_icon.icon = ui_style
	pull_icon.update_appearance(UPDATE_ICON)
	pull_icon.screen_loc = ui_living_pull
	pull_icon.hud = src
	static_inventory += pull_icon


	healths = new /atom/movable/screen/healths/slime()
	infodisplay += healths
