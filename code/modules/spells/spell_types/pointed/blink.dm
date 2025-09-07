/datum/action/cooldown/blink
	name = "Blink"
	desc = "Teleport to a tile in an instant."

	cooldown_time = 2 SECONDS

/datum/action/cooldown/blink/Activate(atom/target)
	. = ..()

	//sound = 'sound/magic/blade_burst.ogg'

GLOBAL_VAR_INIT(filter_x_amount, 2)
GLOBAL_VAR_INIT(filter_y_amount, 2)

/mob/living/proc/spell_blink_effect(duration = 1 SECONDS)
	if(duration < 1 SECONDS)
		CRASH("called with duration less than 1 SECONDS")
	add_filter("spell_blink", 10, displacement_map_filter('icons/tg_logo.png', "spell_blink", size = 0))
	//add_filter("spell_blink_blur", 11, motion_blur_filter(GLOB.filter_x_amount, GLOB.filter_y_amount))

	animate(get_filter("spell_blink"), time = 1 SECONDS, size = 10)
	animate(time = duration)
	animate(time = 1 SECONDS, size = 0)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, remove_filter), "spell_blink"), 2 SECONDS + duration)
	//addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, remove_filter), "spell_blink_blur"), 2 SECONDS + duration)

	animate(src, time = 2 SECONDS, alpha = 0, ANIMATION_PARALLEL)
	animate(time = duration - 1)
	animate(time = 1 SECONDS, alpha = initial(alpha))


