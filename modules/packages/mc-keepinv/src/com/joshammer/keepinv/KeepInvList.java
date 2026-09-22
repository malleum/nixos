package com.joshammer.keepinv;

import java.util.HashSet;
import java.util.Locale;
import java.util.Random;
import java.util.Set;

import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * Per-player keep-inventory.
 *
 * The keepInventory gamerule is global, so the world runs with it off -- every
 * player dies like vanilla -- and this listener turns it back on for the names
 * in config.yml, which NixOS writes from modules/services/mc.nix.
 *
 * Two lists:
 *   players  -- keep, every time.
 *   coinflip -- keep on a per-death roll, at coinflip-chance.
 * A name in both is treated as always-keep; the roll never happens.
 *
 * Nothing here is reachable by a player: no commands, no permissions, no
 * messages -- a coinflip loser sees exactly what a vanilla death looks like.
 * The outcome of every roll is logged to the console so there is a record when
 * somebody disputes it.
 */
public final class KeepInvList extends JavaPlugin implements Listener {
    private Set<String> keepers = Set.of();
    private Set<String> gamblers = Set.of();
    private double chance = 0.5D;

    /**
     * Not SecureRandom: this decides who walks back to their stuff, not
     * anything anyone gains by predicting.
     */
    private final Random random = new Random();

    @Override
    public void onEnable() {
        saveDefaultConfig();
        reloadKeepers();
        getServer().getPluginManager().registerEvents(this, this);
    }

    private static Set<String> lowercased(final Iterable<String> names) {
        final Set<String> out = new HashSet<>();
        for (final String name : names) {
            out.add(name.toLowerCase(Locale.ROOT));
        }
        return out;
    }

    private void reloadKeepers() {
        reloadConfig();
        keepers = lowercased(getConfig().getStringList("players"));
        gamblers = lowercased(getConfig().getStringList("coinflip"));
        chance = getConfig().getDouble("coinflip-chance", 0.5D);

        getLogger().info("always keep inventory: " + keepers);
        getLogger().info("keep inventory at " + Math.round(chance * 100) + "%: " + gamblers);
    }

    /**
     * HIGHEST rather than NORMAL so this is the last word on the event; there
     * is no MONITOR handler here because MONITOR must not mutate the event.
     */
    @EventHandler(priority = EventPriority.HIGHEST)
    public void onPlayerDeath(final PlayerDeathEvent event) {
        final Player player = event.getEntity();
        final String name = player.getName().toLowerCase(Locale.ROOT);

        final boolean keep;
        if (keepers.contains(name)) {
            keep = true;
        } else if (gamblers.contains(name)) {
            keep = random.nextDouble() < chance;
            getLogger().info(player.getName() + " died and rolled " + (keep ? "keep" : "drop"));
        } else {
            keep = false;
        }

        event.setKeepInventory(keep);
        event.setKeepLevel(keep);

        // setKeepInventory(true) stops the *respawn* from clearing the player,
        // but the drop list has already been filled in, so it has to be emptied
        // too or the items exist twice.
        if (keep) {
            event.getDrops().clear();
            event.setDroppedExp(0);
        }
    }
}
