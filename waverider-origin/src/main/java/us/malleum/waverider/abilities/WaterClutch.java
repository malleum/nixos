package us.malleum.waverider.abilities;

import com.starshootercity.abilities.types.CooldownAbility;
import com.starshootercity.abilities.types.VisibleAbility;
import com.starshootercity.cooldowns.Cooldowns;
import com.starshootercity.util.config.ConfigManager;
import net.kyori.adventure.key.Key;
import org.bukkit.Bukkit;
import org.bukkit.Material;
import org.bukkit.Sound;
import org.bukkit.block.Block;
import org.bukkit.block.BlockFace;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockFromToEvent;
import org.bukkit.event.entity.EntityDamageEvent;
import org.bukkit.event.player.PlayerMoveEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.event.player.PlayerToggleSneakEvent;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.jetbrains.annotations.NotNull;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * The Waverider's clutch: sneak while falling and, if a surface lies within
 * range below, a momentary wave (a real, non-flowing water block) appears on it
 * and breaks the fall. The wave lasts one second, and every attempt - hit or
 * miss - starts a one second cooldown, so a panicked early press means eating
 * the landing.
 *
 * A catch that saved the player from a real fall (beyond the vanilla safe-fall
 * height) grants Speed, Regeneration and Night Vision for a minute.
 */
public class WaterClutch implements VisibleAbility, CooldownAbility, Listener {
    private record Pending(Block block, float pressFallDistance, double pressY) { }

    /** Real water blocks currently placed by a clutch; FluidWalker must never solidify these. */
    private static final Set<Block> activeWater = new HashSet<>();

    private final Map<UUID, Pending> pending = new HashMap<>();
    private JavaPlugin plugin;
    private int range;
    private int buffDurationTicks;
    private int minFallBlocks;

    public static boolean isClutchWater(Block block) {
        return activeWater.contains(block);
    }

    @Override
    public @NotNull Key getKey() {
        return Key.key("waverider:water_clutch");
    }

    @Override
    public String title() {
        return "Wavecatch";
    }

    @Override
    public String description() {
        return "Sneak while falling, within ten blocks of the ground, to conjure a fleeting wave that breaks your fall. Any attempt takes a second to recover - time it well. A true catch from a deadly height invigorates you for a minute.";
    }

    @Override
    public Cooldowns.CooldownInfo getCooldownInfo() {
        return new Cooldowns.CooldownInfo(20);
    }

    @Override
    public void initialize(JavaPlugin plugin) {
        this.plugin = plugin;
        range = this.registerConfigOption(plugin, "range",
                Collections.singletonList("Maximum distance (blocks) above a surface at which the clutch still catches"),
                ConfigManager.SettingType.INTEGER, 10);
        buffDurationTicks = this.registerConfigOption(plugin, "buff-duration",
                Collections.singletonList("Duration (ticks) of the Speed/Regeneration/Night Vision reward"),
                ConfigManager.SettingType.INTEGER, 1200);
        minFallBlocks = this.registerConfigOption(plugin, "min-fall-blocks",
                Collections.singletonList("Minimum total fall (blocks) for a catch to grant the reward buffs"),
                ConfigManager.SettingType.INTEGER, 3);
    }

    @EventHandler
    public void onToggleSneak(PlayerToggleSneakEvent event) {
        if (!event.isSneaking()) return;
        this.runForAbility(event.getPlayer(), this::attempt);
    }

    private void attempt(Player player) {
        if (player.isOnGround() || player.getFallDistance() <= 0) return; // not falling: no attempt
        if (player.getLocation().getBlock().isLiquid()) return;           // already in fluid
        if (this.hasCooldown(player)) return;
        this.setCooldown(player);

        // First non-air block below the feet, within range.
        Block feet = player.getLocation().getBlock();
        Block target = null;
        for (int d = 1; d <= range + 1; d++) {
            Block block = feet.getRelative(0, -d, 0);
            if (!block.getType().isAir()) {
                target = block;
                break;
            }
        }
        if (target == null) {
            // Pressed too early: nothing happens, the cooldown ticks, gravity wins.
            player.playSound(player.getLocation(), Sound.BLOCK_POINTED_DRIPSTONE_DRIP_WATER, 1f, 0.6f);
            return;
        }

        Block waterBlock = target.getRelative(BlockFace.UP);
        if (!waterBlock.getType().isAir()) return; // can only conjure the wave into open air

        waterBlock.setType(Material.WATER, false);
        activeWater.add(waterBlock);
        pending.put(player.getUniqueId(),
                new Pending(waterBlock, player.getFallDistance(), player.getLocation().getY()));
        player.playSound(waterBlock.getLocation(), Sound.ITEM_BUCKET_EMPTY, 1f, 1.2f);

        Bukkit.getScheduler().runTaskLater(plugin, () -> {
            activeWater.remove(waterBlock);
            if (waterBlock.getType() == Material.WATER) {
                waterBlock.setType(Material.AIR, false);
            }
            Pending p = pending.get(player.getUniqueId());
            if (p != null && p.block().equals(waterBlock)) {
                pending.remove(player.getUniqueId());
            }
        }, 20L);
    }

    @EventHandler
    public void onBlockFromTo(BlockFromToEvent event) {
        // The wave is a still patch of sea: never let it flow anywhere.
        if (activeWater.contains(event.getBlock())) {
            event.setCancelled(true);
        }
    }

    @EventHandler
    public void onPlayerMove(PlayerMoveEvent event) {
        Pending p = pending.get(event.getPlayer().getUniqueId());
        if (p == null) return;
        Player player = event.getPlayer();
        if (!player.getLocation().getBlock().equals(p.block())) return;
        if (!activeWater.contains(p.block())) return;

        // Caught it: the wave is underfoot before it broke.
        pending.remove(player.getUniqueId());
        double totalFall = p.pressFallDistance() + (p.pressY() - player.getLocation().getY());
        player.setFallDistance(0);
        if (totalFall > minFallBlocks) {
            player.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, buffDurationTicks, 0, false, true, true));
            player.addPotionEffect(new PotionEffect(PotionEffectType.REGENERATION, buffDurationTicks, 0, false, true, true));
            player.addPotionEffect(new PotionEffect(PotionEffectType.NIGHT_VISION, buffDurationTicks, 0, false, true, true));
            player.playSound(player.getLocation(), Sound.ENTITY_DOLPHIN_SPLASH, 1f, 1f);
        }
    }

    @EventHandler(priority = EventPriority.LOW)
    public void onFallDamage(EntityDamageEvent event) {
        // Guarantee: no fall damage while a clutch wave is live directly beneath us.
        if (event.getCause() != EntityDamageEvent.DamageCause.FALL) return;
        if (!(event.getEntity() instanceof Player player)) return;
        Pending p = pending.get(player.getUniqueId());
        if (p == null) return;
        Block feet = player.getLocation().getBlock();
        if (feet.equals(p.block()) || feet.equals(p.block().getRelative(BlockFace.UP))) {
            event.setCancelled(true);
            player.setFallDistance(0);
        }
    }

    @EventHandler
    public void onQuit(PlayerQuitEvent event) {
        pending.remove(event.getPlayer().getUniqueId());
    }
}
