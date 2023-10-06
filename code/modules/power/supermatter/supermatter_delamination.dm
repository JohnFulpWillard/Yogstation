/datum/supermatter_delamination
	///Power amount of the SM at the moment of death
	var/supermatter_power = 0
	///Amount of total gases interacting with the SM
	var/supermatter_gas_amount = 0
	///Reference to the supermatter turf
	var/turf/supermatter_turf
	///Baseline strenght of the explosion caused by the SM
	var/supermatter_explosion_power = 0
	///Amount the gasmix will affect the explosion size
	var/supermatter_gasmix_power_ratio = 0
	///Antinoblium inside sm
	var/supermatter_antinoblium = FALSE
	///Trigger resonance cascading
	var/supermatter_cascading = FALSE
	///Radiation amount
	var/supermatter_radiation = 0

/datum/supermatter_delamination/New(supermatter_power, supermatter_gas_amount, turf/supermatter_turf, supermatter_explosion_power, supermatter_gasmix_power_ratio, supermatter_antinoblium, supermatter_cascading, supermatter_radiation)
	. = ..()

	src.supermatter_power = supermatter_power
	src.supermatter_gas_amount = supermatter_gas_amount
	src.supermatter_turf = supermatter_turf
	src.supermatter_explosion_power = supermatter_explosion_power
	src.supermatter_gasmix_power_ratio = supermatter_gasmix_power_ratio
	src.supermatter_antinoblium = supermatter_antinoblium
	src.supermatter_cascading = supermatter_cascading
	src.supermatter_radiation = supermatter_radiation

	setup_mob_interaction()
	setup_delamination_type()

/datum/supermatter_delamination/proc/setup_mob_interaction()
	for(var/mob/living/victim as anything in GLOB.alive_mob_list)
		if(!istype(victim) || victim.z != supermatter_turf.z)
			continue

		if(ishuman(victim))
			//Hilariously enough, running into a closet should make you get hit the hardest.
			var/mob/living/carbon/human/human = victim
			human.adjust_hallucinations(max(50, min(300, DETONATION_HALLUCINATION * sqrt(1 / (get_dist(victim, src) + 1)) ) ) )

		var/rads = DETONATION_RADS * sqrt( 1 / (get_dist(victim, src) + 1) )
		victim.rad_act(rads)

	for(var/mob/victim as anything in GLOB.player_list)
		var/turf/mob_turf = get_turf(victim)
		if(supermatter_turf.z != mob_turf.z)
			continue

		SEND_SOUND(victim, 'sound/magic/charge.ogg')

		if (victim.z != supermatter_turf.z)
			to_chat(victim, span_boldannounce("You hold onto \the [victim.loc] as hard as you can, as reality distorts around you. You feel safe."))
			continue

		to_chat(victim, span_boldannounce("You feel reality distort for a moment..."))
		SEND_SIGNAL(victim, COMSIG_ADD_MOOD_EVENT, "delam", /datum/mood_event/delam)

/datum/supermatter_delamination/proc/setup_delamination_type()
	call_explosion()
	if(supermatter_cascading)
		call_cascading()
		call_cascadetesla()
		return
	if(supermatter_gas_amount > MOLE_PENALTY_THRESHOLD && !supermatter_cascading)
		call_singulo()
		return
	if(supermatter_power > POWER_PENALTY_THRESHOLD && !supermatter_cascading)
		call_tesla()
		return

/datum/supermatter_delamination/proc/shockwave() //borrowed ynot's code
	var/atom/movable/gravity_lens/shockwave = new(supermatter_turf)
	shockwave.transform = matrix().Scale(0.5)
	shockwave.pixel_x = -240
	shockwave.pixel_y = -240
	animate(shockwave, alpha = 0, transform = matrix().Scale(20), time = 10 SECONDS, easing = QUAD_EASING)
	QDEL_IN(shockwave, 10.5 SECONDS)

/datum/supermatter_delamination/proc/gravitypull()
	for(var/tile in spiral_range_turfs(40, supermatter_turf))
		var/turf/T = tile
		for(var/thing in T)
			var/atom/movable/X = thing
			X.singularity_pull(supermatter_turf, 40)

/datum/supermatter_delamination/proc/call_cascading()
	sound_to_playing_players('sound/magic/lightningbolt.ogg', volume = 50)
	shockwave() //a pulse when sm is blown up
	gravitypull() //will pull everything back once sm explodes
	var/datum/round_event_control/resonance_cascade/xen = new
	xen.runEvent()
	message_admins("The Supermatter Crystal has caused a resonance cascade.")

/datum/supermatter_delamination/proc/call_singulo()
	if(!supermatter_turf)
		return
	var/obj/singularity/created_singularity = new(supermatter_turf)
	created_singularity.energy = 2400
	created_singularity.consume(src)
	message_admins("The Supermatter Crystal has created a singularity [ADMIN_JMP(created_singularity)].")

/datum/supermatter_delamination/proc/call_explosion()
	if(supermatter_power < 0) // in case of negative energy, make it positive
		supermatter_power = -supermatter_power
	var/explosion_mod = clamp((1.001**supermatter_power) / ((1.001**supermatter_power) + SUPERMATTER_EXPLOSION_LAMBDA), 0.1, 1)
	//trying to cheat by spacing the crystal? YOU FOOL THERE ARE NO LOOPHOLES TO ESCAPE YOUR UPCOMING DEATH
	if(istype(supermatter_turf, /turf/open/space) || supermatter_gas_amount < MOLE_SPACE_THRESHOLD)
		message_admins("[src] has exploded in empty space.")
		explosion_mod = max(explosion_mod, 0.5)
	else
		message_admins("[src] has exploded")
	INVOKE_ASYNC(GLOBAL_PROC, /proc/empulse, supermatter_turf, supermatter_explosion_power * explosion_mod, (supermatter_explosion_power * explosion_mod * 2) + (supermatter_explosion_power/4), TRUE, FALSE, FALSE, TRUE)
	explosion(supermatter_turf, supermatter_explosion_power * explosion_mod * 0.5, supermatter_explosion_power * explosion_mod + 2, supermatter_explosion_power * explosion_mod + 4, supermatter_explosion_power * explosion_mod + 6, 1, 1)
	radiation_pulse(supermatter_turf, (supermatter_radiation + 2400) * supermatter_explosion_power)

/datum/supermatter_delamination/proc/call_tesla()
	if(supermatter_turf)
		var/obj/singularity/energy_ball/E = new(supermatter_turf)
		E.energy = supermatter_power
		message_admins("The Supermatter Crystal has created an energy ball [ADMIN_JMP(E)].")

/datum/supermatter_delamination/proc/call_cascadetesla()
	if(supermatter_turf)
		var/obj/singularity/energy_ball/supermatter/E = new(supermatter_turf)
		E.energy = supermatter_power*100 // god
		message_admins("The Supermatter Crystal has created an energy ball [ADMIN_JMP(E)].")
