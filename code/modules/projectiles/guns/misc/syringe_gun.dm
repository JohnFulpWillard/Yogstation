/obj/item/gun/syringe
	name = "syringe gun"
	desc = "A spring loaded rifle designed to fit syringes, used to incapacitate unruly patients from a distance."
	icon_state = "syringegun"
	item_state = "syringegun"
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 3
	throw_range = 7
	force = 4
	materials = list(/datum/material/iron=2000)
	clumsy_check = 0
	fire_sound = 'sound/items/syringeproj.ogg'
	var/load_sound = 'sound/weapons/shotguninsert.ogg'
	var/list/syringes = list()
	var/max_syringes = 1
	var/has_syringe_overlay = TRUE ///If it has an overlay for inserted syringes. If true, the overlay is determined by the number of syringes inserted into it.
	var/allow_piercing = FALSE // whether it can hold piercing syringes

/obj/item/gun/syringe/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_ICON)
	chambered = new /obj/item/ammo_casing/syringegun(src)

/obj/item/gun/syringe/handle_atom_del(atom/A)
	. = ..()
	if(A in syringes)
		syringes.Remove(A)

/obj/item/gun/syringe/recharge_newshot()
	if(!syringes.len)
		return
	chambered.newshot()

/obj/item/gun/syringe/can_shoot()
	return syringes.len

/obj/item/gun/syringe/process_chamber()
	if(chambered && !chambered.BB) //we just fired
		recharge_newshot()
	update_appearance(UPDATE_ICON)

/obj/item/gun/syringe/examine(mob/user)
	. = ..()
	. += "Can hold [max_syringes] syringe\s. Has [syringes.len] syringe\s remaining."

/obj/item/gun/syringe/attack_self(mob/living/user)
	if(!syringes.len)
		to_chat(user, span_warning("[src] is empty!"))
		return FALSE

	var/obj/item/reagent_containers/syringe/S = syringes[syringes.len]

	if(!S)
		return FALSE
	user.put_in_hands(S)

	syringes.Remove(S)
	to_chat(user, span_notice("You unload [S] from \the [src]."))

	return TRUE

/obj/item/gun/syringe/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/syringe = A
		if(syringe.proj_piercing && !allow_piercing)
			to_chat(user, span_warning("[syringe] won't fit into [src]!"))
			return FALSE
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(A, src))
				return FALSE
			to_chat(user, span_notice("You load [A] into \the [src]."))
			syringes += A
			recharge_newshot()
			update_appearance(UPDATE_ICON)
			playsound(loc, load_sound, 40)
			return TRUE
		else
			to_chat(user, span_warning("[src] cannot hold more syringes!"))
	return FALSE

/obj/item/gun/syringe/update_icon(updates=ALL)
	. = ..()
	if(!has_syringe_overlay)
		return
	var/syringe_count = syringes.len
	add_overlay("[initial(icon_state)]_[syringe_count ? clamp(syringe_count, 1, initial(max_syringes)) : "empty"]")

/obj/item/gun/syringe/rapidsyringe
	name = "rapid syringe gun"
	desc = "A modification of the syringe gun design, using a rotating cylinder to store up to six syringes."
	icon_state = "rapidsyringegun"
	max_syringes = 6
	allow_piercing = TRUE

/obj/item/gun/syringe/syndicate
	name = "dart pistol"
	desc = "A small spring-loaded sidearm that functions identically to a syringe gun."
	icon_state = "syringe_pistol"
	item_state = "gun" //Smaller inhand
	w_class = WEIGHT_CLASS_SMALL
	force = 2 //Also very weak because it's smaller
	suppressed = TRUE //Softer fire sound
	can_unsuppress = FALSE //Permanently silenced
	allow_piercing = TRUE

/obj/item/gun/syringe/dna
	name = "modified syringe gun"
	desc = "A syringe gun that has been modified to fit DNA injectors instead of normal syringes."
	allow_piercing = TRUE

/obj/item/gun/syringe/dna/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/dnainjector(src)

/obj/item/gun/syringe/dna/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/dnainjector))
		var/obj/item/dnainjector/D = A
		if(D.used)
			to_chat(user, span_warning("This injector is used up!"))
			return
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(D, src))
				return FALSE
			to_chat(user, span_notice("You load \the [D] into \the [src]."))
			syringes += D
			recharge_newshot()
			update_appearance(UPDATE_ICON)
			playsound(loc, load_sound, 40)
			return TRUE
		else
			to_chat(user, span_warning("[src] cannot hold more syringes!"))
	return FALSE

/obj/item/gun/syringe/blowgun
	name = "blowgun"
	desc = "Fire syringes a short distance."
	icon_state = "blowgun"
	item_state = "blowgun"
	fire_sound = 'sound/items/syringeproj.ogg'
	no_pin_required = TRUE
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL //it's a fucking blowgun it shouldn't even have a triggerguard

/obj/item/gun/syringe/blowgun/Initialize(mapload)
	. = ..()
	update_icon()
	chambered = new /obj/item/ammo_casing/blowgun(src)


/obj/item/gun/syringe/blowgun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	user.adjustStaminaLoss(25)
	user.adjustOxyLoss(25)
	..()
