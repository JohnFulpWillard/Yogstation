/obj/structure/bloodsucker
	icon = 'icons/obj/vamp_obj.dmi'
	///Who owns this structure?
	var/mob/living/owner
	/*
	 *	# Descriptions
	 *
	 *	We use vars to add descriptions to items.
	 *	This way we don't have to make a new /examine for each structure
	 *	And it's easier to edit.
	 */
	var/Ghost_desc
	var/Vamp_desc
	var/Vassal_desc
	var/Hunter_desc

/obj/structure/bloodsucker/examine(mob/user)
	. = ..()
	if(!user.mind && Ghost_desc != "")
		. += span_cult(Ghost_desc)
	if(IS_BLOODSUCKER(user) && Vamp_desc)
		if(!owner)
			. += span_cult("It is unsecured. Click on [src] while in your lair to secure it in place to get its full potential.")
			return
		. += span_cult(Vamp_desc)
	if(IS_VASSAL(user) && Vassal_desc != "")
		. += span_cult(Vassal_desc)
	if(IS_MONSTERHUNTER(user) && Hunter_desc != "")
		. += span_cult(Hunter_desc)

/// This handles bolting down the structure.
/obj/structure/bloodsucker/proc/bolt(mob/user)
	to_chat(user, span_danger("You have secured [src] in place."))
	to_chat(user, span_announce("* Bloodsucker Tip: Examine [src] to understand how it functions!"))
	owner = user

/// This handles unbolting of the structure.
/obj/structure/bloodsucker/proc/unbolt(mob/user)
	to_chat(user, span_danger("You have unsecured [src]."))
	owner = null

/obj/structure/bloodsucker/attackby(obj/item/item, mob/living/user, params)
	/// If a Bloodsucker tries to wrench it in place, yell at them.
	if(item.tool_behaviour == TOOL_WRENCH && !anchored && IS_BLOODSUCKER(user))
		user.playsound_local(null, 'sound/machines/buzz-sigh.ogg', 40, FALSE, pressure_affected = FALSE)
		to_chat(user, span_announce("* Bloodsucker Tip: Examine Bloodsucker structures to understand how they function!"))
		return
	. = ..()

/obj/structure/bloodsucker/attack_hand(mob/user, list/modifiers)
//	. = ..() // Don't call parent, else they will handle unbuckling.
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	/// Claiming the Rack instead of using it?
	if(istype(bloodsuckerdatum) && !owner)
		if(!bloodsuckerdatum.bloodsucker_lair_area)
			to_chat(user, span_danger("You don't have a lair. Claim a coffin to make that location your lair."))
			return FALSE
		if(bloodsuckerdatum.bloodsucker_lair_area != get_area(src))
			to_chat(user, span_danger("You may only activate this structure in your lair: [bloodsuckerdatum.bloodsucker_lair_area]."))
			return FALSE

		/// Radial menu for securing your Persuasion rack in place.
		to_chat(user, span_notice("Do you wish to secure [src] here?"))
		var/static/list/secure_options = list(
			"Yes" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_yes"),
			"No" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_no"))
		var/secure_response = show_radial_menu(user, src, secure_options, radius = 36, require_near = TRUE)
		if(!secure_response)
			return FALSE
		switch(secure_response)
			if("Yes")
				user.playsound_local(null, 'sound/items/ratchet.ogg', 70, FALSE, pressure_affected = FALSE)
				bolt(user)
				return FALSE
		return FALSE
	return TRUE

/obj/structure/bloodsucker/AltClick(mob/user)
	. = ..()
	if(user == owner && user.Adjacent(src))
		balloon_alert(user, "unbolt [src]?")
		var/static/list/unclaim_options = list(
			"Yes" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_yes"),
			"No" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_no")
			)
		var/unclaim_response = show_radial_menu(user, src, unclaim_options, radius = 36, require_near = TRUE)
		switch(unclaim_response)
			if("Yes")
				unbolt(user)

////////////////////////////////////////////////////

#define ALTAR_RANKS_PER_DAY 2
/obj/structure/bloodsucker/bloodaltar
	name = "blood altar"
	desc = "It is made of marble, lined with basalt, and radiates an unnerving chill that puts your skin on edge."
	icon_state = "bloodaltar"
	density = TRUE
	anchored = FALSE
	pass_flags = LETPASSTHROW
	can_buckle = FALSE
	var/sacrifices = 0
	var/sacrificialtask = FALSE
	var/organ_name = ""
	var/suckamount = 0
	var/heartamount = 0
	Ghost_desc = "This is a Blood Altar, where bloodsuckers can get two tasks per night to get more ranks."
	Vamp_desc = "This is a Blood Altar, which allows you to do two tasks per day to advance your ranks.\n\
		Interact with the Altar by clicking on it after it's bolted to get a task.\n\
		By checking your notes or the chat you can see what task needs to be done.\n\
		Remember you only get two tasks per night."
	Vassal_desc = "This is the blood altar, where your master does bounties to advanced their bloodsucking powers.\n\
		Aid your master by bringing them what they need for these bounties or help getting them."
	Hunter_desc = "This is a blood altar, where monsters usually practice a sort of bounty system to advanced their powers.\n\
		They normally sacrifice hearts or blood in exchange for these ranks, forcing them to move out of their lair.\n\
		It can only be used twice per night and it needs to be interacted it to be claimed, making bloodsuckers come back twice a night."

/obj/structure/bloodsucker/bloodaltar/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/climbable)

/obj/structure/bloodsucker/bloodaltar/bolt()
	. = ..()
	anchored = TRUE

/obj/structure/bloodsucker/bloodaltar/unbolt()
	. = ..()
	anchored = FALSE

/obj/structure/bloodsucker/bloodaltar/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!.)
		return
	if(!IS_BLOODSUCKER(user)) //not bloodsucker
		to_chat(user, span_warning("You can't figure out how this works."))
		return
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.has_task && !check_completion(user)) //not done but has a task? put them on their way
		to_chat(user, span_warning("You already have a rank up task!"))
		return
	if(bloodsuckerdatum.altar_uses >= ALTAR_RANKS_PER_DAY) //used the altar already
		to_chat(user, span_notice("You have done all tasks for the night, come back tomorrow for more."))
		return
	var/want_rank = tgui_alert(user, "Do you want to gain a task? This will cost 50 Blood.", "Task Manager", list("Yes", "No"))
	if(want_rank != "Yes" || QDELETED(src))
		return
	generate_task(user) //generate

/obj/structure/bloodsucker/bloodaltar/proc/generate_task(mob/living/user)
	var/task //just like amongus
	var/mob/living/carbon/crewmate = user
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = crewmate.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	suckamount = bloodsuckerdatum.task_blood_required
	heartamount = bloodsuckerdatum.task_heart_required
	if(!suckamount && !heartamount) // Generate random amounts if we don't already have them set
		switch(bloodsuckerdatum.bloodsucker_level + bloodsuckerdatum.bloodsucker_level_unspent)
			if(0 to 3)
				suckamount = rand(100, 200)
				heartamount = rand(1,2)
			if(3 to 8)
				suckamount = rand(200, 300)
				heartamount = rand(1,2)
			if(8 to INFINITY)
				suckamount = rand(500, 600)
				heartamount = rand(5,6)
	if(crewmate.blood_volume < 50)
		to_chat(user, span_danger("You don't have enough blood to gain a task!"))
		return
	bloodsuckerdatum.AddBloodVolume(-50)
	switch(rand(1, 3))
		if(1,2)
			bloodsuckerdatum.task_blood_required = suckamount
			task = "Suck [suckamount] units of pure blood."
		if(3)
			bloodsuckerdatum.task_heart_required = heartamount
			task = "Sacrifice [heartamount] hearts by using them on the altar."
			sacrificialtask = TRUE
	bloodsuckerdatum.task_memory += "<B>Current Rank Up Task</B>: [task]<br>"
	bloodsuckerdatum.has_task = TRUE
	to_chat(user, span_boldnotice("You have gained a new Task! [task] Remember to collect it by using the blood altar!"))

/obj/structure/bloodsucker/bloodaltar/proc/check_completion(mob/living/user)
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.task_blood_drank < bloodsuckerdatum.task_blood_required || sacrifices < bloodsuckerdatum.task_heart_required)
		return FALSE
	bloodsuckerdatum.task_memory = null
	bloodsuckerdatum.has_task = FALSE
	bloodsuckerdatum.bloodsucker_level_unspent++
	bloodsuckerdatum.altar_uses++
	bloodsuckerdatum.task_blood_drank = 0
	bloodsuckerdatum.task_blood_required = 0
	bloodsuckerdatum.task_heart_required = 0
	sacrifices = 0
	to_chat(user, span_notice("You have sucessfully done a task and gained a rank!"))
	sacrificialtask = FALSE
	return TRUE

/obj/structure/bloodsucker/bloodaltar/examine(mob/user)
	. = ..()
	if(sacrificialtask)
		if(sacrifices)
			. += span_boldnotice("It currently contains [sacrifices] [organ_name].")
	else
		return ..()

/obj/structure/bloodsucker/bloodaltar/attackby(obj/item/H, mob/user, params)
	if(!IS_BLOODSUCKER(user) && !IS_VASSAL(user))
		return ..()
	if(sacrificialtask)
		if(istype(H, /obj/item/organ/heart))
			if(istype(H, /obj/item/organ/heart/gland))
				to_chat(usr, span_warning("This type of organ doesn't have blood to sustain the altar!"))
				return ..()
			organ_name = H.name
			balloon_alert(user, "heart fed!")
			qdel(H)
			sacrifices++
			return
	return ..()
#undef ALTAR_RANKS_PER_DAY

////////////////////////////////////////////////////

/obj/structure/bloodsucker/bloodaltar/restingplace
	name = "resting place"
	desc = "This seem to hold a bit of significance."
	icon_state = "restingplace"
	var/awoken = FALSE
	can_buckle = TRUE
	Ghost_desc = "This is a Resting Place, where Lasombra bloodsucker can ascend their powers."
	Vamp_desc = "This is a Resting Place, which allows you to ascend your powers by gaining points using your ranks or blood.\n\
		Interact with the Altar by clicking on it after you have fed it a abyssal essence, acquirable through influences or sacrifices done on it.\n\
		Remember most ascended powers have benefits if used in the dark.\n\
		It only seems to speak to elders of 4 or higher ranks."
	Vassal_desc = "This is the resting place, where your master does rituals to ascend their bloodsucking powers.\n\
		Aid your master by bringing them what they need for these or by help getting them."
	Hunter_desc = "This is a blood altar, where monsters ascend their powers to shadowy levels.\n\
		They normally need ranks or blood in exchange for power, forcing them to move out of their lair and weakening them."

/obj/structure/bloodsucker/bloodaltar/restingplace/deconstruct(disassembled = TRUE)
	. = ..()
	if(awoken)
		new /obj/item/bloodsucker/abyssal_essence(loc)
	qdel(src)

/obj/structure/bloodsucker/bloodaltar/restingplace/attackby(obj/item/H, mob/user, params)
	if(!IS_BLOODSUCKER(user) && !IS_VASSAL(user))
		return ..()
	if(!awoken)
		if(istype(H, /obj/item/bloodsucker/abyssal_essence))
			to_chat(usr, span_notice("As you touch [src] with the [H], you start sensing something different coming from [src]!"))
			qdel(H)
			awoken = TRUE
		else
			to_chat(user, span_cult("Seems like you need a direct link to the abyss to awaken [src]. Maybe searching a spacial influence would yield something."))
		return
	return ..()

/obj/effect/reality_smash/attack_hand(mob/user, list/modifiers) // this is important
	if(!IS_BLOODSUCKER(user)) //only bloodsucker will attack this with their hand
		return
	if(DOING_INTERACTION(user, src))
		return
	if(user.mind in src.siphoners)
		balloon_alert(user, "already harvested!")
		return
	balloon_alert(user, "harvesting...")
	if(do_after(user, 10 SECONDS, src))
		user.put_in_hands(new /obj/item/bloodsucker/abyssal_essence)
		to_chat(user, span_notice("You finish harvesting the energy of [src]!"))
		src.siphoners |= user.mind

/obj/structure/bloodsucker/bloodaltar/restingplace/attack_hand(mob/user, list/modifiers)
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!IS_BLOODSUCKER(user))
		return ..()

	if(!anchored)
		return ..()

	if(LAZYLEN(buckled_mobs))
		do_sacrifice(buckled_mobs, user)
		return

	if(bloodsuckerdatum.my_clan?.control_type != BLOODSUCKER_CONTROL_SHADOWS)
		return ..()

	if(bloodsuckerdatum.bloodsucker_level < 4)
		to_chat(user, span_warning("Uncontent with your age, the resting place blocks its secrets. (You need to be rank 4)"))
		return ..()

	if(bloodsuckerdatum.clanpoints)
		var/list/upgradablepowers = list()
		var/list/unupgradablepowers = list(/datum/action/cooldown/bloodsucker/feed, /datum/action/cooldown/bloodsucker/masquerade, /datum/action/cooldown/bloodsucker/veil)
		for(var/datum/action/cooldown/bloodsucker/power as anything in bloodsuckerdatum.powers)
			if(initial(power.purchase_flags) & BLOODSUCKER_CAN_BUY)
				upgradablepowers += power
			if(is_type_in_list(power, unupgradablepowers))
				upgradablepowers -= power
			if(initial(power.ascended_power) == null)
				upgradablepowers -= power

		var/datum/action/cooldown/bloodsucker/choice = tgui_input_list(user, "What Power do you wish to ascend?", "Darkness Manager", upgradablepowers)
		if(!choice)
			return
		if((locate(upgradablepowers[choice]) in bloodsuckerdatum.powers))
			return
		var/datum/action/cooldown/bloodsucker/granted = new choice.ascended_power
		bloodsuckerdatum.BuyPower(granted)
		granted.level_current = rand(3, 4)
		granted.UpdateDesc()
		qdel(choice)
		to_chat(user, span_boldnotice("You have ascended [choice]!"))
		bloodsuckerdatum.clanpoints--
		return

	if(!awoken) //don't want this to affect power upgrading if you make another one
		to_chat(user, span_cult("Seems like you need a direct link to the abyss to awaken [src]. Maybe searching a spacial influence would yield something."))
		return

	icon_state = initial(icon_state) + (awoken ? "_idle" : "_awaken")
	update_appearance(UPDATE_ICON)
	var/rankspent
	switch(bloodsuckerdatum.clanprogress)
		if(0)
			bloodsuckerdatum.clanprogress++
			bloodsuckerdatum.clanpoints++
			to_chat(user, span_notice("As you touch the [src] you feel a slight pulse flow through you... You have gained a point!"))
			return
		if(1 to 3)
			rankspent = 1
		if(4 to 6)
			rankspent = 2
		if(7)
			rankspent = 3
		if(8 to INFINITY)
			to_chat(user, span_notice("You have evolved all abilities possible."))
			return
	var/want_clantask = tgui_alert(user, "Do you want to spend a rank to gain a shadowpoint? This will cost [rankspent] ranks.", "Dark Manager", list("Yes", "No"))
	if(want_clantask == "No" || QDELETED(src))
		return
	if(bloodsuckerdatum.bloodsucker_level_unspent < rankspent)
		var/another_shot = tgui_alert(user, "It seems like you don't have enough ranks, spend 550 blood instead?", "Dark Manager", list("Yes", "No"))
		if(another_shot == "No" || QDELETED(src))
			return
		if(bloodsuckerdatum.bloodsucker_blood_volume < 550)
			to_chat(user, span_danger("You don't have enough blood to gain a shadowpoint!"))
			return
		bloodsuckerdatum.AddBloodVolume(-550)
	else
		bloodsuckerdatum.bloodsucker_level_unspent -= rankspent
	bloodsuckerdatum.clanpoints++
	bloodsuckerdatum.clanprogress++

/obj/structure/bloodsucker/bloodaltar/restingplace/proc/do_sacrifice(list/pig, mob/living/carbon/user)
	var/mob/living/carbon/sacrifice = pick(pig)
	if(!sacrifice.mind)
		balloon_alert(user, "not worthy to sacrifice!")
		return
	if(sacrifice.stat == DEAD)
		balloon_alert(user, "[sacrifice.p_theyre()] already dead...")
		return
	balloon_alert(user, "starting sacrifice...")
	if(!do_after(user, 10 SECONDS, sacrifice))
		balloon_alert(user, "interrupted!")
		return
	playsound(get_turf(sacrifice), 'sound/weapons/slash.ogg', 50, TRUE, -1)
	sacrifice.adjustBruteLoss(200)
	balloon_alert(user, "success!")
	new /obj/item/bloodsucker/abyssal_essence(get_turf(src))

#define METALLIMIT 50

/obj/structure/bloodsucker/moldingstone
	name = "molding stone"
	desc = "Not made of marble, but will have to do."
	icon_state = "molding_stone"
	anchored = FALSE
	density = TRUE
	can_buckle = TRUE
	buckle_lying = 180
	var/metal = 0

/obj/structure/bloodsucker/moldingstone/examine(mob/user)
	. = ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.my_clan?.control_type >= BLOODSUCKER_CONTROL_METAL)
		if(metal)
			. += span_boldnotice("It currently contains [metal] metal to use in sculpting.")
	else
		return ..()

/obj/structure/bloodsucker/moldingstone/bolt()
	. = ..()
	anchored = TRUE

/obj/structure/bloodsucker/moldingstone/unbolt()
	. = ..()
	anchored = FALSE

/obj/structure/bloodsucker/moldingstone/update_overlays()
	. = ..()
	switch(metal)
		if(1 to 5)
			. += "metal"
		if(6 to 20)
			. += "metal_2"
		if(21 to 50)
			. += "metal_3"

/obj/structure/bloodsucker/moldingstone/attackby(obj/item/I, mob/user, params)
	if(!anchored)
		return
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!bloodsuckerdatum)
		return ..()
	if(bloodsuckerdatum.my_clan?.control_type < BLOODSUCKER_CONTROL_METAL)
		return ..()
	if(istype(I, /obj/item/stack/sheet/metal))
		if(metal >= METALLIMIT)
			balloon_alert(user, "full!")
			return
		var/obj/item/stack/sheet/metal/M = I
		if(metal + M.amount > METALLIMIT)
			M.use(METALLIMIT - metal)
			metal = METALLIMIT
		else
			metal = M.amount
			qdel(M)
		balloon_alert(user, "added [metal] metal")
	if(istype(I, /obj/item/bloodsucker/chisel))
		start_sculpiting(user)
	update_appearance(UPDATE_ICON)

/obj/structure/bloodsucker/moldingstone/proc/start_sculpiting(mob/living/artist)
	if(metal < 10)
		balloon_alert(artist, "not enough metal!")
		return
	var/list/possible_statues = list()
	for(var/obj/structure/bloodsucker/bloodstatue/statues_available as anything in subtypesof(/obj/structure/bloodsucker/bloodstatue))
		possible_statues[statues_available::name] = statues_available
	var/obj/structure/bloodsucker/bloodstatue/what_type = tgui_input_list(artist, "What kind of statue would you like to make?", "Artist Manual", possible_statues)
	if(!do_after(artist, 10 SECONDS, src))
		artist.balloon_alert(artist, "ruined!")
		metal -= rand(5, 10)
		update_appearance(UPDATE_ICON)

		return
	artist.balloon_alert(artist, "done, a masterpiece!")
	new what_type(get_turf(src))

/obj/structure/bloodsucker/moldingstone/CtrlClick(mob/user)
	if(!anchored)
		return ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!bloodsuckerdatum)
		return ..()
	if(bloodsuckerdatum.my_clan?.control_type < BLOODSUCKER_CONTROL_METAL)
		return ..()
	if(metal)
		var/count = input("How much metal would you like to retrieve from [src]?","Fine Metal", metal) as null | num
		if(count > METALLIMIT)
			count = METALLIMIT
		if(count > metal)
			count = metal
		metal -= count
		new /obj/item/stack/sheet/metal(get_turf(user), count)
	else
		to_chat(user, span_warning("There's no metal to retrieve in [src]."))
	update_appearance(UPDATE_ICON)
#undef METALLIMIT

/obj/structure/bloodsucker/bloodstatue
	name = "bloody countenance"
	desc = "It looks upsettingly familiar..."
	icon_state = "statue"

/obj/structure/bloodsucker/bloodstatue/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/art, 30)

/obj/structure/bloodsucker/bloodstatue/bolt()
	. = ..()
	anchored = TRUE
	START_PROCESSING(SSprocessing, src)

/obj/structure/bloodsucker/bloodstatue/unbolt()
	. = ..()
	anchored = FALSE
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/bloodsucker/bloodstatue/command
	name = "captain bust"
	desc = "It fills you with an eerie sense of patriotism."
	icon_state = "statue_command"

/obj/structure/bloodsucker/bloodstatue/command/attack_hand(mob/user, list/modifiers) //get rid of area requirement
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(istype(bloodsuckerdatum) && !owner)
		if(!bloodsuckerdatum.bloodsucker_lair_area)
			to_chat(user, span_danger("You don't have a lair. Claim a coffin to make that location your lair."))
			return FALSE
		to_chat(user, span_notice("Do you wish to secure [src] here?"))
		var/static/list/secure_options = list(
			"Yes" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_yes"),
			"No" = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_no"))
		var/secure_response = show_radial_menu(user, src, secure_options, radius = 36, require_near = TRUE)
		if(!secure_response)
			return FALSE
		switch(secure_response)
			if("Yes")
				user.playsound_local(null, 'sound/items/ratchet.ogg', 70, FALSE, pressure_affected = FALSE)
				bolt(user)
				return FALSE
		return FALSE
	return TRUE

/obj/structure/bloodsucker/bloodstatue/command/bolt()
	. = ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = owner?.mind?.has_antag_datum(/datum/antagonist/bloodsucker)
	var/area/current_area = get_area(src)
	if(current_area == bloodsuckerdatum.bloodsucker_lair_area)
		return
	bloodsuckerdatum.bloodsucker_lair_area.contained_turfs += current_area.contained_turfs

/obj/structure/bloodsucker/bloodstatue/command/unbolt()
	. = ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = owner?.mind?.has_antag_datum(/datum/antagonist/bloodsucker)
	var/area/current_area = get_area(src)
	if(current_area == bloodsuckerdatum.bloodsucker_lair_area)
		return
	bloodsuckerdatum.bloodsucker_lair_area.turfs_to_uncontain += current_area.contained_turfs

/obj/structure/bloodsucker/bloodstatue/greytide
	name = "greytider bust"
	desc = "Despite its simple attire it looks quite menancing."
	icon_state = "statue_assist"

/obj/structure/bloodsucker/bloodstatue/greytide/process()
	for(var/mob/living/carbon/carbon_in_area in get_area(src))
		if(IS_VASSAL(carbon_in_area) || IS_BLOODSUCKER(carbon_in_area) || carbon_in_area.has_status_effect(STATUS_EFFECT_EXPOSED))
			continue
		carbon_in_area.apply_status_effect(STATUS_EFFECT_EXPOSED)

////////////////////////////////////////////////////

/*/obj/structure/bloodsucker/bloodportrait
	name = "oil portrait"
	desc = "A disturbingly familiar face stares back at you. Those reds don't seem to be painted in oil..."
/obj/structure/bloodsucker/bloodbrazier
	name = "lit brazier"
	desc = "It burns slowly, but doesn't radiate any heat."
/obj/structure/bloodsucker/bloodmirror
	name = "faded mirror"
	desc = "You get the sense that the foggy reflection looking back at you has an alien intelligence to it."*/

////////////////////////////////////////////////////

/obj/structure/bloodsucker/possessedarmor
	name = "knight's armor"
	desc = "I swear I saw its eyes move..."
	icon_state = "posarmor"
	anchored = FALSE
	density = TRUE
	Ghost_desc = "This Knight's armor will come alive once non-bloodsuckers get close to it."
	Vamp_desc = "This is a possesed knight's armor, it will come alive once mortals get close to it.\n\
		You can reinforce it with 5 silver bars.\n\
		Good for immediate defense of your lair."
	Vassal_desc = "This is a possesed knight's armor, it will protect your master if people get too close to it."
	Hunter_desc = "This is a suspicious knight's armor. These things shouldn't be here, I shouldn't get too close."
	var/upgraded = FALSE

/obj/structure/bloodsucker/possessedarmor/upgraded
	name = "shiny knight's armor"
	upgraded = TRUE

/obj/structure/bloodsucker/possessedarmor/bolt()
	. = ..()
	anchored = TRUE
	START_PROCESSING(SSprocessing, src)

/obj/structure/bloodsucker/possessedarmor/unbolt()
	. = ..()
	anchored = FALSE
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/bloodsucker/possessedarmor/AltClick(mob/user)
	if(!anchored)
		setDir(turn(dir,-90))
	else
		return ..()

/obj/structure/bloodsucker/possessedarmor/attackby(obj/item/I, mob/user, params)
	if(upgraded)
		to_chat(user, span_warning("[src] is already reinforced!"))
		return
	if(istype(I, /obj/item/stack/sheet/mineral/silver))
		var/obj/item/stack/sheet/mineral/silver/S = I
		if(S.amount < 5)
			to_chat(user, span_warning("You need at least five silver bars to reinforce [src]!"))
			return
		else
			to_chat(user, span_notice("You start adding [I] to [src]..."))
			if(do_after(user, 5 SECONDS, src))
				S.use(5)
				new /obj/structure/bloodsucker/possessedarmor/upgraded(src.loc)
				qdel(src)
				return
	return ..()

/obj/structure/bloodsucker/possessedarmor/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/bloodsucker/possessedarmor/process()
	for(var/mob/living/passerby in dview(1, get_turf(src)))
		if(IS_BLOODSUCKER(passerby) || IS_VASSAL(passerby) || passerby.restrained())
			continue
		to_chat(passerby, span_warning("The armor starts moving!"))
		if(upgraded)
			new /mob/living/simple_animal/hostile/bloodsucker/possessedarmor/upgraded(src.loc)
		else
			new /mob/living/simple_animal/hostile/bloodsucker/possessedarmor(src.loc)
		qdel(src)

////////////////////////////////////////////////////

/obj/structure/bloodsucker/vassalrack
	name = "persuasion rack"
	desc = "If this wasn't meant for torture, then someone has some fairly horrifying hobbies."
	icon_state = "vassalrack"
	anchored = FALSE
	/// Start dense. Once fixed in place, go non-dense.
	density = TRUE
	can_buckle = TRUE
	buckle_lying = 180
	Ghost_desc = "This is a Vassal rack, which allows Bloodsuckers to thrall crewmembers into loyal minions."
	Vamp_desc = "This is the Vassal rack, which allows you to thrall crewmembers into loyal minions in your service.\n\
		Simply click and hold on a victim, and then drag their sprite on the vassal rack. Click on help intent on the vassal rack to unbuckle them.\n\
		To convert into a Vassal, repeatedly click on the persuasion rack while NOT on help intent. The time required scales with the tool in your off hand. This costs Blood to do.\n\
		Vassals can be turned into special ones by continuing to torture them once converted."
	Vassal_desc = "This is the vassal rack, which allows your master to thrall crewmembers into their minions.\n\
		Aid your master in bringing their victims here and keeping them secure.\n\
		You can secure victims to the vassal rack by click dragging the victim onto the rack while it is secured."
	Hunter_desc = "This is the vassal rack, which monsters use to brainwash crewmembers into their loyal slaves.\n\
		They usually ensure that victims are handcuffed, to prevent them from running away.\n\
		Their rituals take time, allowing us to disrupt it."
	/// Resets on each new character to be added to the chair. Some effects should lower it...
	var/convert_progress = 3
	/// Mindshielded and Antagonists willingly have to accept you as their Master.
	var/disloyalty_confirm = FALSE
	/// Prevents popup spam.
	var/disloyalty_offered = FALSE
	/// For Tzimisce bloodsuckers' rituals
	var/meat_points = 0
	var/bigmeat = 0
	var/intermeat = 0
	var/mediummeat = 0
	var/smallmeat = 0
	var/meat_amount = 0

/obj/structure/bloodsucker/vassalrack/deconstruct(disassembled = TRUE)
	. = ..()
	new /obj/item/stack/sheet/metal(src.loc, 4)
	new /obj/item/stack/rods(loc, 4)
	qdel(src)

/obj/structure/bloodsucker/vassalrack/examine(mob/user)
	. = ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.my_clan?.control_type == BLOODSUCKER_CONTROL_FLESH)
		if(meat_amount)
			. += span_boldnotice("It currently contains [meat_points] points to use in rituals.")
			. += span_boldnotice("You can add meat points to the rack by using muscle, acquired from <i>Dicing</i> corpses, on it.")
	else
		return ..()

/obj/structure/bloodsucker/vassalrack/bolt()
	. = ..()
	density = FALSE
	anchored = TRUE

/obj/structure/bloodsucker/vassalrack/unbolt()
	. = ..()
	density = TRUE
	anchored = FALSE

/obj/structure/bloodsucker/vassalrack/MouseDrop_T(atom/movable/movable_atom, mob/user)
	var/mob/living/living_target = movable_atom
	if(!anchored && IS_BLOODSUCKER(user))
		to_chat(user, span_danger("Until this rack is secured in place, it cannot serve its purpose."))
		to_chat(user, span_announce("* Bloodsucker Tip: Examine the Persuasion Rack to understand how it functions!"))
		return
	// Default checks
	if(!isliving(movable_atom) || !living_target.Adjacent(src) || living_target == user || !isliving(user) || has_buckled_mobs() || user.incapacitated() || living_target.buckled)
		return
	// Don't buckle Silicon to it please.
	if(issilicon(living_target))
		to_chat(user, span_danger("You realize that Silicon cannot be vassalized, therefore it is useless to buckle them."))
		return
	if(do_after(user, 5 SECONDS, living_target))
		attach_victim(living_target, user)

/obj/structure/bloodsucker/vassalrack/proc/attach_victim(mob/living/target, mob/living/user)
	// Standard Buckle Check
	target.forceMove(get_turf(src))
	if(!buckle_mob(target))
		return
	user.visible_message(
		span_notice("[user] straps [target] into the rack, immobilizing them."),
		span_boldnotice("You secure [target] tightly in place. They won't escape you now."),
	)

	playsound(loc, 'sound/effects/pop_expl.ogg', 25, 1)
	density = TRUE
	update_appearance(UPDATE_ICON)

	// Set up Torture stuff now
	convert_progress = 3
	disloyalty_confirm = FALSE
	disloyalty_offered = FALSE

/// Attempt Release (Owner vs Non Owner)
/obj/structure/bloodsucker/vassalrack/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(IS_BLOODSUCKER(user) || IS_VASSAL(user))
		return ..()

	if(buckled_mob == user)
		user.visible_message(
			span_danger("[user] tries to release themself from the rack!"),
			span_danger("You attempt to release yourself from the rack!"),
			span_hear("You hear a squishy wet noise."))
		if(!do_after(user, 20 SECONDS, user))
			return
	else
		buckled_mob.visible_message(
			span_danger("[user] tries to pull [buckled_mob] rack!"),
			span_danger("[user] tries to pull [buckled_mob] rack!"),
			span_hear("You hear a squishy wet noise."))
		if(!do_after(user, 10 SECONDS, buckled_mob))
			return

	return ..()

/obj/structure/bloodsucker/vassalrack/unbuckle_mob(mob/living/buckled_mob, force = FALSE, can_fall = TRUE)
	. = ..()
	if(!.)
		return FALSE
	visible_message(span_danger("[buckled_mob][buckled_mob.stat == DEAD ? "'s corpse" : ""] slides off of the rack."))
	density = FALSE
	buckled_mob.Paralyze(2 SECONDS)
	update_appearance(UPDATE_ICON)
	return TRUE

/obj/structure/bloodsucker/vassalrack/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!.)
		return FALSE
	// Is there anyone on the rack & If so, are they being tortured?
	if(!has_buckled_mobs())
		return FALSE
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	var/mob/living/carbon/buckled_carbons = pick(buckled_mobs)
	if(user.a_intent == INTENT_HELP)
		if(istype(bloodsuckerdatum))
			unbuckle_mob(buckled_carbons)
			return FALSE
		user_unbuckle_mob(buckled_carbons, user)
		return
	if(!bloodsuckerdatum.my_clan)
		to_chat(user, span_warning("You can't vassalize people until you enter a Clan (Through your Antagonist UI button)"))
		user.balloon_alert(user, "join a clan first!")
		return
	/// If I'm not a Bloodsucker, try to unbuckle them.
	var/datum/antagonist/vassal/vassaldatum = IS_VASSAL(buckled_carbons)
	// Are they our Vassal, or Dead?
	if(buckled_carbons.stat == DEAD)
		if(bloodsuckerdatum.my_clan?.control_type < BLOODSUCKER_CONTROL_FLESH)
			balloon_alert(user, "[buckled_carbons.p_theyre()] dead!")
			return
		do_ritual(user, buckled_carbons)
		return
	if(vassaldatum && (vassaldatum in bloodsuckerdatum.vassals))
		SEND_SIGNAL(bloodsuckerdatum, BLOODSUCKER_PRE_MAKE_FAVORITE, vassaldatum)
		return

	// Not our Vassal, but Alive & We're a Bloodsucker, good to torture!
	torture_victim(user, buckled_carbons)

#define MEATLIMIT 3

/obj/structure/bloodsucker/vassalrack/attackby(obj/item/I, mob/user, params) //Tzimisce stuff
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.my_clan?.control_type < BLOODSUCKER_CONTROL_FLESH)
		return ..() // only gamers
	if(istype(I, /obj/item/muscle))
		if(meat_amount >= MEATLIMIT)
			to_chat(user, span_warning("You can't fit more meat into [src]"))
			return
		var/obj/item/muscle/M = I
		meat_points += M.size
		switch(M.size)
			if(4)
				bigmeat++
			if(3)
				intermeat++
			if(2)
				mediummeat++
			if(1)
				smallmeat++
		meat_amount = bigmeat + intermeat + mediummeat + smallmeat
		qdel(I)
	update_appearance(UPDATE_ICON)
#undef MEATLIMIT

/obj/structure/bloodsucker/vassalrack/update_overlays()
	. = ..()
	if(bigmeat)
		. += "bigmeat_[bigmeat]"
	if(intermeat)
		. += "mediummeat_[intermeat]"
		. += "smallmeat_[intermeat]"
	if(mediummeat)
		. += "mediummeat_[mediummeat + intermeat]"
	if(smallmeat)
		. += "smallmeat_[smallmeat + intermeat]"

/obj/structure/bloodsucker/vassalrack/CtrlClick(mob/user)
	if(!anchored)
		return ..()
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(bloodsuckerdatum.my_clan?.control_type < BLOODSUCKER_CONTROL_FLESH)
		return ..()
	if(meat_amount)
		if(smallmeat)
			new /obj/item/muscle/small(user.drop_location())
			smallmeat--
			meat_points -= 1
		if(mediummeat)
			new /obj/item/muscle/medium(user.drop_location())
			mediummeat--
			meat_points -= 2
		if(intermeat)
			new /obj/item/muscle/medium(user.drop_location())
			new /obj/item/muscle/small(user.drop_location())
			intermeat--
			meat_points -= 3
		if(bigmeat)
			new /obj/item/muscle/big(user.drop_location())
			bigmeat--
			meat_points -= 4
	else
		to_chat(user, span_warning("There's no meat to retrieve in [src]"))
	meat_amount = bigmeat + intermeat + mediummeat + smallmeat
	update_appearance(UPDATE_ICON)

/**
 *	Step One: Tick Down Conversion from 3 to 0
 *	Step Two: Break mindshielding/antag (on approve)
 *	Step Three: Blood Ritual
 */

/obj/structure/bloodsucker/vassalrack/proc/torture_victim(mob/living/user, mob/living/target)
	if(DOING_INTERACTION(user, target))
		balloon_alert(user, "already interacting!")
		return
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(IS_VASSAL(target))
		var/datum/antagonist/vassal/vassaldatum = target.mind.has_antag_datum(/datum/antagonist/vassal)
		if(!vassaldatum.master.broke_masquerade)
			balloon_alert(user, "someone else's vassal!")
			return FALSE

	var/disloyalty_requires = RequireDisloyalty(user, target)
	if(disloyalty_requires == VASSALIZATION_BANNED)
		balloon_alert(user, "can't be vassalized!")
		return FALSE

	// Conversion Process
	if(convert_progress)
		balloon_alert(user, "spilling blood...")
		bloodsuckerdatum.AddBloodVolume(-TORTURE_BLOOD_HALF_COST)
		if(!do_torture(user, target))
			return FALSE
		bloodsuckerdatum.AddBloodVolume(-TORTURE_BLOOD_HALF_COST)
		// Prevent them from unbuckling themselves as long as we're torturing.
		target.Paralyze(1 SECONDS)
		convert_progress--

		// We're done? Let's see if they can be Vassal.
		if(convert_progress)
			balloon_alert(user, "needs more persuasion...")
			return

		if(disloyalty_requires)
			balloon_alert(user, "has external loyalties! more persuasion required!")
		else
			balloon_alert(user, "ready for communion!")
		return

	if(!disloyalty_confirm && disloyalty_requires)
		if(!do_disloyalty(user, target))
			return
		if(!disloyalty_confirm)
			balloon_alert(user, "refused persuasion!")
		else
			balloon_alert(user, "ready for communion!")
		return

	user.balloon_alert_to_viewers("smears blood...", "painting bloody marks...")
	if(!do_after(user, 5 SECONDS, target))
		balloon_alert(user, "interrupted!")
		return
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		to_chat(user, span_danger("<i>They're mindshielded! Break their mindshield with a candelabrum or surgery before continuing!</i>"))
		return VASSALIZATION_DISLOYAL
	// Convert to Vassal!
	bloodsuckerdatum.AddBloodVolume(-TORTURE_CONVERSION_COST)
	if(bloodsuckerdatum.make_vassal(target))
		SEND_SIGNAL(bloodsuckerdatum, BLOODSUCKER_MADE_VASSAL, user, target)

/obj/structure/bloodsucker/vassalrack/proc/do_torture(mob/living/user, mob/living/carbon/target, mult = 1)
	// Fifteen seconds if you aren't using anything. Shorter with weapons and such.
	var/torture_time = 15
	var/torture_dmg_brute = 2
	var/torture_dmg_burn = 0
	var/obj/item/bodypart/selected_bodypart = pick(target.bodyparts)
	// Get Weapon
	var/obj/item/held_item = user.get_inactive_held_item()
	/// Weapon Bonus
	if(held_item)
		torture_time -= held_item.force / 4
		if(!held_item.use_tool(src, user, 0, volume = 5))
			return
		switch(held_item.damtype)
			if(BRUTE)
				torture_dmg_brute = held_item.force / 4
				torture_dmg_burn = 0
			if(BURN)
				torture_dmg_brute = 0
				torture_dmg_burn = held_item.force / 4
		switch(held_item.sharpness)
			if(SHARP_EDGED)
				torture_time -= 2
			if(SHARP_POINTY)
				torture_time -= 3

	// Minimum 5 seconds.
	torture_time = max(5 SECONDS, torture_time * 10)
	// Now run process.
	if(!do_after(user, (torture_time * mult), target))
		return FALSE

	if(held_item)
		playsound(loc, held_item.hitsound, 30, 1, -1)
		held_item.play_tool_sound(target)
	target.visible_message(
		span_danger("[user] performs a ritual, spilling some of [target]'s blood from their [selected_bodypart.name] and shaking them up!"),
		span_userdanger("[user] performs a ritual, spilling some blood from your [selected_bodypart.name], shaking you up!"))

	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob, emote), "scream")
	target.adjust_jitter(5 SECONDS)
	target.apply_damages(brute = torture_dmg_brute, burn = torture_dmg_burn, def_zone = selected_bodypart.body_zone)
	return TRUE

/// Offer them the oppertunity to join now.
/obj/structure/bloodsucker/vassalrack/proc/do_disloyalty(mob/living/user, mob/living/target)
	if(disloyalty_offered)
		return FALSE

	disloyalty_offered = TRUE
	to_chat(user, span_notice("[target] has been given the opportunity for servitude. You await their decision..."))
	var/alert_response = tgui_alert(
		user = target, \
		message = "You are being tortured! Do you want to give in and pledge your undying loyalty to [user]? \n\
			You will not lose your current objectives, but they come second to the will of your new master!", \
		title = "THE HORRIBLE PAIN! WHEN WILL IT END?!",
		buttons = list("Accept", "Refuse"),
		timeout = 10 SECONDS, \
		autofocus = TRUE, \
	)
	switch(alert_response)
		if("Accept")
			disloyalty_confirm = TRUE
		else
			target.balloon_alert_to_viewers("stares defiantly", "refused vassalization!")
	disloyalty_offered = FALSE

	return TRUE

/obj/structure/bloodsucker/vassalrack/proc/RequireDisloyalty(mob/living/user, mob/living/target)
#ifdef BLOODSUCKER_TESTING
	if(!target || !target.mind)
#else
	if(!target || !target.client)
#endif
		balloon_alert(user, "target has no mind!")
		return VASSALIZATION_BANNED

	var/datum/antagonist/bloodsucker/bloodsuckerdatum = IS_BLOODSUCKER(user)
	return bloodsuckerdatum.AmValidAntag(target)

/obj/structure/bloodsucker/vassalrack/proc/do_ritual(mob/living/user, mob/living/target)
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
	if(!target.mind)
		to_chat(user, span_warning("[target] is catatonic!"))
	/// To deal with Blood
	var/mob/living/carbon/human/B = user
	var/mob/living/carbon/human/H = target

	/// Due to the checks leding up to this, if they fail this, they're dead & Not our vassal.
	if(!IS_VASSAL(target)) //remind me to refactor this later
		to_chat(user, span_notice("Do you wish to rebuild this body? This will remove any restraints they might have, and will cost 150 Blood!"))
		var/revive_response = tgui_alert(usr, "Would you like to revive [target]?", "Ghetto Medbay", list("Yes", "No"))
		if(revive_response == "Yes")
			if(!do_after(user, 7 SECONDS, src))
				to_chat(user, span_danger("<i>The ritual has been interrupted!</i>"))
				return
			if(prob(70 - bloodsuckerdatum.bloodsucker_level * 7)) //calculation, stops going wrong at level 10
				to_chat(user, span_danger("Something has gone terribly wrong! You have accidentally turned [target] into a High-Functioning Zombie!"))
				to_chat(target, span_announce("As Blood drips over your body, your heart fails to beat... But you still wake up."))
				H.set_species(/datum/species/zombie)
			else
				to_chat(user, span_danger("You have brought [target] back from the Dead!"))
				to_chat(target, span_announce("As Blood drips over your body, your heart begins to beat... You live again!"))
			B.blood_volume -= 150
			target.revive(full_heal = TRUE, admin_revive = FALSE)
			return
		to_chat(user, span_danger("You decide not to revive [target]."))
		// Unbuckle them now.
		unbuckle_mob(B)
		return
	var/list/races = list(HUSK_MONSTER)
	switch(bloodsuckerdatum.bloodsucker_level)
		if(1 to 3)
			races += ARMMY_MONSTER
		if(3 to 5)
			races += ARMMY_MONSTER
			races += CALCIUM_MONSTER
		if(5 to INFINITY)
			races += ARMMY_MONSTER
			races += CALCIUM_MONSTER
			races += TRIPLECHEST_MONSTER
	var/list/options = list()
	options = races
	var/answer = tgui_input_list(user, "We have the chance to mutate our Vassal, how should we mutilate their corpse? This will cost us blood.", "What do we do with our Vassal?", options)
	var/meat_cost = 0
	var/blood_gained
	if(!answer)
		to_chat(user, span_notice("You decide to leave your Vassal just the way they are."))
		return
	to_chat(user, span_warning("You start mutating your Vassal into a [answer]..."))
	if(!do_after(user, 5 SECONDS, src))
		to_chat(user, span_danger("<i>The ritual has been interrupted!</i>"))
		return
	playsound(target.loc, 'sound/weapons/slash.ogg', 50, TRUE, -1)
	switch(answer)
		if(HUSK_MONSTER)
			if(HAS_TRAIT(target, TRAIT_HUSK))
				to_chat(user, span_warning("[target] is already a Husk!"))
				return
			if(!do_after(user, 1 SECONDS, target))
				return
			playsound(target.loc, 'sound/weapons/slash.ogg', 50, TRUE, -1)
			if(!do_after(user, 1 SECONDS, target))
				return
			to_chat(user, span_notice("You suck all the blood out of [target], turning them into a Living Husk!"))
			to_chat(target, span_notice("Your master has mutated you into a Living Husk!"))
			playsound(target.loc, 'sound/magic/mutate.ogg', 50, TRUE, -1)
			/// Just take it all
			blood_gained = 250
			target.remove_all_languages()
			target.grant_language(/datum/language/vampiric)
			H.become_husk()
			bloodsuckerdatum.bloodsucker_level_unspent++
		if(ARMMY_MONSTER)
			meat_cost = 4
			var/mob/living/simple_animal/hostile/bloodsucker/tzimisce/armmy/A
			if(!(HAS_TRAIT(target, TRAIT_HUSK)))
				to_chat(user, span_warning("You need to mutilate [target] into a husk first before doing this."))
				return
			if(meat_points < meat_cost)
				to_chat(user, span_warning("You need at least [meat_cost - meat_points] more meat points to do this."))
				return
			if(!do_after(user, 1 SECONDS, target))
				return
			playsound(target.loc, 'sound/weapons/slash.ogg', 50, TRUE, -1)
			to_chat(user, span_notice("You transfer your blood and toy with [target]'s flesh, leaving their body as a head and arm almalgam."))
			to_chat(target, span_notice("Your master has mutated you into a tiny arm monster!"))
			B.blood_volume -= 100
			A = new /mob/living/simple_animal/hostile/bloodsucker/tzimisce/armmy(target.loc)
			target.forceMove(A)
			target.mind.transfer_to(A)
			A.bloodsucker = target
		/// Chance to give Bat form, or turn them into a bat.
		if(CALCIUM_MONSTER)
			meat_cost = 8
			var/mob/living/simple_animal/hostile/bloodsucker/tzimisce/calcium/C
			if(!(HAS_TRAIT(target, TRAIT_HUSK)))
				to_chat(user, span_warning("You need to mutilate [target] into a husk first before doing this."))
				return
			if(meat_points < meat_cost)
				to_chat(user, span_warning("You need at least [meat_cost - meat_points] more meat points to do this."))
				return
			if(!do_after(user, 1 SECONDS, target))
				return
			playsound(target.loc, 'sound/weapons/slash.ogg', 50, TRUE, -1)
			to_chat(user, span_notice("You transfer your blood and toy with [target]'s flesh and bones, leaving their body as a boney and flesh amalgam."))
			to_chat(target, span_notice("Your master has mutated you into a fractured monster!"))
			B.blood_volume -= 150
			C = new /mob/living/simple_animal/hostile/bloodsucker/tzimisce/calcium(target.loc)
			target.forceMove(C)
			target.mind.transfer_to(C)
			C.bloodsucker = target
		if(TRIPLECHEST_MONSTER)
			meat_cost = 12
			var/mob/living/simple_animal/hostile/bloodsucker/tzimisce/triplechest/T
			if(!(HAS_TRAIT(target, TRAIT_HUSK)))
				to_chat(user, span_warning("You need to mutilate [target] into a husk first before doing this."))
				return
			if(meat_points < meat_cost)
				to_chat(user, span_warning("You need at least [meat_cost - meat_points] more meat points to do this."))
				return
			if(!do_after(user, 1 SECONDS, target))
				return
			playsound(target.loc, 'sound/weapons/slash.ogg', 50, TRUE, -1)
			if(!do_after(user, 1 SECONDS, target))
				return
			to_chat(user, span_notice("You transfer your blood and toy with [target]'s flesh and bones, leaving their body as a huge pile of flesh and organs."))
			to_chat(target, span_notice("Your master has mutated you into a gargantuan monster!"))
			B.blood_volume -= 300
			T = new /mob/living/simple_animal/hostile/bloodsucker/tzimisce/triplechest(target.loc)
			target.forceMove(T)
			target.mind.transfer_to(T)
			T.bloodsucker = target
	if(blood_gained)
		user.blood_volume += blood_gained
	var/meatlost = 0
	while(meat_cost)
		meat_points--
		meat_cost--
		meatlost++
		if(smallmeat && meatlost == 1)
			smallmeat--
			meatlost--
		if(mediummeat && meatlost == 2)
			mediummeat--
			meatlost -= 2
		if(intermeat && meatlost == 3)
			intermeat--
			meatlost -= 3
		if(bigmeat && meatlost == 4)
			bigmeat--
			meatlost -= 4
	update_appearance(UPDATE_ICON)
	meat_amount = bigmeat + intermeat + mediummeat + smallmeat

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/structure/bloodsucker/candelabrum
	name = "candelabrum"
	desc = "It burns slowly, but doesn't radiate any heat."
	icon_state = "candelabrum"
	light_color = "#66FFFF"//LIGHT_COLOR_BLUEGREEN // lighting.dm
	light_power = 3
	light_range = 0 // to 2
	density = FALSE
	can_buckle = TRUE
	anchored = FALSE
	Ghost_desc = "This is a magical candle which drains at the sanity of non Bloodsuckers and Vassals.\n\
		Vassals can also turn the candle on."
	Vamp_desc = "This is a magical candle which drains at the sanity of mortals who are not under your command while it is active.\n\
		You can click on it to turn it on, clicking on it with a mindshielded individual buckled will start to disable their mindshields."
	Vassal_desc = "This is a magical candle which drains at the sanity of the fools who havent yet accepted your master, as long as it is active.\n\
		You can turn it on and off by clicking on it while you are next to it."
	Hunter_desc = "This is a blue Candelabrum, which causes insanity to those near it while active."
	var/lit = FALSE

/obj/structure/bloodsucker/candelabrum/deconstruct(disassembled = TRUE)
	. = ..()
	new /obj/item/candle(loc, 1)
	new /obj/item/stack/rods(loc, 4)
	qdel(src)

/obj/structure/bloodsucker/candelabrum/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/bloodsucker/candelabrum/update_icon_state()
	. = ..()
	icon_state = "candelabrum[lit ? "_lit" : ""]"

/obj/structure/bloodsucker/candelabrum/examine(mob/user)
	. = ..()

/obj/structure/bloodsucker/candelabrum/bolt()
	. = ..()
	anchored = TRUE
	density = TRUE

/obj/structure/bloodsucker/candelabrum/unbolt()
	. = ..()
	anchored = FALSE
	density = FALSE

/obj/structure/bloodsucker/candelabrum/proc/toggle(mob/user)
	lit = !lit
	if(lit)
		set_light(2, 3, "#66FFFF")
		START_PROCESSING(SSobj, src)
	else
		set_light(0)
		STOP_PROCESSING(SSobj, src)
	update_appearance(UPDATE_ICON)

/obj/structure/bloodsucker/candelabrum/process()
	if(!lit)
		return
	for(var/mob/living/carbon/nearly_people in viewers(7, src))
		/// We dont want Bloodsuckers or Vassals affected by this
		if(IS_VASSAL(nearly_people) || IS_BLOODSUCKER(nearly_people))
			continue
		nearly_people.adjust_hallucinations(5 SECONDS)
		if(nearly_people.getStaminaLoss() >= 100)
			continue
		if(nearly_people.getStaminaLoss() >= 60)
			spawn(10)
			nearly_people.adjustStaminaLoss(1) // keeps the slowness by constantly updating it
		else
			nearly_people.adjustStaminaLoss(10)
		SEND_SIGNAL(nearly_people, COMSIG_ADD_MOOD_EVENT, "vampcandle", /datum/mood_event/vampcandle)
		to_chat(nearly_people, span_warning("<i>You start to feel extremely weak and drained.</i>"))

/// Mindshield breaking
/obj/structure/bloodsucker/candelabrum/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!.)
		return
	if(!anchored)
		return
	// Checks: They're Buckled & Alive.
	if(IS_BLOODSUCKER(user) && has_buckled_mobs())
		var/mob/living/carbon/target = pick(buckled_mobs)
		if(target.stat >= DEAD || user.a_intent == INTENT_HELP)
			unbuckle_mob(target)
			return
		if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
			if(user.blood_volume >= 50)
				switch(input("Do you wish to spend 50 Blood to deactivate [target]'s mindshield?") in list("Yes", "No"))
					if("Yes")
						user.blood_volume -= 50
						if(!do_after(user, 20 SECONDS, target))
							to_chat(user, span_danger("<i>The ritual has been interrupted!</i>"))
							return FALSE
						remove_loyalties(target)
						to_chat(user, span_boldnotice("You deactivated [target]'s mindshield!"))
			else
				to_chat(user, span_danger("You don't have enough Blood to deactivate [target]'s mindshield."))
			return
	if(IS_VASSAL(user) || IS_BLOODSUCKER(user))
		toggle()

/// Buckling someone in
/obj/structure/bloodsucker/candelabrum/MouseDrop_T(mob/living/target, mob/user)
	if(!anchored && IS_BLOODSUCKER(user))
		to_chat(user, span_danger("Until the candelabrum is secured in place, it cannot serve its purpose."))
		return
	/// Default checks
	if(!target.Adjacent(src) || target == user || !isliving(user) || has_buckled_mobs() || user.incapacitated() || target.buckled)
		return
	/// Are they mindshielded or a bloodsucker/vassal?
	if(!HAS_TRAIT(target, TRAIT_MINDSHIELD))
		to_chat(user, span_warning("[target] doesn't have a mindshield for you to turn off!"))
		return
	/// Good to go - Buckle them!
	if(do_after(user, 5 SECONDS, target))
		attach_mob(target, user)

/obj/structure/bloodsucker/candelabrum/proc/attach_mob(mob/living/target, mob/living/user)
	user.visible_message(
		span_notice("[user] lifts and buckles [target] onto the candelabrum."),
		span_boldnotice("You buckle [target] onto the candelabrum."),
	)

	playsound(src.loc, 'sound/effects/pop_expl.ogg', 25, 1)
	target.forceMove(get_turf(src))

	if(!buckle_mob(target))
		return
	update_appearance(UPDATE_ICON)

/obj/structure/bloodsucker/candelabrum/proc/remove_loyalties(mob/living/target, mob/living/user)
	// Find Mindshield implant & destroy, takes a good while.
	for(var/obj/item/implant/all_implants as anything in target.implants)
		if(all_implants.type == /obj/item/implant/mindshield)
			all_implants.removed(target, silent = TRUE)

/// Attempt Unbuckle
/obj/structure/bloodsucker/candelabrum/unbuckle_mob(mob/living/buckled_mob, force = FALSE, can_fall = TRUE)
	. = ..()
	src.visible_message(span_danger("[buckled_mob][buckled_mob.stat==DEAD?"'s corpse":""] slides off of the candelabrum."))
	update_appearance(UPDATE_ICON)

/// Blood Throne - Allows Bloodsuckers to remotely speak with their Vassals. - Code (Mostly) stolen from comfy chairs (armrests) and chairs (layers)
/* broken currently
/obj/structure/bloodsucker/bloodthrone
	name = "wicked throne"
	desc = "Twisted metal shards jut from the arm rests. Very uncomfortable looking. It would take a masochistic sort to sit on this jagged piece of furniture."
	icon = 'icons/obj/vamp_obj_64.dmi'
	icon_state = "throne"
	buckle_lying = 0
	anchored = FALSE
	density = TRUE
	can_buckle = TRUE
	Ghost_desc = "This is a Bloodsucker throne, any Bloodsucker sitting on it can remotely speak to their Vassals by attempting to speak aloud."
	Vamp_desc = "This is a Blood throne, sitting on it will allow you to telepathically speak to your vassals by simply speaking."
	Vassal_desc = "This is a Blood throne, it allows your Master to telepathically speak to you and others like you."
	Hunter_desc = "This is a chair that hurts those that try to buckle themselves onto it, though the Undead have no problem latching on.\n\
		While buckled, Monsters can use this to telepathically communicate with eachother."
	var/mutable_appearance/armrest

// Add rotating and armrest
/obj/structure/bloodsucker/bloodthrone/Initialize(mapload)
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE)
	armrest = GetArmrest()
	armrest.layer = ABOVE_MOB_LAYER
	return ..()

/obj/structure/bloodsucker/bloodthrone/Destroy()
	QDEL_NULL(armrest)
	return ..()

/obj/structure/bloodsucker/bloodthrone/bolt()
	. = ..()
	anchored = TRUE

/obj/structure/bloodsucker/bloodthrone/unbolt()
	. = ..()
	anchored = FALSE

// Armrests
/obj/structure/bloodsucker/bloodthrone/proc/GetArmrest()
	return mutable_appearance('icons/obj/vamp_obj_64.dmi', "thronearm")

/obj/structure/bloodsucker/bloodthrone/proc/update_armrest()
	if(has_buckled_mobs())
		add_overlay(armrest)
	else
		cut_overlay(armrest)

// Rotating
/obj/structure/bloodsucker/bloodthrone/setDir(newdir)
	. = ..()
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.setDir(newdir)

	if(has_buckled_mobs() && dir == NORTH)
		layer = ABOVE_MOB_LAYER
	else
		layer = OBJ_LAYER

// Buckling
/obj/structure/bloodsucker/bloodthrone/buckle_mob(mob/living/user, force = FALSE, check_loc = TRUE)
	if(!anchored)
		to_chat(user, span_announce("[src] is not bolted to the ground!"))
		return
	user.visible_message(
		span_notice("[user] sits down on [src]."),
		span_boldnotice("You sit down onto [src]."),
	)
	if(IS_BLOODSUCKER(user))
		RegisterSignal(user, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	else
		user.Paralyze(6 SECONDS)
		to_chat(user, span_cult("The power of the blood throne overwhelms you!"))
		user.apply_damage(10, BRUTE)
		unbuckle_mob(user)
		return
	return ..()

/obj/structure/bloodsucker/bloodthrone/post_buckle_mob(mob/living/target)
	. = ..()
	update_armrest()
	target.pixel_y += 2

// Unbuckling
/obj/structure/bloodsucker/bloodthrone/unbuckle_mob(mob/living/user, force = FALSE, can_fall = TRUE)
	src.visible_message(span_danger("[user] unbuckles themselves from [src]."))
	if(IS_BLOODSUCKER(user))
		UnregisterSignal(user, COMSIG_MOB_SAY)
	return ..()

/obj/structure/bloodsucker/bloodthrone/post_unbuckle_mob(mob/living/target)
	target.pixel_y -= 2

// The speech itself
/obj/structure/bloodsucker/bloodthrone/proc/handle_speech(datum/source, mob/speech_args)

	var/message = speech_args[SPEECH_MESSAGE]
	var/mob/living/carbon/human/user = source
	var/rendered = span_cultlarge("<b>[user.real_name]:</b> [message]")
	user.log_talk(message, LOG_SAY, tag=ROLE_BLOODSUCKER)
	for(var/mob/living/carbon/human/vassals in GLOB.player_list)
		var/datum/antagonist/vassal/vassaldatum = vassals.mind.has_antag_datum(/datum/antagonist/vassal)
		if(vassals == user) // Just so they can hear themselves speak.
			to_chat(vassals, rendered)
		if(!istype(vassaldatum))
			continue
		if(vassaldatum.master.owner == user.mind)
			to_chat(vassals, rendered)

	for(var/mob/dead_mob in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(dead_mob, user)
		to_chat(dead_mob, "[link] [rendered]")

	speech_args[SPEECH_MESSAGE] = ""
*/
