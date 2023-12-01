//Yes, they can only be rectangular.
//Yes, I'm sorry.
/datum/turf_reservation
	var/list/reserved_turfs = list()
	///Turfs around the reservation for cordoning
	var/list/cordon_turfs = list()
	///Area of turfs next to the cordon to fill with pre_cordon_area's
	var/list/pre_cordon_turfs = list()
	var/width = 0
	var/height = 0
	var/bottom_left_coords[3]
	var/top_right_coords[3]
	var/turf_type = /turf/open/space
	///Distance away from the cordon where we can put a "sort-cordon" and run some extra code (see make_repel). 0 makes nothing happen
	var/pre_cordon_distance = 0
	/// The z stack size of the reservation. Note that reservations are ALWAYS reserved from the bottom up
	var/z_size = 0
	/// List of the bottom left turfs. Indexed by what their z index for this reservation is
	var/list/bottom_left_turfs = list()

	/// List of the top right turfs. Indexed by what their z index for this reservation is
	var/list/top_right_turfs = list()

/datum/turf_reservation/transit
	turf_type = /turf/open/space/transit
	pre_cordon_distance = 7

/datum/turf_reservation/proc/Release()
	var/list/reserved_copy = reserved_turfs.Copy()
	SSmapping.used_turfs -= reserved_turfs
	reserved_turfs = list()

	var/list/cordon_copy = cordon_turfs.Copy()
	SSmapping.used_turfs -= cordon_turfs
	cordon_turfs = list()

	var/release_turfs = reserved_copy + cordon_copy

	for(var/turf/reserved_turf as anything in release_turfs)
		SEND_SIGNAL(reserved_turf, COMSIG_TURF_RESERVATION_RELEASED, src)

	// Makes the linter happy, even tho we don't await this
	INVOKE_ASYNC(SSmapping, /datum/controller/subsystem/mapping/proc/reserve_turfs, reserved_copy)

/// Attempts to calaculate and store a list of turfs around the reservation for cordoning. Returns whether a valid cordon was calculated
/datum/turf_reservation/proc/calculate_cordon_turfs(turf/BL, turf/TR)
	if(BL.x < 2 || BL.y < 2 || TR.x > (world.maxx - 2) || TR.y > (world.maxy - 2))
		return FALSE // no space for a cordon here

	var/list/possible_turfs = CORNER_OUTLINE(BL, width, height)
	for(var/turf/cordon_turf as anything in possible_turfs)
		if(!(cordon_turf.flags_1 & UNUSED_RESERVATION_TURF_1))
			return FALSE
	cordon_turfs = possible_turfs

	pre_cordon_turfs.Cut()

	if(pre_cordon_distance)
		var/turf/offset_turf = locate(BL.x + pre_cordon_distance, BL.y + pre_cordon_distance, BL.z)
		var/list/to_add = CORNER_OUTLINE(offset_turf, width - pre_cordon_distance * 2, height - pre_cordon_distance * 2) //we step-by-stop move inwards from the outer cordon
		for(var/turf/turf_being_added as anything in to_add)
			pre_cordon_turfs |= turf_being_added //add one by one so we can filter out duplicates

	return TRUE

/// Actually generates the cordon around the reservation, and marking the cordon turfs as reserved
/datum/turf_reservation/proc/generate_cordon()
	for(var/turf/cordon_turf as anything in cordon_turfs)
		var/area/misc/cordon/cordon_area = GLOB.areas_by_type[/area/misc/cordon] || new
		var/area/old_area = cordon_turf.loc
		old_area.turfs_to_uncontain += cordon_turf
		cordon_area.contained_turfs += cordon_turf
		cordon_area.contents += cordon_turf
		cordon_turf.ChangeTurf(/turf/cordon, /turf/cordon)

		cordon_turf.flags_1 &= ~UNUSED_RESERVATION_TURF_1
		SSmapping.unused_turfs["[cordon_turf.z]"] -= cordon_turf
		SSmapping.used_turfs[cordon_turf] = src

	//swap the area with the pre-cordoning area
	for(var/turf/pre_cordon_turf as anything in pre_cordon_turfs)
		make_repel(pre_cordon_turf)

///Register signals in the cordon "danger zone" to do something with whoever trespasses
/datum/turf_reservation/proc/make_repel(turf/pre_cordon_turf)
	SHOULD_CALL_PARENT(TRUE)
	//Okay so hear me out. If we place a special turf IN the reserved area, it will be overwritten, so we can't do that
	//But signals are preserved even between turf changes, so even if we register a signal now it will stay even if that turf is overriden by the template
	RegisterSignals(pre_cordon_turf, list(COMSIG_PARENT_QDELETING, COMSIG_TURF_RESERVATION_RELEASED), PROC_REF(on_stop_repel))

/datum/turf_reservation/proc/on_stop_repel(turf/pre_cordon_turf)
	SHOULD_CALL_PARENT(TRUE)
	SIGNAL_HANDLER

	stop_repel(pre_cordon_turf)

///Unregister all the signals we added in RegisterRepelSignals
/datum/turf_reservation/proc/stop_repel(turf/pre_cordon_turf)
	UnregisterSignal(pre_cordon_turf, list(COMSIG_PARENT_QDELETING, COMSIG_TURF_RESERVATION_RELEASED))

/datum/turf_reservation/transit/make_repel(turf/pre_cordon_turf)
	..()

	RegisterSignal(pre_cordon_turf, COMSIG_ATOM_ENTERED, PROC_REF(space_dump))

/datum/turf_reservation/transit/stop_repel(turf/pre_cordon_turf)
	..()

	UnregisterSignal(pre_cordon_turf, COMSIG_ATOM_ENTERED)

/datum/turf_reservation/transit/proc/space_dump(atom/source, atom/movable/enterer)
	SIGNAL_HANDLER

	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(throw_atom), enterer)

/datum/turf_reservation/proc/Reserve(width, height, zlevel)
	src.width = width
	src.height = height
	if(width > world.maxx || height > world.maxy || width < 1 || height < 1)
		return FALSE
	var/list/avail = SSmapping.unused_turfs["[zlevel]"]
	var/turf/BL
	var/turf/TR
	var/list/turf/final = list()
	var/passing = FALSE
	for(var/i in avail)
		CHECK_TICK
		BL = i
		if(!(BL.flags_1 & UNUSED_RESERVATION_TURF_1))
			continue
		if(BL.x + width > world.maxx || BL.y + height > world.maxy)
			continue
		TR = locate(BL.x + width - 1, BL.y + height - 1, BL.z)
		if(!(TR.flags_1 & UNUSED_RESERVATION_TURF_1))
			continue
		final = block(BL, TR)
		if(!final)
			continue
		passing = TRUE
		for(var/I in final)
			var/turf/checking = I
			if(!(checking.flags_1 & UNUSED_RESERVATION_TURF_1))
				passing = FALSE
				break
		if(passing) // found a potentially valid area, now try to calculate its cordon
			passing = calculate_cordon_turfs(BL, TR)
		if(!passing)
			continue
		break
	if(!passing || !istype(BL) || !istype(TR))
		return FALSE
	bottom_left_coords = list(BL.x, BL.y, BL.z)
	top_right_coords = list(TR.x, TR.y, TR.z)
	for(var/i in final)
		var/turf/T = i
		reserved_turfs |= T
		T.flags_1 &= ~UNUSED_RESERVATION_TURF_1
		SSmapping.unused_turfs["[T.z]"] -= T
		SSmapping.used_turfs[T] = src
		T.ChangeTurf(turf_type, turf_type)
	generate_cordon()
	return TRUE

/datum/turf_reservation/New()
	LAZYADD(SSmapping.turf_reservations, src)

/datum/turf_reservation/Destroy()
	Release()
	LAZYREMOVE(SSmapping.turf_reservations, src)
	return ..()

// Look up levels[z].traits[trait]
/datum/controller/subsystem/mapping/proc/level_trait(z, trait)
	if (!isnum(z) || z < 1)
		return null
	if (z_list)
		if (z > z_list.len)
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], z_list.len = [z_list.len]")
			return list()
		var/datum/space_level/S = get_level(z)
		return S.traits[trait]
	else
		var/list/default = DEFAULT_MAP_TRAITS
		if (z > default.len)
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], default.len = [default.len]")
			return list()
		return default[z][DL_TRAITS][trait]

// Check if levels[z] has any of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_any_trait(z, list/traits)
	for (var/I in traits)
		if (level_trait(z, I))
			return TRUE
	return FALSE

// Check if levels[z] has all of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_all_traits(z, list/traits)
	for (var/I in traits)
		if (!level_trait(z, I))
			return FALSE
	return TRUE

// Get a list of all z which have the specified trait
/datum/controller/subsystem/mapping/proc/levels_by_trait(trait)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		if (S.traits[trait])
			. += S.z_value

// Get a list of all z which have any of the specified traits
/datum/controller/subsystem/mapping/proc/levels_by_any_trait(list/traits)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		for (var/trait in traits)
			if (S.traits[trait])
				. += S.z_value
				break

/// Calculates the effective bounds information for the given turf. Returns a list of the information, or null if not applicable.
/datum/turf_reservation/proc/calculate_turf_bounds_information(turf/target)
	for(var/z_idx in 1 to z_size)
		var/turf/bottom_left = bottom_left_turfs[z_idx]
		var/turf/top_right = top_right_turfs[z_idx]
		var/bl_x = bottom_left.x
		var/bl_y = bottom_left.y
		var/tr_x = top_right.x
		var/tr_y = top_right.y

		if(target.x < bl_x)
			continue

		if(target.y < bl_y)
			continue

		if(target.x > tr_x)
			continue

		if(target.y > tr_y)
			continue

		var/list/return_information = list()
		return_information["z_idx"] = z_idx
		return_information["offset_x"] = target.x - bl_x
		return_information["offset_y"] = target.y - bl_y
		return return_information
	return null

/// Gets the turf below the given target. Returns null if there is no turf below the target
/datum/turf_reservation/proc/get_turf_below(turf/target)
	var/list/bounds_info = calculate_turf_bounds_information(target)
	if(isnull(bounds_info))
		return null

	var/z_idx = bounds_info["z_idx"]
	// check what z level, if its the max, then there is no turf below
	if(z_idx == z_size)
		return null

	var/offset_x = bounds_info["offset_x"]
	var/offset_y = bounds_info["offset_y"]
	var/turf/bottom_left = bottom_left_turfs[z_idx + 1]
	return locate(bottom_left.x + offset_x, bottom_left.y + offset_y, bottom_left.z)

/// Gets the turf above the given target. Returns null if there is no turf above the target
/datum/turf_reservation/proc/get_turf_above(turf/target)
	var/list/bounds_info = calculate_turf_bounds_information(target)
	if(isnull(bounds_info))
		return null

	var/z_idx = bounds_info["z_idx"]
	// check what z level, if its the min, then there is no turf above
	if(z_idx == 1)
		return null

	var/offset_x = bounds_info["offset_x"]
	var/offset_y = bounds_info["offset_y"]
	var/turf/bottom_left = bottom_left_turfs[z_idx - 1]
	return locate(bottom_left.x + offset_x, bottom_left.y + offset_y, bottom_left.z)
// Prefer not to use this one too often
/datum/controller/subsystem/mapping/proc/get_station_center()
	var/station_z = levels_by_trait(ZTRAIT_STATION)[1]
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), station_z)
