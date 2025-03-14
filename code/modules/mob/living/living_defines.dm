/mob/living
	see_invisible = SEE_INVISIBLE_LIVING
	sight = 0
	hud_possible = list(HEALTH_HUD,STATUS_HUD,ANTAG_HUD,NANITE_HUD,DIAG_NANITE_FULL_HUD)
	pressure_resistance = 10
	infra_luminosity = 10

	hud_type = /datum/hud/living

	var/resize = 1 //Badminnery resize
	var/lastattacker = null
	var/lastattackerckey = null

	//Health and life related vars
	var/maxHealth = 100 //Maximum health that should be possible.
	var/health = 100 	//A mob's health

	//Damage related vars, NOTE: THESE SHOULD ONLY BE MODIFIED BY PROCS
	var/bruteloss = 0	//Brutal damage caused by brute force (punching, being clubbed by a toolbox ect... this also accounts for pressure damage)
	var/oxyloss = 0		//Oxygen depravation damage (no air in lungs)
	var/toxloss = 0		//Toxic damage caused by being poisoned or radiated
	var/fireloss = 0	//Burn damage caused by being way too hot, too cold or burnt.
	var/cloneloss = 0	//Damage caused by being cloned or ejected from the cloner early. slimes also deal cloneloss damage to victims
	var/staminaloss = 0		//Stamina damage, or exhaustion. You recover it slowly naturally, and are knocked down if it gets too high. Holodeck and hallucinations deal this.
	var/crit_threshold = HEALTH_THRESHOLD_CRIT // when the mob goes from "normal" to crit

	var/mobility_flags = MOBILITY_FLAGS_DEFAULT

	var/resting = FALSE

	var/lying = 0			//number of degrees. DO NOT USE THIS IN CHECKS. CHECK FOR MOBILITY FLAGS INSTEAD!!
	var/lying_prev = 0		//last value of lying on update_mobility

	var/last_special = 0 //Used by the resist verb, likely used to prevent players from bypassing next_move by logging in/out.
	var/timeofdeath = 0

	///This var, if true, kills the mob on initalize
	var/startDead = FALSE

	//Allows mobs to move through dense areas without restriction. For instance, in space or out of holder objects.
	var/incorporeal_move = FALSE //FALSE is off, INCORPOREAL_MOVE_BASIC is normal, INCORPOREAL_MOVE_SHADOW is for ninjas
								 //and INCORPOREAL_MOVE_JAUNT is blocked by holy water/salt

	var/list/roundstart_quirks = list()

	var/list/surgeries = list()	//a list of surgery datums. generally empty, they're added when the player wants them.

	var/now_pushing = null //used by living/Bump() and living/PushAM() to prevent potential infinite loop.

	var/cameraFollow = null

	var/tod = null // Time of death

	/// How often biological functions tick. For example, 3 would be a 1/3 of every tick
	var/life_tickrate = 1 

	var/on_fire = 0 //The "Are we on fire?" var
	var/fire_stacks = 0 //Tracks how many stacks of fire we have on, max is usually 20

	var/bloodcrawl = 0 //0 No blood crawling, BLOODCRAWL for bloodcrawling, BLOODCRAWL_EAT for crawling+mob devour
	var/holder = null //The holder for blood crawling
	var/ventcrawler = 0 //0 No vent crawling, 1 vent crawling in the nude, 2 vent crawling always
	var/limb_destroyer = 0 //1 Sets AI behavior that allows mobs to target and dismember limbs with their basic attack.

	var/mob_size = MOB_SIZE_HUMAN
	var/mob_biotypes = MOB_ORGANIC
	var/metabolism_efficiency = 1 //more or less efficiency to metabolize helpful/harmful reagents and regulate body temperature..
	var/has_limbs = 0 //does the mob have distinct limbs?(arms,legs, chest,head)

	var/list/pipes_shown = list()
	var/list/wires_shown = list()
	var/last_played_vent

	var/smoke_delay = FALSE //used to prevent spam with smoke reagent reaction on mob.
	var/foam_delay = FALSE //used to prevent spam with foam reagent reaction on mob.

	var/health_doll_icon //if this exists AND the normal sprite is bigger than 32x32, this is the replacement icon state (because health doll size limitations). the icon will always be screen_gen.dmi

	var/last_bumped = 0
	var/unique_name = 0 //if a mob's name should be appended with an id when created e.g. Mob (666)

	var/list/butcher_results = null //these will be yielded from butchering with a probability chance equal to the butcher item's effectiveness
	var/list/guaranteed_butcher_results = null //these will always be yielded from butchering
	var/butcher_difficulty = 0 //effectiveness prob. is modified negatively by this amount; positive numbers make it more difficult, negative ones make it easier

	var/hellbound = 0 //People who've signed infernal contracts are unrevivable.

	var/weather_immunities = NONE

	var/stun_absorption = null //converted to a list of stun absorption sources this mob has when one is added

	var/blood_volume = 0 //how much blood the mob has

	var/see_override = 0 //0 for no override, sets see_invisible = see_override in silicon & carbon life process via update_sight()

	var/list/status_effects //a list of all status effects the mob has

	/// List of changes to body temperature, used by desease symtoms like fever
	var/list/body_temp_changes = list()

	//this stuff is here to make it simple for admins to mess with custom held sprites
	var/icon/held_lh = 'icons/mob/pets_held_lh.dmi' //icons for holding mobs
	var/icon/held_rh = 'icons/mob/pets_held_rh.dmi'
	var/icon/held_icon = 'icons/mob/pets_held.dmi' //backup for what it looks like when held and equipped in a slot
	var/held_state = null //normally use the default icon but if need be use another one
	var/worn_layer //use to set if you want your inhand mob sprite to be hidden or not

	//Speech
	var/cultslurring = 0
	var/lizardspeech = 0

	var/list/implants = null

	var/last_words	//used for database logging

	var/can_be_held = FALSE	//whether this can be picked up and held.
	var/worn_slot_flags = NONE //if it can be held, can it be equipped to any slots?

	var/radiation = 0 //If the mob is irradiated.
	var/ventcrawl_layer = PIPING_LAYER_DEFAULT
	var/losebreath = 0

	//List of active diseases
	var/list/diseases = list() // list of all diseases in a mob
	var/list/disease_resistances = list()

	//Whether the mob is slowed down when dragging another prone mob
	var/drag_slowdown = TRUE

	//Allergies
	var/allergies

	//Last projectile that damaged this mob, not including surgery
	var/last_damage = ""

	//Due to the fact that silicon and carbons can both be connected to a network we share at this level of inheritance
	var/datum/ai_network/ai_network
	/// Variable to track the body position of a mob, regardgless of the actual angle of rotation (usually matching it, but not necessarily).
	var/body_position = STANDING_UP
	///The x amount a mob's sprite should be offset due to the current position they're in
	var/body_position_pixel_x_offset = 0
	///The y amount a mob's sprite should be offset due to the current position they're in or size (e.g. lying down moves your sprite down)
	var/body_position_pixel_y_offset = 0

	///How many hands does this mob have by default. This shouldn't change at runtime.
	var/default_num_hands = 2
	///How many hands hands does this mob currently have. Should only be changed through set_num_hands()
	var/num_hands = 2
	///How many usable hands does this mob currently have. Should only be changed through set_usable_hands()
	var/usable_hands = 2
	/// What our current gravity state is. Used to avoid duplicate animates and such
	var/gravity_state = null
	/// Is the mob looking vertically
	var/looking_vertically = FALSE
