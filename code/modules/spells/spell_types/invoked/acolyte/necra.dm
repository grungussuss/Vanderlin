// Necrite
/obj/effect/proc_holder/spell/targeted/burialrite
	name = "Burial Rites"
	range = 5
	overlay_state = "consecrateburial"
	releasedrain = 30
	recharge_time = 30 SECONDS
	max_targets = 0
	cast_without_targets = TRUE
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "Undermaiden grant thee passage forth and spare the trials of the forgotten."
	invocation_type = "whisper" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 15

/obj/effect/proc_holder/spell/targeted/burialrite/cast(list/targets,mob/user = usr)
	. = ..()
	if(user.is_holding_item_of_type(/obj/item/weapon/knife/dagger/steel/profane)) // If you are holding an assassin's cursed dagger, break it and free the souls contained within, sending them into the lukewarm arms of Necra.
		var/obj/item/weapon/knife/dagger/steel/profane/held_profane = user.is_holding_item_of_type(/obj/item/weapon/knife/dagger/steel/profane)
		var/saved_souls = held_profane.release_profane_souls(user) // Releases the trapped souls and breaks the dagger. Gets the number of souls saved by destroying the dagger.
		user.adjust_triumphs(saved_souls) // Every soul saved earns you a big fat triumph.
	var/target_turf = get_step(user, user.dir)
	for(var/obj/structure/closet/crate/coffin/coffin in target_turf)
		if(pacify_coffin(coffin, user))
			user.visible_message(span_rose("[user] consecrates [coffin]."), span_rose("My funeral rites have been performed on [coffin]."))
			SEND_SIGNAL(user, COMSIG_GRAVE_CONSECRATED, coffin)
			GLOB.vanderlin_round_stats[STATS_GRAVES_CONSECRATED]++
			return
	for(var/obj/structure/closet/dirthole/hole in target_turf)
		if(pacify_coffin(hole, user))
			user.visible_message(span_rose("[user] consecrates [hole]."), span_rose("My funeral rites have been performed on [hole]."))
			SEND_SIGNAL(user, COMSIG_GRAVE_CONSECRATED, hole)
			GLOB.vanderlin_round_stats[STATS_GRAVES_CONSECRATED]++
			return
	to_chat(user, span_warning("I failed to perform the rites."))

/obj/effect/proc_holder/spell/targeted/soulspeak
	name = "Speak with Soul"
	range = 5
	overlay_state = "speakwithdead"
	releasedrain = 30
	recharge_time = 75 SECONDS
	req_items = list(/obj/item/clothing/neck/psycross/silver/necra)
	max_targets = 0
	cast_without_targets = TRUE
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "Undermaiden brooks thee respite, be heard, wanderer."
	invocation_type = "whisper" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 40

/obj/effect/proc_holder/spell/targeted/soulspeak/cast(list/targets,mob/user = usr)
	var/mob/living/carbon/spirit/capturedsoul = null
	var/list/souloptions = list()
	var/list/itemstore = list()
	for(var/mob/living/carbon/spirit/S in GLOB.spirit_list)
		if(S.summoned)
			continue
		if(!S.client)
			continue
		souloptions += S.livingname
	var/pickedsoul = input(user, "Which wandering soul shall I commune with?", "Available Souls") as null|anything in souloptions
	if(!pickedsoul)
		to_chat(user, span_warning("I was unable to commune with a soul."))
		return
	for(var/mob/living/carbon/spirit/P in GLOB.spirit_list)
		if(P.livingname == pickedsoul)
			to_chat(P, span_blue("You feel yourself being pulled out of the Underworld."))
			sleep(2 SECONDS)
			if(QDELETED(P) || P.summoned)
				to_chat(user, span_blue("Your connection to the soul suddenly disappears!"))
				return
			capturedsoul = P
			break
	if(capturedsoul)
		SSdeath_arena.remove_fighter(capturedsoul)
		for(var/obj/item/I in capturedsoul.held_items) // this is still ass
			capturedsoul.temporarilyRemoveItemFromInventory(I, force = TRUE)
			itemstore += I.type
			qdel(I)
		capturedsoul.summoned = TRUE
		capturedsoul.beingmoved = TRUE
		capturedsoul.invisibility = INVISIBILITY_OBSERVER
		capturedsoul.status_flags |= GODMODE
		capturedsoul.Stun(61 SECONDS)
		capturedsoul.density = FALSE

		var/list/icon_dimensions = get_icon_dimensions(user.icon)
		var/orbitsize = (icon_dimensions["width"] + icon_dimensions["height"]) * 0.5
		orbitsize -= (orbitsize/world.icon_size)*(world.icon_size*0.25)
		capturedsoul.setDir(2)
		capturedsoul.orbit(user, orbitsize, FALSE, 20, 36)

		capturedsoul.update_cone()

		addtimer(CALLBACK(src, PROC_REF(return_soul), user, capturedsoul, itemstore), 60 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(return_soul_warning), user, capturedsoul), 50 SECONDS)
		to_chat(user, span_blue("I feel a cold chill run down my spine, a ghastly presence has arrived."))
		return ..()
	to_chat(user, span_warning("I was unable to commune with a soul."))
	return FALSE

/obj/effect/proc_holder/spell/targeted/soulspeak/proc/return_soul_warning(mob/user, mob/living/carbon/spirit/soul)
	if(!QDELETED(user))
		to_chat(user, span_warning("The soul is being pulled away..."))
	if(!QDELETED(soul))
		to_chat(soul, span_warning("I'm starting to be pulled away..."))

/obj/effect/proc_holder/spell/targeted/soulspeak/proc/return_soul(mob/user, mob/living/carbon/spirit/soul, list/itemstore)
	if(!QDELETED(user))
		to_chat(user, span_blue("The soul returns to the Underworld."))
	if(QDELETED(soul))
		return
	to_chat(soul, span_blue("You feel yourself being transported back to the Underworld."))
	soul.orbiting?.end_orbit()
	soul.drop_all_held_items()
	var/turf/soul_turf = pick(GLOB.underworldspiritspawns)
	soul.forceMove(soul_turf)
	for(var/I in itemstore)
		soul.put_in_hands(new I())
	soul.beingmoved = FALSE
	soul.fully_heal(FALSE)
	soul.invisibility = initial(soul.invisibility)
	soul.status_flags &= ~GODMODE
	soul.update_cone()
	soul.density = initial(soul.density)
	SSdeath_arena.add_fighter(soul, soul.mind?.last_death)

/obj/effect/proc_holder/spell/targeted/churn
	name = "Churn Undead"
	range = 5
	overlay_state = "necra"
	releasedrain = 30
	recharge_time = 30 SECONDS
	max_targets = 0
	cast_without_targets = TRUE
	req_items = list(/obj/item/clothing/neck/psycross/silver/necra)
	sound = 'sound/magic/churn.ogg'
	associated_skill = /datum/skill/magic/holy
	invocation = "The Undermaiden rebukes!"
	invocation_type = "shout" //can be none, whisper, emote and shout
	miracle = TRUE
	devotion_cost = 60

/obj/effect/proc_holder/spell/targeted/churn/cast(list/targets,mob/living/user = usr)
	var/prob2explode = 100
	if(user && user.mind)
		prob2explode = 0
		for(var/i in 1 to user.get_skill_level(/datum/skill/magic/holy))
			prob2explode += 80
	for(var/mob/living/L in targets)
		var/isvampire = FALSE
		var/iszombie = FALSE
		if(L.stat == DEAD)
			continue
		if(L.mind)
			var/datum/antagonist/vampire/V = L.mind.has_antag_datum(/datum/antagonist/vampire)
			if(V)
				if(!V.disguised)
					isvampire = TRUE
			if(L.mind.has_antag_datum(/datum/antagonist/zombie))
				iszombie = TRUE
			if(istype(V, /datum/antagonist/vampire/lord))
				user.visible_message("<span class='warning'>[L] overpowers being churned!</span>", "<span class='userdanger'>[L] is too strong, I am churned!</span>")
				user.Stun(50)
				user.throw_at(get_ranged_target_turf(user, get_dir(user,L), 7), 7, 1, L, spin = FALSE)
				continue
		if((L.mob_biotypes & MOB_UNDEAD) || isvampire || iszombie)
			var/undead_prob = prob2explode
			if(isvampire)
				undead_prob -= 20
			if(prob(undead_prob))
				L.visible_message("<span class='warning'>[L] HAS BEEN CHURNED BY NECRA'S GRIP!</span>", "<span class='danger'>I'VE BEEN CHURNED BY NECRA'S GRIP!</span>")
				explosion(get_turf(L), light_impact_range = 1, flame_range = 1, smoke = FALSE)
				L.Stun(50)
				if(istype(L, /mob/living/simple_animal/hostile/retaliate/poltergeist))
					L.gib()
			else
				L.visible_message("<span class='warning'>[L] resists being churned!</span>", "<span class='userdanger'>I resist being churned!</span>")
	return ..()
