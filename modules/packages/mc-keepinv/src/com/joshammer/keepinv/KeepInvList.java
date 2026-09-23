package com.joshammer.keepinv;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.Set;

import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.event.inventory.InventoryType;
import org.bukkit.inventory.Inventory;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.PlayerInventory;
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
     * Inventory types whose contents belong to the open screen rather than to
     * the player: closing the screen -- which dying does -- hands the items
     * back, and a player who never gets the chance to have them handed back
     * loses them. Anything not listed here (chests, shulkers, hoppers, the
     * ender chest) stores its items in a block or in player data and survives
     * the death untouched, so this must not touch it either.
     */
    private static final Set<InventoryType> TRANSIENT_SCREENS = EnumSet.of(
            InventoryType.CRAFTING,
            InventoryType.WORKBENCH,
            InventoryType.ANVIL,
            InventoryType.SMITHING,
            InventoryType.GRINDSTONE,
            InventoryType.CARTOGRAPHY,
            InventoryType.LOOM,
            InventoryType.STONECUTTER,
            InventoryType.ENCHANTING,
            InventoryType.MERCHANT,
            InventoryType.BEACON);

    /**
     * Screens whose last slot is a result slot. The stack sitting in one is a
     * preview computed from the input slots, not an item anybody owns yet:
     * taking it *and* the inputs would hand the player the ingredients and the
     * finished product both, which is a duplication bug and a nastier one than
     * the loss this class exists to fix.
     */
    private static final Set<InventoryType> RESULT_SLOT_LAST = EnumSet.of(
            InventoryType.ANVIL,
            InventoryType.SMITHING,
            InventoryType.GRINDSTONE,
            InventoryType.STONECUTTER,
            InventoryType.CARTOGRAPHY,
            InventoryType.LOOM,
            InventoryType.MERCHANT);

    /** As above, but the crafting grids put their result slot first. */
    private static final Set<InventoryType> RESULT_SLOT_FIRST = EnumSet.of(
            InventoryType.CRAFTING,
            InventoryType.WORKBENCH);

    /**
     * Index of the preview slot in {@code inventory}, or -1 when every slot
     * holds a real item -- an enchanting table's item and lapis, a beacon's
     * payment.
     */
    private static int resultSlot(final Inventory inventory) {
        final InventoryType type = inventory.getType();
        if (RESULT_SLOT_FIRST.contains(type)) {
            return 0;
        }
        if (RESULT_SLOT_LAST.contains(type)) {
            return inventory.getSize() - 1;
        }
        return -1;
    }

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

    private static boolean present(final ItemStack stack) {
        return stack != null && !stack.getType().isAir();
    }

    /**
     * Empties the slots that a kept inventory does not cover -- the item on the
     * cursor and, if the player died with a crafting-style screen open, its
     * contents -- and returns what was in them.
     */
    private static List<ItemStack> takeStraySlots(final Player player) {
        final List<ItemStack> stray = new ArrayList<>();

        final ItemStack cursor = player.getItemOnCursor();
        if (present(cursor)) {
            stray.add(cursor.clone());
            player.setItemOnCursor(null);
        }

        final Inventory top = player.getOpenInventory().getTopInventory();
        if (TRANSIENT_SCREENS.contains(top.getType())) {
            final int result = resultSlot(top);
            for (int slot = 0; slot < top.getSize(); slot++) {
                if (slot == result) {
                    // Clear it so the close cannot drop a copy of a craft whose
                    // ingredients are going back into the player's inventory,
                    // but never hand it to anyone.
                    top.setItem(slot, null);
                    continue;
                }
                final ItemStack stack = top.getItem(slot);
                if (present(stack)) {
                    stray.add(stack.clone());
                    top.setItem(slot, null);
                }
            }
        }

        return stray;
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

        if (!keep) {
            return;
        }

        // setKeepInventory(true) stops the *respawn* from clearing the player,
        // but the drop list has already been filled in, so it has to be emptied
        // too or the items exist twice.
        //
        // The cursor and an open crafting grid are the exception: those items
        // are in the drop list but not in the inventory that is being kept, so
        // clearing the list on its own destroys them. Move them into the
        // inventory first, and drop only what will not fit.
        final List<ItemStack> stray = takeStraySlots(player);

        event.getDrops().clear();
        event.setDroppedExp(0);

        final PlayerInventory inventory = player.getInventory();
        for (final ItemStack stack : stray) {
            event.getDrops().addAll(inventory.addItem(stack).values());
        }
    }
}
