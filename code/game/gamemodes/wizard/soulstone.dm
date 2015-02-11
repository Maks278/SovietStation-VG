/obj/item/device/soulstone
	name = "Soul Stone Shard"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "soulstone"
	item_state = "shard-soulstone"
	desc = "A fragment of the legendary treasure known simply as the 'Soul Stone'. The shard still flickers with a fraction of the full artefacts power."
	w_class = 1.0
	flags = FPRINT
	slot_flags = SLOT_BELT
	origin_tech = "bluespace=4;materials=4"
	var/imprinted = "empty"

//////////////////////////////Capturing////////////////////////////////////////////////////////

	attack(mob/living/carbon/human/M as mob, mob/user as mob)
		if(!istype(M, /mob/living/carbon/human))//If target is not a human.
			return ..()
		if(istype(M, /mob/living/carbon/human/manifested))
			user << "The soul stone shard seems unable to pull the soul out of that poor manifested ghost back onto our plane."
			return
		add_logs(user, M, "captured [M.name]'s soul", object=src)

		transfer_soul("VICTIM", M, user)
		return

	/*attack(mob/living/simple_animal/shade/M as mob, mob/user as mob)//APPARENTLY THEY NEED THEIR OWN SPECIAL SNOWFLAKE CODE IN THE LIVING ANIMAL DEFINES
		if(!istype(M, /mob/living/simple_animal/shade))//If target is not a shade
			return ..()
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to capture the soul of [M.name] ([M.ckey])</font>")

		transfer_soul("SHADE", M, user)
		return*/
///////////////////Options for using captured souls///////////////////////////////////////

	attack_self(mob/user)
		if (!in_range(src, user))
			return
		user.set_machine(src)
		var/dat = "<TT><B>Soul Stone</B><BR>"
		for(var/mob/living/simple_animal/shade/A in src)
			dat += "Captured Soul: [A.name]<br>"
			dat += {"<A href='byond://?src=\ref[src];choice=Summon'>Summon Shade</A>"}
			dat += "<br>"
			dat += {"<a href='byond://?src=\ref[src];choice=Close'> Close</a>"}
		user << browse(dat, "window=aicard")
		onclose(user, "aicard")
		return




	Topic(href, href_list)
		var/mob/U = usr
		if (!in_range(src, U)||U.machine!=src)
			U << browse(null, "window=aicard")
			U.unset_machine()
			return

		add_fingerprint(U)
		U.set_machine(src)

		switch(href_list["choice"])//Now we switch based on choice.
			if ("Close")
				U << browse(null, "window=aicard")
				U.unset_machine()
				return

			if ("Summon")
				for(var/mob/living/simple_animal/shade/A in src)
					A.status_flags &= ~GODMODE
					A.canmove = 1
					A << "<b>You have been released from your prison, but you are still bound to [U.name]'s will. Help them suceed in their goals at all costs.</b>"
					A.loc = U.loc
					A.cancel_camera()
					src.icon_state = "soulstone"

		attack_self(U)

/obj/item/device/soulstone/cultify()
	return

///////////////////////////Transferring to constructs/////////////////////////////////////////////////////
/obj/structure/constructshell
	name = "empty shell"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "construct"
	desc = "A wicked machine used by those skilled in magical arts. It is inactive."
	flags = FPRINT

/obj/structure/constructshell/cultify()
	return

/obj/structure/constructshell/cult
	icon_state = "construct-cult"
	desc = "This eerie contraption looks like it would come alive if supplied with a missing ingredient."

/obj/structure/constructshell/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, /obj/item/device/soulstone))
		O.transfer_soul("CONSTRUCT",src,user)


////////////////////////////Proc for moving soul in and out off stone//////////////////////////////////////


/obj/item/proc/transfer_soul(var/choice as text, var/target, var/mob/U as mob)
	var/deleteafter = 0
	switch(choice)
		if("VICTIM")
			var/mob/living/carbon/human/T = target
			var/obj/item/device/soulstone/C = src
			if(C.imprinted != "empty")
				U << "\red <b>Capture failed!</b>: \black The soul stone has already been imprinted with [C.imprinted]'s mind!"
			else
				if (T.stat == 0)
					U << "\red <b>Capture failed!</b>: \black Kill or maim the victim first!"
				else
					if(T.client == null)
						U << "\red <b>Capture failed!</b>: \black The soul has already fled it's mortal frame."
					else
						if(C.contents.len)
							U << "\red <b>Capture failed!</b>: \black The soul stone is full! Use or free an existing soul to make room."
						else
							for(var/obj/item/W in T)
								T.drop_from_inventory(W)
							new /obj/effect/decal/remains/human(T.loc) //Spawns a skeleton
							T.invisibility = 101
							var/atom/movable/overlay/animation = new /atom/movable/overlay( T.loc )
							animation.icon_state = "blank"
							animation.icon = 'icons/mob/mob.dmi'
							animation.master = T
							flick("dust-h", animation)
							del(animation)
							var/mob/living/simple_animal/shade/S = new /mob/living/simple_animal/shade( T.loc )
							S.loc = C //put shade in stone
							S.status_flags |= GODMODE //So they won't die inside the stone somehow
							S.canmove = 0//Can't move out of the soul stone
							S.name = "Shade of [T.real_name]"
							S.real_name = "Shade of [T.real_name]"
							if (T.client)
								T.client.mob = S
							S.cancel_camera()
							C.icon_state = "soulstone2"
							C.name = "Soul Stone: [S.real_name]"
							S << "Your soul has been captured! You are now bound to [U.name]'s will, help them suceed in their goals at all costs."
							U << "\blue <b>Capture successful!</b>: \black [T.real_name]'s soul has been ripped from their body and stored within the soul stone."
							U << "The soulstone has been imprinted with [S.real_name]'s mind, it will no longer react to other souls."
							C.imprinted = "[S.name]"
							var/ref = "\ref[U.mind]"
							var/list/necromancers
							if(!(U.mind in ticker.mode.necromancer))
								ticker.mode:necromancer[ref] = list()
							necromancers = ticker.mode:necromancer[ref]
							necromancers.Add(S.mind)
							ticker.mode:necromancer[ref] = necromancers
							ticker.mode.update_necro_icons_added(U.mind)
							ticker.mode.update_necro_icons_added(S.mind)
							ticker.mode.risen.Add(S.mind)
							del T
		if("SHADE")
			var/mob/living/simple_animal/shade/T = target
			var/obj/item/device/soulstone/C = src
			if (T.stat == DEAD)
				U << "\red <b>Capture failed!</b>: \black The shade has already been banished!"
			else
				if(C.contents.len)
					U << "\red <b>Capture failed!</b>: \black The soul stone is full! Use or free an existing soul to make room."
				else
					if(T.name != C.imprinted)
						U << "\red <b>Capture failed!</b>: \black The soul stone has already been imprinted with [C.imprinted]'s mind!"
					else
						T.loc = C //put shade in stone
						T.status_flags |= GODMODE
						T.canmove = 0
						T.health = T.maxHealth
						C.icon_state = "soulstone2"
						T << "Your soul has been recaptured by the soul stone, its arcane energies are reknitting your ethereal form"
						U << "\blue <b>Capture successful!</b>: \black [T.name]'s has been recaptured and stored within the soul stone."
		if("CONSTRUCT")
			var/obj/structure/constructshell/T = target
			var/obj/item/device/soulstone/C = src
			var/mob/living/simple_animal/shade/A = locate() in C
			var/mob/living/simple_animal/construct/Z
			if(A)
				var/construct_class = alert(U, "Please choose which type of construct you wish to create.",,"Juggernaut","Wraith","Artificer")
				ticker.mode.update_necro_icons_removed(A.mind)
				switch(construct_class)
					if("Juggernaut")
						Z = new /mob/living/simple_animal/construct/armoured (get_turf(T.loc))
						Z.key = A.key
						if(iscultist(U))
							if(ticker.mode.name == "cult")
								ticker.mode:add_cultist(Z.mind)
							else
								ticker.mode.cult+=Z.mind
							ticker.mode.update_cult_icons_added(Z.mind)
						del(T)
						Z << "<B>You are a Juggernaut. Though slow, your shell can withstand extreme punishment, create shield walls and even deflect energy weapons, and rip apart enemies and walls alike.</B>"
						Z << "<B>You are still bound to serve your creator, follow their orders and help them complete their goals at all costs.</B>"
						Z.spell_list += new /obj/effect/proc_holder/spell/aoe_turf/conjure/lesserforcewall(Z)
						Z.cancel_camera()
						deleteafter = 1

					if("Wraith")
						Z = new /mob/living/simple_animal/construct/wraith (get_turf(T.loc))
						Z.key = A.key
						if(iscultist(U))
							if(ticker.mode.name == "cult")
								ticker.mode:add_cultist(Z.mind)
							else
								ticker.mode.cult+=Z.mind
							ticker.mode.update_cult_icons_added(Z.mind)
						del(T)
						Z << "<B>You are a Wraith. Though relatively fragile, you are fast, deadly, and even able to phase through walls.</B>"
						Z << "<B>You are still bound to serve your creator, follow their orders and help them complete their goals at all costs.</B>"
						Z.spell_list += new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift(Z)
						Z.cancel_camera()
						deleteafter = 1

					if("Artificer")
						Z = new /mob/living/simple_animal/construct/builder (get_turf(T.loc))
						Z.key = A.key
						if(iscultist(U))
							if(ticker.mode.name == "cult")
								ticker.mode:add_cultist(Z.mind)
							else
								ticker.mode.cult+=Z.mind
							ticker.mode.update_cult_icons_added(Z.mind)
						del(T)
						Z << "<B>You are an Artificer. You are incredibly weak and fragile, but you are able to construct fortifications, use magic missile, repair allied constructs (by clicking on them), </B><I>and most important of all create new constructs</I><B> (Use your Artificer spell to summon a new construct shell and Summon Soulstone to create a new soulstone).</B>"
						Z << "<B>You are still bound to serve your creator, follow their orders and help them complete their goals at all costs.</B>"
						Z.spell_list += new /obj/effect/proc_holder/spell/aoe_turf/conjure/construct/lesser(Z)
						Z.spell_list += new /obj/effect/proc_holder/spell/aoe_turf/conjure/wall(Z)
						Z.spell_list += new /obj/effect/proc_holder/spell/aoe_turf/conjure/floor(Z)
						Z.spell_list += new /obj/effect/proc_holder/spell/aoe_turf/conjure/soulstone(Z)
						Z.cancel_camera()
						deleteafter = 1
				if(Z && Z.mind && !iscultist(Z))
					var/ref = "\ref[U.mind]"
					var/list/necromancers
					if(!(U.mind in ticker.mode.necromancer))
						ticker.mode:necromancer[ref] = list()
					necromancers = ticker.mode:necromancer[ref]
					necromancers.Add(Z.mind)
					ticker.mode:necromancer[ref] = necromancers
					ticker.mode.update_necro_icons_added(U.mind)
					ticker.mode.update_necro_icons_added(Z.mind)
					ticker.mode.risen.Add(Z.mind)
			else
				U << "\red <b>Creation failed!</b>: \black The soul stone is empty! Go kill someone!"
	ticker.mode.update_all_necro_icons()
	if(deleteafter)
		del(src)
	return