//Contains the target item datums for Steal objectives.

/datum/objective_item
	var/name = "A silly bike horn! Honk!"
	var/targetitem = /obj/item/bikehorn		//typepath of the objective item
	var/difficulty = 9001							//vaguely how hard it is to do this objective
	var/list/excludefromjob = list()				//If you don't want a job to get a certain objective (no captain stealing his own medal, etcetc)
	var/list/altitems = list()				//Items which can serve as an alternative to the objective (darn you blueprints)
	var/list/special_equipment = list()
	var/datum/objective/steal/objective		//The objective datum for our objective

/datum/objective_item/proc/check_special_completion() //for objectives with special checks (is that slime extract unused? does that intellicard have an ai in it? etcetc)
	return 1

/datum/objective_item/proc/TargetExists()
	return TRUE

/datum/objective_item/steal/New()
	..()
	if(TargetExists())
		GLOB.possible_items += src
	else
		qdel(src)

/datum/objective_item/steal/Destroy()
	GLOB.possible_items -= src
	return ..()

/datum/objective_item/steal/caplaser
	name = "the Captain's antique laser gun."
	targetitem = /obj/item/gun/energy/laser/captain
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/hoslaser
	name = "the Head of Security's personal laser gun."
	targetitem = /obj/item/gun/energy/e_gun/hos
	difficulty = 10
	excludefromjob = list("Head Of Security")

/datum/objective_item/steal/handtele
	name = "a hand teleporter."
	targetitem = /obj/item/hand_tele
	difficulty = 5
	excludefromjob = list("Captain", "Research Director")

/datum/objective_item/steal/jetpack
	name = "the Captain's jetpack."
	targetitem = /obj/item/tank/jetpack/oxygen/captain
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/magboots
	name = "the Chief Engineer's advanced magnetic boots."
	targetitem =  /obj/item/clothing/shoes/magboots/advance
	difficulty = 5
	excludefromjob = list("Chief Engineer")

/datum/objective_item/steal/capmedal
	name = "the medal of captaincy."
	targetitem = /obj/item/clothing/accessory/medal/gold/captain
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/hypo
	name = "the Chief Medical Officer's hypospray deluxe."
	targetitem = /obj/item/hypospray/deluxe/cmo
	difficulty = 5
	excludefromjob = list("Chief Medical Officer")

/datum/objective_item/steal/nukedisc
	name = "the nuclear authentication disk."
	targetitem = /obj/item/disk/nuclear
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/nukedisc/check_special_completion(obj/item/disk/nuclear/N)
	return !N.fake

/datum/objective_item/steal/reflector
	name = "a reflective jacket."
	targetitem = /obj/item/clothing/suit/armor/laserproof
	difficulty = 3
	excludefromjob = list("Head of Security", "Warden")

/datum/objective_item/steal/aiupload
	name = "an AI upload board."
	targetitem = /obj/item/circuitboard/computer/aiupload
	difficulty = 5
	excludefromjob = list("Network Admin", "Chief Engineer", "Research Director") // CE has access. RD has authority. 

/datum/objective_item/steal/reactive
	name = "the Research Director's reactive teleport armor."
	targetitem = /obj/item/clothing/suit/armor/reactive/teleport
	difficulty = 5
	excludefromjob = list("Research Director")

/datum/objective_item/steal/documents
	name = "any set of secret documents of any organization."
	targetitem = /obj/item/documents //Any set of secret documents. Doesn't have to be NT's
	difficulty = 5

/datum/objective_item/steal/nuke_core
	name = "the heavily radioactive plutonium core from the onboard self-destruct. Take care to wear the proper safety equipment when extracting the core!"
	targetitem = /obj/item/nuke_core
	difficulty = 15

/datum/objective_item/steal/nuke_core/New()
	special_equipment += /obj/item/storage/box/syndie_kit/nuke
	..()

GLOBAL_VAR_INIT(hdd_research_project, pick("Project Bee", "Project Shiptest", "Project Monke"))

/datum/objective_item/steal/hdd_extraction
	name = "the source code for Project Bee from the master R&D server mainframe."
	targetitem = /obj/item/computer_hardware/hard_drive/cluster/hdd_theft
	difficulty = 10
	excludefromjob = list("Scientist", "Research Director") //Scientist isn't sus in that room but a gene or robo is. 

/datum/objective_item/steal/hdd_extraction/New()
	name = "the source code for [GLOB.hdd_research_project] from the master R&D server mainframe."
	special_equipment += /obj/item/paper/guides/antag/hdd_extraction
	return ..()

/datum/objective_item/steal/supermatter
	name = "a sliver of a supermatter crystal. Be sure to use the proper safety equipment when extracting the sliver!"
	targetitem = /obj/item/nuke_core/supermatter_sliver
	difficulty = 15

/datum/objective_item/steal/supermatter/New()
	special_equipment += /obj/item/storage/box/syndie_kit/supermatter
	..()

/datum/objective_item/steal/supermatter/TargetExists()
	return GLOB.main_supermatter_engine != null

//Items with special checks!
/datum/objective_item/steal/plasma
	name = "28 moles of plasma (full tank)."
	targetitem = /obj/item/tank
	difficulty = 3
	excludefromjob = list("Chief Engineer","Research Director","Station Engineer","Scientist","Atmospheric Technician")

/datum/objective_item/steal/plasma/check_special_completion()
	var/target_amount = text2num(name)
	var/found_amount = 0
	for(var/datum/mind/M in objective.get_owners())
		if(!isliving(M.current))
			continue

		var/list/all_items = M.current.get_all_contents()
		for(var/o in all_items)
			if(!istype(o, /obj/item/tank))
				continue
			var/obj/item/tank/T = o
			found_amount += T.air_contents.get_moles(GAS_PLASMA)
	if (istype(objective.team, /datum/team/infiltrator))
		for (var/area/A in world)
			if (is_type_in_typecache(A, GLOB.infiltrator_objective_areas))
				for (var/obj/item/tank/T in A.get_all_contents()) //Check for items
					found_amount += T.air_contents.get_moles(GAS_PLASMA)
					CHECK_TICK
			CHECK_TICK
		CHECK_TICK
	return found_amount >= target_amount

/datum/objective_item/steal/holotool
	name = "the holotool."
	targetitem = /obj/item/holotool
	difficulty = 5
	excludefromjob = list("Research Director")
	
/datum/objective_item/steal/functionalai
	name = "a functional AI."
	targetitem = /obj/item/aicard
	difficulty = 20 //beyond the impossible
	excludefromjob = list(ROLE_INFILTRATOR) 

/datum/objective_item/steal/functionalai/check_special_completion(obj/item/aicard/C)
	for(var/mob/living/silicon/ai/A in C)
		if(isAI(A) && A.stat != DEAD) //See if any AI's are alive inside that card.
			return 1
	return 0

/datum/objective_item/steal/blueprints
	name = "the Chief Engineer's station blueprints."
	targetitem = /obj/item/areaeditor/blueprints
	difficulty = 10
	excludefromjob = list("Chief Engineer")
	altitems = list(/obj/item/photo)

/datum/objective_item/steal/blueprints/check_special_completion(obj/item/I)
	if(istype(I, /obj/item/areaeditor/blueprints))
		return TRUE
	if(istype(I, /obj/item/photo))
		var/obj/item/photo/P = I
		if(P.picture.has_blueprints)	//if the blueprints are in frame
			return TRUE
	return FALSE

/datum/objective_item/steal/slime
	name = "an unused sample of slime extract."
	targetitem = /obj/item/slime_extract
	difficulty = 3
	excludefromjob = list("Research Director","Scientist")

/datum/objective_item/steal/slime/check_special_completion(obj/item/slime_extract/E)
	if(E.Uses > 0)
		return 1
	return 0

/datum/objective_item/steal/blackbox
	name = "the telecommunications blackbox."
	targetitem = /obj/item/blackbox
	difficulty = 10
	excludefromjob = list("Chief Engineer","Station Engineer","Atmospheric Technician","Network Admin")

//Unique Objectives
/datum/objective_item/unique/docs_red
	name = "the \"Red\" secret documents."
	targetitem = /obj/item/documents/syndicate/red
	difficulty = 10

/datum/objective_item/unique/docs_blue
	name = "the \"Blue\" secret documents."
	targetitem = /obj/item/documents/syndicate/blue
	difficulty = 10

/datum/objective_item/special/New()
	..()
	if(TargetExists())
		GLOB.possible_items_special += src
	else
		qdel(src)

/datum/objective_item/special/Destroy()
	GLOB.possible_items_special -= src
	return ..()

//Old ninja objectives.
/datum/objective_item/special/pinpointer/nuke
	name = "the Captain's pinpointer."
	targetitem = /obj/item/pinpointer
	difficulty = 10

/datum/objective_item/special/aegun
	name = "an advanced energy gun."
	targetitem = /obj/item/gun/energy/e_gun/nuclear
	difficulty = 10

/datum/objective_item/special/ddrill
	name = "a diamond drill."
	targetitem = /obj/item/pickaxe/drill/diamonddrill
	difficulty = 10

/datum/objective_item/special/boh
	name = "the Research Director's bag of holding."    //Just in case these are activated again this one is updated to reference the only one on station now. - Aquizit Jan '23
	targetitem = /obj/item/storage/backpack/holding
	difficulty = 10

/datum/objective_item/special/hypercell
	name = "a hyper-capacity power cell."
	targetitem = /obj/item/stock_parts/cell/hyper
	difficulty = 5

/datum/objective_item/special/laserpointer
	name = "a laser pointer."
	targetitem = /obj/item/laser_pointer
	difficulty = 5

/datum/objective_item/special/corgimeat
	name = "a piece of corgi meat."
	targetitem = /obj/item/reagent_containers/food/snacks/meat/slab/corgi
	difficulty = 5

/datum/objective_item/stack/New()
	..()
	if(TargetExists())
		GLOB.possible_items_special += src
	else
		qdel(src)

/datum/objective_item/stack/Destroy()
	GLOB.possible_items_special -= src
	return ..()

//Stack objectives get their own subtype
/datum/objective_item/stack
	name = "5 cardboard."
	targetitem = /obj/item/stack/sheet/cardboard
	difficulty = 9001

/datum/objective_item/stack/check_special_completion(obj/item/stack/S)
	var/target_amount = text2num(name)
	var/found_amount = 0

	if(istype(S, targetitem))
		found_amount = S.amount
	return found_amount>=target_amount

/datum/objective_item/stack/diamond
	name = "10 diamonds."
	targetitem = /obj/item/stack/sheet/mineral/diamond
	difficulty = 10

/datum/objective_item/stack/gold
	name = "50 gold bars."
	targetitem = /obj/item/stack/sheet/mineral/gold
	difficulty = 15

/datum/objective_item/stack/uranium
	name = "25 refined uranium bars."
	targetitem = /obj/item/stack/sheet/mineral/uranium
	difficulty = 10
