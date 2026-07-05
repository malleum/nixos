package us.malleum.waverider.abilities;

import com.starshootercity.abilities.types.VisibleAbility;
import com.starshootercity.events.PlayerSwapOriginEvent;
import com.starshootercity.util.config.ConfigManager;
import net.kyori.adventure.key.Key;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.block.Block;
import org.bukkit.block.BlockFace;
import org.bukkit.block.data.BlockData;
import org.bukkit.block.data.Waterlogged;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityDamageEvent;
import org.bukkit.event.player.PlayerChangedWorldEvent;
import org.bukkit.event.player.PlayerGameModeChangeEvent;
import org.bukkit.event.player.PlayerMoveEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.event.player.PlayerRespawnEvent;
import org.bukkit.event.player.PlayerToggleSneakEvent;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.jetbrains.annotations.NotNull;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Water and lava behave like solid ground: the top fluid block under the player
 * is replaced client-side with an invisible barrier, so ordinary client physics
 * make it walkable/runnable/jumpable. Sneaking withdraws the floor and lets the
 * player sink in and swim. While striding the surface the player gets Speed
 * (level configurable, default III - faster than a boat's ~8 blocks/s), and
 * lava underfoot cannot burn them.
 *
 * The floor is purely packet-level; the real world is never modified. The
 * server sees the player standing on air above fluid, so the server MUST run
 * with allow-flight=true in server.properties or the vanilla anti-fly check
 * kicks them after a few seconds of hovering. Deliberately NOT worked around
 * with Player#setAllowFlight: vanilla skips ALL fall damage for mayfly
 * players, which would break Hard Landing and the falls-onto-fluid splat.
 */
public class FluidWalker implements VisibleAbility, Listener {
    /** How far below the feet to look for a fluid surface. Covers near-terminal fall speed (~4 blocks/tick). */
    private static final int SCAN_DEPTH = 5;
    /** Grace period for cancelling lava/fire damage after the last lava-walk tick. */
    private static final long LAVA_GRACE_MILLIS = 600;
    /**
     * Sneaking can only withdraw the floor while the accumulated fall is within
     * vanilla safe-fall height (no damage anyway). Past this, only a Wavecatch
     * breaks the fall - holding shift is no longer a free dive.
     */
    private static final float SNEAK_DIVE_MAX_FALL = 3.0f;

    /** Plain barrier for lava (nothing in vanilla is lava-loggable). */
    private static final BlockData BARRIER = Material.BARRIER.createBlockData();
    /** Waterlogged barrier for water: solid to the client but still renders the water, so no dry patch underfoot. */
    private static final BlockData WATER_BARRIER = Material.BARRIER.createBlockData(data -> {
        if (data instanceof Waterlogged waterlogged) waterlogged.setWaterlogged(true);
    });

    private final Map<UUID, Set<Location>> fakeFloors = new HashMap<>();
    private final Map<UUID, Long> lastLavaWalk = new HashMap<>();
    /** Potion amplifier while striding the surface (2 = Speed III). */
    private int speedAmplifier;

    @Override
    public @NotNull Key getKey() {
        return Key.key("waverider:fluid_walker");
    }

    @Override
    public String title() {
        return "Surface Tension";
    }

    @Override
    public String description() {
        return "You tread water and lava as if it were stone, striding the surface with great haste. Sneak to slip beneath - though not out of a real fall: catch it, or crater. Lava cannot burn you while you stand atop it.";
    }

    @EventHandler
    public void onPlayerMove(PlayerMoveEvent event) {
        Location to = event.getTo();
        this.runForAbility(event.getPlayer(),
                player -> update(player, to, player.isSneaking()),
                (Runnable) () -> clear(event.getPlayer()));
    }

    @Override
    public void initialize(JavaPlugin plugin) {
        speedAmplifier = this.registerConfigOption(plugin, "speed-amplifier",
                Collections.singletonList("Speed potion amplifier while striding fluid (2 = Speed III, just faster than a boat)"),
                ConfigManager.SettingType.INTEGER, 2);
    }

    @EventHandler
    public void onToggleSneak(PlayerToggleSneakEvent event) {
        // Sneaking withdraws the floor immediately so the player drops in and swims.
        this.runForAbility(event.getPlayer(),
                player -> update(player, player.getLocation(), event.isSneaking()));
    }

    @EventHandler
    public void onDamage(EntityDamageEvent event) {
        if (!(event.getEntity() instanceof Player player)) return;
        switch (event.getCause()) {
            case LAVA, FIRE, FIRE_TICK, HOT_FLOOR -> this.runForAbility(player, p -> {
                Long last = lastLavaWalk.get(p.getUniqueId());
                if (last != null && System.currentTimeMillis() - last < LAVA_GRACE_MILLIS) {
                    event.setCancelled(true);
                    p.setFireTicks(0);
                }
            });
            default -> { }
        }
    }

    @EventHandler
    public void onQuit(PlayerQuitEvent event) {
        forget(event.getPlayer());
    }

    @EventHandler
    public void onChangedWorld(PlayerChangedWorldEvent event) {
        // Client chunk state was reset by the world switch; just drop our tracking.
        forget(event.getPlayer());
    }

    @EventHandler
    public void onRespawn(PlayerRespawnEvent event) {
        forget(event.getPlayer());
    }

    @EventHandler
    public void onGameModeChange(PlayerGameModeChangeEvent event) {
        clear(event.getPlayer());
    }

    @EventHandler
    public void onSwapOrigin(PlayerSwapOriginEvent event) {
        clear(event.getPlayer());
    }

    private void update(Player player, Location to, boolean sneaking) {
        // Sneaking withdraws the floor only from a standstill or a harmless hop:
        // beyond vanilla safe-fall height the surface stays solid even while
        // sneaking, so a real fall can only be saved by a Wavecatch (whose water
        // resets the fall, re-arming sneak-to-sink the moment it catches).
        boolean canSneakThrough = player.getFallDistance() <= SNEAK_DIVE_MAX_FALL;
        if ((sneaking && canSneakThrough) || player.getVehicle() != null || player.isGliding()
                || player.getGameMode() == GameMode.SPECTATOR
                || to == null || to.getWorld() == null) {
            clear(player);
            return;
        }

        World world = to.getWorld();
        int x = to.getBlockX();
        int y = to.getBlockY();
        int z = to.getBlockZ();

        Block feet = world.getBlockAt(x, y, z);
        if (feet.isLiquid() && !WaterClutch.isClutchWater(feet)) {
            // Already inside the fluid (dove in, or got here before the floor did):
            // no floor until they climb back out or bob above the surface. Passing
            // through a clutch wave doesn't count - the floor below must hold so a
            // catch over open water ends standing on the surface.
            clear(player);
            return;
        }

        // Walk down from the feet looking for the top block of a fluid column.
        // Anything solid first means ordinary ground - no floor. A clutch wave is
        // fall-through, so look past it to the real surface underneath.
        Integer surfaceY = null;
        for (int d = 1; d <= SCAN_DEPTH; d++) {
            Block block = world.getBlockAt(x, y - d, z);
            if (WaterClutch.isClutchWater(block)) continue;
            if (block.isLiquid()) {
                surfaceY = y - d;
                break;
            }
            if (!block.isPassable()) break;
        }
        if (surfaceY == null) {
            clear(player);
            return;
        }

        // Build the 3x3 client-side floor at surface level.
        Set<Location> wanted = new HashSet<>();
        boolean lava = false;
        for (int dx = -1; dx <= 1; dx++) {
            for (int dz = -1; dz <= 1; dz++) {
                Block block = world.getBlockAt(x + dx, surfaceY, z + dz);
                if (!block.isLiquid()) continue;
                if (WaterClutch.isClutchWater(block)) continue;           // never solidify a clutch wave
                Block above = block.getRelative(BlockFace.UP);
                if (above.isLiquid() && !WaterClutch.isClutchWater(above)) continue; // not the surface
                if (block.getType() == Material.LAVA) lava = true;
                wanted.add(block.getLocation());
            }
        }
        if (wanted.isEmpty()) {
            clear(player);
            return;
        }

        Set<Location> current = fakeFloors.computeIfAbsent(player.getUniqueId(), u -> new HashSet<>());
        for (Location loc : current) {
            if (!wanted.contains(loc)) {
                player.sendBlockChange(loc, loc.getBlock().getBlockData());
            }
        }
        for (Location loc : wanted) {
            if (!current.contains(loc)) {
                player.sendBlockChange(loc,
                        loc.getBlock().getType() == Material.WATER ? WATER_BARRIER : BARRIER);
            }
        }
        fakeFloors.put(player.getUniqueId(), wanted);

        // Speed only while actually striding the surface, not while airborne above it.
        if (y == surfaceY + 1) {
            PotionEffect speed = player.getPotionEffect(PotionEffectType.SPEED);
            if (speed == null || speed.getAmplifier() < speedAmplifier || speed.getDuration() < 30) {
                player.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, 60, speedAmplifier, true, false, true));
            }
            if (lava) {
                lastLavaWalk.put(player.getUniqueId(), System.currentTimeMillis());
                if (player.getFireTicks() > 0) player.setFireTicks(0);
            }
        }
    }

    /** Withdraw the floor, resyncing the client with the real blocks. */
    private void clear(Player player) {
        Set<Location> current = fakeFloors.remove(player.getUniqueId());
        if (current != null) {
            for (Location loc : current) {
                player.sendBlockChange(loc, loc.getBlock().getBlockData());
            }
        }
    }

    /** Drop tracking without sending packets (client state already reset). */
    private void forget(Player player) {
        fakeFloors.remove(player.getUniqueId());
        lastLavaWalk.remove(player.getUniqueId());
    }
}
