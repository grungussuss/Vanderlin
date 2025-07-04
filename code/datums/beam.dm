//Beam Datum and effect
/datum/beam
	var/atom/origin = null
	var/atom/target = null
	var/list/elements = list()
	var/icon/base_icon = null
	var/icon
	var/icon_state = "" //icon state of the main segments of the beam
	var/max_distance = 0
	var/sleep_time = 3
	var/finished = 0
	var/target_oldloc = null
	var/origin_oldloc = null
	var/static_beam = 0
	var/beam_type = /obj/effect/ebeam //must be subtype
	var/timing_id = null
	var/recalculating = FALSE
	var/bcolor
	var/forced_plane
	var/forced_layer

	var/datum/mana_pool/mana_pool
	var/redraws
	var/draws_invis
	var/obj/effect/proc_holder/spell/spell_source
	var/list/hit_targets = list()  // Track what we've already hit

/datum/beam/New(beam_origin,beam_target,beam_icon='icons/effects/beam.dmi',beam_icon_state="b_beam",time=50,maxdistance=10,btype = /obj/effect/ebeam,beam_sleep_time=3,beam_color = COLOR_WHITE, redraws = TRUE, invisible_state, incoming_spell)
	origin = beam_origin
	origin_oldloc =	get_turf(origin)
	target = beam_target
	target_oldloc = get_turf(target)
	src.redraws = redraws
	sleep_time = beam_sleep_time
	if(origin_oldloc == origin && target_oldloc == target)
		static_beam = 1
	max_distance = maxdistance
	base_icon = new(beam_icon,beam_icon_state)
	icon = beam_icon
	icon_state = beam_icon_state
	beam_type = btype
	bcolor = beam_color
	if(time < INFINITY)
		addtimer(CALLBACK(src,PROC_REF(End)), time)
	draws_invis = invisible_state
	spell_source = incoming_spell

/datum/beam/proc/Start()
	Draw()
	if(redraws)
		recalculate_in(sleep_time)

/datum/beam/proc/recalculate()
	if(recalculating)
		recalculate_in(sleep_time)
		return
	recalculating = TRUE
	timing_id = null
	if(origin && target && get_dist(origin,target)<max_distance && origin.z == target.z)
		var/origin_turf = get_turf(origin)
		var/target_turf = get_turf(target)
		if(!static_beam && (origin_turf != origin_oldloc || target_turf != target_oldloc))
			origin_oldloc = origin_turf //so we don't keep checking against their initial positions, leading to endless Reset()+Draw() calls
			target_oldloc = target_turf
			Reset()
			Draw()
		after_calculate()
		recalculating = FALSE
	else
		End()

/datum/beam/proc/afterDraw()
	return

/datum/beam/proc/recalculate_in(time)
	if(timing_id)
		deltimer(timing_id)
	timing_id = addtimer(CALLBACK(src, PROC_REF(recalculate)), time, TIMER_STOPPABLE)

/datum/beam/proc/after_calculate()
	if((sleep_time == null) || finished)	//Does not automatically recalculate.
		return
	if(isnull(timing_id))
		timing_id = addtimer(CALLBACK(src, PROC_REF(recalculate)), sleep_time, TIMER_STOPPABLE)

/datum/beam/proc/End(destroy_self = TRUE)
	finished = TRUE
	if(!isnull(timing_id))
		deltimer(timing_id)
	if(!QDELETED(src) && destroy_self)
		qdel(src)
	hit_targets = null
	spell_source = null
	origin?.BeamBroken(target)

/datum/beam/proc/Reset()
	for(var/obj/effect/ebeam/B in elements)
		qdel(B)
	elements.Cut()

/datum/beam/Destroy()
	Reset()
	target = null
	origin = null
	return ..()

/datum/beam/proc/Draw()
	var/Angle = round(Get_Angle(origin,target))
	var/matrix/rot_matrix = matrix()
	rot_matrix.Turn(Angle)

	//Translation vector for origin and target
	var/DX = (32*target.x+target.pixel_x)-(32*origin.x+origin.pixel_x)
	var/DY = (32*target.y+target.pixel_y)-(32*origin.y+origin.pixel_y)
	var/N = 0
	var/length = round(sqrt((DX)**2+(DY)**2)) //hypotenuse of the triangle formed by target and origin's displacement

	for(N in 0 to length-1 step 32)//-1 as we want < not <=, but we want the speed of X in Y to Z and step X
		if(QDELETED(src) || finished)
			break
		var/obj/effect/ebeam/X = new beam_type(origin_oldloc)
		X.owner = src
		X.spell_source = spell_source
		if(draws_invis)
			X.invisibility = draws_invis
		elements += X

		//Assign icon, for main segments it's base_icon, for the end, it's icon+icon_state
		//cropped by a transparent box of length-N pixel size
		if(N+32>length)
			var/icon/II = new(icon, icon_state)
			II.DrawBox(null,1,(length-N),32,32)
			X.icon = II
		else
			X.icon = base_icon
		X.transform = rot_matrix

		//Calculate pixel offsets (If necessary)
		var/Pixel_x
		var/Pixel_y
		if(DX == 0)
			Pixel_x = 0
		else
			Pixel_x = round(sin(Angle)+32*sin(Angle)*(N+16)/32)
		if(DY == 0)
			Pixel_y = 0
		else
			Pixel_y = round(cos(Angle)+32*cos(Angle)*(N+16)/32)

		//Position the effect so the beam is one continous line
		var/a
		if(abs(Pixel_x)>32)
			a = Pixel_x > 0 ? round(Pixel_x/32) : CEILING(Pixel_x/32, 1)
			X.x += a
			Pixel_x %= 32
		if(abs(Pixel_y)>32)
			a = Pixel_y > 0 ? round(Pixel_y/32) : CEILING(Pixel_y/32, 1)
			X.y += a
			Pixel_y %= 32

		X.pixel_x = Pixel_x
		X.pixel_y = Pixel_y
		X.color = bcolor
		if(forced_plane)
			X.plane = forced_plane
		if(forced_plane)
			X.layer = forced_layer
		CHECK_TICK
	afterDraw()

/obj/effect/ebeam
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/datum/beam/owner
	var/obj/effect/proc_holder/spell/spell_source

/obj/effect/ebeam/Destroy()
	owner = null
	return ..()

/obj/effect/ebeam/react_to_entry

/obj/effect/ebeam/react_to_entry/Initialize(mapload, beam_owner)
	. = ..()
	if(isnull(owner))
		return
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	// Technically the beam is entering the mob but we'll count it
	for(var/thing in loc)
		on_entered(src, thing)

/obj/effect/ebeam/react_to_entry/proc/on_entered(datum/source, atom/movable/entering)
	SIGNAL_HANDLER
	SEND_SIGNAL(owner, COMSIG_BEAM_ENTERED, src, entering)

/atom/proc/Beam(atom/BeamTarget,icon_state="b_beam",icon='icons/effects/beam.dmi',time=50, maxdistance=10,beam_type=/obj/effect/ebeam,beam_sleep_time = 3, beam_color = COLOR_WHITE, spell_source)
	var/datum/beam/newbeam = new(src,BeamTarget,icon,icon_state,time,maxdistance,beam_type,beam_sleep_time,beam_color, incoming_spell = spell_source)
	INVOKE_ASYNC(newbeam, TYPE_PROC_REF(/datum/beam, Start))
	return newbeam

/atom/proc/LeyBeam(atom/BeamTarget,icon_state="b_beam",icon='icons/effects/beam.dmi',time=INFINITY, maxdistance=10,beam_type=/obj/effect/ebeam,beam_sleep_time = 3, beam_color = COLOR_WHITE, datum/mana_pool, layer = UPPER_LEYLINE_LAYER, redraws = TRUE)
	var/datum/beam/newbeam = new(src,BeamTarget,icon,icon_state,time,maxdistance,beam_type,beam_sleep_time,beam_color,redraws, invisible_state = INVISIBILITY_LEYLINES)
	if(mana_pool)
		newbeam.mana_pool = mana_pool
	newbeam.forced_plane = LEYLINE_PLANE
	newbeam.forced_layer = UPPER_LEYLINE_LAYER
	INVOKE_ASYNC(newbeam, TYPE_PROC_REF(/datum/beam, Start))
	return newbeam
