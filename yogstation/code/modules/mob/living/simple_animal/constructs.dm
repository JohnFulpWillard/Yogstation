/mob/living/simple_animal/hostile/construct/ratvar_act()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD && !IS_SERVANT_OF_RATVAR(src))
		to_chat(src, span_userdanger("A blinding light boils you alive! <i>Run!</i>"))
		adjustFireLoss(35)
		return FALSE
