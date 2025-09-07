/datum/action/cooldown/blink
	name = "Blink"
	desc = "Teleport to a tile in an instant."
	sound = 'sound/magic/churn.ogg'

	charge_required = FALSE
	cooldown_time = 2 SECONDS
	has_visual_effects = FALSE

/datum/action/cooldown/blink/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return
	return

/datum/action/cooldown/blink/cast(mob/living/cast_on)
	. = ..()
	cast_on.blind_eyes(3)
	cast_on.visible_message(span_warning("[owner] points at [cast_on]'s eyes!"), span_warning("My eyes are covered in darkness!"))

/datum/action/cooldown/blink
	charge_sound = 'sound/magic/holycharging.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/skill/magic/holy
	required_items = list(/obj/item/clothing/neck/psycross/noc)

	invocation = "Noc blinds thee of thy sins!"
	invocation_type = INVOCATION_SHOUT

