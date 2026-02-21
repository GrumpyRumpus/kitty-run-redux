Kitty Run Redux -- Ideas

============================================================
GAMEPLAY
============================================================

---- Combat ----
  [ ] Dash/slide move for dodging under swooping enemies
  [ ] More enemy variety (ground walkers, shielded flyers, chargers)
  [ ] Combo system -- chain stomps/kills for score multipliers
  [ ] Boss encounters every N points (larger enemy, health bar, attack patterns)
  [ ] Variable double-jump height -- short-hop on quick tap like first jump
  [ ] Mob AI awareness -- bias toward SHOOT when near kitty, SWOOP toward kitty X

---- Powerups ----
  [ ] Power-up drop system -- random drops from killed enemies or floating collectibles
  [ ] Rapid fire -- reduce bullet cooldown for a duration
  [ ] Giant bullet -- larger projectile, pierces through multiple enemies
  [ ] Extra jumps -- triple/quad jump for a duration
  [ ] Shield -- absorbs one hit without losing health
  [ ] Score magnet -- pulls nearby pickups toward kitty
  [ ] Speed boost -- temporarily increases max run speed + ground scroll

---- Difficulty ----
  [ ] Progressive difficulty -- ground speed increases over time too
  [ ] Ground gaps -- pits kitty must jump over (ground already tiles, remove segments)
  [ ] Varying platform heights -- elevated platforms to jump onto

============================================================
POLISH
============================================================

---- Stomp Juice ----
  [x] Screen shake on stomp (reuse game._screen_shake)
  [x] Hitstop/freeze frame on stomp (~50ms physics pause for impact weight)
  [x] Squash-stretch on kitty sprite -- squish wide on contact, stretch tall on bounce
  [x] Stomp sound effect (currently silent)
  [x] Wire stomp kills to add_kill_score for score popup
      mob_killed signal should fire from take_damage(collider.health) path -- verify

---- Hit Feedback ----
  [x] White flash on mob damage -- shader uniform (flash_amount) on sprite material
  [x] Bullet impact particles (enemies + ground)
  [x] Draw kitty bullets on a layer below kitty so they don't overlap the sprite
  [x] Distinguish enemy bullets visually -- tint red or different sprite
  [x] Replace string-based collision in bullet.gd
      body.name.begins_with("Ground") -> body is Grounds

---- Movement Feel ----
  [x] Landing feedback -- sprite squash + dust puff on land
  [x] Double jump visual (dust puff on second jump)
  [ ] Death animation -- slow-mo, zoom, sound

---- Spawning ----
  [x] Wider mob spawn Y band -- was 50px, now y=32..85 (vp_height/8 through vp_height/3)
      stays well above ground (y=128..153)

============================================================
CONTENT
============================================================

  [ ] Multiple biomes -- swap bg/ground colors as score increases
  [ ] Unlockable kitty skins earned by high scores
  [ ] Collectible coins/gems -- scattered along ground for bonus points

============================================================
AUDIO
============================================================

  [ ] More music tracks -- distinct loops for menu, gameplay, game over
      MusicManager exists but only has two tracks currently
  [ ] SFX coverage -- stomp, enemy death, powerup pickup, button hover/click, death jingle
      jump/shoot/hurt sounds exist, these are the gaps

============================================================
HUD
============================================================

  [ ] Health as heart sprites -- replace unicode hearts with pixel art icons
  [ ] Powerup timer bar -- small bar showing remaining duration of active powerup
  [ ] Distance tracker -- show distance traveled alongside score
  [ ] Floating score popups -- "+1" text at kill location that fades upward
      score_popup.tscn exists, just needs to be wired to all kill paths

============================================================
QOL
============================================================

  [ ] Input rebinding
  [ ] Gamepad support (right stick aim)
  [ ] First-run tutorial hints (double jump, stomp, shooting)
  [ ] Fullscreen toggle in options menu

============================================================
CODE QUALITY
============================================================

  [ ] Replace static vars on State (kitty, state_machine, direction) with instance vars
      static vars caused the "running on start" bug already -- still a latent footgun
      pass refs through init() instead
  [ ] Simplify state machine stack -- only keeps 3 entries via resize
      two explicit vars (current_state, previous_state) would be clearer
  [x] Remove commented-out debug prints
  [x] Defer settings save -- _save() skipped during _load() via _loading flag
  [x] Replace string-based collision in bullet.gd
      moved to Hit Feedback section above
  [x] Fix hurting knockback direction -- now based on damage source position, not velocity
